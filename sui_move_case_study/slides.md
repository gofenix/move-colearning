# Sui move 案例分析

## Fenix

---

# 简介

## Move: Web3 JavaScript

## Sui: 高性能公链

![](https://raw.githubusercontent.com/zhenfeng-zhu/pic-go/main/202301101000459.png)

---

# 环境

## Sui

```bash
# install sui
cargo install --locked --force  --git https://github.com/MystenLabs/sui.git --branch devnet sui
```

## Move Analyzer

```bash
# install move-analyzer
cargo install --git https://github.com/move-language/move move-analyzer --locked --force
```

## VSCode

## move-analyzer 和 Move syntax 插件

---

# 基础知识

## Move.toml

```toml
[package]
name = "basics"
version = "0.0.1"

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework", rev = "devnet" }

[addresses]
basics =  "0x0"
```

---

# 基础知识

## init

```rust
fun init(ctx: &mut TxContext) {
    /* ... */
}
```

---

# 基础知识

## entry

```rust
module examples::object {
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct Object has key {
        id: UID
    }

    public fun create(ctx: &mut TxContext): Object {
        Object { id: object::new(ctx) }
    }

    entry fun create_and_transfer(to: address, ctx: &mut TxContext) {
        transfer::transfer(create(ctx), to)
    }
}
```

---

# 基础知识

## string

```rust
module examples::strings {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;
    use std::string::{Self, String};

    struct Name has key, store {
        id: UID,
        name: String
    }

    public fun issue_name_nft(
        name_bytes: vector<u8>, ctx: &mut TxContext
    ): Name {
        Name {
            id: object::new(ctx),
            name: string::utf8(name_bytes)
        }
    }
}
```

---

# 基础知识

## 共享对象

```rust
transfer::share_object(DonutShop {
    id: object::new(ctx),
    price: 1000,
    balance: balance::zero()
})
```

---

# 基础知识

## transfer

- Aptos Coe Move 版本

```rust
struct CoolAssetStore has key {
    assets: Table<TokenId, CoolAsset>
}

public fun opt_in(addr: &signer) {
    move_to(addr, CoolAssetHolder { assets: table::new() }
}

public entry fun cool_transfer(addr: &signer, recipient: address, id:TokenId) acquires CoolAssetStore {
    // withdraw
    let sender = signer::address_of(addr);
    assert!(exists<CoolAssetStore>(sender), ETokenStoreNotPublished);
    let sender_assets = &mut borrow_global_mut<CoolAssetStore (sender).assets;
    assert!(table::contains(sender_assets, id), ETokenNotFound);
    let asset = table::remove(&sender_assets, id);

    // check that 30 days have elapsed
    assert!(time::today() > asset.creation_date + 30, ECantTransferYet)


```

---

```rust
   // deposit
   assert!(exists<CoolAssetStore>(recipient), ETokenStoreNotPublished);
    let recipient_assets = &mut borrow_global_mut<CoolAssetStore>(recipient).assets;
    assert!(table::contains(recipient_assets, id), ETokenIdAlreadyUsed);
    table::add(recipient_assets, asset)
}
```

---

# 基础知识

## transfer

- Sui Move 版本

```rust
public entry fun cool_transfer(
    asset: CoolAsset, recipient: address, ctx: &mut TxContext
) {
    assert!(tx_context::epoch(ctx) > asset.creation_date + 30, ECantTransferYet);
    transfer(asset, recipient)
}
```

---

# 基础知识

## event

```solidity
event Transfer(address indexed from, address indexed to, uint256 value);

// 定义_transfer函数，执行转账逻辑
function _transfer(
    address from,
    address to,
    uint256 amount
) external {

    _balances[from] = 10000000; // 给转账地址一些初始代币

    _balances[from] -=  amount; // from地址减去转账数量
    _balances[to] += amount; // to地址加上转账数量

    // 释放事件
    emit Transfer(from, to, amount);
}
```

---

# 基础知识

## event

```rust
use sui::event;

struct DonutBought has copy, drop {
    id: ID
}

/// Buy a donut.
public entry fun buy_donut(
    shop: &mut DonutShop, payment: &mut Coin<SUI>, ctx: &mut TxContext) {
    assert!(coin::value(payment) >= shop.price, ENotEnough);

    let coin_balance = coin::balance_mut(payment);
    let paid = balance::split(coin_balance, shop.price);
    let id = object::new(ctx);

    balance::join(&mut shop.balance, paid);

    // Emit the event using future object's ID.
    event::emit(DonutBought { id: object::uid_to_inner(&id) });
    transfer::transfer(Donut { id }, tx_context::sender(ctx))
}
```

---

# 基础知识

## one time witness

```rust
/// Example of spawning an OTW.
module examples::my_otw {
    use std::string;
    use sui::tx_context::TxContext;
    use examples::one_time_witness_registry as registry;

    /// Type is named after the module but uppercased
    struct MY_OTW has drop {}

    /// To get it, use the first argument of the module initializer.
    /// It is a full instance and not a reference type.
    fun init(witness: MY_OTW, ctx: &mut TxContext) {
        registry::add_record(
            witness, // here it goes
            string::utf8(b"My awesome record"),
            ctx
        )
    }
}
```

---

# 深入 object

- 数据结构

```rust
struct Color {
    red: u8,
    green: u8,
    blue: u8,
}
```

- Sui 对象

```rust
use sui::object::UID;

struct ColorObject has key {
    id: UID,
    red: u8,
    green: u8,
    blue: u8,
}
```

---

# 深入 object

## 构造函数

```rust
use sui::object;
use sui::tx_context::TxContext;

fun new(red: u8, green: u8, blue: u8, ctx: &mut TxContext): ColorObject {
    ColorObject {
        id: object::new(ctx),
        red,
        green,
        blue,
    }
}
```

---

# 深入 object

## 存储 Sui 对象

- transfer 函数

```rust
public fun transfer<T: key>(obj: T, recipient: address)
```

-

```rust
use sui::transfer;

// This is an entry function that can be called directly by a Transaction.
public entry fun create(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
    let color_object = new(red, green, blue, ctx);
    transfer::transfer(color_object, tx_context::sender(ctx))
}
```

- get 方法

```rust
public fun get_color(self: &ColorObject): (u8, u8, u8) {
    (self.red, self.green, self.blue)
}
```

---

# Move 设计模式

## 1. 面向资源编程

## 2. 状态存储机制

## 3. 能力

- copy: 被修饰的值可以被复制。
- drop: 被修饰的值在作用域结束时可以被丢弃。
- store: 被修饰的值可以被存储到全局状态。
- key: 被修饰的值可以作为键值对全局状态进行访问。

---

# Move 设计模式

## 能力

```rust
struct AdminCap has key, store {}
```

---

# Move 设计模式

## 能力

```rust
module capability::m {
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    struct OwnerCapability has key { id: UID }

    /// A Coin Type
    struct Coin has key, store {
        id: UID,
        value: u64
    }

    /// Module initializer is called once on module publish.
    /// Here we create only one instance of `OwnerCapability` and send it to the publisher.
    fun init(ctx: &mut TxContext) {
        transfer::transfer(OwnerCapability {
            id: object::new(ctx)
        }, tx_context::sender(ctx))
    }
```

---

```rust

    /// The entry function can not be called if `OwnerCapability` is not passed as
    /// the first argument. Hence only owner of the `OwnerCapability` can perform
    /// this action.
    public entry fun mint_and_transfer(
        _: &OwnerCapability, to: address, ctx: &mut TxContext
    ) {
        transfer::transfer(Coin {
            id: object::new(ctx),
            value: 100,
        }, to)
    }
}
```

---

# Move 设计模式

## witness

witness 是一种临时资源，相关资源只能被使用一次，资源在使用后被丢弃，确保不能重复使用相同的资源来初始化任何其他结构，通常用来确认一个类型的的所有权。

```rust
// 注册一个M_COIN类型的通用Token
module examples::m_coin {
    use sui::coin;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

		// 必须是模块名大写字母
    struct M_COIN has drop{}

		// 第一个位置传递
    fun init (witness: M, ctx: &mut TxContext) {
        let cap = coin::create_currency(witness, 8, ctx);
        transfer::transfer(cap, tx_context::sender(ctx));
    }
}
```

---

# Move 设计模式

## hot potato

```rust
struct Hot_Potato {}
```

- 保证调用者一定会按照预先设定的顺序去调用函数。

---

- 闪电贷本质也是调用顺序问题

```rust
module example::flash_lender {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// A shared object offering flash loans to any buyer willing to pay `fee`.
    struct FlashLender<phantom T> has key {
        id: UID,
        /// Coins available to be lent to prospective borrowers
        to_lend: Balance<T>,
        /// Number of `Coin<T>`'s that will be charged for the loan.
        /// In practice, this would probably be a percentage, but
        /// we use a flat fee here for simplicity.
        fee: u64,
    }

    /// A "hot potato" struct recording the number of `Coin<T>`'s that
    /// were borrowed. Because this struct does not have the `key` or
    /// `store` ability, it cannot be transferred or otherwise placed in
    /// persistent storage. Because it does not have the `drop` ability,
    /// it cannot be discarded. Thus, the only way to get rid of this
    /// struct is to call `repay` sometime during the transaction that created it,
    /// which is exactly what we want from a flash loan.
```

---

```rust
    struct Receipt<phantom T> {
        /// ID of the flash lender object the debt holder borrowed from
        flash_lender_id: ID,
        /// Total amount of funds the borrower must repay: amount borrowed + the fee
        repay_amount: u64
    }

    /// An object conveying the privilege to withdraw funds from and deposit funds to the
    /// `FlashLender` instance with ID `flash_lender_id`. Initially granted to the creator
    /// of the `FlashLender`, and only one `AdminCap` per lender exists.
    struct AdminCap has key, store {
        id: UID,
        flash_lender_id: ID,
    }

    // === Creating a flash lender ===

    /// Create a shared `FlashLender` object that makes `to_lend` available for borrowing.
    /// Any borrower will need to repay the borrowed amount and `fee` by the end of the
    /// current transaction.
    public fun new<T>(to_lend: Balance<T>, fee: u64, ctx: &mut TxContext): AdminCap {
        let id = object::new(ctx);
        let flash_lender_id = object::uid_to_inner(&id);
        let flash_lender = FlashLender { id, to_lend, fee };
        // make the `FlashLender` a shared object so anyone can request loans
        transfer::share_object(flash_lender);
```

---

```rust

        // give the creator admin permissions
        AdminCap { id: object::new(ctx), flash_lender_id }
    }

    // === Core functionality: requesting a loan and repaying it ===

    /// Request a loan of `amount` from `lender`. The returned `Receipt<T>` "hot potato" ensures
    /// that the borrower will call `repay(lender, ...)` later on in this tx.
    /// Aborts if `amount` is greater that the amount that `lender` has available for lending.
    public fun loan<T>(
        self: &mut FlashLender<T>, amount: u64, ctx: &mut TxContext
    ): (Coin<T>, Receipt<T>) {
        let to_lend = &mut self.to_lend;
        assert!(balance::value(to_lend) >= amount, ELoanTooLarge);
        let loan = coin::take(to_lend, amount, ctx);
        let repay_amount = amount + self.fee;
        let receipt = Receipt { flash_lender_id: object::id(self), repay_amount };

        (loan, receipt)
    }

    /// Repay the loan recorded by `receipt` to `lender` with `payment`.
    /// Aborts if the repayment amount is incorrect or `lender` is not the `FlashLender`
    /// that issued the original loan.

```

---

```rust
public fun repay<T>(self: &mut FlashLender<T>, payment: Coin<T>, receipt: Receipt<T>) {
        let Receipt { flash_lender_id, repay_amount } = receipt;
        assert!(object::id(self) == flash_lender_id, ERepayToWrongLender);
        assert!(coin::value(&payment) == repay_amount, EInvalidRepaymentAmount);

        coin::put(&mut self.to_lend, payment)
    }
}
```

---

# Move 设计模式

- Hot Potato 设计模式不仅仅只适用于闪电贷的场景，还可以用来控制更复杂的函数调用顺序。

```rust
module example::hot_potato {
    struct Potato {
        has_cut: bool,
        has_cook: bool,
    }
    public fun get_potato(_sender: &signer): Potato {
        Potato {has_cut: false, has_cook: false,}
    }
    public fun cut_potatoes(potato: &mut Potato) {
        assert!(!potato.has_cut, 0);
        potato.has_cut = true;
    }
    public fun cook_potato(potato: &mut Potato) {
        assert!(!potato.has_cook && potato.has_cut, 0);
        potato.has_cook = true;
    }
    public fun consume_potato(_sender: &signer, potato: Potato) {
        assert!(potato.has_cook && potato.has_cut, 0);
        let Potato {has_cut: _, has_cook: _ } = potato;
    }
}
```

---

# 现实世界的样例

## DevNetNFT

```rust
module examples::devnet_nft {
    use sui::url::{Self, Url};
    use std::string;
    use sui::object::{Self, ID, UID};
    use sui::event;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// An example NFT that can be minted by anybody
    struct DevNetNFT has key, store {
        id: UID,
        /// Name for the token
        name: string::String,
        /// Description of the token
        description: string::String,
        /// URL for the token
        url: Url,
        // TODO: allow custom attributes
    }
```

---

```rust
    // ===== Events =====
    struct NFTMinted has copy, drop {
        // The Object ID of the NFT
        object_id: ID,
        // The creator of the NFT
        creator: address,
        // The name of the NFT
        name: string::String,
    }

    // ===== Public view functions =====

    /// Get the NFT's `name`
    public fun name(nft: &DevNetNFT): &string::String {
        &nft.name
    }

    /// Get the NFT's `description`
    public fun description(nft: &DevNetNFT): &string::String {
        &nft.description
    }

    /// Get the NFT's `url`
    public fun url(nft: &DevNetNFT): &Url {
        &nft.url
    }
```

---

```rust

    // ===== Entrypoints =====
    /// Create a new devnet_nft
    public entry fun mint_to_sender(
        name: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let nft = DevNetNFT {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url)
        };

        event::emit(NFTMinted {
            object_id: object::id(&nft),
            creator: sender,
            name: nft.name,
        });

        transfer::transfer(nft, sender);
    }
```

---

```rust
    /// Transfer `nft` to `recipient`
    public entry fun transfer(
        nft: DevNetNFT, recipient: address, _: &mut TxContext
    ) {
        transfer::transfer(nft, recipient)
    }

    /// Update the `description` of `nft` to `new_description`
    public entry fun update_description(
        nft: &mut DevNetNFT,
        new_description: vector<u8>,
        _: &mut TxContext
    ) {
        nft.description = string::utf8(new_description)
    }

    /// Permanently delete `nft`
    public entry fun burn(nft: DevNetNFT, _: &mut TxContext) {
        let DevNetNFT { id, name: _, description: _, url: _ } = nft;
        object::delete(id)
    }
}

```

---

# 现实世界的样例

## Coin

```rust
module examples::mycoin {
    use std::option;
    use sui::coin;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    /// The type identifier of coin. The coin will have a type
    /// tag of kind: `Coin<package_object::mycoin::MYCOIN>`
    /// Make sure that the name of the type matches the module's name.
    struct MYCOIN has drop {}

    /// Module initializer is called once on module publish. A treasury
    /// cap is sent to the publisher, who then controls minting and burning
    fun init(witness: MYCOIN, ctx: &mut TxContext) {
        let (treasury, metadata) = coin::create_currency(witness, 6, b"MYCOIN", b"", b"", option::none(), ctx);
        transfer::freeze_object(metadata);
        transfer::transfer(treasury, tx_context::sender(ctx))
    }
}
```

---

# Sui move 工程化

## 单元测试

## multi package


- 代码演示

---

# 谢谢大家

# 新春快乐

# 祝大家新的一年，变得更强！
