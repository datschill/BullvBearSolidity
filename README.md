
# Informations

This is a project that I developed while I was at [BullvBear](https://bullvbear.xyz/).

Smart contract can also be found on [Etherscan](https://etherscan.io/address/0xE06A776516BD2E27A83e32A13064355e3f310f94#code).

All the content in this repository has been sourced from [the public repository](https://github.com/sherlock-audit/2022-11-bullvbear) created for the audit.

# About BullvBear

BullvBear is a peer-to-peer marketplace enabling traders to buy and sell NFTs in the future.
- People bullish on a collection will take a buy order (bull) and will pay the settlement price (bull price/collateral) to get
any NFT from the collection before the settlement deadline. They will usually pay a price discounted to the current floor price, therefore will get a discounted NFT
- People bearish on a collection will pay a security deposit (bear price/premium) to be able to sell any NFT from the collection at the predetermined settlement price (bull price/collateral) to a buyer. If the collection floor price goes down they will cash out a profit (shorting). If they don’t send the NFT, they lose their security deposit that is sent to the buyer (bull)

---

# On-chain context

```
DEPLOYMENT: mainnet
ERC20: any
ERC721: any
```

Any ERC721 collection and ERC20 tokens can be used on BullvBear, but these would have to be allowed first by the team.

---

# Requirements

Foundry : https://github.com/foundry-rs/foundry

# Building Contracts

```bash
forge build
```

# Running tests

```bash
forge test -vvv
```

# Test Coverage

```bash
forge coverage
```

---

# Audit scope

`src/BvbProtocol.sol`

---

# Contract In Scope

`BvbProtocol.sol` (337 nSLOC)

## Underlying Mechanism

BvbProtocol allows two people to match around a Put Option.

The put option seller is the Bull, and the put option buyer is the Bear.

The Bull will deposit a collateral, to guarantee the buy, and the Bear will deposit a premium.

The Bear will then be able to sell any NFT from a specific collection to the Bull before the expiration of the option.

If the Bear doesn't settle the contract by sending an NFT before the expiration, the Bull will be able to withdraw the collateral he deposited, as well as the premium deposited by the Bear.

Otherwise, if the Bear decides to sell a NFT to the Bull, the Bull will receive the NFT, and the Bear will receive the premium he deposited and the collateral deposited by the Bull. In that case, the NFT will be taken from the Bear and sent to the Bull.

# Functional specs

Check the [Gitbook](https://bullvbear.gitbook.io/home/understanding-the-protocol/smart-contracts)

# Technical specs

## User Methods

### Match Order

`matchOrder(Order calldata order, bytes calldata signature)`

Anybody can create an Order offchain (with signature) to take a Bull or a Bear position with a specific set of parameters displayed on our website. He would be the Maker of this Order.

Then anybody that submits this Order to BvbProtocol, through this method, would be the Taker of this Order.

This Order could be matched only if several requirements are met, like Maker and Taker having enough liquidity to pay for their due, but also having approved BvbProtocol to move their funds on their behalf.

After an Order has been matched, it will be considered as a Contract by BvbProtocol.

All funds will be held by BvbProtocol, which will be the amount paid by the Bull (`order.collateral` + fees) and the Bear (`order.premium` + fees).

### Settle Contract

`settleContract(Order calldata order, uint tokenId)`

This method is only available to an User who is Bear in the Contract (= matched Order), before the Contract expiration (`order.expiry`)

When calling this method, BvbProtocol will retrieve the token specified by the Bear and send it to the Bull. It will also send `order.premium` and `order.collateral` to the Bear.

There is a case where BvbProtocol will eventually hold the delivered NFT, but it will be withdrawable by the Bull through `withdrawToken()` method. The reason is explained in the **Known Risks** section.

### Reclaim Contract

`reclaimContract(Order calldata order)`

Callable by any User, for an expired Contract that hasn't been settled by the Bear.

When calling this method, BvbProtocol will transfers Contract funds (`order.premium` + `order.collateral`) to the Bull.

### Withdraw Token

`withdrawToken(bytes32 orderHash, uint tokenId)`

Callable by any User, for a token held by BvbProtocol.

When caling this method, BvbProtocol will transfer the specified NFT to the determined recipient.

A token should be withdrawable only if it wasn't possible to send it directly to the recipient at settlement.

### Buy Position

`buyPosition(SellOrder calldata sellOrder, bytes calldata signature)`

Anybody can create a SellOrder offchain (with signature) to sell a position he owns on a Contract. He would be the Maker of this SellOrder.

Then anybody that submits this SellOrder to BvbProtocol, through this method, would be the Taker of this SellOrder.

This SellOrder could be bought only if several requirements are met, like Taker having enough liquidity to pay, but also having approved BvbProtocol to move their funds on their behalf (if not directly paid in ETH).

After a SellOrder has been bought, the position of the Maker will be transfered to the Taker.

`sellOrder.price` will be sent from the Taker to the Maker, and potentially a bit more if the Taker if willing to pay more directly (through ETH).

### Transfer Position

`transferPosition(bytes32 orderHash, bool isBull, address recipient)`

Callable by any position owner of a Contract.

This method will transfer the specified position to the recipient.

### Batch Methods

`batchMatchOrders(Order[] calldata orders, bytes[] calldata signatures)`
`batchSettleContracts(Order[] calldata orders, uint[] calldata tokenIds)`
`batchReclaimContracts(Order[] calldata orders)`

Batch methods are callable by the same Users as their unit method.

These methods allows to match/settle/reclaim several Orders/Contracts at once, with the exact same mechanisms.

It should be noted that no ETH can be sent along `batchMatchOrders()`, as a security measure.

### Cancel (Sell) Orders

`cancelOrder(Order memory order)`
`cancelSellOrder(SellOrder memory sellOrder)`

Callable by any Maker of Order or SellOrder.

These methods allow to disable any Order or SellOrder previously signed.

It ensures that nobody will be able to use them with `matchOrder()` nor `buyPosition()`.

### Set Minimum Valid Nonce (Sell)

`setMinimumValidNonce(uint _minimumValidNonce)`
`setMinimumValidNonceSell(uint _minimumValidNonceSell)`

Callable by any User.

These methods allow to mass disable Orders or SellOrders previously signed, by setting a minimum valid nonce.

It ensures that nobody will be able to use an Order/SellOrder if the the nonce is below the Maker's minimum valid nonce.

## View Methods

### Hash

`hashOrder(Order memory order)`
`hashSellOrder(SellOrder memory sellOrder)`

`hashOrder()` and `hashSellOrder()` returns the EIP712 hashes of Order and SellOrder.

These hashes are used in signatures, but also to identify Orders and SellOrders in BvbProtocol.

### Checks

`isValidSignature(address signer, bytes32 orderHash, bytes calldata signature)`
`isWhitelisted(address[] memory whitelist, address buyer)`
`checkIsValidOrder(Order calldata order, bytes32 orderHash, bytes calldata signature)`
`checkIsValidSellOrder(SellOrder calldata sellOrder, bytes32 sellOrderHash, Order memory order, bytes32 orderHash, bytes calldata signature)`

`isValidSignature()` checks that a signature was effectively signed by the Order/SellOrder Maker.

`isWhitelisted()` checks that a user is allowed to use a SellOrder.

`checkIsValidOrder()` and `checkIsValidSellOrder()` are helpers that validate if Order and SellOrder are valid, according to several requirements.
These requirements were pulled out, respectively from `matchOrder()` and `buyPosition()`, to these helpers, to be able to build more easily on top of BvbProtocol without rewriting them.

## Owner Methods

These methods are only callable by the owner of BvbProtocol.

None of these methods allow the owner to take custody of user's funds or assets at any time.

### Set Allowed Collection

`setAllowedCollection(address collection, bool allowed)`

This method is used to allow or disallow a collection (ERC721) to be used on any Order or SellOrder on BvbProtocol.

### Set Allowed Asset

`setAllowedAsset(address asset, bool allowed)`

This method is used to allow or disallow an asset (ERC20) to be used on any Order or SellOrder on BvbProtocol.

### Set Fee

`setFee(uint16 _fee)`

This method is used to set the fee rate on BvbProtocol.

Note that fees can't be set higher than 5%.

### Withdraw Fees

`withdrawFees(address asset, address recipient)`

This method is used to withdraw accumulated fees for a specific asset (ERC20) on BvbProtocol.

---

# Known Risks

Smart contracts can't Make Order nor SellOrder but they can be Taker. Which may open some attack vectors.
The main attack would happens in the settleContract() method. As a malicious Bull (which would be a smart contract) could block the reception of the delivered NFT, thus the settlement. Which would cause a loss of funds for the Bear.

That's why we put a try/catch for this transfer, allowing BvbProtocol to reroute the transfer if it fails.

You could find a basic example of how a malicious Bull could have stolen any Bear if we didn't write this check, [here](bvb-protocol/mocks/BvbMaliciousBull.sol).

More globally, we decided to allowlist ERC20s and ERC721s that can be used on our platform, to block malicious users that would have tried to make Orders/SellOrders with shady assets in order to steal other users' funds. (for example, by blocking transfers after an Order was matched)

---

# Solidity Metrics 

Metrics can be found [here](bvb-protocol/solidity-metrics.html)

---

# Team & Contacts

We’ll all be in the Discord with DMs open if you have any questions. Please reach out!

- Pierre (Blockchain Dev) :
    - GitHub : [@datschill](https://github.com/datschill)
    - Twitter : [@0xd0s1](https://twitter.com/0xd0s1)
    - Discord : dos#3333
    - Mail : pierre@bullvbear.xyz
- Alonso (Dev) :
    - GitHub : [@mydoum](https://github.com/mydoum)
    - Twitter : [@aalonsogiraldo](https://twitter.com/aalonsogiraldo)
    - Discord : AlonsoGiraldo#4993
    - Mail : alonso@bullvbear.xyz
- Ness :
    - GitHub : [@nessben](https://github.com/nessben)
    - Twitter : [@nessben](https://twitter.com/nessben)
    - Discord : Ness#4130
    - Mail : ness@bullvbear.xyz
- Hugo :
    - GitHub : [@hugomercierooo](https://github.com/hugomercierooo)
    - Twitter : [@hugomercierooo](https://twitter.com/hugomercierooo)
    - Discord : mercier#0001
    - Mail : hugo@bullvbear.xyz
