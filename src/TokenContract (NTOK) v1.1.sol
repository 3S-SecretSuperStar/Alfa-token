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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract ERC20I {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20 is ERC20I {

    uint256 constant MAX_UINT256 = 2**256 - 1;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
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

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract NtokContract is ERC20, OwnableToken
{
    using SafeMath for uint256;

    NtokContract ntok; // Init instance this contract

    address thisContract;

    uint256 public payments; // how much ether was
    mapping (address => uint256) public payers;

    uint8  public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public name;                   //fancy name: eg Simon Bucks
    string public symbol;                 //An identifier: eg SBX
    string public version = 'H1.0';       //human 0.1 standard. Just an arbitrary versioning scheme.

   //make sure this function name matches the contract name above. So if you're token is called TutorialToken, make sure the //contract name above is also TutorialToken instead of ERC20Token
    function NtokContract() public payable {
        decimals = 18;                                // Amount of decimals for display purposes
        name = "Alfa NTOK";            // Set the name for display purposes
        symbol = "аNTOK";                              // Set the symbol for display purposes
        balances[this] = 50000 * 10 ** uint(decimals);               // Give the creator all initial tokens (100000 for example)
        totalSupply = balances[this];                        // Update total supply (100000 for example)
        thisContract = this;
        ntok = NtokContract(this);
    }

    /**
    * @dev withdraw accumulated balance.
    */
    function withdrawPayments(uint256 payment) public onlyOwner {
        require(payment != 0);
        require(this.balance >= payment.add(msg.gas));
        payments = payments.sub(payment);
        ntok.transfer(payment);
    }

    /**
    * @dev withdraw tokens from the contract.
    */
    function withdrawTo(address _receiverAddress, uint256 _amount) public onlyOwner {
        ntok.transfer(_receiverAddress, _amount);
    }

    /* Payment menager */
    function() public payable {
        payers[msg.sender] = payers[msg.sender].add(msg.value);
        payments = payments.add(msg.value); // add payments to the statistic
    }
}

contract NtokAirdrop is OwnableToken {

    NtokContract ntok; // Init instance this contract
    uint256 public paySize; // show size of payment in mass transfer
    uint256 public holdersCount;
    uint256 public tokensSpent;

    event Wasted(address to, uint256 value, uint256 date);  // Wasted(_to, _amount, now);

    function NtokAirdrop(address _ancestor) public {
        require(_ancestor != address(0));
        ntok = NtokContract(_ancestor);
    }

    function setPaySize(uint256 _value) public onlyOwner
        returns (uint256)
    {
        paySize = _value;
        return paySize;
    }

    function balanceThis() view public returns (uint256) {
        return ntok.balanceOf(this);
    }

    /**
     * Notify owners about their balances was in promo action.
     *
     * @param _holders addresses of the owners to be notified
     */
    function massTransfer(address [] _holders) public onlyOwner {

        uint256 count = _holders.length;
        assert(count < 10000);
        assert(paySize * count <= ntok.balanceOf(this));
        for (uint256 i = 0; i < count; i++) {
            ntok.transfer(_holders [i], paySize);
        }
        holdersCount += count;
        tokensSpent += paySize * count;
        Wasted(owner, tokensSpent, now);
    }

    /**
     * Kill this smart contract.
     */
    function kill() public onlyOwner {
        //ntok.transfer(_to, paySize);
        selfdestruct (owner);
    }

    function() public {
        revert();
    }

}
