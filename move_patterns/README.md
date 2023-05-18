# Sui move 设计模式

[toc]

# Move 介绍

Move 是一种专门为数字资产管理和转移而设计的编程语言，它的主要用途是实现 Diem 区块链（前身是 Libra）上的应用程序。这种语言提供了安全、沙盒式和形式化验证等功能，可以帮助开发者编写可靠的区块链应用，避免发生攻击等安全问题。除了在区块链领域之外，Move 还可以在其他开发场景中应用。

Move 是一种编程语言，它从 Rust 中获取灵感。Move 名字的来源是因为它使用移动语义来表示数字资产（例如货币），这种语义意味着一个资源只能属于一个所有者，因此不能被复制。这使得 Move 可以更好地支持数字资产安全和合规性。

# 为什么会存在 Move 设计模式

为什么会存在 Move 设计模式，主要有以下三个方面。

## 面向资源编程

面向资源编程是一种新颖的编程范式，它将编程对象从简单的数据和方法转向了资源的概念。资源是一种代表性的实体，如区块链上的 Token、经济市场上的股票等，资源拥有自己的唯一标识符和状态，并且可以被转移、分配、销毁等操作。

面向资源编程语言将资源作为程序的核心概念，程序员需要对资源的所有权和权限进行管理，并在程序中建立资源之间的依赖关系。Move 编程语言就是一种典型的基于资源的编程语言，它通过更贴合区块链数字资产的特点，使得资源在区块链上更加安全和高效，同时也能够支持更多的功能。

与传统面向对象编程不同，基于资源编程对应用程序的实现和设计提出了新的挑战，需要更多的资源管理技能和资源分配策略。但是，相比传统的基于对象和方法的编程方式，基于资源编程能够更好地体现分布式、去中心化的特点，因此，其应用范围和潜力更加广阔。

## 状态存储机制

在 Solidity 中，状态变量是可以定义并保存的变量，它们的值存储在全局储存中。这意味着在合约代码中，可以直接访问和修改这些变量。这些变量的值可以在合约的整个生命周期内保持不变，直到被修改或删除。因为状态变量是全局的，所以它们可以在整个合约内被访问和修改，而不需要额外的参数或函数调用。这种特性使得 Solidity 非常适合用于构建分布式应用程序或智能合约。

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

在 Move 中，存储资源的方式与其他平台不同，Move 的资源对象是通过代码中的变量来表示的，而不是将资源直接存储。因此，为了访问资源，需要使用显示的接口来调用变量，以明确指示资源对象的访问方式。

在传统的 Move 语言中，访问资源（如数据、代码等）需要通过全局存储操作接口来实现。具体的操作函数包括 move_to、move_from、borrow_global 和 borrow_global_mut 等函数。无论是从全局存储中取出资源，还是将资源存放到账户下面，或者对引用的资源对象进行修改，都需要显式地表示。

也就是说，开发者需要自行管理资源的使用、获取和释放等操作，而不是交给 Move 语言自动处理。这样能够确保资源的有效管理和安全性。

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

在核心的 Move 语言中，全局存储是编程模型的一部分，并可以通过特殊的操作（如 move_to、move_from 等全局存储操作符）访问。资源和模块都存储在核心的 Move 全局存储中。当发布一个模块时，它会被存储到 Move 中新生成的一个模块地址中。当一个新的对象（也称为资源）被创建时，它通常会被存储到某个地址中。

但是，链上的存储是昂贵且有限的（不适合存储和索引优化）。目前的区块链无法扩展以处理存储密集的应用程序，如市场和社交应用。

因此，在 Sui Move 中没有全局存储。Sui Move 不允许任何与全局存储相关的操作（有一个字节码验证器可用于检测违规）。相反，存储发生在 Sui 中。当发布一个模块时，新发布的模块被存储在 Sui 存储中，而不是 Move 存储中。同样，新创建的对象存储在 Sui 存储中。这也意味着，当需要在 Move 中读取对象时，不能依赖全局存储操作，而必须通过 Sui 显式传递需要访问的所有对象到 Move 中。

## Ability

Ability 是指在 Move 语言中，对于一个给定的类型，所能够允许的操作的一种类型特性。换句话说，它定义了类型的功能或行为能力。使用 Ability 可以严格限定某一类型值的操作，从而避免潜在的安全风险或错误。例如，对于一个自定义能够接受交易的类型，可以定义其 Ability 为只允许特定用户或特定条件下进行交易操作，从而确保类型值的安全性和完整性。

- copy 复制：允许此类型的值被复制
- drop 丢弃：允许此类型的值被弹出/丢弃，没有话表示必须在函数结束之前将这个值销毁或者转移出去。
- store 存储：允许此类型的值存在于全局存储中或者某个结构体中
- key 键值：允许此类型作为全局存储中的键(具有 key 能力的类型才能保存到全局存储中)

其中，copy（复制）允许此类型值被复制，drop（丢弃）允许此类型值被弹出或丢掉，store（存储）允许此类型值存在全局存储或某个结构体中，key（键值）允许此类型作为全局存储中的键。需要注意的是，如果一个类型不具备 key 能力，那么是无法保存到全局存储中的。

## 总结

作为面向资源的编程语言，以上三个特点也是与其他语言非常不同的地方，基于资源编程的 Move 编程模式，也主要是围绕这些特性产生的。

# Capability

Capability 可以理解为是指一个人、组织或系统所具有的能力或资质。

在商业和管理领域，capability 通常被用于描述某个组织或者个人能够有效地执行某个任务或者实现特定目标的能力。例如，企业可以将其机器人和自动化技术的能力视为其制造业的核心能力，而一位经理人可以拥有有效管理团队和有效沟通的能力，这些都是他们的能力。能力可以包括生产能力、研发能力、市场营销能力、人力资源能力、战略规划能力等等。对于一个组织或者个人，他们不仅需要拥有一定的能力，还需要持续地提升和发展他们的能力，以适应越来越复杂和具有挑战性的市场和商业环境。

在 Move 中呢，首先它是一个资源，可以证明资源所有者特定的权限，如铸造权、管理权、函数调用权等。在 Move 智能合约中，Capability 是一个广泛使用的设计模式，可以用来进行访问控制。

例如，sui-framework 中的 TreasuryCap 就采用了 Capability 来限制某些权限。此外，Capability 也是已知最古老的 Move 设计模式之一，可以追溯到 Libra 项目及其代币智能合约，用于授权铸币。

## 如何使用

Capability 本质上是一个资源对象，它只能被可信任的用户持有。在合约中，可以定义一个 AdminCap 来代表该模块的控制权限，只要某个用户持有该权限，就可以被视为可信任的用户。Capability 资源对象内不需要任何的字段，其作用是为了控制和限制合约中的某些操作只能由特定的用户执行。

```rust
struct AdminCap has key, store {}
```

Capability 通常在模块初始化的时候生成，并且可以赋予部署者一个具有访问权限的资源。
比如在 Sui 的 init 函数里面，这个 Capability 资源可以被移动到储存到调用者的账户下。

当需要使用一些需要访问权限的函数时，被调用的函数会检查调用者账户下是否存在这个 Capability 资源，如果存在则说明调用者拥有正确的访问权限，就能够使用相应的函数。

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

此代码定义了一个名为 example::capability 的模块，其中包含一个名为 OwnerCapability 的结构体类型，此类型需要具有 store 和 key 的能力。

然后，init 函数用于存储一个 OwnerCapability 资源到发送者地址下面，确保发送者地址为@example。

最后，admin_fun 函数只允许具有 OwnerCapability 的用户调用，用户必须从发送者地址中获取 OwnerCapability 资源，然后可以在函数中对其进行操作。

其中 acquires 关键字表示获取资源时需要进行写锁定以避免并发问题。

### sui

sui 中的 Move 与 Aptos 或者 starcoin 中的 Core Move 有所不同，sui 封装了全局操作函数。

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

该模块定义了两个结构体类型：OwnerCapability 和 Coin。OwnerCapability 有一个 UID 类型的 id 成员变量；

Coin 包含 UID 类型的 id 和 u64 类型的 value 成员变量。

init 函数用于初始化模块，创建 OwnerCapability 实例并将其发送到发布者。

mint_and_transfer 函数是模块的入口函数，可以供 OwnerCapability 调用，将创建 Coin 实例并将其转移到给定地址上。tx_context::sender 和 object::new 是 Sui 的两个函数。

## 总结

Move 语言中的访问控制实现相较于其他语言来说更为复杂，原因在于 Move 的存储架构和模组的特殊性需要将资源存储到一个账户下面。

如果仅在实现访问控制时，Move 也可以使用 VecMap 等数据结构。但使用 Capability 这种模式更加契合面向资源编程的概念，且更易于使用。

关于 Capability（权限）也有一些限制。

首先，作为一个凭证，Capability 是不能被复制的，因为如果被复制，那么持有者就可以通过复制获得更多的权限，这就破坏了权限控制的原则。

其次，正常的业务逻辑下，Capability 也是不能随意丢弃的，因为一旦丢弃，就会对系统造成不可逆的影响，这也与权限控制原则相矛盾。因此，在使用 Capability 时需要注意这些限制和要求。

# Wrapper

Wrapper 是一种封装对象或数据结构的技巧，它将原始对象或数据结构包装在另一个对象中，从而提供额外的功能或抽象层面。

Wrapper 可以用于管理或简化复杂的数据结构和算法，提供更高层次的接口，增加安全性，以及实现适配器模式等。在编程中常见的 Wrapper 包括装饰器、代理、适配器等。

我们先回头看下，在上个 Capability 的例子中，通常合约初始化时会铸造一个 Capability，那么在这之后如果我想将这个 Capability 转让给其他人怎么办？

在 Move 中，想要将数据存储到一个地址下，需要使用 move_to 函数，该函数需要一个 signer 参数作为交易发起者的签名。如果没有签名，交易就无法被主动执行，因此需要使用 Wrapper 模式来解决这个问题。Wrapper 模式可以理解为一个中间层，它包装了实际执行操作的函数，使其可以被调用者轻松使用。在 Move 编程实践中，Wrapper 模式被广泛使用，可以让开发者更方便地操作区块链上的数据。

Wrapper 模式即包装器模式，它是一种设计模式，常被用来将一个对象包装起来，达到修改该对象行为的目的。在这里，Wrapper 模式的具体应用是在需要给一个地址发送一个资源时，为了方便处理，我们可以将要发送的对象放在一个 Wrapper 对象中进行包装。用户在主动调用接受 Wrapper 的函数时，函数会通过 Wrapper 获取其中被包装的对象。由于这个函数是由用户主动调用的，所以在获取到被包装的对象后，可以直接将其存放到用户想要的位置下面。这样，Wrapper 模式就实现了将对象进行包装，方便传递和处理的目的。

> 这种场景总主要是因为不能直接发送，所以需要先预把对象，预存到一个地方，然后接受者再主动去确认拿取，就如同现实生活中 Offer 需要确认一般，所以这种模式一般也叫做 Offer 模式

## 如何使用

### aptos

为了实现资源的转移，可以在合约中可以定义一个 Offer 结构体，类型参数接受一个泛型 T，从而可以给任意类型包装，然后定义一个 receipt 字段进行访问控制。

用户接受 Offer 时，首先从 Offer 地址下取出来，随后在验证地址是否和 Offer 中的地址相同。

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

## 总结

Wrapper（包装器）中的有一个限制：只能指定一个地址来接受 Offer。如果需要赋予多个人一个 Capability（能力），就需要解决这个限制。

此外，在 Move 中，一个账户下只能存放一种类型的资源，也会造成不能再存放其他人的 Offer。因此，一般在用的时候，建议将 receipt 字段替换为一个 vector（向量）或者一个 table（表）来储存多个目标地址，以解决这些限制。

```rust
/// 定义一个Offer来包装一个对象
struct Wrapper<T: key + store> has key, store {
    receipt: address,
    map: VecMap<T>,
}
```

此外在其他场景中如果没有提供存放资源的接口，那么可以通过 Wrapper 来将其保存。

例如下面的 Coin 模块，由于 Move 中的特性，定义的资源只能在定义这个资源的模块内操作，所以当 mint 函数返回一个 Coin 对象时，用户不能直接使用 move_to 来存放。

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

那么此时用户可以定义一个自己的 Wrapper 结构将其包装，随后就可以将这个嵌套结构一同放到自己的地址下。

```rust
struct Wrapper has key, store {
        coin: Coin
}
```

# Witness

witness：中文翻译是见证者，证人。

witness 在 move 里面，是一种临时资源，它只能被使用一次，并在使用后被丢弃，意味着它就像一个见证者来看这个合约。

它的作用是确保不能重复使用相同的资源来初始化其他结构，并通常用来确认一个类型的所有权。

witness 的实现得益于 Move 中的类型系统，该系统限制了类型实例化的范围，只能在定义该类型的模块中创建。这样可以保证 witness 的正确使用和有效性。

一个简单的例子，在 framework 里面定义了 coin 合约用来定义 token 标准，如果想要注册 token 那么合约会调用 publish_coin。

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

这段代码定义了三个模块，分别是 framework::coin、examples::xcoin 和 hacker::hack。

在 framework::coin 中，定义了一个名为 publish_coin 的公共函数，该函数的输入参数是一个泛型类型 T: drop，这意味着只有实现了 drop trait 的类型才能作为该函数的调用参数。该函数的作用是将一个 coin 注册到注册表中。

在 examples::xcoin 中，定义了一个名为 X 的结构体，并为其实现了 drop trait，然后定义了一个名为 publish 的公共函数，该函数调用了 coin::publish_coin<X>(X {})，即调用了 framework::coin 模块中的 publish_coin 函数，并传递了一个 X 类型的实例作为参数。由于 X 类型实现了 drop trait，因此可以作为 publish_coin 函数的调用参数，该函数将 X 类型的 coin 注册到了注册表中。

在 hacker::hack 中，同样也使用了 framework::coin 模块和 examples::xcoin 模块，并定义了一个名为 publish 的公共函数。不同的是，该函数中尝试调用 coin::publish_coin<X>(X {})，传递了一个 X 类型的实例作为参数。由于 X 类型只在 examples::xcoin 中定义，因此 hacker::hack 模块无法构造 X 类型的实例，该调用是非法的。

```
┌─ /sources/m.move:25:31
   │
25 │         coin::publish_coin<X>(X {});
   │                               ^^^^ Invalid instantiation of '(examples=0x1)::xcoin::X'.
All structs can only be constructed in the module in which they are declared
```

witness 在 Sui 中与其他 Move 公链有一些区别。

Sui 存在一种特殊的数据结构类型叫做 one-time witness 类型。如果一个结构类型的名称与定义它的模块名称相同且是大写，并且没有字段或者只有一个布尔字段，那么就是一个 one-time witness 类型。

即，一次性见证者，顾名思义，只能被用一次。这种类型只会在模块初始化时使用，合约可以通过 sui framwork 中的 types::is_one_time_witness 函数来验证一个结构类型是否是 one-time witness 类型。

例如在 sui 的 coin 库中，如果需要注册一个 coin 类型，那么需要调用 create_currency 函数。函数参数则就需要一个 one-time witness 类型。为了传递该类型参数，需要在模块初始化 init 函数参数中第一个位置传递，即：

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

sui 中的初始化函数只能有一个或者两个参数，且最后的参数一定是&mut TxContext 类型，one-time witness 类型同样是模块初始化时自动传递的。

init 函数如果传递除了上述提到的以外的参数，Move 编译器能够编译通过，但是部署时 Sui 的验证器会报错。此外如果第一个传递的参数不是 one-time witness 类型，同样也只会在部署时 Sui 验证才会报错。

## 总结

witness 模式通常其他模式一同使用，例如 Wrapper 和 capability 模式。

# Transferable Witness

一个 Transferable Witness 就像是一个可以保存一段时间的证人，但是它被放在一个可以用完就扔掉的包装里。也就是说，这个证人在被用完之后，就不能再次使用了。

这种模式基于两个概念的结合：Capability 和 Witness。由于 Witness 非常重要，因此生成 Witness 应该仅允许授权用户（最好只允许一次）。

但是某些场景需要在模块 X 中对某个类型进行授权，以便在其他模块 Y 中使用。或者，授权可能需要在某段时间之后执行。

对于这些相对罕见的场景，存储型 Witness 是一个完美的解决方案。

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

该模块定义了一个可在智能合约环境中在不同参与者之间传递的"Witness"类型。该"Witness"类型被包装在一个"WitnessCarrier"结构体中，并使用"transfer::transfer"函数将其发送给模块发布者。

简单理解为，我们有一个东西叫做"Witness"，并且可以让它在不同的人之间传来传去。它被包装在一个叫做"WitnessCarrier"的盒子里。当需要一个新的"Witness"时，我们可以使用"init"函数来创造一个新的盒子，并将它发给想要使用它的人。当我们得到一个盒子时，我们可以使用"get_witness"函数来打开盒子并得到"Witness"里面的东西。这个模块可以让我们在不同的人之间共享一个"Witness"，这在某些特殊的情况下很有用，比如需要得到多个人的批准或许可的时候。

接下来我们来看代码：
"Witness"现在拥有了一个叫做"store"的功能，可以让我们把它存储在一个包装器内。这意味着我们可以更方便地控制和管理"Witness"，同时避免直接在智能合约中暴露和处理它的内部数据细节。

"WitnessCarrier"结构体包含了"Witness"的类型。使用"WitnessCarrier"结构体只能获取"Witness"一次，也就是说，只能使用一次。简单来说，"WitnessCarrier"是一个临时容器，用来获取"Witness"的内容并在获取后将其销毁。

将一个"WitnessCarrier"结构体发送给模块发布者。这意味着将这个包装了"Witness"的数据类型发送给处理它的函数或代码模块，以用于后续的流程或操作。

打开一个"WitnessCarrier"并获取其中包装的内部"WITNESS"类型。这意味着我们可以将包装的"Witness"从"WitnessCarrier"中分离出来，单独使用它的数据和功能，或者将其传递给其他需要使用它的地方。这个过程就叫做"Unwrap"。

# Hot Potato

Hot Potato 模式是一种没有 key、store 和 drop 能力的结构，意味着它不能存储和丢弃数据，并且没有唯一标识符。该模式的主要优势在于它能够利用 Move 中的 Ability 来实现某些操作。

具体来说，Hot Potato 模式要求其创建者必须在创建它时将其使用掉。这种模式在需要原子性的程序中是理想的，因为在同一交易中必须启动和偿还贷款。因此，Hot Potato 模式可以确保在同一交易中完成所有必要的操作，从而保持原子性。

总之，Hot Potato 模式是一种利用 Move 中 Ability 的无 key、无 store 和无 drop 能力的结构，适用于需要原子性的程序中。

```rust
struct Hot_Potato {}
```

相较于 Solidity 中的闪电贷的实现，Move 中的实现是优雅的。

在 Solidity 中实现闪电贷会涉及到许多动态调用，而且还存在重入、拒绝服务攻击等问题。

而在 Move 中，如果一个函数返回的是一个不具备任何能力的 potato，那么由于没有 drop 的 ability，这个 potato 不能被储存到全局变量中或其他结构体中，也不能在函数结束时丢弃。因此，必须解构这个资源或者将它传递给另一个可以使用这个 potato 的函数。

这种方式可以实现函数的调用流程，即模块可以在没有调用者任何背景和条件下，保证调用者一定会按照预先设定的顺序去调用函数。

> 闪电贷本质也是一个调用顺序的问题

## 如何使用

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

sui 官方示例中同样实现了闪电贷。

当用户借款时，会调用"loan"函数并得到一定数量的资金（"coin"），同时也会得到一个记录着借贷金额（"value"）但没有任何借贷能力（"ability"）的"receipt"收据。如果用户试图不归还资金，那么这个收据将被丢弃，从而导致报错。为确保借贷协议的正确性，用户必须调用"repay"函数来归还借款并销毁该收据。收据的销毁是由模块控制的，并且在销毁时会验证传入的金额是否与收据中的金额相等，以确保借贷协议的正确执行。

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

## 总结

Hot Potato 设计模式不仅仅只适用于闪电贷的场景，还可以用来控制更复杂的函数调用顺序。

例如我们想要一个制作土豆的合约，当用户调用 get_potato 时，会得到一个没有任何能力的 potato，我们想要用户得倒之后，按照切土豆、煮土豆最后才能吃土豆的一个既定流程来操作。所以用户为了完成交易那么必须最后调用 consume_potato，但是该函数限制了土豆必须被 cut 和 cook，所以需要分别调用 cut_potato 和 cook_potato，cook_potato 中又限制了必须先被 cut，从而合约保证了调用顺序必须为 get→cut→cook→consume，从而控制了调用顺序。

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

# ID Pointer

ID（Identity）指针是一种程序设计技术，用于将一个对象的数据和其访问器/能力分开处理，以便更好地控制和管理对象的访问。通过使用 ID 指针，程序可以更加灵活、高效地操作对象，并可以有效地避免多个访问器/能力之间的冲突问题。这种技术广泛应用于计算机系统和软件的设计与开发中。

在 Java 中，可以通过以下两种方式使用 ID Pointer 技术：

使用引用类型和对象的引用变量
在 Java 中，所有的对象都是通过引用来访问和使用的。因此，我们可以使用引用变量来实现对一个对象的访问，并可以将这些引用变量作为 ID Pointer 来处理，来实现对一个对象的各种操作和控制。

使用接口和实现类
在 Java 中，可以使用接口和实现类的方式，将一个对象的访问和处理分离开来，并通过 ID Pointer 来管理和控制这些访问操作。具体而言，我们可以定义一个接口，其中包含该对象的各种访问操作，然后再定义一个实现类来实现这些操作，最后使用 ID Pointer 来引用该实现类对象，进行访问和控制。这样，可以实现对一个对象的高效、灵活的操作和管理。

ID Pointer 在 move 中也是通过将主要数据（即一个对象）与其访问器/能力分离开来。

比如我们有几个例子：

1. 访问共享对象

比如，我们在前面用一种名为 TransferCap，这个工具可以控制某些共享对象的转移和修改（例如修改“所有者”字段）。

2. 分离动态数据和静态数据

举个例子，假设有一种加密货币的非同质化代币（NFT），每个代币都有其特定的属性（动态数据），例如代币名称、价值等。与此同时，每个代币也隶属于一个代币收藏集（静态数据），并且每个收藏集都具有独特的属性，例如代币发行时间、开发者团队等。通过将 NFT 和其所属的收藏集分离开来，并分别处理它们，可以提高代码的效率并使代码更加灵活。

3. 避免不必要的类型链接和见证需求

举个例子，假设我们正在构建一个流动性池（LiquidityPool）合约，并需要定义一个 LP 代币类型。为了避免类型链接和见证需求，我们可以将 LP 代币类型定义为一个简单的结构体，其中只包含代币的名称和总供应量等基本信息。通过这种方式，我们可以在不降低代码清晰度和性能的前提下，避免不必要的类型链接和见证需求。

这个例子实现了在 Sui 上简单的“锁”和“钥匙”机制。其中 Lock <T>是一个共享对象，可以包含任何对象，而 Key 是一种所有权对象，需要它才能访问锁的内容。

为了访问 Lock<T>的内容，用户需要先获取与该 Lock<T>相关联的 Key，然后就可以使用相应的 Key 来访问 Lock<T>的内容。

每个 Key 都有一个独特的 ID 字段，通过这个 ID 字段就可以将 Key 链接到其对应的 Lock<T>，从而实现了将动态和静态内容拆分开来的目的。同时，这个 ID 字段可以在链外被发现和验证，从而实现安全的访问控制，避免了其他人随意访问锁中的内容的情况发生。

总的来说，这个例子使用了"锁"和"钥匙"的机制来实现分布式系统中的共享对象和所有权对象的管理，并使用了 ID Pointer 技术来实现安全的访问控制。

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

不管是设计模式也好，别的模式也要，他都是为了解决问题而发明的有效的方法。除了我们已经熟悉的 web2 世界的 23 种设计模式以外，还有 MVVM、Combinator 等其它的东西，都已经是前辈们经过多年的摸爬滚打总结出来的，其有效性不容置疑。

比如我们要做一个分布式系统，在哪里放 gate way，在哪里放 database，在哪里放 cache，在哪里放计算节点，这些东西都已经是早就总结好的了。类似的东西就叫 pattern。一个 architecture 就是由很多个 pattern 组合起来的。除此之外，做游戏也好，做编译器也好，设计数据库也好，每一大类的问题都有他们自己的 pattern。他们的档次跟设计模式不一样，但是要解决的问题都是一样的，就是让你高效地解决问题。

智能合约是新的，Move 也是新的，我们要更好的学习 Move 的设计模式，学习里面的精髓，学习如何合理的组织我们的代码，如何解耦，做出更牛逼的 Web3 产品。

也祝大家接下来变得更强！

https://d.ifengimg.com/w935_h595_q90_webp/x0.ifengimg.com/ucms/2023_01/00E78A814D79BC0414718417DA22B82523936AB4_size58_w935_h595.jpg
