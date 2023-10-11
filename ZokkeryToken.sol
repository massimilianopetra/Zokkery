// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {

	address payable private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = payable(msg.sender);
    }

    modifier _ownerOnly(){
        require(msg.sender == _owner);
        _;
    }
	
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }
	

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual _ownerOnly {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual _ownerOnly {
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = payable (newOwner);
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function getBalance() public  view  returns (uint) {
        return address(this).balance;
    }

    function withdraw(uint amount) external _ownerOnly {
        require(amount <= getBalance());
        _owner.transfer(amount);
    }
}

// ERC20 Interface
interface IZokkeryToken {

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

// ZokkeryToken
contract ZokkeryToken is IZokkeryToken,Ownable {


	uint256 private constant _hardCap = 2_000_000_000; //2 billion

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
	
	uint256 private _totalSupply;
	
    string public constant name = "Zokkery";
    string public constant symbol = "ZOK";
	uint8 public constant  decimals = 18;
	
    constructor() {
        _mint(msg.sender, _hardCap*10**decimals);
    }

	/* *********** Public methods ************ */
	function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function burn(uint256 amount) external {
        require(msg.sender != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[msg.sender];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[msg.sender] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(msg.sender, address(0), amount);
    }
	
	/* *********** Private methods ************ */
	
	function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[address(this)] += amount;
        }
        emit Transfer(address(0), address(this), amount);
        _approve(address(this), account, amount);
    }
	
	function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
	
	function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
	
	/* *********** Default methods ************ */
	
	fallback() external payable {
        emit Track("fallback()", msg.sender, msg.value, msg.data);
    }

    receive() external payable {
        emit Track("receive()", msg.sender, msg.value, "");
    }
}
