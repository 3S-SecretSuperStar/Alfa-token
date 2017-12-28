pragma solidity ^0.4.18;

/**
 * Math operations with safety checks
 */
library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure
    returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/* Owner setter */
contract OwnableToken {

    address public owner;

    modifier onlyOwner()
    {
        require(owner == msg.sender);
        _;
    }

    function OwnableToken() public payable
    {
        owner = msg.sender;
    }

    function changeOwner(address _new_owner) payable public onlyOwner
    {
        require(_new_owner != address(0));
        owner = _new_owner;
    }
}

/*
 * Abstract contract for the full ERC 20 Token standard
 * https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20I
{
    uint256 public totalSupply;

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/* ERC 20 Token implementation */
contract ERC20 is ERC20I {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public
    returns (bool success)
    {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public
    returns (bool success)
    {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view public
    returns (uint256 balance)
    {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public
    returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view public
    returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}

/* economical airdopable smart contract */
contract NtokContractAirdrop is ERC20, OwnableToken
{
    using SafeMath for uint256;

    event Wasted(address to, uint256 value, uint256 date);  // Wasted(_to, _amount, now);

    uint8  public decimals;  //How many decimals to show.
    string public name;
    string public symbol;  //An identifier: eg SBX length 6 symbols max
    string public version = 'H1.1';  //human 0.1 standard. Just an arbitrary versioning scheme.

    uint256 public paySize;  // show size of payment in mass transfer
    uint256 public holdersCount;
    uint256 public tokensSpent;

    /* Autoconstructor */
    function NtokContractAirdrop() public payable {
        decimals = 18;                                // Amount of decimals for display purposes
        name = "Alfa NTOK";            // Set the name for display purposes
        symbol = "аNTOK";                              // Set the symbol for display purposes
        balances[msg.sender] = 20185000 * 10 ** uint(decimals);               // Give the creator all initial tokens (100000 for example)
        totalSupply = balances[msg.sender];                        // Update total supply (100000 for example)
    }

    /**
     * @dev notify owners about their balances was in promo action.
     * @param _holders addresses of the owners to be notified
     */
    function massTransfer(uint256 _gasprice, address [] _holders) public onlyOwner {

        uint256 count = _holders.length;
        assert(count < 10000);
        require(tx.gasprice >= _gasprice * 10 ** 9);
        assert(paySize * count <= balanceOf(this));
        for (uint256 i = 0; i < count; i++) {
            transfer(_holders [i], paySize);
        }
        holdersCount += count;
        tokensSpent += paySize * count;
        Wasted(owner, tokensSpent, now);
    }

    /**
    * @dev withdraw tokens from the contract.
    */
    function withdrawTo(address _receiverAddress, uint256 _amount) public onlyOwner {
        this.transfer(_receiverAddress, _amount);
    }

    function setPaySize(uint256 _value) public onlyOwner
    returns (uint256)
    {
        paySize = _value;
        return paySize;
    }

    /**
     * @dev kill this smart contract.
    */
    function kill() public onlyOwner {
        selfdestruct (owner);
    }

    function() public {
        revert(); // revert all incoming transactions
    }
}