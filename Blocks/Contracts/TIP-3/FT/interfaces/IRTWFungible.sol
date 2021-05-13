pragma ton-solidity >= 0.36.0;

interface IRTWFungible {

    function getWalletAddress(uint256 pubkey) external returns (address walletAddress);

    function deployWallet(int8 workchainId, uint256 pubkey, uint256 tokens, uint128 grams) external returns (address walletAddress);

    function grant(address dest, uint256 pubkey, uint256 tokens, uint128 grams) external;
}