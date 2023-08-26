// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Staking {
    using SafeERC20 for IERC20;

    address public linqToken;
    uint256 public totalStaked;
    uint256 slippage = 6;
    uint256 public slippageAmount;
    address public constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor(address _linqToken) {
        linqToken = _linqToken;
    }

    function stakeTokens(uint256 _amount) external {
        totalStaked += _amount;
        IERC20(linqToken).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function unStake() external {
        uint256 staked = totalStaked;
        totalStaked = 0;
        IERC20(linqToken).safeTransfer(msg.sender, staked);
    }

    function addLiquidity(uint256 _tokenAmount) external payable {
        slippageAmount  =  (_tokenAmount * 6) / 100;
        uint256 liquidityAmount = _tokenAmount - slippageAmount;
        require(_tokenAmount > 0, "Token amount must be greater than 0");

        IERC20 token = IERC20(linqToken);

        token.safeTransferFrom(msg.sender, address(this), liquidityAmount);
        token.approve(uniswapRouter, liquidityAmount);

        IUniswapV2Router02 router = IUniswapV2Router02(uniswapRouter);

        // Add liquidity using the provided token amount and ETH value sent
        router.addLiquidityETH{value: msg.value}(
            address(token),
            liquidityAmount,
            0, // slippage is acceptable
            0, // slippage is acceptable
            address(this),
            block.timestamp
        );

        // Refund any remaining ETH back to the sender
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}