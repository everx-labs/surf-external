pragma ton-solidity ^0.39.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../interfaces/IRTWFungible.sol";
import "../../libraries/RootTokenContractErrors.sol";
import "../../libraries/TONTokenWalletConstants.sol";
import "./TONTokenWallet.sol";

contract RootTokenContract is IRTWFungible {

    uint256 public _creator;
    bytes public _icon;
    bytes public _description;
    bytes public _name;
    bytes public _code;
    uint8 public _decimals;

    address public _root_owner_address;
    uint256 public _root_publicKey;
    uint256 public _total_supply;
    TvmCell public _image_wallet;

    uint256 public _total_granted;

    constructor(
        uint256 tokenCreator,
        string tokenName,
        string tokenIcon,
        string tokenDescription,
        string tokenCode,
        uint8 tokenDecimalPlaces,
        uint256 tokenSupply,
        TvmCell imageWallet,
        uint256 rootPublicKey,
        address rootOwnerAddress
    ) public {
        tvm.accept();
        _creator = tokenCreator;
        _name = tokenName;
        _icon = tokenIcon;
        _description = tokenDescription;
        _code = tokenCode;
        _decimals = tokenDecimalPlaces;
        _total_supply = tokenSupply;
        _image_wallet = imageWallet;
        _root_publicKey = rootPublicKey;
        _root_owner_address = rootOwnerAddress;
        _total_granted = 0;
    }

    function getWalletAddress(uint256 pubkey) override external returns (address walletAddress) {
        return getExpectedWalletAddress(pubkey);
    }

    function deployWallet(int8 workchainId, uint256 pubkey, uint256 tokens, uint128 grams) override external onlyOwner returns (address walletAddress) {
        require(grams >= TONTokenWalletConstants.target_gas_balance, RootTokenContractErrors.error_not_enough_grams);
        require(pubkey != 0, RootTokenContractErrors.error_wrong_recipient);
        require(tokens + _total_granted <= _total_supply, RootTokenContractErrors.error_total_granted_too_much);
        tvm.accept();

        TvmCell stateInit = getStateInit(pubkey);
        TvmCell payload = tvm.encodeBody(TONTokenWallet, _name, _code, _decimals, tokens, _image_wallet);
        walletAddress = tvm.deploy(stateInit, payload, grams, workchainId);

        _total_granted += tokens;
        
        return walletAddress;
    }

    function grant(address dest, uint256 pubkey, uint256 tokens, uint128 grams) override external onlyOwner {
        
        require(tokens + _total_granted <= _total_supply, RootTokenContractErrors.error_total_granted_too_much);
        require(dest != address(0), RootTokenContractErrors.error_wrong_recipient);
        require(grams >= TONTokenWalletConstants.target_gas_balance, RootTokenContractErrors.error_not_enough_grams);
        tvm.accept();
        require(dest == getExpectedWalletAddress(pubkey), RootTokenContractErrors.error_wrong_recipient);
        TONTokenWallet(dest).accept{ value: grams, flag: 1 }(tokens);

        _total_granted += tokens;
    }

    // =============== Support functions ==================

    modifier onlyOwner() {
        if(_root_owner_address.value == 0) {
            require(msg.pubkey() == tvm.pubkey(), RootTokenContractErrors.error_message_sender_is_not_my_owner);
        } else {
            require(_root_owner_address == msg.sender, RootTokenContractErrors.error_message_sender_is_not_my_owner);
        }
        _;
    }

    function getExpectedWalletAddress(uint256 walletPublicKey) private inline view returns (address) {        
        return address.makeAddrStd(0, tvm.hash(getStateInit(walletPublicKey)));
    }

    function getStateInit(uint256 walletPublicKey) private inline view returns (TvmCell) {
        TvmCell code = _image_wallet.toSlice().loadRef();
        return tvm.buildStateInit({
            contr: TONTokenWallet,
            varInit: {
                _root_address: address(this),
                _root_publicKey: _root_publicKey,
                _wallet_publicKey: walletPublicKey,
                _tokens: 0
            },
            pubkey: walletPublicKey,
            code: code
        });
    }
}