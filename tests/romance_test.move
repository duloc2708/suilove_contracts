
module love::tests {

    #[test_only]
    use std::string;

    #[test_only]
    use std::option;

    #[test_only]
    use sui::coin::{Self, Coin};

    // #[test_only]
    // use sui::transfer;

    #[test_only]
    use sui::sui::SUI;

    #[test_only]
    use sui::test_scenario::{Self, Scenario};

    #[test_only]
    use love::romance::{Self, Romance, MessageBox};
    
    #[test]
    fun test_create_share_pair_ok() {
        let initiator = @0x003;
        
        let lucky_dog = @0x005;

        let name = b"I love you";
        let declaration = b"Love you forever";
        let envelope = b"envelope photo";

        let scenario_val = test_scenario::begin(initiator);
        let scenario = &mut scenario_val;
        
        create(name, declaration, envelope, scenario);

        test_scenario::next_tx(scenario, initiator);
        check_name_declaration(name, declaration, envelope, scenario);

        // share the romance
        test_scenario::next_tx(scenario, initiator);
        share_romance(scenario);

        // user pair the romance and check the romance after share
        test_scenario::next_tx(scenario, lucky_dog);
        pair_romance(scenario);

        // check the romance after pair successfully
        test_scenario::next_tx(scenario, lucky_dog);
        check_romance_lucky_dog_after_pair(scenario);
    
        test_scenario::end(scenario_val);
    }

    #[test]
    fun send_redpack_tests() {

        let initiator: address = @0x007;
        let lucky_dog: address = @0x008;

        let name = b"I love you";
        let declaration = b"Love you forever";
        let envelope = b"envelope photo";

        let scenario_val = test_scenario::begin(initiator);
        let scenario = &mut scenario_val;

        create(name, declaration, envelope, scenario);

        test_scenario::next_tx(scenario, initiator);
        check_name_declaration(name, declaration, envelope, scenario);

        // share the romance
        test_scenario::next_tx(scenario, initiator);
        share_romance(scenario);

        // pair romance
        test_scenario::next_tx(scenario, lucky_dog);
        pair_romance(scenario);

        // send redpack
        test_scenario::next_tx(scenario, lucky_dog);
        send_redpack(scenario, 10);

        // check balance
        // test_scenario::next_tx(scenario, &lucky_dog);
        // check_balance(scenario, 0);

        test_scenario::next_tx(scenario, initiator);
        check_balance(scenario, 10);

        test_scenario::end(scenario_val);
    }

    fun create(name: vector<u8>, declaration: vector<u8>, envelope: vector<u8>, scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        romance::create(name, declaration, envelope, ctx);
    }

    fun check_name_declaration(name: vector<u8>, declaration: vector<u8>, envelope: vector<u8>, scenario: &mut Scenario) {
        let romance = test_scenario::take_from_sender<Romance>(scenario);
        let name_str = string::utf8(name);
        let declaration_str = string::utf8(declaration);
        assert!(romance::name(&romance) == name_str, 0);
        assert!(romance::declaration(&romance) == declaration_str, 0);
        assert!(romance::envelope(&romance) == envelope, 0);
        test_scenario::return_to_sender(scenario, romance);
    }

    fun share_romance(scenario: &mut Scenario) {
        let romance = test_scenario::take_from_sender<Romance>(scenario);
        let msg_box = test_scenario::take_from_sender<MessageBox>(scenario);
        romance::share(romance, msg_box);
    }
    
    fun pair_romance(scenario: &mut Scenario) {
        let romance = test_scenario::take_shared<Romance>(scenario);
        // let romance_ref = test_scenario::borrow_mut(&mut romance);
        let ctx = test_scenario::ctx(scenario);

        assert!(romance::is_share(&romance), 0);
        romance::pair(&mut romance, ctx);

        test_scenario::return_shared<Romance>(romance);
    }

    fun check_romance_lucky_dog_after_pair(scenario: &mut Scenario) {
        // let romance_wrapper = test_scenario::take_shared<Romance>(scenario);
        // let romance_ref = test_scenario::borrow_mut(&mut romance_wrapper);
        let romance_ref = test_scenario::take_shared<Romance>(scenario);
        
        let sender = test_scenario::sender(scenario);

        // assert!(option::is_some<Romance>(&romance::mate(&romance_ref)), 0);
        assert!(option::borrow(&romance::mate(&romance_ref)) == &sender, 0);

        test_scenario::return_shared<Romance>(romance_ref);
    }

    fun send_redpack(scenario: &mut Scenario, amount: u64) {
        let romance_wrapper = test_scenario::take_shared<Romance>(scenario);
        // let romance_ref = test_scenario::borrow_mut(&mut romance_wrapper);
        // let sender = test_scenario::sender(scenario);

        let ctx = test_scenario::ctx(scenario);
        let profit = coin::mint_for_testing<SUI>(amount, ctx);
        // let to_send = coin::take(coin::balance_mut(&mut profit), amount, ctx);

        romance::send_redpack(&mut romance_wrapper, profit, ctx);

        // transfer::transfer(profit, sender);
        test_scenario::return_shared(romance_wrapper);
    }

    fun check_balance(scenario: &mut Scenario, amount: u64) {

        let profit = test_scenario::take_from_sender<Coin<SUI>>(scenario);
        assert!(coin::value(&profit) == amount, 0);

        test_scenario::return_to_sender(scenario, profit);
    }
}