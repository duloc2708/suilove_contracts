
module love::romance {

    use sui::object::{Self, ID, UID};
    use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::event::emit;

    use sui::dynamic_object_field as dof;

    const Item_Type_Photo: vector<u8> = b"photo";
    const Item_Type_Text: vector<u8> = b"text";

    struct Romance has key, store {
        id: UID,
        name: String,
        envelope: vector<u8>,
        envelope_url: Option<String>,
        creator: address, // creator
        declaration: String,    // declaration of love
        mate: address,  // another person
        is_paired: bool,
        created_at: u64,
    }
    
    struct RomanceInfo has key, store {
        id: UID,
        romance_id: ID,
        name: String,
        declaration: String,
        creator: address,
    }

    struct RomanceRegistry has key, store  {
        id: UID
    }

    struct RomanceManagerCap has key, store {
        id: UID
    }

    struct RomanceItem<Item> has key, store {
        id: UID,
        item: Item,
        from: address,
        to: address,
        created_at: u64,
    }

    struct RomancePairRequestMsg has key, store {
        id: UID,
        romance_id: ID,
        name: String,
        declaration: String,
        creator: address,
        created_at: u64, 
    }

    struct Message has key, store {
        id: UID,
        content: vector<u8>,
        type: String,
        from: address,
        to: address,
        created_at: u64,
    }

    struct MessageItem has store, copy, drop {
        msg_id: ID,
        content: vector<u8>,
        type: String,
    }

    struct RedPackItem has store, copy, drop {
        redpack_id: ID,
        value: u64,
    }

    // ------------------- Events --------------------// 
    /// Event for the Romance platform created
    struct RegistryCreatedEvent has copy, drop { registry_id: ID }

    /// Event for the Romance created
    struct RomanceCreatedEvent has copy, drop { 
        romance_id: ID,
        name: String, 
        declaration: String,
        creator: address,
        created_at: u64,
    }

    /// Event for the Romance pair success
    struct RomancePairSuccessEvent has copy, drop {
        romance_id: ID,
        creator: address,
        mate: address,
    }

    // Romance already paired
    const EAREADLY_PAIRED: u64 = 0;

    const ENOT_ROMANCE_MEMBER: u64 = 1;

    const EONLY_MATE_CAN_PAIR: u64 = 2;

    // Getters
    public fun name(romance: &Romance): String {
        romance.name
    }

    public fun creator(romance: &Romance): address {
        romance.creator
    }

    public fun declaration(romance: &Romance): String {
        romance.declaration
    }

    public fun mate(romance: &Romance): address {
        romance.mate
    }

    public fun envelope(romance: &Romance): vector<u8> {
        romance.envelope
    }

    public fun is_creator(romance_ref: &Romance, addr: address): bool {
        creator(romance_ref) == addr
    }

    public fun is_mate(romance_ref: &Romance, addr: address): bool {
        mate(romance_ref) == addr
    }

    public fun is_paired(romance_ref: &Romance): bool {
        romance_ref.is_paired
    }

    /// init function for module
    /// Create a shared Registry and give its creator the capability to manage the platform
    fun init(ctx: &mut TxContext) {
        // let id = object::new(ctx);
        
        // emit(RegistryCreatedEvent { registry_id: object::uid_to_inner(&id)});
        
        
        // transfer::share_object(RomanceRegistry {
        //     id,
        // });
        new_cap(ctx);
        new_registry(ctx);

    }

    fun new_cap(ctx: &mut TxContext) {
        transfer::transfer(RomanceManagerCap { id: object::new(ctx) }, tx_context::sender(ctx));
    }

    fun new_registry(ctx: &mut TxContext) {
        let id = object::new(ctx);
        
        emit(RegistryCreatedEvent { registry_id: object::uid_to_inner(&id)});
        
        
        transfer::share_object(RomanceRegistry {
            id,
        });
    }

    // Create a new romance contract
    public entry fun create_romance(
        reg: &mut RomanceRegistry, 
        name: vector<u8>, 
        declaration: vector<u8>, 
        envelope: vector<u8>, 
        envelope_url: Option<vector<u8>>, 
        mate: address,
        ctx: &mut TxContext) {

        let creator = tx_context::sender(ctx);

        let envelope_url = if (option::is_some<vector<u8>>(&envelope_url)) { 
            option::some(string::utf8(option::extract(&mut envelope_url))) 
        } else { option::none()};

        let romance_id = object::new(ctx);
        let romance_inner_id = object::uid_to_inner(&romance_id);

        let name = string::utf8(name);
        let declaration = string::utf8(declaration);
        let created_at = tx_context::epoch(ctx);

        let romance = Romance {
            id: romance_id,
            name,
            envelope,
            envelope_url,
            creator,
            declaration,
            mate,
            is_paired: false,
            created_at,
        };

        emit(RomanceCreatedEvent {
            romance_id: romance_inner_id,
            name, 
            declaration,
            creator,
            created_at, 
        });

        // notify the mate to pair
        transfer::transfer(RomancePairRequestMsg {
            id: object::new(ctx),
            romance_id: romance_inner_id,
            name,
            declaration,
            creator,
            created_at, 
        }, mate);

        let romance_id = RomanceInfo { 
            id: object::new(ctx), 
            romance_id: romance_inner_id,
            name,
            declaration,
            creator,
        };

        dof::add(&mut reg.id, romance_inner_id, romance_id);

        transfer::share_object(romance);
    }

    // another person pair the romance, if the romance doesn't already pair or not the owner
    public entry fun pair(romance: &mut Romance, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        
        // assert!(!is_mate(romance, sender), EONLY_MATE_CAN_PAIR);
        if (is_mate(romance, sender)) {
            romance.is_paired = true;

            emit(RomancePairSuccessEvent {
                romance_id: object::id(romance),
                creator: romance.creator,
                mate: sender,
            });
        }        
    }

    /// send a message to another
    public entry fun send_message(romance_ref: &mut Romance, content: vector<u8>, type: vector<u8>, is_record: bool, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        

        let to = get_romance_recipient(romance_ref, sender);
        let type = format_item_type(type);
        let created_at = tx_context::epoch(ctx);
        let msg = Message {
            id: object::new(ctx),
            content,
            type,
            from: sender,
            to,
            created_at,
        };

        if (is_record) {
            let msg_id = object::id(&msg);
            let item = MessageItem {
                msg_id,
                content,
                type,
            };

            dof::add(&mut romance_ref.id, msg_id, RomanceItem {
                id: object::new(ctx),
                item,
                from: sender,
                to,
                created_at
            });
        };

        transfer::transfer(msg, to);
    }

    /// Send redpack
    public entry fun send_redpack(romance_ref: &mut Romance, redpack: Coin<SUI>, is_record: bool, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        

        let is_creator = is_creator(romance_ref, sender);
        let is_mate = is_mate(romance_ref, sender);

        assert!(is_creator|| is_mate, ENOT_ROMANCE_MEMBER);

        let to = get_romance_recipient(romance_ref, sender);
        let redpack_value = coin::value(&redpack);
        let created_at = tx_context::epoch(ctx);

        if (is_record) {
            let redpack_id = object::id(&redpack);
            let item = RedPackItem {
                redpack_id,
                value: redpack_value,
            };

            dof::add(&mut romance_ref.id, redpack_id, RomanceItem {
                id: object::new(ctx),
                item,
                from: sender,
                to,
                created_at,
            });
        };

        transfer::transfer(redpack, to);
    }

    fun get_romance_recipient(romance_ref: &Romance, sender: address): address {
        let is_creator = is_creator(romance_ref, sender);
        let is_mate = is_mate(romance_ref, sender);

        assert!(is_creator|| is_mate, ENOT_ROMANCE_MEMBER);

        if (is_creator) {
            mate(romance_ref)
        } else {
            creator(romance_ref)
        }

    }

    fun format_item_type(type: vector<u8>): String {
        let type = if (&type == &Item_Type_Photo) {
            type
        } else {
            Item_Type_Text
        };

        string::utf8(type)
    }

    #[test_only] 
    public fun test_init(ctx: &mut TxContext) {
        new_cap(ctx);
        new_registry(ctx)
    }

}

