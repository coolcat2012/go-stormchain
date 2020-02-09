pragma solidity >=0.4.22 <0.6.0;
/**
 * @title ApplicationChain.sol
 * @author Raymond Fu
 * @date: Feb 6, 2020
 * Stormchain can be registered on other blockchains as a
 * deligated application chain to support an application
 * using the tokens from the other chain.
 * This is used to generate applications from MOAC blockchain.
 */

contract ApplicationChain {

    using SafeMath for uint256;

    address internal owner;
    mapping(address => uint) public admins;
    
    uint256 public balance = 0;
    uint256 public chainId;
    uint256 public period;
    uint256 public flushEpoch;
    
    mapping(uint256=>flushRound) public flushMapping;
    uint256[] public flushList;
    
    mapping(uint256=>address[]) public flushValidatorList;
    
    struct flushRound{
        uint256 flushId;
        address validator;
        uint256 blockNumber;
        string blockHash;
    }
    
    string extraData;

    constructor(uint256 p, uint256 f, address[] initial_validators) public payable {
        owner = msg.sender;
        chainId = block.number;
        period = p;
        flushEpoch = f;
        balance = msg.value;
        
        uint256 flushId = 1;
        flushMapping[flushId].flushId = 1;
        flushMapping[flushId].validator = msg.sender;
        uint i;
        for (i=0; i<initial_validators.length; i++){
            flushValidatorList[flushId].push(initial_validators[i]);
        }
        flushMapping[flushId].blockNumber = 1;
        flushMapping[flushId].blockHash = "";        
    }
    
    function addAdmin(address admin) public {
        require(msg.sender == owner || admins[msg.sender] == 1);
        admins[admin] = 1;
    }

    function removeAdmin(address admin) public {
        require(msg.sender == owner || admins[msg.sender] == 1);
        admins[admin] = 0;
    }

    function addFund() public payable {
        balance += msg.value;
    }
    
    function withdrawFund(address recv, uint amount) public {
        require(owner == msg.sender || admins[msg.sender] == 1);
        require(admins[recv] == 1);
        require(amount <= balance);
        
        recv.transfer(amount);
    }

    function flush(address[] current_validators, uint256 blockNumber, string blockHash) public {
        uint256 flushId = flushList.length;
        uint i;
        for (i=1; i<=flushValidatorList[flushId].length; i++){
            if (flushValidatorList[flushId][i]==msg.sender &&
                flushMapping[flushId].blockNumber + flushEpoch == blockNumber){
                flushId = flushList.length + 1;
                flushMapping[flushId].flushId = flushId;
                flushMapping[flushId].validator = msg.sender;
                uint j;
                for (j=0; j<current_validators.length; j++){
                        flushValidatorList[flushId].push(current_validators[j]);
                    }
                flushMapping[flushId].blockNumber = blockNumber;
                flushMapping[flushId].blockHash = blockHash;  
                flushList.push(flushId);
                
                // give reward to validators
            }
        }
    }
    
    function getGenesisInfo() public returns (string) {
        
        string memory s = "";
        for (uint i=0; i<flushValidatorList[1].length; i++){
            s = string(abi.encodePacked(s, addr2str(flushValidatorList[1][0])));
        }
        return string(abi.encodePacked('{',
        '{',
        ' "config": {',
        ' "chainId": ',
        uint2str(chainId),
        ',',
        '  "pbft": {',
        '   "period": ',
        uint2str(period),
        ',',
        '   "epoch": ',
        uint2str(flushEpoch),
        '',
        '  }',
        ' },',
        '  "nonce": "0x0",',
        '  "timestamp": "0x5de22b51",',
        '  "extraData": "0x0000000000000000000000000000000000000000000000000000000000000000',
        s,
        '0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",',
        '  "gasLimit": "0x47b760",',
        '  "difficulty": "0x1",',
        '  "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",',
        '  "coinbase": "0x0000000000000000000000000000000000000000",',
        '  "alloc": {},',
        '  "number": "0x0",',
        '  "gasUsed": "0x0",',
        '  "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000"',
        '}'));
    }
    
    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function addr2str(address _addr) public pure returns(string) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(51);

        for (uint i = 0; i < 20; i++) {
            str[i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[i*2+1] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }
}

pragma solidity ^0.4.22;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}