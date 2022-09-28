// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";
import {Oracle} from "./Oracle.sol";

contract StableCoin is ERC20{

    DepositorCoin public depositorCoin; 
    uint256 public feeRatePercentage;
    Oracle public oracle;
    uint256 public constant INITIAL_COLLATERAL_PERCENTAGE = 10;

    constructor( uint256 _feeRatePercentage, Oracle _oracle) ERC20("StableCoin", "STC"){
        feeRatePercentage = _feeRatePercentage;
        oracle = _oracle;
    }

    function mint() external payable{
        uint256 fee = _getFee(msg.value);
        uint256 remainingEth = msg.value - fee;
        uint256 mintStableCoinAmount = remainingEth * oracle.getPrice();
        _mint(msg.sender, mintStableCoinAmount);
    }

    function _getFee(uint256 ethAmount) private view returns (uint256){
        bool hasDepositors = address (depositorCoin) != address(0) && depositorCoin.totalSupply() > 0;
        if(!hasDepositors){
            return 0;
        }
        return (feeRatePercentage * ethAmount)/ 100;
    }

    function burn (uint256 burnStableCoinAmount) external {
        int256 deficitOrSurplus = _getDeficitOrSurplusInContractInUsd();
        require(deficitOrSurplus >=0, "STC cannot burn while being in deficit");
        _burn(msg.sender, burnStableCoinAmount);
        uint256 refundingEth = burnStableCoinAmount / oracle.getPrice();
        uint256 fee = _getFee(refundingEth);
        uint256 refundEthAfterFee = refundingEth - fee;        
        (bool success,) = msg.sender.call{value : refundEthAfterFee}("");
        require(success, "STC: Burn refund transaction failed");

    }


    function depositCollateralBuffer() external payable {
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractInUsd();
        
        if(deficitOrSurplus <= 0){

            uint256 deficitInUsd = uin256(deficitOrSurplusInUsd * -1);
            uint256 usdInEthPrice = oracle.getPrice();
            uint256 deficitInEth = deficitInUsd / usdInEthPrice; 

            uint256 requiredInitialSurplusInUsd = (INITIAL_COLLATERAL_PERCENTAGE * totalSupply)/100;
            uint256 requiredInitialSurplusInEth = requiredInitialSurplusInUsd/ usdInEthPrice;
            require(msg.value >= deficitInEth + requiredInitialSurplusInEth, "STC: Initial collateral ratio not met");

            uint256 newInitialSurplusInEth = msg.value - deficitInEth;
            uint256 newInitialSurplusInUsd = newInitialSurplusInEth * usdInEthPrice;
            depositorCoin = new DepositorCoin();
            uint256 mintDepositorCoinAmount = newInitialSurplusInUsd;
            depositorCoin.mint(msg.sender, mintDepositorCoinAmount);
            return;
        }          


        uint256 surplusInUsd  = uin256 (deficitOrSurplusInUsd);
        uint256 dpcInUsdPrice = _getDPCInUsdPrice(surplusInUsd);
        uint256 mintDepositorCoinAmount = (msg.value * dpcInUsdPrice / oracle.getPrice());

        depositorCoin.mint(msg.sender, mintDepositorCoinAmount);
    }

    function _getDeficitOrSurplusInContractInUsd() private view returns (uint256){
        uint256 ethContractBalanceInUsd = (address(this).balance - msg.value) * oracle.getPrice();
        uint256 totalStableCoinBalanceInUsd = totalSupply;
        int256 deficitOrSurplus = int256(ethContractBalanceInUsd) - int256(totalStableCoinBalanceInUsd);
        return deficitOrSurplus;
    }

    funtion _getDPCInUsdPrice(uin256 surplusInUsd) private view returns (uin256){
        return depositorCoin.totalSupply()/ surplusInUsd;
    }

    function withdrawCollateralBuffer(uint256 burnDepositorCoinAmount) external {
        require(depositorCoin.balanceOf(msg.sender) > = burnDepositorCoinAmount, "STC: Sender has insufficient DPC funds");
        depositorCoin.burn(msg.sender, burnDepositorCoinAmount);
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractInUsd();
        require(deficitOrSurplusInUsd > 0 , "STC: No funds to withdraw");

        uint256 surplusInUsd = uint256(deficitOrSurplusInUsd);
        uint256 dpcInUsdPrice = _getDPCInUsdPrice(surplusInUsd);
        uint256 refundingUsd = burnDepositorCoinAmount / dpcInUsdPrice;
        uint256 refundingInEth = refundingUsd / oracle.getPrice();

        (bool success,) = msg.sender.call{value: refundingEth } ("");
        require(success, "STC: Withdraw refund transaction failed");
    }
 
}
