
module love::user_tests {
    
    #[test_only]
    use std::string::{Self, String};
    use std::vector;

    #[test_only]
    use std::option::{Self, Option};

    #[test_only]
    use sui::object::{Self, ID};

    #[test_only]
    use sui::test_scenario::{Self};

    // #[test_only]
    // use sui::table::{Self};

    #[test_only]
    use love::user::{Self, BlacklistTable, FriendshipTable, User, UserGlobalState, vector_string, init_test};

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
            init_test(ctx);
        };

        test_scenario::next_tx(scenario, user_addr);
        {
            let state = test_scenario::take_shared<UserGlobalState>(scenario);
            let ctx = test_scenario::ctx(scenario);
        
            user::create_user_without_avatar_url(&mut state, nickname, age, avatar, gender, language, city, country, hobby, bio, ctx);
            test_scenario::return_shared(state);
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

    #[test]
    fun test_user_friendship_should_work() {
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

        let _user2_id: Option<ID> = option::none();
        // let user2_name: Option<String> = option::none();
        // let user2_avatar: Option<String> = option::none();
        // let user2_avatar_url: vector<u8> = vector::empty();

        // init 
        {
            let ctx = test_scenario::ctx(scenario);
            init_test(ctx);
        };

        // create user
        test_scenario::next_tx(scenario, user_addr);
        {
            let state = test_scenario::take_shared<UserGlobalState>(scenario);
            let ctx = test_scenario::ctx(scenario);
        
            user::create_user_without_avatar_url(&mut state, nickname, age, avatar, gender, language, city, country, hobby, bio, ctx);
            test_scenario::return_shared(state);
        };

        // add friendship
        test_scenario::next_tx(scenario, user2_addr);
        {
            let state = test_scenario::take_shared<UserGlobalState>(scenario);
            let ctx = test_scenario::ctx(scenario);
        
            user::create_user_without_avatar_url(&mut state, nickname, age, avatar, gender, language, city, country, hobby, bio, ctx);
            test_scenario::return_shared(state);
        };

        test_scenario::next_tx(scenario, user2_addr);
        {
            let u = test_scenario::take_from_sender<User>(scenario);
        
            _user2_id = option::some(object::id(&u));
            // user2_name = option::some(u.name);
            // user2_avatar = u.avatar;
            // user2_avatar_url = u.avatar_url;
            test_scenario::return_to_sender(scenario, u);
        };

        // add friendship
        test_scenario::next_tx(scenario, user_addr);
        {
           let fs_table = test_scenario::take_from_sender<FriendshipTable>(scenario);
           let ctx = test_scenario::ctx(scenario);
           let user_id2 = option::extract(&mut _user2_id);
           user::add_friendship(&mut fs_table, user_id2, string::utf8(nickname), user2_addr, avatar, option::none(), ctx);
           option::fill(&mut _user2_id, user_id2);
           test_scenario::return_to_sender(scenario, fs_table);
        };

        // check friendship
        test_scenario::next_tx(scenario, user_addr);
        {
            let fs_table = test_scenario::take_from_sender<FriendshipTable>(scenario);
            // let ctx = test_scenario::ctx(scenario);
            // let user_id2 = option::extract(&mut user2_id);
            // let fs = table::borrow<address, Friendship>(&fs_table.friendships, user2_addr);
            assert!(user::is_friendship(&fs_table, user2_addr), 0);
            assert!(user::get_friendship_count(&fs_table) == 1, 0 );
            // assert!(fs.user_id == user_id2);
            user::remove_friendship(&mut fs_table, user2_addr);
            test_scenario::return_to_sender(scenario, fs_table);
        };

        test_scenario::next_tx(scenario, user_addr);
        {
            let fs_table = test_scenario::take_from_sender<FriendshipTable>(scenario);

            assert!(!user::is_friendship(&fs_table, user2_addr), 0);
            assert!(user::get_friendship_count(&fs_table) == 0, 0 );

            test_scenario::return_to_sender(scenario, fs_table);
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

        test_scenario::end(scenario_val);
    }

    #[test]
    fun test_user_block_should_work() {
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

        let _user2_id: Option<ID> = option::none();
        // let user2_name: Option<String> = option::none();
        // let user2_avatar: Option<String> = option::none();
        // let user2_avatar_url: vector<u8> = vector::empty();

        // init 
        {
            let ctx = test_scenario::ctx(scenario);
            init_test(ctx);
        };

        // create user
        test_scenario::next_tx(scenario, user_addr);
        {
            let state = test_scenario::take_shared<UserGlobalState>(scenario);
            let ctx = test_scenario::ctx(scenario);
        
            user::create_user_without_avatar_url(&mut state, nickname, age, avatar, gender, language, city, country, hobby, bio, ctx);
            test_scenario::return_shared(state);
        };

        test_scenario::next_tx(scenario, user2_addr);
        {
            let state = test_scenario::take_shared<UserGlobalState>(scenario);
            let ctx = test_scenario::ctx(scenario);
        
            user::create_user_without_avatar_url(&mut state, nickname, age, avatar, gender, language, city, country, hobby, bio, ctx);
            test_scenario::return_shared(state);
        };

        
        test_scenario::next_tx(scenario, user2_addr);
        {
            let u = test_scenario::take_from_sender<User>(scenario);
        
            _user2_id = option::some(object::id(&u));
            // user2_name = option::some(u.name);
            // user2_avatar = u.avatar;
            // user2_avatar_url = u.avatar_url;
            test_scenario::return_to_sender(scenario, u);
        };

        // block user
        test_scenario::next_tx(scenario, user_addr);
        {
            let state = test_scenario::take_shared<UserGlobalState>(scenario);
            let fs_table = test_scenario::take_from_sender<BlacklistTable>(scenario);
           
            let ctx = test_scenario::ctx(scenario);
            
            user::block_user(&mut state, &mut fs_table, user2_addr, ctx);
           
            test_scenario::return_to_sender(scenario, fs_table);
            test_scenario::return_shared(state);
        };

        // check block_user
        test_scenario::next_tx(scenario, user_addr);
        {
            let fs_table = test_scenario::take_from_sender<BlacklistTable>(scenario);
            let state = test_scenario::take_shared<UserGlobalState>(scenario);
            let ctx = test_scenario::ctx(scenario);
           
            assert!(user::is_blocked(&fs_table, user2_addr), 0);
            assert!(user::get_block_user_count(&fs_table) == 1, 0 );
            
            user::cancel_block_user(&mut state, &mut fs_table, user2_addr, ctx);
        
            test_scenario::return_shared(state);
            test_scenario::return_to_sender(scenario, fs_table);
        };

        test_scenario::next_tx(scenario, user_addr);
        {
            let fs_table = test_scenario::take_from_sender<BlacklistTable>(scenario);
            let state = test_scenario::take_shared<UserGlobalState>(scenario);
           
            assert!(!user::is_blocked(&fs_table, user2_addr), 0);
            assert!(user::get_block_user_count(&fs_table) == 0, 0 );
        
            test_scenario::return_shared(state);
            test_scenario::return_to_sender(scenario, fs_table);
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

        test_scenario::end(scenario_val);
    }

    public fun stringify(b: vector<u8>): String {
        string::utf8(b)
    }
}