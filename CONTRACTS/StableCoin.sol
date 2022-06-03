// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >= 0.8.0;

import "./Interfaces/IProxy.sol";

contract StableCoin is IERC20
{
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address immutable deployer;

    uint256 public _totalSupply;

    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_)
    {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        deployer = msg.sender;
    }

    modifier OnlyDeployer()
    {
        require(msg.sender == deployer, "Sender not deployer");
        _;
    }

    function totalSupply() external view virtual override returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256)
    {
        return _balances[account];
    }

//--------------------------------------------------------------------------------------------------------------//
    
    function transfer(address to, uint256 amount) external virtual override returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view virtual override returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool)
    {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool)
    {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked
        {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked
        {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual
    {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked
        {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual
    {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max)
        {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked
            {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

//--------------------------------------------------------------------------------------------------------------//
    
    function mint(address account, uint amount) external virtual override OnlyDeployer returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) external virtual override returns (bool)
    {
        _burn(msg.sender, amount);
        return true;
    }

    function burnFrom(address from, uint256 amount) external virtual override returns (bool)
    {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
        return true;
    }
}
