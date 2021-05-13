pragma ton-solidity >= 0.36.0;

interface ITTWFungible {

    struct Allowance {
        address spender;
        uint256 allowedToken;
    }

    function accept(uint256 tokens) external;

    function transfer(address dest, uint256 tokens, uint128 grams) external;

    function internalTransfer(uint256 senderKey, uint256 tokens) external;

    function approve(address spender, uint256 remainingTokens, uint256 tokens) external;

    function allowance() external returns (Allowance);

    function transferFrom(address dest, address to, uint256 tokens, uint128 grams) external;

    function internalTransferFrom(address to, uint256 tokens) external;

}