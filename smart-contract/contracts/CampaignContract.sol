// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ICampaignContract.sol";
import "./nfts/SJFractions.sol";

contract CampaignContract is ICampaignContract, Ownable, Initializable, ERC1155Holder {
    // Counter campaign id
    using Counters for Counters.Counter;

    address public fractionContract;
    address public vaultWallet;
    address public collectableCampaignsAssetWallet;

    Counters.Counter private _campCounter;

    constructor() initializer {
        vaultWallet = owner();
    }

    // Constructor
    function initialize(address _collectableCampaignsAssetWallet) public payable initializer {
        collectableCampaignsAssetWallet = _collectableCampaignsAssetWallet;
    }

    // Mapping
    mapping(uint256 => string) private countToCampaignId; // Map counter to campaign
    mapping(string => Campaign) private idToCampaign; // Map campaignId to campaign
    mapping(string => mapping(string => SuperFan)) private fanToCamp; // Map campaignId to list fan


    modifier conditions(string memory _campaignId, uint _endTimestamp, uint256 _fractionCount){
        require( bytes(_campaignId).length !=0, "CampaignContract::createCampaign: You must set campaignId not empty");
        require(isDivisibleBy10(_fractionCount), "CampaignContract::createCampaign: You must set fraction divisible by 10");
        require(vaultWallet != address(0), "CampaignContract::createCampaign: You must set vault wallet first");
        require(_endTimestamp > block.timestamp, "CampaignContract::createCampaign: Campaign must end in the future");
        require(!isExisted(_campaignId), "CampaignContract::createCampaign:: Campaign is existed");
        _;
    }

    modifier validFund(string memory _campaignId, uint256 _amount) {
        require(isExisted(_campaignId), "CampaignContract::fundCampaign: Non existent campaign id provided");
        require(isCampaignActive(_campaignId), "CampaignContract::fundCampaign: Campaign not active");
        require(!isGoalReached(_campaignId),"CampaignContract::fundCampaign: Campaing is Goal Reached");
        require(_amount > 0, "CampaignContract::fundCampaign: You must send some amount fractions");
        _;
    }

    modifier validClaim(string memory _campaignId) {
        require(!isCampaignActive(_campaignId) || isGoalReached(_campaignId),"CampaignContract::claim: Campaing is not End");
        _;
    }

    modifier validClaimOther(string memory _campaignId) {
        require(!isGoalReached(_campaignId),"CampaignContract::fundCampaign: Campaing is Goal Reached");
        _;
    }

    function setFractionContract(address _fractionContract) external onlyOwner {
        fractionContract = _fractionContract;
    }

    function isExisted(string memory _campaignId) override internal  view returns(bool){
        return idToCampaign[_campaignId].fractionCount != 0;
    }

    function isGoalReached(string memory _campaignId) override internal view returns(bool) {
        return idToCampaign[_campaignId].goal;
    }

    function isCampaignActive(string memory _campaignId) override internal view returns(bool) {
        return idToCampaign[_campaignId].endDate > block.timestamp;
    }

    function setVaultWallet(address vault) override external onlyOwner {
        require(vault !=  address(0), "Vault wallet cannot be empty");
        vaultWallet = vault;
    }

    function setCollectableCampaignsAssetWallet(address _collectableCampaignsAssetWallet) override external {
        require(collectableCampaignsAssetWallet == address(0), "CampaignContract::setCollectableCampaignsAssetWallet: Can only be set one time");
        collectableCampaignsAssetWallet = _collectableCampaignsAssetWallet;
    }


    function createCampaign(string memory _creator,
        string memory _campaignId, string memory _uri, uint256 _raise, CampaignType _campaignType, uint256 _startDate,
        uint256 _endDate, uint256 _fractionCount, uint256 _priceFraction
    ) override public onlyOwner conditions(_campaignId, _endDate, _fractionCount) {
        require(fractionContract != address(0), "You must set fraction contract first");
        uint256 newCampCount = _campCounter.current();

        Campaign memory _camp = Campaign(
            _creator,
            _campaignId,
            _raise,
            0,
            _campaignType,
            _startDate,
            _endDate,
            _fractionCount,
            _fractionCount * 90 / 100, //10% Owned by SuperJoi
            _priceFraction,
            false
        );

        idToCampaign[_campaignId] = _camp;
        countToCampaignId[newCampCount] = _campaignId;
        _campCounter.increment();

        SJFractions _sjfractions = SJFractions(fractionContract);
        _sjfractions.mint(_campaignId, _uri, _fractionCount, address(this));

        emit CreateCampaign(_campaignId, _camp, _uri);
    }

    function getCampaigns() override public view returns (Campaign[] memory) {
        uint256 currentCampId = _campCounter.current();
        Campaign[] memory listCamp = new Campaign[](currentCampId);
        for (uint i = 0; i < currentCampId; i++) {
            listCamp[i] = idToCampaign[countToCampaignId[i]];
        }

        return listCamp;
    }

    function getCampaign(string memory _campaignId) override public view returns (Campaign memory) {
        return idToCampaign[_campaignId];
    }

    function fundCampaign(
        string memory _campaignId, uint256 _fractionAmount, string memory investor
    ) override public validFund(_campaignId, _fractionAmount) onlyOwner {
        Campaign storage campaign = idToCampaign[_campaignId];
        SuperFan storage superfan = fanToCamp[_campaignId][investor];

        require(_fractionAmount <= campaign.remainFractions, "CampaignContract::fundCampaign: Number of fragment must less than remain fragment.");

        uint256 payAmount = _fractionAmount * campaign.pricePerFraction;

        // Update campaign
        campaign.amount += payAmount;
        campaign.remainFractions -= _fractionAmount;

        // Add user to list fan
        superfan.fundedAmount += payAmount;
        superfan.numberOfFractions += _fractionAmount;
        superfan.claimed = false;

        emit FundCampaign(investor,_campaignId,_fractionAmount,payAmount);
        checkFinalPayment(campaign.remainFractions, _campaignId);
    }

    function setGoalReached(string memory _campaignId) override public onlyOwner{
        Campaign storage campaign = idToCampaign[_campaignId];
        require(campaign.endDate < block.timestamp, "This campaign is not ended.");
        campaign.goal = true;
    }



    function checkFinalPayment(uint256 currentRemainFractions, string memory _campaignId) override internal{
        if(currentRemainFractions == 0){
            Campaign storage campaign = idToCampaign[_campaignId];

            campaign.goal = true;
            emit GoalReached(_campaignId, campaign);
        }
    }

    /**
        Claim superfan
    **/
    function claimFractionSuperfan(string memory _campaignId, string memory _fanId, address _fanAddress) override external onlyOwner validClaim(_campaignId) {
        SuperFan storage _sjfan = fanToCamp[_campaignId][_fanId];
        require(_sjfan.fundedAmount > 0 && _sjfan.numberOfFractions > 0, "You are not funded this campaign");
        require(_sjfan.claimed != true, "You have claimed");

        // Transfer fragments token to user
        SJFractions _sjfractions = SJFractions(fractionContract);
        uint256 itemId = _sjfractions.getItemId(_campaignId);
        _sjfractions.safeTransferFrom(address(this), _fanAddress, itemId, _sjfan.numberOfFractions, "0x00");

        // Update sjfan info
        _sjfan.claimed = true;

        //Emit event claim
        emit ClaimCampaign(block.timestamp,_sjfan.numberOfFractions,_fanAddress,"superfan_wallet",_fanId,_campaignId);

    }

    /**
        Claim SJ Asset Wallet
    **/
    function claimFractionSJAssetWallet(string memory _campaignId) override external onlyOwner validClaim(_campaignId){
        Campaign memory _camp = idToCampaign[_campaignId];

        SJFractions _sjfractions = SJFractions(fractionContract);
        uint256 itemId = _sjfractions.getItemId(_campaignId);
        uint256 numberFraction = _camp.fractionCount * 10 / 100;

        // Tranfer 10% fraction of campaign to Collectable Campaigns Asset Wallet
        _sjfractions.safeTransferFrom(address(this), collectableCampaignsAssetWallet, itemId, numberFraction, "0x00");

        //Emit event claim
        emit ClaimCampaign(block.timestamp, numberFraction,collectableCampaignsAssetWallet,"asset_wallet","",_campaignId);

    }

    /**
        Claim Creator Wallet
    **/
    function claimFractionCreator(string memory _campaignId, address _creatorWallet, uint256 _fractionCount ) override external onlyOwner validClaimOther(_campaignId){
        this.claimFractionOther(_campaignId,"creator_wallet",_creatorWallet,_fractionCount);
    }

    function claimFractionOther(string memory _campaignId,string memory _typeClaim, address _otherWallet, uint256 _fractionCount) override external onlyOwner validClaimOther(_campaignId) {
        Campaign memory _camp = idToCampaign[_campaignId];
        require(_fractionCount > 0 && _camp.remainFractions > _fractionCount, "CampaignContract::claimFractionOther:Over limit");

        SJFractions _sjfractions = SJFractions(fractionContract);
        uint256 itemId = _sjfractions.getItemId(_campaignId);
        _sjfractions.safeTransferFrom(address(this), _otherWallet, itemId, _fractionCount, "0x00");

        //Emit event claim
        emit ClaimCampaign(block.timestamp, _fractionCount, _otherWallet, _typeClaim ,"",_campaignId);
    }
}
