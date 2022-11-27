
module love::romance {

    use sui::object::{Self, ID, UID};
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::transfer;
    use sui::vec_map;
    use sui::vec_set;

    struct Romance has key, store {
        id: UID,
        name: String,
        envelope: vector<u8>,
        envelope_url: Option<String>,
        initiator: address, // creator
        declaration: String,    // declaration of love
        mate: Option<address>,  // matched person
        msgbox_id: ID,
        is_share: bool,
        pair_time: Option<u64>,
    }

    struct Message has key, store {
        id: UID,
        msg: String,
        from: address,
        to: address,
        created_at: u64,
    }

    struct MessageBox has key {
        id: UID,
        belongs: vec_set::VecSet<address>,  // the messge box belongs the initiator and mate, only the two can put messge 
        messages: vec_map::VecMap<ID, Message>,
    }

    // Romance already paired
    const EAREADLY_PAIRED: u64 = 0;

    const ENOT_INITIATOR_OR_LUCKEY_DOG: u64 = 1;

    const ECANT_PAIR_SELF: u64 = 2;

    // Getters
    public fun name(romance: &Romance): String {
        romance.name
    }

    public fun initiator(romance: &Romance): address {
        romance.initiator
    }

    public fun declaration(romance: &Romance): String {
        romance.declaration
    }

    public fun mate(romance: &Romance): Option<address> {
        romance.mate
    }

    public fun envelope(romance: &Romance): vector<u8> {
        romance.envelope
    }

    public fun is_initiator(romance_ref: &Romance, sender: address): bool {
        initiator(romance_ref) == sender
    }

    public fun is_mate(romance_ref: &Romance, sender: address): bool {
        option::borrow(&mate(romance_ref)) == &sender
    }

    public fun is_share(romance_ref: &Romance): bool {
        romance_ref.is_share
    }

    // Create a new romance contract
    public entry fun create(name: vector<u8>, declaration: vector<u8>, envelope: vector<u8>, envelope_url: Option<vector<u8>>, ctx: &mut TxContext) {

        let initiator = tx_context::sender(ctx);

        let msg_box = MessageBox {
            id: object::new(ctx),
            belongs: vec_set::empty<address>(),
            messages: vec_map::empty<ID, Message>(),
        };
        let msgbox_id = object::id(&msg_box);

        let envelope_url = if (option::is_some<vector<u8>>(&envelope_url)) { option::some(string::utf8(option::extract(&mut envelope_url))) } else { option::none()};

        let romance = Romance {
            id: object::new(ctx),
            name: string::utf8(name),
            envelope,
            envelope_url,
            initiator: initiator,
            declaration: string::utf8(declaration),
            mate: option::none(),
            msgbox_id,
            is_share: false,
            pair_time: option::none(),
        };

        // transfer::transfer(romance, initiator);
        // transfer::transfer(msg_box, initiator);
        // Share a object must in create object transaction
        romance.is_share = true;
        transfer::share_object(romance);
        transfer::share_object(msg_box);
    }

    // the romance owner share this romance
    // public entry fun share(romance: Romance, msg_box: MessageBox) {
    //     romance.is_share = true;
    //     transfer::share_object(romance);
    //     transfer::share_object(msg_box);
    // }

    // another person pair the romance, if the romance doesn't already pair or not the owner
    public entry fun pair(romance: &mut Romance, ctx: &mut TxContext) {
        let mate = tx_context::sender(ctx);

        assert!(!is_initiator(romance, mate), ECANT_PAIR_SELF);
        assert!(option::is_none(&romance.mate), EAREADLY_PAIRED);

        let now = tx_context::epoch(ctx);
        option::fill(&mut romance.mate, mate);
        option::fill(&mut romance.pair_time, now);
    }

    /// send a message to another
    public entry fun send_message(romance_ref: &Romance, msg_box: &mut MessageBox, msg: vector<u8>, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        

        let to = get_romance_recipient(romance_ref, sender);

        let msg = Message {
            id: object::new(ctx),
            msg: string::utf8(msg),
            from: sender,
            to,
            created_at: tx_context::epoch(ctx)
        };

        let msg_id = object::id(&msg);
        vec_map::insert(&mut msg_box.messages, msg_id, msg);
    }

    /// Send redpack
    public entry fun send_redpack(romance_ref: &mut Romance, coin: Coin<SUI>, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        

        let is_initiator = is_initiator(romance_ref, sender);
        let is_mate = is_mate(romance_ref, sender);

        assert!(is_initiator|| is_mate, ENOT_INITIATOR_OR_LUCKEY_DOG);

        let to = get_romance_recipient(romance_ref, sender);

        transfer::transfer(coin, to);
    }

    fun get_romance_recipient(romance_ref: &Romance, sender: address): address {
        let is_initiator = is_initiator(romance_ref, sender);
        let is_mate = is_mate(romance_ref, sender);

        assert!(is_initiator|| is_mate, ENOT_INITIATOR_OR_LUCKEY_DOG);

        if (is_initiator) {
            *option::borrow(&romance_ref.mate)
        } else {
            initiator(romance_ref)
        }

    }
}

