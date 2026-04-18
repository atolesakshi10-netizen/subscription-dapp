// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DecentralizedSubscriptionPaymentSystem {
    address public owner;
    uint256 public subscriptionFee;
    uint256 public subscriptionDuration;

    struct Subscriber {
        uint256 startTime;
        uint256 nextPaymentDue;
        bool isActive;
    }

    mapping(address => Subscriber) public subscribers;

    event Subscribed(address indexed user, uint256 startTime, uint256 nextPaymentDue);
    event Renewed(address indexed user, uint256 nextPaymentDue);
    event Cancelled(address indexed user);
    event Withdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(uint256 _fee, uint256 _duration) {
        owner = msg.sender;
        subscriptionFee = _fee;
        subscriptionDuration = _duration;
    }

    function subscribe() public payable {
        require(msg.value == subscriptionFee, "Incorrect subscription fee");
        require(!subscribers[msg.sender].isActive, "Already subscribed");

        subscribers[msg.sender] = Subscriber({
            startTime: block.timestamp,
            nextPaymentDue: block.timestamp + subscriptionDuration,
            isActive: true
        });

        emit Subscribed(msg.sender, block.timestamp, block.timestamp + subscriptionDuration);
    }

    function renewSubscription() public payable {
        Subscriber storage sub = subscribers[msg.sender];

        require(sub.isActive, "No active subscription");
        require(msg.value == subscriptionFee, "Incorrect renewal fee");
        require(block.timestamp <= sub.nextPaymentDue, "Subscription expired, subscribe again");

        sub.nextPaymentDue = block.timestamp + subscriptionDuration;

        emit Renewed(msg.sender, sub.nextPaymentDue);
    }

    function cancelSubscription() public {
        require(subscribers[msg.sender].isActive, "No active subscription");
        subscribers[msg.sender].isActive = false;

        emit Cancelled(msg.sender);
    }

    function checkSubscriptionStatus(address _user)
        public
        view
        returns (uint256 startTime, uint256 nextPaymentDue, bool isActive)
    {
        Subscriber memory sub = subscribers[_user];
        return (sub.startTime, sub.nextPaymentDue, sub.isActive);
    }

    function withdrawFunds() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds available");

        payable(owner).transfer(amount);

        emit Withdrawn(owner, amount);
    }
}