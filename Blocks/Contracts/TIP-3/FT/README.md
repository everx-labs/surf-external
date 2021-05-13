# FT tokens by TON Surf

## Smart contracts description 

RTW FT - RootTokenContract.sol the original wallet that initially contains the tokens. When deployed, the RTW stores all tokens in the totalSupply variable and the number of granted tokens — totalGranted — is set to 0. totalGranted must be below or equal to totalSupply. If deployed with rootOwnerAddress == 0, then external messages are controlled.

TTW FT - TONTokenWallet.sol wallet to which the owner can transfer a certain amount of tokens.

## RTW FT
```sh
constructor (
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
);
```
##### Methods
- getWalletAddress
Calculates wallet address with defined public key.
```sh
function getWalletAddress (uint256 pubkey) external returns (address walletAddress);
```
- deployWallet
Allows deploying the token wallet in a specified workchain and sending some tokens to it.
```sh
function deployWallet (
    int8 workchainId,
    uint256 pubkey,
    uint256 tokens,
    uint128 grams
) external onlyOwner returns (address walletAddress);
```
- grant
Sends tokens to the TTW. The function must call the accept function of the token wallet and increase the totalGranted value.
```sh
function grant (address dest, uint256 pubkey, uint256 tokens, uint128 grams) external onlyOwner;
```

## TTW FT
```sh
constructor (
    string name,
    string code,
    uint8 decimals,
    uint256 tokens,
    TvmCell imageWallet
);
```
##### Methods
- accept
Called by an internal message only. Receives tokens from the RTW.
```sh
function accept (uint256 tokens) public onlyRoot;
```
- transfer
Sends tokens to another token wallet. The function must call internalTransfer function of destination wallet.
```sh
function transfer (
    address dest,
    uint256 tokens,
    uint128 grams
) external onlyOwner;
```
- approve
Allows the spender wallet to withdraw tokens from the wallet multiple times, up to the tokens amount. If current spender allowance is equal to remainingTokens, then overwrite it with tokens, otherwise, do nothing.
```sh
function approve (
    address spender,
    uint256 remainingTokens,
    uint256 tokens
) public onlyOwner;
```
- allowance
Returns the amount of tokens the spender is still allowed to withdraw from the wallet.
```sh
function allowance () external returns (Allowance);
```
- transferFrom
Called by an external message only; allows transferring tokens from the dest wallet to to the wallet. The function must call the internalTransferFrom function of the dest contract and attach certain grams value to internal message.
```sh
function transferFrom (address dest, address to, uint256 tokens, uint128 grams) public;
```
- disapprove
Called by an external message only; cancels the permission to send tokens given to an approved wallet. The function must set the approved address and amount (or token Id) to 0.
```sh
function disapprove () public onlyOwner;
```