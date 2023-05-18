# 为什么会存在 Move 设计模式

- 面向资源编程

- 状态存储机制

```solidity
// A solidity examply
// set msg.sender to owner
contract A {
    // 定义一个状态变量
    address owner;
    function setOwner() public {
	// 通过变量名直接修改
        owner = msg.sender;
    }
}
```

```rust
module example::m {
    // A Coin type
    // 一种Coin类型的资源
    struct Coin has key, store{
        value: u64
    }
    // send sender a coin value of 100
    // 在sender地址下存放100个coin
    public entry fun mint(sender: &signer) {
        move_to(sender, Coin {
            value: 100
        });
    }
}
```

- Ability

  - copy 复制：允许此类型的值被复制
  - drop 丢弃：允许此类型的值被弹出/丢弃，没有话表示必须在函数结束之前将这个值销毁或者转移出去。
  - store 存储：允许此类型的值存在于全局存储中或者某个结构体中
  - key 键值：允许此类型作为全局存储中的键(具有 key 能力的类型才能保存到全局存储中)

  ***

# Capability

Capability 可以理解为是指一个人、组织或系统所具有的能力或资质。

```rust
struct AdminCap has key, store {}
```

### aptos

```rust
module example::capability {
    use std::signer;

    // 定义一个OwnerCapability类型
    struct OwnerCapability has key, store {}

    // 向管理者地址下存放一个OwnerCapability资源
    public entry fun init(sender: signer) {
        assert!(signer::address_of(&sender) == @example, 0);
        move_to(&sender, OwnerCapability {})
    }

    // Only user with OwnerCapability can call this function
    // 只有具有OwnerCapability的用户才能调用此函数
    public entry fun admin_fun(sender: &signer) acquires OwnerCapability {
        assert!(exists<OwnerCapability>(signer::address_of(sender)), 1);
        let _cap = borrow_global<OwnerCapability>(signer::address_of(sender));
        // do something with the cap.
    }
}
```

### sui

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

# Wrapper

Wrapper 是一种封装对象或数据结构的技巧，它将原始对象或数据结构包装在另一个对象中，从而提供额外的功能或抽象层面。

### aptos

```rust
module example::offer {
    use std::signer;

    struct OwnerCapability has key, store {}

    /// 定义一个Offer来包装一个对象
    struct Offer<T: key + store> has key, store {
        receipt: address,
        offer: T,
    }
    /// 发送一个Offer到地址to下
    public entry fun send_offer(sender: &signer, to: address) {
        move_to<Offer<OwnerCapability>>(sender, Offer<OwnerCapability> {
            receipt: to,
            offer: OwnerCapability {},
        });
    }
    /// 地址to调用函数从而接受Offer中的对象
    public entry fun accept_role(sender: &signer, grantor: address) acquires Offer {
        assert!(exists<Offer<OwnerCapability>>(grantor), 0);
        let Offer<OwnerCapability> { receipt, offer: admin_cap } = move_from<Offer<OwnerCapability>>(grantor);
        assert!(receipt == signer::address_of(sender), 1);
        move_to<OwnerCapability>(sender, admin_cap);
    }
}

```

### sui

Sui 中由于资源都是一个 Object，每一个对象都是属于一个 Owner 的，所以需要主动给用户发送资源时，只需要使用 transfer::transfer(obj, to)，不需要使用 Offer 模式

## 限制

Wrapper（包装器）中的有一个限制：只能指定一个地址来接受 Offer。如果需要赋予多个人一个 Capability（能力），就需要解决这个限制。

```rust
/// 定义一个Offer来包装一个对象
struct Wrapper<T: key + store> has key, store {
    receipt: address,
    map: VecMap<T>,
}
```

```rust
module example::coin {
    struct Coin has key, store {
        value: u64
    }
    struct MintCapability has key, store {}

    public fun mint(amount: u64, _cap: &MintCapability): Coin {
        Coin { value: amount }
    }
}
```

```rust
struct Wrapper has key, store {
        coin: Coin
}
```

---

# Witness

witness 在 move 里面，是一种临时资源，它只能被使用一次，并在使用后被丢弃，意味着它就像一个见证者来看这个合约。

```rust
module framework::coin {
    /// The witness patameter ensures that the function can only be called by the module defined T.
    public fun publish_coin<T: drop>(_witness: T) {
        // register this coin to the registry table
    }
}
module examples::xcoin {
    use framework::coin;
    /// The Witness type.
    struct X has drop {}
    /// Only this module defined X can call framework::publish_coin<X>
    public fun publish() {
        coin::publish_coin<X>(X {});
    }
}
module hacker::hack {
    use framework::coin;
    use examples::xcoin::X;

    public fun publish() {
        // Illegal, X can not be constructed here.
        coin::publish_coin<X>(X {});
    }
}

```

### Move 编译器类型检查

```
// Move编译器报错
┌─ /sources/m.move:25:31
   │
25 │         coin::publish_coin<X>(X {});
   │                               ^^^^ Invalid instantiation of '(examples=0x1)::xcoin::X'.
All structs can only be constructed in the module in which they are declared
```

### one-time witness

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

### Transferable Witness

一个 Transferable Witness 就像是一个可以保存一段时间的证人，但是它被放在一个可以用完就扔掉的包装里。也就是说，这个证人在被用完之后，就不能再次使用了。

```rust
module examples::transferable_witness {
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};

    /// Witness now has a `store` that allows us to store it inside a wrapper.
    struct WITNESS has store, drop {}

    /// Carries the witness type. Can be used only once to get a Witness.
    struct WitnessCarrier has key { id: UID, witness: WITNESS }

    /// Send a `WitnessCarrier` to the module publisher.
    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            WitnessCarrier { id: object::new(ctx), witness: WITNESS {} },
            tx_context::sender(ctx)
        )
    }

    /// Unwrap a carrier and get the inner WITNESS type.
    public fun get_witness(carrier: WitnessCarrier): WITNESS {
        let WitnessCarrier { id, witness } = carrier;
        object::delete(id);
        witness
    }
}
```

---

# Hot Potato

Hot Potato 模式是一种利用 Move 中 Ability 的无 key、无 store 和无 drop 能力的结构，适用于需要原子性的程序中。

```rust
struct Hot_Potato {}
```

### aptos

```rust
public fun flashloan<X, Y, Curve>(x_loan: u64, y_loan: u64): (Coin<X>, Coin<Y>, Flashloan<X, Y, Curve>)
    acquires LiquidityPool, EventsStore {
        let pool = borrow_global_mut<LiquidityPool<X, Y, Curve>>(@liquidswap_pool_account);
        ...
        let reserve_x = coin::value(&pool.coin_x_reserve);
        let reserve_y = coin::value(&pool.coin_y_reserve);
        // Withdraw expected amount from reserves.
        let x_loaned = coin::extract(&mut pool.coin_x_reserve, x_loan);
        let y_loaned = coin::extract(&mut pool.coin_y_reserve, y_loan);
        ...
        // Return loaned amount.
        (x_loaned, y_loaned, Flashloan<X, Y, Curve> { x_loan, y_loan })
    }

public fun pay_flashloan<X, Y, Curve>(
        x_in: Coin<X>,
        y_in: Coin<Y>,
        loan: Flashloan<X, Y, Curve>
    ) acquires LiquidityPool, EventsStore {
        ...
        let Flashloan { x_loan, y_loan } = loan;

        let x_in_val = coin::value(&x_in);
        let y_in_val = coin::value(&y_in);

        let pool = borrow_global_mut<LiquidityPool<X, Y, Curve>>(@liquidswap_pool_account);

        let x_reserve_size = coin::value(&pool.coin_x_reserve);
        let y_reserve_size = coin::value(&pool.coin_y_reserve);

        // Reserve sizes before loan out
        x_reserve_size = x_reserve_size + x_loan;
        y_reserve_size = y_reserve_size + y_loan;

        // Deposit new coins to liquidity pool.
        coin::merge(&mut pool.coin_x_reserve, x_in);
        coin::merge(&mut pool.coin_y_reserve, y_in);
        ...
    }
```

### sui

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
    public fun repay<T>(self: &mut FlashLender<T>, payment: Coin<T>, receipt: Receipt<T>) {
        let Receipt { flash_lender_id, repay_amount } = receipt;
        assert!(object::id(self) == flash_lender_id, ERepayToWrongLender);
        assert!(coin::value(&payment) == repay_amount, EInvalidRepaymentAmount);

        coin::put(&mut self.to_lend, payment)
    }
}

```

### 复杂的函数调用顺序

Hot Potato 设计模式不仅仅只适用于闪电贷的场景，还可以用来控制更复杂的函数调用顺序。

```rust
module example::hot_potato {
    /// Without any capability,
    struct Potato {
        has_cut: bool,
        has_cook: bool,
    }
    /// When calling this function, the `sender` will receive a `Potato` object.
    /// The `sender` can do nothing with the `Potato` such as store, drop,
    /// or move_to the global storage, except passing it to `consume_potato` function.
    public fun get_potato(_sender: &signer): Potato {
        Potato {
            has_cut: false,
            has_cook: false,
        }
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
        let Potato {has_cut: _, has_cook: _ } = potato; // destroy the Potato.
    }
}

```

---

# ID Pointer

ID 指针是一种程序设计技术，用于将一个对象的数据和其访问器/能力分开处理，以便更好地控制和管理对象的访问。通过使用 ID 指针，程序可以更加灵活、高效地操作对象，并可以有效地避免多个访问器/能力之间的冲突问题。

```rust
module examples::lock_and_key {
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::option::{Self, Option};

    /// Lock is empty, nothing to take.
    const ELockIsEmpty: u64 = 0;

    /// Key does not match the Lock.
    const EKeyMismatch: u64 = 1;

    /// Lock already contains something.
    const ELockIsFull: u64 = 2;

    /// Lock that stores any content inside it.
    struct Lock<T: store + key> has key {
        id: UID,
        locked: Option<T>
    }

    /// A key that is created with a Lock; is transferable
    /// and contains all the needed information to open the Lock.
    struct Key<phantom T: store + key> has key, store {
        id: UID,
        for: ID,
    }

    /// Returns an ID of a Lock for a given Key.
    public fun key_for<T: store + key>(key: &Key<T>): ID {
        key.for
    }

    /// Lock some content inside a shared object. A Key is created and is
    /// sent to the transaction sender. For example, we could turn the
    /// lock into a treasure chest by locking some `Coin<SUI>` inside.
    ///
    /// Sender gets the `Key` to this `Lock`.
    public entry fun create<T: store + key>(obj: T, ctx: &mut TxContext) {
        let id = object::new(ctx);
        let for = object::uid_to_inner(&id);

        transfer::share_object(Lock<T> {
            id,
            locked: option::some(obj),
        });

        transfer::transfer(Key<T> {
            for,
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    /// Lock something inside a shared object using a Key. Aborts if
    /// lock is not empty or if key doesn't match the lock.
    public entry fun lock<T: store + key>(
        obj: T,
        lock: &mut Lock<T>,
        key: &Key<T>,
    ) {
        assert!(option::is_none(&lock.locked), ELockIsFull);
        assert!(&key.for == object::borrow_id(lock), EKeyMismatch);

        option::fill(&mut lock.locked, obj);
    }

    /// Unlock the Lock with a Key and access its contents.
    /// Can only be called if both conditions are met:
    /// - key matches the lock
    /// - lock is not empty
    public fun unlock<T: store + key>(
        lock: &mut Lock<T>,
        key: &Key<T>,
    ): T {
        assert!(option::is_some(&lock.locked), ELockIsEmpty);
        assert!(&key.for == object::borrow_id(lock), EKeyMismatch);

        option::extract(&mut lock.locked)
    }

    /// Unlock the Lock and transfer its contents to the transaction sender.
    public fun take<T: store + key>(
        lock: &mut Lock<T>,
        key: &Key<T>,
        ctx: &mut TxContext,
    ) {
        transfer::public_transfer(unlock(lock, key), tx_context::sender(ctx))
    }
}

```

# 总结

祝大家接下来变得更强！

![](https://d.ifengimg.com/w935_h595_q90_webp/x0.ifengimg.com/ucms/2023_01/00E78A814D79BC0414718417DA22B82523936AB4_size58_w935_h595.jpg)
