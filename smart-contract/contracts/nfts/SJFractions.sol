// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

import "../interfaces/ICampaignContract.sol";
import "../interfaces/AbstractERC1155.sol";

contract SJFractions is ERC1155, AbstractERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private _itemId;

    address public campaignContract;
    mapping (uint256 => string) private _tokenURIs;
    mapping (string => uint256) private _campaignToItemId;
    mapping(address => bool) private _isManager;
    mapping(address => bool) private _blacklist;

    event MintItem(
        uint256 itemId,
        string campaignId,
        uint256 amount
    );

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC1155("SuperJoiNFTFraction")  {
        name_ = _name;
        symbol_ = _symbol;

    }


    modifier onlyManager {
        require(_isManager[msg.sender] == true, "CampaignContract::mint: Only Manager can perform this action");
        _;
    }

    function getItemId(string memory _campaignId) public view returns(uint256){
        ICampaignContract.Campaign memory _camp = ICampaignContract(campaignContract).getCampaign(_campaignId);
        require(bytes(_camp.campaignId).length != 0, "SJFractions::getItemId: Campaign is not exist");

        return _campaignToItemId[_campaignId];
    }

    function addUserToBlacklist(address userAddress) public onlyOwner {
        _blacklist[userAddress] = true;
    }

    function setManager(address userAddress) public onlyOwner {
        _isManager[userAddress] = true;
    }


    function setCampaignContract(address _campaignContract) public onlyOwner {
        campaignContract = _campaignContract;
        setManager(_campaignContract);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override(ERC1155)
    {
        require(_blacklist[from] != true && _blacklist[to] != true, "SJFractions::_beforeTokenTransfer: You or receiver are in the blacklist");
        require(_isManager[from] == true || _isManager[to] == true,"SJFractions::_beforeTokenTransfer: From/To is not Manager");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _setTokenUri(uint256 tokenId, string memory tokenURI) private {
        _tokenURIs[tokenId] = tokenURI;
    }

    function mint(string memory campaignId, string memory tokenURI, uint256 amount, address owner) public onlyManager {
        require(campaignContract != address(0), "SJFractions::mint: You must set campaign contract first");

        ICampaignContract.Campaign memory _camp = ICampaignContract(campaignContract).getCampaign(campaignId);
        require(bytes(_camp.campaignId).length != 0, "SJFractions::mint: Campaign is not exist");

        uint256 newItemId = _itemId.current();
        _mint(owner, newItemId, amount, "");
        _setTokenUri(newItemId, tokenURI);
        _campaignToItemId[campaignId] = newItemId;
        _itemId.increment();

        emit MintItem(
            newItemId,
            campaignId,
            amount
        );
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        return(_tokenURIs[tokenId]);
    }

}