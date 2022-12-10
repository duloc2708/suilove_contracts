
module love::user_tests {
    
    #[test_only]
    use std::string::{Self, String};
    use std::vector;

    #[test_only]
    use std::option::{Self};

    #[test_only]
    use sui::test_scenario::{Self};

    #[test_only]
    use love::user::{Self, User, vector_string};

    #[test]
    fun test_user_create_update_ok() {

        let user_addr = @0x008;
        let user2_addr = @0x009;

        let nickname = b"James";
        let age = 22;
        let avatar = b"xxxxxxxxxxxx";
        let avatar_url = b"https://www.abc.com";
        let gender = b"male";
        let language = b"English";
        let city = b"Chicago";
        let country = b"USA";
        let hobby = vector::singleton(b"tech");
        let bio = b"Move";
        let ilike2 = vector::singleton(b"nba");

        let scenario_val = test_scenario::begin(user_addr);
        let scenario = &mut scenario_val;

        // create user
        {
            let ctx = test_scenario::ctx(scenario);
            user::create_user_without_avatar_url(nickname, age, avatar, gender, language, city, country, hobby, bio, ctx);
        };
        
        // getter
        test_scenario::next_tx(scenario, user_addr);
        {
            let u = test_scenario::take_from_sender<User>(scenario);
            assert!(user::nickname(&u) == stringify(nickname), 0);
            assert!(user::bio(&u) == stringify(bio), 0);
            assert!(user::avatar(&u) == avatar, 0);
            assert!(option::is_none(&user::avatar_url(&u)), 0);
            assert!(user::ilike(&u) == vector_string(hobby), 0);

            test_scenario::return_to_sender(scenario, u);
        };

        // setter 
        test_scenario::next_tx(scenario, user_addr); 
        {
            let u = test_scenario::take_from_sender<User>(scenario);
            let u_ref = &mut u;
            user::update_user_avatar_url(u_ref, avatar_url);
            user::update_user_ilike(u_ref, ilike2);
            test_scenario::return_to_sender(scenario, u);
        };

        // check update
        test_scenario::next_tx(scenario, user_addr);
        {
            let u = test_scenario::take_from_sender<User>(scenario);
            assert!(option::is_some(&user::avatar_url(&u)), 0);
            assert!(option::contains(&user::avatar_url(&u), &stringify(avatar_url)), 0);
            assert!(user::ilike(&u) == vector_string(ilike2), 0);
            test_scenario::return_to_sender(scenario, u);
        };

        // transfer user
        test_scenario::next_tx(scenario, user_addr);
        {
            let u = test_scenario::take_from_sender<User>(scenario);
            user::transfer_user(u, user2_addr);
        };

        // check transfer user
        test_scenario::next_tx(scenario, user2_addr);
        {
            let sender = test_scenario::sender(scenario);
            let u = test_scenario::take_from_sender<User>(scenario);
            let owner = user::wallet_addr(&u);
            assert!(sender == owner, 0);
            test_scenario::return_to_sender(scenario, u);
        };

        test_scenario::end(scenario_val);
    }

    public fun stringify(b: vector<u8>): String {
        string::utf8(b)
    }
}