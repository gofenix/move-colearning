module mypkg::color_object {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct ColorObject has key {
        id: UID,
        red: u8,
        green: u8,
        blue: u8,
    }

    fun new(red: u8, green: u8, blue: u8, ctx: &mut TxContext): ColorObject {
        ColorObject {
            id: object::new(ctx),
            red,
            green,
            blue,
        }
    }

    public entry fun create(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
        let color_object = new(red, green, blue, ctx);
        transfer::transfer(color_object, tx_context::sender(ctx))
    }

    public fun get_color(self: &ColorObject): (u8, u8, u8) {
        (self.red, self.green, self.blue)
    }
}

#[test_only]
module mypkg::color_object_test {
    use sui::test_scenario;

    use mypkg::color_object::{Self, ColorObject};

    #[test]
    fun test_create() {
        let owner = @0x1;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        // creat object
        {
            let ctx = test_scenario::ctx(scenario);
            color_object::create(255, 0, 255, ctx);
        };

        let not_owner = @0x2;
        test_scenario::next_tx(scenario, not_owner);
        {
            assert!(!test_scenario::has_most_recent_for_sender<ColorObject>(scenario), 0);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let object = test_scenario::take_from_sender<ColorObject>(scenario);
            let (red, green, blue) = color_object::get_color(&object);
            assert!(red==255 && green == 0 && blue == 255, 0);
            test_scenario::return_to_sender(scenario, object);
        };

        test_scenario::end(scenario_val);
    }

}