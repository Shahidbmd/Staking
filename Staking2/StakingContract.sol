// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
contract StakingContract is ERC721Holder {

 uint256 constant APR = 150;
 uint256 constant secondsInYear = 31536000;
 uint256 constant minDuration = 120 seconds;
 uint256 constant tokensToStake = 1500 *10 **18;
 IERC721 private NFT;
 IERC20 private RewardToken;

 mapping(address =>Staker) private stakersDetails;

 struct Staker {
    uint256 stakeTime;
    uint256 unstakeTime;
    uint256 claimTime;
    uint256 nftId;
    uint256 tokenStaked;
    bool isStaking;
 }

 //Events
 event Stake (address indexed staker , uint256 amountStaked , uint256 nftId);
 event Unstake (address indexed unstaker , uint256 amountUnstaked , uint256 nftId);
 event ClaimRewards(address indexed claimer , uint256 rewardsAmount);

 constructor(IERC721 _nft, IERC20 _rewardToken){
    RewardToken = _rewardToken;
    NFT = _nft;
 }

 function getStakerData(address account) external view returns(Staker memory){
     return stakersDetails[account];
 }

 function minStakingTime() external pure returns(uint256){
     return minDuration;
 }

 function minTokensToStake() external pure returns(uint256){
     return tokensToStake;
 }


 function stake(uint256 _nftId , uint256 _tokensToStake) public {
    _greaterThanZero(_nftId);
    require(_tokensToStake == tokensToStake , "Invalid Staking Tokens");
    _nftTransfer(msg.sender,address(this), _nftId);
    RewardTransferFrom(msg.sender, address(this), _tokensToStake);
    stakersDetails[msg.sender] = Staker({stakeTime : block.timestamp , unstakeTime : 0,
    claimTime : block.timestamp , nftId : _nftId , tokenStaked : _tokensToStake, isStaking :true });
    emit Stake (msg.sender, _tokensToStake , _nftId);
 }

 function unstake() external {
    require(stakersDetails[msg.sender].isStaking, "Zero Staking");
    Staker memory staker = stakersDetails[msg.sender];
    require(block.timestamp  >= staker.stakeTime + minDuration, "Can't unstake now");
    require(RewardToken.balanceOf(address(this)) >= staker.tokenStaked + _calculateRewards(msg.sender), "insuffient Tokens for Unstake");
    _nftTransfer(address(this), msg.sender, staker.nftId);
    if(_calculateRewards(msg.sender) > 0) {
        claimRewards();
    }
    _rewardTransfer(msg.sender , staker.tokenStaked);
    emit Unstake (msg.sender, staker.tokenStaked , staker.nftId);
    delete stakersDetails[msg.sender];
 }

 function claimRewards() public {
    require(stakersDetails[msg.sender].isStaking, "Zero Staking");
    uint256 totalRewards = _calculateRewards(msg.sender);
    _greaterThanZero(totalRewards);
    stakersDetails[msg.sender].claimTime = block.timestamp;
    _rewardTransfer(msg.sender , totalRewards);
    emit ClaimRewards(msg.sender, totalRewards);
     
 }

 function _calculateRewards(address account) public view returns(uint256){
     Staker memory staker = stakersDetails[account];
    uint256 estimatedRewards = (APR * staker.tokenStaked) /100 ;
    uint256 rewardPerSec = estimatedRewards / secondsInYear ;
    uint256 rewards = rewardPerSec * (block.timestamp - staker.claimTime);
    return rewards;
 }

 function _nftTransfer(address from, address to , uint256 _nftId) internal {
    NFT.safeTransferFrom(from,to, _nftId);
 }

 function _rewardTransfer(address to, uint256 amountOfTokens) internal {
    RewardToken.transfer(to,amountOfTokens);
 }
 function RewardTransferFrom(address from, address to, uint256 amountOfTokens) internal {
    RewardToken.transferFrom(from,to, amountOfTokens);
 }

 function _greaterThanZero(uint256 value) internal pure {
     require(value >0, "invalid value");
 }

}
    