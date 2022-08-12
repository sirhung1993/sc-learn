// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SJFractions.sol";

contract SJMarketplace is ReentrancyGuard, Ownable, IERC1155Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    //to check if the market is open or close
    bool public isMarketOpen = false;
    address tokenContract;
    uint8 SELL_PERCENT_FEE = 10;
    uint256 removingPrice = 2 ether;

    struct MarketItem {
        uint itemId;
        uint256 tokenId;
        uint256 amount;
        string campaignId;
        uint256 price;
        address nftContract;
        address payable seller;
        address payable owner;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;
    mapping (address => bool) private _listNFTContract;

    event MarketItemCreated (
        uint indexed itemId,
        uint256 indexed tokenId,
        uint256 amount,
        string campaignId,
        uint256 price,
        address indexed nftContract,
        address seller,
        address owner,
        bool sold
    );

    event MarketItemSold (
        uint indexed itemId,
        uint256 indexed tokenId,
        uint256 amount,
        string campaignId,
        uint256 price,
        address seller,
        address owner,
        address indexed nftContract
    );

    event MarketItemRemoved (
        uint indexed itemId,
        uint256 indexed tokenId,
        address indexed nftContract
    );

    //to set the market open/close
    function setMarketOpen(bool _isOpen) external onlyOwner {
        isMarketOpen = _isOpen;
    }

    function setSellPercentFee(uint8 _percent) external onlyOwner {
        require(_percent >= 0 && _percent <= 100, "Invalid percentage!");
        SELL_PERCENT_FEE = _percent;
    }

    function setAcceptNFTContract(address _nftContract) external onlyOwner {
        _listNFTContract[_nftContract] = true;
    }

    function removeAcceptNFTContract(address _nftContract) external onlyOwner {
        _listNFTContract[_nftContract] = false;
    }

    function setRemovingPrice(uint256 _removingPrice) external onlyOwner {
        require(removingPrice >= 0, "Removing price must greater or equal zero");
        removingPrice = _removingPrice;
    }

    function _checkAcceptNFTContract(address _nftContract) private view returns (bool) {
        return _listNFTContract[_nftContract];
    }

    function setTokenContract(address _tokenContract) external onlyOwner {
        tokenContract = _tokenContract;
    }

    /* Places an item for sale on the marketplace */
    function createMarketItem(
        address nftContract,
        string memory campaignId,
        uint256 amount,
        uint256 price
    ) public nonReentrant {
        require(isMarketOpen, "The Market is now closed! Please try again later!");
        require(price > 0, "Price must be at least 1 wei");
        require(_checkAcceptNFTContract(nftContract), "This NFT is not acceptable to sell on martket");
        require(tokenContract != address(0), "Token contract is null");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        uint256 _fracId = SJFractions(nftContract).getItemId(campaignId);
        require(_fracId != 0, "Token is not exist");

        idToMarketItem[itemId] =  MarketItem(
            itemId,
            _fracId,
            amount,
            campaignId,
            price,
            nftContract,
            payable(msg.sender),
            payable(address(0)),
            false // isSold
        );

        IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), _fracId, amount, "0x00");

        emit MarketItemCreated(
            itemId,
            _fracId,
            amount,
            campaignId,
            price,
            nftContract,
            msg.sender,
            address(0),
            false // isSold
        );
    }

    function _checkItemSeller(uint256 itemId) private view returns (bool) {
        address itemSeller = idToMarketItem[itemId].seller;
        if(itemSeller == msg.sender) {
            return true;
        }

        return false;
    }

    /* Remove an item for sale on the marketplace */
    function removeMarketItem(
        address nftContract,
        uint256 itemId
    ) public nonReentrant {
        require(_checkAcceptNFTContract(nftContract), "This NFT is not acceptable to sell on market");
        require(_checkItemSeller(itemId), "You're not own this item");
        require(IERC20(tokenContract).balanceOf(msg.sender) >= removingPrice, "Your balance is not enough to remove item from market");

        MarketItem storage _item = idToMarketItem[itemId];

        // Send NFT to seller
        IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, _item.tokenId, _item.amount, "0x00");

        // Send removing fee to owner
        IERC20(tokenContract).transferFrom(msg.sender, owner(), removingPrice);

        delete idToMarketItem[itemId];

        emit MarketItemRemoved(
            itemId,
            _item.tokenId,
            nftContract
        );
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(
        address nftContract,
        uint256 itemId
    ) public nonReentrant {
        MarketItem storage _item = idToMarketItem[itemId];
        require(isMarketOpen, "The Market is now closed! Please try again later!");
        require(_checkAcceptNFTContract(nftContract), "This NFT is not acceptable to sell on martket");
        require(idToMarketItem[itemId].seller != msg.sender, "You cannot buy your item");
        require(idToMarketItem[itemId].price > 0, "Invalid price or item does not exist");
        require(!idToMarketItem[itemId].sold, "This item has been sold!");

        // Send token to seller & owner
        if (SELL_PERCENT_FEE > 0) {
            uint listingPrice = _item.price / SELL_PERCENT_FEE;
            IERC20(tokenContract).transferFrom(msg.sender, idToMarketItem[itemId].seller, _item.price-listingPrice);
            IERC20(tokenContract).transferFrom(msg.sender, owner(), listingPrice);
        } else {
            IERC20(tokenContract).transferFrom(msg.sender, owner(), _item.price);
        }

        // Send NFT to buyer
        IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, _item.tokenId, _item.amount, "0x000");

        // Mark the NFT as sold
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();

        // Emit event
        emit MarketItemSold(
            itemId,
            _item.tokenId,
            _item.amount,
            _item.campaignId,
            _item.price,
            _item.seller,
            msg.sender,
            nftContract
        );
    }

    function getItemById(uint256 itemId) public view returns (MarketItem memory) {
        return idToMarketItem[itemId];
    }

    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (!idToMarketItem[i+1].sold && idToMarketItem[i+1].seller != address(0)) {
                MarketItem storage currentItem = idToMarketItem[i+1];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i+1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i+1].owner == msg.sender) {
                MarketItem storage currentItem = idToMarketItem[i+1];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items a user has created */
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint totalItemCount = _itemIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i+1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i+1].seller == msg.sender) {
                MarketItem storage currentItem = idToMarketItem[i+1];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override(IERC1155Receiver) returns (bytes4) {
        return
        bytes4(
            keccak256(
                "onERC1155Received(address,address,uint256,uint256,bytes)"
            )
        );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override(IERC1155Receiver) returns (bytes4) {
        return
        bytes4(
            keccak256(
                "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
            )
        );
    }

    function supportsInterface(bytes4 interfaceId) external override view returns (bool) {
        return interfaceId == type(IERC1155).interfaceId;
    }
}
