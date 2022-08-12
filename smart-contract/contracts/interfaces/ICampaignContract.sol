// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma abicoder v2;


abstract contract ICampaignContract {

    enum CampaignType {
        FLEX, //0
        FIX   //1
    }

    // Campaign
    struct Campaign {
        string creator;
        string campaignId;
        uint256 raise;
        uint256 amount;
        CampaignType campaignType;
        uint256 startDate;
        uint256 endDate;
        uint256 fractionCount;
        uint256 remainFractions;
        uint256 pricePerFraction;
        bool goal;
    }

    event ClaimCampaign(
        uint256 claimedAt,
        uint256 claimedFractions,
        address walletAddress,
        string claimType,
        string id,
        string campaignId
    );


    // Fan info
    struct SuperFan {
        uint256 fundedAmount;
        uint256 numberOfFractions;
        bool claimed;
        address walletAddress;
    }

    // Events
    event FundCampaign(string fanId, string campaignId, uint256 fractionAmount,uint256 fundedAmount);
    event CreateCampaign( string campaignId, Campaign campaign, string urlContent);
    event GoalReached(string campaignId, Campaign campaign);

    function setVaultWallet(address vaultAddress) external virtual;

    function isDivisibleBy10(uint256 _fractionCount) internal pure returns(bool){
        return (_fractionCount > 0) && (_fractionCount % 10 == 0);
    }

    function isExisted(string memory _campaignId)  internal virtual view returns(bool);
    function isGoalReached(string memory _campaignId) internal virtual view returns(bool);
    function isCampaignActive(string memory _campaignId)  internal virtual view returns(bool);
    function checkFinalPayment(uint256 _currentRemainFractions, string memory _campaignId) internal virtual;

    function getCampaign(string memory _campaignId) external virtual view returns(Campaign memory);
    function getCampaigns() external  virtual  view returns(Campaign[] memory);

    function createCampaign(string memory _creator, string memory _campaignId,string memory _uri, uint256 _raise, CampaignType _campaignType, uint256 _startDate,uint256 _endDate,
        uint256 _fractionCount, uint256 _priceFraction) external  virtual ;

    function fundCampaign(string memory _campaignId, uint256 _fractionAmount, string memory investor) external virtual;

    function setGoalReached(string memory _campaignId) external virtual;
    function setCollectableCampaignsAssetWallet(address _collectableCampaignsAssetnWallet) external virtual;

    function claimFractionSJAssetWallet(string memory _campaignId)  external virtual;

    function claimFractionCreator(string memory _campaignId, address _creatorWallet, uint256 _fractionCount) external virtual;

    function claimFractionSuperfan(string memory _campaignId, string memory _fanId, address _fanAddress)  external virtual;

    function claimFractionOther(string memory _campaignId,string memory _typeClaim, address _otherWallet, uint256 _fractionCount) external virtual;

}
