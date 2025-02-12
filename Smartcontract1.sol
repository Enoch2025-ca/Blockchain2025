// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract Purchase {
    uint public value;
    address payable public seller;
    address pauable public buyer;

enum State { Created, Locked, Release, Inactive }
// The state variable has a default value of the first member, 'State.created'
State public state;

modifier condition(bool condition_) {
    require(condition_);
    _;
}

/// Only the buyer can call this function.
error OnlyBuyer();
/// Only the seller can call this function.
error OnlySeller();
/// The function cannot be called at the current state.
error InvalidState();
/// The provided value has to be even.
error ValueNotEven();

modifier onlyBuyer(){
    if (msg.sender !=buyer)
        revert onlyBuyer();
        _;
}

modifier OnlySeller () {
    if (msg.sender != seller)
        revert OnlySeller();
        _;
}

modifier inState(State state_) {
    if (state != state_)
        revert InvalidState();
    _;
}

event Aborted();
event PurchaseConfirmed();
event ItemReceicved();
event SellerRefuned();

// Ensure that 'msg.value' is an even number.
// Division will truncate if it is an odd number.
// chech via multiplication that it wasnt an odd number.
// need to add infinite gas to line below as per sample.
constructor() payable {
    seller = payable(msg.sender);
    value = msg.value / 2;
    if ((2 * value) != msg.value)
        revert ValueNotEven();
}

/// Abort ther purchase and reclaim the ether.
/// Can only be called by the seller before
/// the contract is locked.
function abort()
    external
    OnlySeller
    inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;
        // We use transfer here directly. It is 
        // reentrancy-safe, because it is the 
        // last call in the function and we already changed state.
        seller.transfer(address(this) .balance);
}

/// Confirm the purchase as buyer.
/// Transaction have to include '2 * value' ether.
/// The ether will be locked until confirmReceived
/// is called.
function confirmPurchase()
external
inState(State.Created)
condition(msg.value == (2 * value))
payable
{
    emit PurchasedConfirmed();
    buyer = payable(msg.sender);
    state = State.locked;
}

/// Confirm that you (the buyer) received the item.
/// This will release the locked ether.
function confirmReceived()
    external
    onlyBuyer
    inState(State.Locked)
{
    emit ItemReceived ();
    // It is important to change the state first because
    // otherwise, the contract called usied 'send' below
    // can call in again here.
    state = State.Release;

    buyer.transfer(value);
}

/// This function refunds the seller, i.e 
/// pays back the locked funds of the seller.
function refundSeller()
    external
    OnlySeller
    inState(State.Release)
{
    emit SellerRefuned();
    // It is important to change the state first because
    // otherwise the contract called used 'send' below
    // can call in again here
    state = State.Inactive;

    seller.transfer(3 * value);
    }
}