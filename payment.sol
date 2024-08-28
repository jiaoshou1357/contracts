// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/*
 @author junfeiLi
*/
/*购买操作*/
// 部分已经阉割后的合约源码仅供参考
contract Payment is ERC20,AccessControl {
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE"); //卖方角色
    bytes32 public constant BUYER_ROLE = keccak256("BUYER_ROLE"); //买方角色
    uint public buyDeposit; //买方押金
    address payable public seller;
    address payable public buyer;
    //订单状态
    enum OrderState { Created, LockedAmount,TransportIng, Release, Termination }
    OrderState public state;
    /*事件*/
    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();


    /* 修饰符 */
    modifier OnlyBuyer() {
       require(hasRole(BUYER_ROLE, msg.sender),'only Buyer can operate');
        _;
    }
    modifier OnlySeller() {
        require(hasRole(SELLER_ROLE, msg.sender),'only Seller can operate');
        _;
    }
    modifier isThreeAmount() { 
        require(msg.value == (3 * buyDeposit),'');
        _;
    }
       /// 交易中特定状态才可以执行特定操作
    modifier inState(OrderState state_) {
        if (state != state_)
            revert('The current state cannot call this function');
        _;
    }
   //确保押金是3的倍数
    constructor() payable ERC20("Payment", "PAY") {
        seller = payable(msg.sender);
        buyDeposit = msg.value / 3;
        if ((3 * buyDeposit) != msg.value)
            revert('amount must be an even number');
    }
    // 终止交易
    function interrupt()
        external
        OnlySeller
        inState(OrderState.Created)
    {
        emit Aborted();
        state = OrderState.Termination;
        (bool success,bytes memory data) = seller.call{value:address(this).balance}("");
        if(!success) {
            revert();
        }
        
    }
    //确认支付
    function confirmPay()
        external
        inState(OrderState.Created)
        isThreeAmount
        payable
    {
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = OrderState.LockedAmount;
    }

    //确认收货
    function confirmReceived()
        external
        OnlyBuyer
        inState(OrderState.LockedAmount)
    {
        emit ItemReceived();
        state = OrderState.Release;
         (bool success,bytes memory data) = buyer.call{value:buyDeposit}("");
        if(!success) {
            revert('');
        }
    }

    //返回卖家的锁定资金
    function returnSellerAccount()
        external
        OnlySeller
        inState(OrderState.Release)
    {
        emit SellerRefunded();
        state = OrderState.Termination;
         (bool success,bytes memory data) = seller.call{value:3 * buyDeposit}("");
        if(!success) {
            revert();
        }
    }
}