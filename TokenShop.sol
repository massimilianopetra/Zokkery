// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC20 Interface
interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Track(string indexed _function, address sender, uint value, bytes data);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract TokenShop {

    address payable private _owner; 
    address private _tokenAddress; 
    uint256 private _lotPrice;
    uint256 private _lotSize;


    event Bought(
        address indexed buyer,
        uint256 amount
    );

    event Track(
        string indexed _function, 
        address sender, 
        uint value, 
        bytes data
    );

    constructor(address token) {
        _owner = payable(msg.sender);
        _tokenAddress = token;
    }

    modifier _ownerOnly(){
        require(msg.sender == _owner, "Not the owner");
        _;
    }

    /* *********** Public methods ************ */

    function getBalance() public  view  returns (uint) {
        return address(this).balance;
    }

    function getSize() external  view  returns (uint256) {
        return _lotSize;
    }

    function getPrice() external  view  returns (uint256) {
        return _lotPrice;
    }

    function setSize(uint256 lotSize) external _ownerOnly {
        require (lotSize > 0);
        _lotSize = lotSize;
    }

    function setPrice(uint256 lotPrice) external _ownerOnly {
        require (lotPrice > 0);
        _lotPrice = lotPrice;
    }

    function withdraw(uint amount) external _ownerOnly {
        require(amount <= getBalance());
        _owner.transfer(amount);
    }

    /* *********** Default methods ************ */
	
	fallback() external payable {
        uint256 amount;

        // At least pay for a lotSize
        require (msg.value >= _lotPrice);
        amount = _lotSize*(msg.value/_lotPrice);
        require(IERC20(_tokenAddress).transfer(msg.sender,amount));
        emit Track("fallback()", msg.sender, msg.value, msg.data);
    }

    receive() external payable {

        uint256 amount;

        // At least pay for a lotSize
        require (msg.value >= _lotPrice);
        amount = _lotSize*(msg.value/_lotPrice);
        require(IERC20(_tokenAddress).transfer(msg.sender,amount));
        emit Track("receive()", msg.sender, msg.value, "");
    }
}