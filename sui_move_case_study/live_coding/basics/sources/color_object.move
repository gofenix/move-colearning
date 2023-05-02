module basics::color_object {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct ColorObject has key {
        id: UID,
        red: u8,
        green: u8,
        blue: u8,
    }

    // == Functions covered in Chapter 1 ==

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

    // == Functions covered in Chapter 2 ==

    /// Copies the values of `from_object` into `into_object`.
    public entry fun copy_into(from_object: &ColorObject, into_object: &mut ColorObject) {
        into_object.red = from_object.red;
        into_object.green = from_object.green;
        into_object.blue = from_object.blue;
    }

    public entry fun delete(object: ColorObject) {
        let ColorObject { id, red: _, green: _, blue: _ } = object;
        object::delete(id);
    }

    public entry fun transfer(object: ColorObject, recipient: address) {
        transfer::transfer(object, recipient)
    }

    // == Functions covered in Chapter 3 ==

    public entry fun freeze_object(object: ColorObject) {
        transfer::freeze_object(object)
    }

    public entry fun create_immutable(red: u8, green: u8, blue: u8, ctx: &mut TxContext) {
        let color_object = new(red, green, blue, ctx);
        transfer::freeze_object(color_object)
    }

    public entry fun update(
        object: &mut ColorObject,
        red: u8, green: u8, blue: u8,
    ) {
        object.red = red;
        object.green = green;
        object.blue = blue;
    }
}

#[test_only]
module basics::color_objectTest{
    // test_scenario
    use sui::test_scenario;
    use basics::color_object::{Self, ColorObject};

    #[test]
    fun test_cerate(){
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
