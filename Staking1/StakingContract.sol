// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingContract is ReentrancyGuard, Ownable {
    uint256 private constant APR = 100;
    uint256 private constant secondsInYear = 31104000;
    IERC20 public stakingToken;
    
    //Events
    event Staked (address indexed account, uint256 amount ,uint256 timeToStake);
    event Unstaked (address indexed account, uint256 amount ,uint256 timeToUnstake);
    event ClaimRewards(address indexed account, uint amount , uint256 totalRewards);
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
        emit Staked (msg.sender, amount, block.timestamp);
    }
    
    function unstake() external nonReentrant {
        require(stakers[msg.sender].isStaking, "No staking");
        uint256 stakedAmount = stakers[msg.sender].stakedTokens;
        uint256 rewards = calculateRewards(msg.sender);
        require(stakingToken.balanceOf(address(this)) > stakedAmount + rewards, "insufficient Tokens");
        stakers[msg.sender].stakeEnd = block.timestamp;
        stakers[msg.sender].isStaking =false;
        stakers[msg.sender].stakedTokens = 0;
        stakers[msg.sender].timeToClaim = block.timestamp;
        if(rewards > 0) {
            stakingToken.transfer(msg.sender,stakedAmount + rewards);
        }
        else{
            stakingToken.transfer(msg.sender,stakedAmount);
        } 
        emit Unstaked (msg.sender, stakedAmount + rewards, block.timestamp);
    }

    function claimRewards() external nonReentrant {
        require(stakers[msg.sender].stakedTokens > 0, "Staking is insufficient");
        uint256 totalReward = calculateRewards(msg.sender);
        require(totalReward > 0, "insufficient rewards");
        stakers[msg.sender].timeToClaim = block.timestamp;
        stakingToken.transfer(msg.sender,totalReward);
        emit ClaimRewards(msg.sender,totalReward,block.timestamp);
    }

    function calculateRewards(address account) public view returns(uint256) {
        uint256 reward;
        uint256 estimatedReward;
        uint rewardPerSec;
        uint256 noOfSeconds;
        noOfSeconds = block.timestamp - stakers[account].timeToClaim;
        estimatedReward = (APR * stakers[account].stakedTokens)/100;
        rewardPerSec = estimatedReward / secondsInYear; 
        reward = rewardPerSec * noOfSeconds;
        return reward;
    }
        
    function withdraw() external onlyOwner {
         uint256 balance = stakingToken.balanceOf(address(this));
        require(balance > 0,"insufficient Funds");
        stakingToken.transfer(msg.sender,balance);
    }
}