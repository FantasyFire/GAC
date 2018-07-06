pragma solidity ^0.4.22;

import "./StandardToken.sol";
import "./Ownable.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `StandardToken` functions.
 */
contract Gac is StandardToken, Ownable {

    string public constant name = "Game Alliance Chain";
    string public constant symbol = "GAC";
    uint8 public constant decimals = 18;
    uint256 constant INITIAL_SUPPLY = 100000000000 * (10 ** uint256(decimals));
    uint256 constant max_batch_size = 100;
    //最大单次转账金额
    uint256 internal max_value_per_transfer = 100000;
    

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    

    /**
    * @dev transfer to payees in batch.
    */
    function dispatch(address[] _payees, uint256[] _values)  public onlyOwner returns(bool){
        //维度判定
        require(_payees.length == _values.length && _values.length > 0, "Dimensions of payees and values are not same." );
        require(_values.length < max_batch_size, "Batch size should within 100.");
        //求和防溢出（如溢出返回为0）
        uint256 _sum = _summary(_values);
        //转账账号余额判定
        require(_sum > 0 && balances[msg.sender] > _sum, "Payer balance is insufficient.");

        address _from = msg.sender;
        for(uint256 i=0; i<_payees.length; i++){
            //wrong address will pass away.
            address _to = _payees[i];
            //wrong value will pass away.
            uint256 _value = _values[i];

            //要求收款人地址不为空且转账金额合规
            require(_to > address(0) && _value > 0 && _value < max_value_per_transfer);
            //如果值为0 或接收方发生溢出，则跳过该转账。
            require(balances[_to] + _value >= balances[_to] && balances[_to] + _value <= INITIAL_SUPPLY);

            //如果收款人未有账本，首次转账记录用户信息
            if(balances[_to] == 0){
                users.push(_to);
            }

            balances[_from] = balances[_from].sub(_value);
            balances[_to] = balances[_to].add(_value);
            emit Transfer(_from, _to, _value);
        }
        return true;
    }    

    /**
    * @dev Retrieve GAC from payers.
    */
    function retrieve(address[] _payers, uint256[] _values) public onlyOwner returns(bool){
        //维度合规性检查
        require(_payers.length == _values.length && _values.length > 0 && _values.length < max_batch_size, "Dimemsions of payers and values should be same.");
        //求和防溢出检查（若溢出则返回为0）
        uint256 _sum = _summary(_values);
        //账户操作前防溢出以及防超出发行量检查
        require(balances[msg.sender] + _sum < INITIAL_SUPPLY, "Total balance should within initial supply.");

        for(uint256 i=0; i<_payers.length; i++){
            address _from = _payers[i];
            uint256 _value = _values[i];
            if(_from == address(0) || _value == 0){
                continue;
            }

            //转出账户余额判定
            require(_value > 0 && balances[_from] >= _value, "Value should not be empty and payer has sufficient balance.");

            balances[_from] = balances[_from].sub(_value);
            balances[msg.sender] = balances[msg.sender].add(_value);
            emit Transfer(_from, msg.sender, _value);
        }

        return true;
    }

    // @dev set max value each transfer can carry out.
    function setMaxValuePerTransfer(uint256 _max_value) public onlyOwner {
        require(_max_value>0 && _max_value < INITIAL_SUPPLY);
        max_value_per_transfer = _max_value;
    }

    // @dev Chek if player has enough balance.
    function checkBalance(address _player, uint256 _value) public view returns(bool){
        return balances[_player] > _value;
    }

    // @dev export balances by ceo
    function exportBalances() public onlyOwner view returns(address[], uint256 []){
        if(users.length == 0){
            return (new address[](0), new uint256[](0));
        }

        uint256 [] memory _listOfValues = new uint256[](users.length);
        for(uint i = 0; i < users.length; i++){
            _listOfValues[i] = balances[users[i]];
        }

        return (users, _listOfValues);
    }


    // TODO: 补充生态治理、挖矿分红、推广分红

    /**
    * @dev calc sum of value array.
    */
    function _summary(uint256[] _values) internal pure returns(uint256){
        require(_values.length>0);
        uint256 _sum = 0;
        for(uint256 i=0; i<_values.length; i++){
            uint256 __sum = _sum;
            _sum += _values[i];
            if(_sum < __sum){
                return 0;
            }
        }

        return _sum;
    }
}
