// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
 import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract StakingContract is ReentrancyGuard, Ownable {
    uint256 private constant APR = 100;
    uint256 private constant secondsInYear = 31104000;
    //total Amouunt Staked
    uint256 public totalStaked;
    IERC20 public stakingToken;

    //staker Details
    struct Staker {
        uint256 stakedTokens;
        uint256 stakeStart;
        uint256 stakeEnd;
        uint256 timeToClaim;
        bool isStaking;
    }
    mapping(address => Staker) public stakers;
    
    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }
    
    function stake(uint256 amount) external {
        require(amount > 1 ether, "Invalid Staking Amount");
        require(!stakers[msg.sender].isStaking, "Already staking");
        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakers[msg.sender].stakedTokens = amount;
        stakers[msg.sender].stakeStart = block.timestamp;
        stakers[msg.sender].timeToClaim = block.timestamp;
        stakers[msg.sender].isStaking = true;
        totalStaked += amount;
    }
    
    function unstake() external nonReentrant {
        require(stakers[msg.sender].isStaking, "No staking");
        require(stakingToken.balanceOf(address(this)) > stakers[msg.sender].stakedTokens, "insufficient Tokens");
        uint256 stakedAmount = stakers[msg.sender].stakedTokens;
        uint256 reward = calculateRewards();
        stakers[msg.sender].stakeEnd = block.timestamp;
        stakers[msg.sender].isStaking =false;
        stakers[msg.sender].stakedTokens = 0;
        stakingToken.transfer(msg.sender,stakedAmount + reward);
    }

    function claimRewards() external nonReentrant {
        require(stakers[msg.sender].stakedTokens > 0, "Invalid Transaction");
        uint256 reward = calculateRewards();
        stakers[msg.sender].timeToClaim = block.timestamp;
        stakingToken.transfer(msg.sender,reward);
    }

    function calculateRewards() internal view returns(uint256) {
        uint256 reward;
        uint256 estimatedReward;
        uint rewardPerSec;
        uint256 noOfSeconds;
        noOfSeconds = block.timestamp - stakers[msg.sender].timeToClaim;
        estimatedReward = (APR * stakers[msg.sender].stakedTokens)/100;
        rewardPerSec = estimatedReward / secondsInYear; 
        reward = rewardPerSec * noOfSeconds;
        require(reward > 0, "insufficient Rewards");
        return reward;
    }
        
    function withdraw() external onlyOwner {
         uint256 balance = stakingToken.balanceOf(address(this));
        require(balance > 0,"insufficient Funds");
       
        stakingToken.transfer(msg.sender,balance);
    }
}