pragma ton-solidity >= 0.36.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../../interfaces/ITTWExtended.sol";
import "../interfaces/ITTWFungible.sol";
import "../../libraries/TONTokenWalletErrors.sol";
import "../../libraries/TONTokenWalletConstants.sol";


contract TONTokenWallet is ITTWExtended, ITTWFungible {

    address public static _root_address;
    uint256 public static _root_publicKey;
    uint256 public static _wallet_publicKey;
    uint256 public static _tokens;

    bytes public _name;
    bytes public _code;
    uint8 public _decimals;

    TvmCell public _image_wallet;
    Allowance public _allowance;
  
    constructor(
        string name,
        string code,
        uint8 decimals,
        uint256 tokens,
        TvmCell imageWallet
        ) public {
            tvm.accept();
            _name = name;
            _code = code;
            _decimals = decimals;
            _tokens = tokens;
            _image_wallet = imageWallet;
            _allowance = Allowance(address(0), 0);
    }

    function accept(uint256 tokens) override public onlyRoot {
        tvm.accept();
        _tokens += tokens;
    }

    function transfer ( address dest, uint256 tokens, uint128 grams ) override external onlyOwner {
        require(tokens >= 0, TONTokenWalletErrors.error_wrong_value_of_tokens);
        require(tokens <= _tokens, TONTokenWalletErrors.error_not_enough_balance);
        require(dest != address(0), TONTokenWalletErrors.error_wrong_recipient);
        tvm.accept();

        TONTokenWallet(dest).internalTransfer{ value: grams, flag: 1 }(_wallet_publicKey, tokens);

        _tokens -= tokens;
    }

    function internalTransfer(uint256 sender_key, uint256 tokens) override public {
        address expectedSenderAddress = getExpectedAddress(sender_key);
        require(msg.sender == expectedSenderAddress, TONTokenWalletErrors.error_message_sender_is_not_good_wallet);
        
        _tokens += tokens;
    }

    function allowance() override external returns (Allowance) {
        return (_allowance.spender != address(0) ? _allowance : Allowance(address(0), 0));
    }

    function approve(address spender, uint256 remainingTokens, uint256 tokens) override public onlyOwner {
        require(spender != address(0), TONTokenWalletErrors.error_wrong_recipient);
        require(tokens <= _tokens, TONTokenWalletErrors.error_not_enough_balance);
        tvm.accept();
        if(_allowance.allowedToken != 0) {
            if(_allowance.allowedToken == remainingTokens) {
                _allowance = Allowance(spender, tokens);
            }
        } else {
            _allowance = Allowance(spender, tokens);
        }
    }

    function transferFrom(address dest, address to, uint256 tokens, uint128 grams) override public {
        require(grams >= TONTokenWalletConstants.target_gas_balance, TONTokenWalletErrors.error_not_enough_grams);
        require(to != address(0), TONTokenWalletErrors.error_wrong_recipient);
        tvm.accept();
        TONTokenWallet(dest).internalTransferFrom{ value: grams, flag: 1 }(to, tokens);
    }

    function internalTransferFrom( address to, uint256 tokens ) override public {
        require(tokens <= _allowance.allowedToken, TONTokenWalletErrors.error_not_enough_allowance);
        require(msg.sender == _allowance.spender, TONTokenWalletErrors.error_wrong_spender);
        TONTokenWallet(to).internalTransfer(tvm.pubkey(), tokens);
        
        _allowance = Allowance(msg.sender, (_allowance.allowedToken - tokens));
        _tokens -= tokens;
    }
    
    function disapprove() override public onlyOwner {
        tvm.accept();
        _allowance = Allowance(address(0), 0);
    }

    // =============== Support functions ==================

    modifier onlyOwner() {
        require(msg.pubkey() == tvm.pubkey(), TONTokenWalletErrors.error_message_sender_is_not_my_owner);
        _;
    }

    modifier onlyRoot() {
        require(_root_address == msg.sender, TONTokenWalletErrors.error_message_sender_is_not_my_root);
        _;
    }

    function getExpectedAddress( uint256 sender_publicKey ) private inline view returns (address) {
        TvmCell code = _image_wallet.toSlice().loadRef();
        TvmCell stateInit = tvm.buildStateInit({
            contr: TONTokenWallet,
            varInit: {
                _root_address: _root_address,
                _root_publicKey: _root_publicKey,
                _wallet_publicKey: sender_publicKey,
                _tokens: 0
            },
            pubkey: sender_publicKey,
            code: code
        });
        return address.makeAddrStd(0, tvm.hash(stateInit));
    }
}
