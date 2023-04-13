// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract StakingContract is ERC721Holder,ReentrancyGuard {
 using SafeMath for uint256;
 uint256 constant APR = 150;
 uint256 constant secondsInYear = 31536000;
 uint256 constant minStakingDuration = 120 seconds;
 uint256 constant tokensToStake = 100 *10 **18;
 IERC721 private NFT;
 IERC20 private EtherToken;

 mapping(address =>Staker[]) private stakersDetails;

 struct Staker {
    uint256 stakeTime;
    uint256 unstakeTime;
    uint256 rewardClaimTime;
    uint256 nftId;
    uint256 amountStaked;
 }

 //Events
 event Stake (address indexed staker,uint256 amountStaked , uint256 nftId);
 event Unstake (address indexed unstaker , uint256 amountUnstaked , uint256 nftId);
 event ClaimRewards(address indexed claimer , uint256 rewardsAmount);

 constructor(IERC721 _nft, IERC20 _etherToken){
    EtherToken = _etherToken;
    NFT = _nft;
 }

 function getStakingDetails(address account) external view returns(Staker[] memory){
     return stakersDetails[account];
 }

 function minStakingTime() external pure returns(uint256){
     return minStakingDuration;
 }

 function tokensAmountToStake() external pure returns(uint256){
     return tokensToStake;
 }

 function getTotalStakingAmount(address _account) public view returns(uint256) {
    uint256 total;
      for(uint256 i = 0; i < stakersDetails[_account].length; i++) {
            total += stakersDetails[_account][i].amountStaked;
      }
   return total;
 }

 function getTotalNoOfStaking(address _account) external view returns (uint256) {
    return stakersDetails[_account].length ;
 }



 function stake(uint256 _nftId) external nonReentrant {
    _greaterThanZero(_nftId);
    _nftTransfer(msg.sender,address(this), _nftId);
    _tokenTransfer(msg.sender, address(this), tokensToStake);
    Staker memory staker = Staker({stakeTime : block.timestamp , unstakeTime : 0,
    rewardClaimTime : block.timestamp , nftId : _nftId , amountStaked : tokensToStake });
    stakersDetails[msg.sender].push(staker);
    emit Stake (msg.sender,tokensToStake ,_nftId);
 }

 function unstake(uint256 _stakedId) external nonReentrant {
    Staker memory staker = stakersDetails[msg.sender][_stakedId];
    require(staker.stakeTime != 0, "Have not Staked ");
    require(block.timestamp  >= staker.stakeTime + minStakingDuration, "Can't unstake now");
    uint256 rewardsCalculated = _calculateRewards(msg.sender, _stakedId);
    stakersDetails[msg.sender][_stakedId] = stakersDetails[msg.sender][stakersDetails[msg.sender].length - 1];
    stakersDetails[msg.sender].pop();
    if(EtherToken.balanceOf(address(this)) >= staker.amountStaked + rewardsCalculated && rewardsCalculated >0) {
       claimRewards(_stakedId);
       _tokenTransfer(msg.sender , staker.amountStaked);
       _nftTransfer(address(this), msg.sender, staker.nftId);
     }
     _tokenTransfer(msg.sender , staker.amountStaked);
     _nftTransfer(address(this), msg.sender, staker.nftId);
    emit Unstake (msg.sender, staker.amountStaked , staker.nftId);
 }

 function claimRewards(uint256 _stakedId) public nonReentrant {
    require(staker.stakeTime != 0, "Have not Staked ");
    uint256 totalRewards = _calculateRewards(msg.sender, _stakedId);
    _greaterThanZero(totalRewards);
    stakersDetails[msg.sender][_stakedId].rewardClaimTime = block.timestamp;
    _tokenTransfer(msg.sender , totalRewards);
    emit ClaimRewards(msg.sender, totalRewards);
     
 }

 function _calculateRewards(address _account, uint256 _stakedId) public view returns(uint256){
     Staker memory staker = stakersDetails[_account][_stakedId];
    uint256 estimatedRewards = (APR.mul(staker.amountStaked)).div(100) ;
    uint256 rewardPerSec = estimatedRewards.div(secondsInYear);
    uint256 rewards = rewardPerSec.mul(block.timestamp.sub(staker.rewardClaimTime));
    return rewards;
 }

 function _nftTransfer(address from, address to , uint256 _nftId) internal {
    NFT.safeTransferFrom(from,to, _nftId);
 }

 function _tokenTransfer(address to, uint256 amountOfTokens) internal  {
    EtherToken.transfer(to,amountOfTokens);
 }
 function _tokenTransfer(address from, address to, uint256 amountOfTokens) internal {
    EtherToken.transferFrom(from,to, amountOfTokens);
 }

 function _greaterThanZero(uint256 value) internal pure {
     require(value >0, "invalid value");
 }

}
    