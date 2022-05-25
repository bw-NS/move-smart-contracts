address 0x2{
    module RockPaperScissors {
        use DiemFramework::DiemAccount; 
        use Std::Signer; 
        use Std::Vector;
        use DiemFramework::DiemTimestamp;
        use DiemFramework::XUS::XUS;
        use Std::Hash;
    //States definition
    // enum States {
    //     InTransition,
    //     Play, 
    //     Canceled, 
    //     Finished, 
    //     Reveal  
    // }
    // States private state = States.Play;
    //Insert variable definitions

    struct Players has key{
        choiceHash: vector<u8>,
        addr:address,
        revealed:bool ,
        choice:u64
    }
    struct RPS_res has key{
        num_player : u64,
        time_create: u64,
        players : vector<address>,
        currState : vector<u8>
    }
    // player[] private players;
    //Transitions 
    fun create(ownerAddr:&signer){
        move_to<RPS_res>(ownerAddr, RPS_res{
            currState: b"Play",
            num_player:0,
            time_create: DiemTimestamp::now_microseconds(), 
            players: Vector::empty<address>()
        });
    }

    fun cancelPlay (ownerAddr:address) acquires RPS_res  
    
    {   
        let baseResource: &mut RPS_res= borrow_global_mut<RPS_res>(ownerAddr);
        assert(*&mut baseResource.currState == b"Play", 100);
    //Guards
        assert( *&mut baseResource.num_player == 1, 100);     
        //State change
        *&mut baseResource.currState = b"Canceled"; 
    }

    fun cancelReveal (ownerAddr:address) acquires RPS_res, Players
    
    {
        let baseResource: &mut RPS_res= borrow_global_mut<RPS_res>(ownerAddr);
        assert(*&mut baseResource.currState == b"Reveal", 100);
        *&mut baseResource.currState = b"InTransition"; 
    //Guards
        let p = &mut baseResource.players;
        let p1 = Vector::borrow(p,0);
        let p2 = Vector::borrow(p,1);
        let r1 = &borrow_global<Players>(*p1).revealed;
        let player2  = borrow_global<Players>(*p2);
        assert(*r1 != player2.revealed && DiemTimestamp::now_microseconds() >= *&baseResource.time_create + 20000,100 );     
        //State change
        *&mut baseResource.currState = b"Canceled"; 
    }

    public fun choose (choiceHash: vector<u8>, player:&signer,  ownerAddr:address)  acquires RPS_res
 
    {
        let state: &mut RPS_res= borrow_global_mut<RPS_res>(ownerAddr);
        assert(*&mut state.currState == b"Play", 100);
    //Guards
        
        assert(DiemTimestamp::now_microseconds() <= *&mut state.time_create+20000,100 );   
        //State change
        let with_cap = DiemAccount::extract_withdraw_capability(player);
        DiemAccount::pay_from<XUS>(&with_cap, ownerAddr, 1, b"choosing", b"sign");
        DiemAccount::restore_withdraw_capability(with_cap);
        *&mut state.currState = b"InTransition";
        //Actions
        Vector::push_back(&mut state.players, Signer::address_of(player));
        *&mut state.num_player = *&mut state.num_player +1;
        move_to<Players>(player, Players{
            choiceHash: choiceHash,
            addr: Signer::address_of(player),
            revealed: false,
            choice: 0
        });

        //State change
        *&mut state.currState = b"Play";
    }

    fun close (ownerAddr: address)  acquires RPS_res
    
    {
        let state: &mut RPS_res= borrow_global_mut<RPS_res>(ownerAddr);
        assert(*&mut state.currState == b"Play", 100);
    //Guards
        assert(*&mut state.num_player == 2, 100);     
        //State change
        *&mut state.currState = b"Reveal"; 
    }

    fun finish (ownerAddr: address)  acquires RPS_res, Players
    
    {
        let state: &mut RPS_res= borrow_global_mut<RPS_res>(ownerAddr);
        assert(*&mut state.currState == b"Reveal", 100);
    //Guards
        let p1 = Vector::borrow(&mut state.players, 0);
        let p2 = Vector::borrow(&mut state.players, 1);
        let player1= borrow_global<Players>(*p1);
        let player2= borrow_global<Players>(*p2);
        assert(*&player1.revealed && *&player2.revealed,100);     
        //State change
        *&mut state.currState = b"Finished";  
    }

    fun reveal ( playerID: u64 ,  choice: u64 , random:vector<u8>, player:&signer, ownerAddr: address ) acquires RPS_res, Players 
    {
        let state: &mut RPS_res= borrow_global_mut<RPS_res>(ownerAddr);
        assert(*&mut state.currState == b"Reveal", 100);
    //Guards
        let players = &mut state.players;
        let p = Vector::borrow(players, playerID);
        let p_info: &mut Players= borrow_global_mut<Players>(*p);
        assert(*&p_info.addr == Signer::address_of(player) && *&p_info.choiceHash == Hash::sha2_256(random),100);   
        //State change
        *&mut state.currState == b"InTransition";
        //Actions
        p_info.choice = choice;
        p_info.revealed = true;     
        //State change
        *&mut state.currState == b"Reveal";
    }

    fun withdrawCanceled (  playerID: u64, player:&signer, ownerAddr:&signer )  acquires RPS_res, Players
    {
        let state: &mut RPS_res= borrow_global_mut<RPS_res>(Signer::address_of(ownerAddr));
        assert(*&mut state.currState == b"Canceled", 100);
    //Guards
        let players = &mut state.players;
        let p = Vector::borrow(players, playerID);
        let p_info: &mut Players= borrow_global_mut<Players>(*p);
        assert( *&p_info.addr == Signer::address_of(player) && (*&state.num_player == 1) || (*&p_info.revealed),100);   
        //State change
        *&mut state.currState == b"InTransition";
        //Actions
        p_info.addr = Signer::address_of(ownerAddr); 
        let send_amount = if(*&state.num_player==1)1 else 2;
        
        let with_cap = DiemAccount::extract_withdraw_capability(ownerAddr);
        DiemAccount::pay_by_signers<XUS>(&with_cap, player, send_amount, b""); 
        DiemAccount::restore_withdraw_capability(with_cap);
    
        

        //State change
        *&mut state.currState == b"Canceled";
    }

    fun withdrawFinished ( playerID: u64, player: &signer, ownerAddr: &signer )  acquires RPS_res, Players
    {
        let state: &mut RPS_res= borrow_global_mut<RPS_res>(Signer::address_of(ownerAddr));
        assert(*&mut state.currState == b"Finished", 100);
    //Guards
        let players = &state.players;
        let p = Vector::borrow(players, playerID);
        let p0 = Vector::borrow(players, 0);
        let p1 = Vector::borrow(players, 1);
        let p_info = borrow_global<Players>(*p);
        let p0_info= borrow_global<Players>(*p0);
        let p1_info = borrow_global<Players>(*p1);
        assert( *&p_info.addr == Signer::address_of(player) && ((*&p0_info.choice + *&p1_info.choice) % 2) == playerID,100);   
        //State change
        *&mut state.currState == b"InTransition";
        //Actions
        let p_inf = borrow_global_mut<Players>(*p);
        *&mut p_inf.addr = Signer::address_of(ownerAddr);
        let with_cap = DiemAccount::extract_withdraw_capability(ownerAddr);
        DiemAccount::pay_by_signers<XUS>(&with_cap, player, 1, b""); 
        DiemAccount::restore_withdraw_capability(with_cap);      
        //State change
        *&mut state.currState == b"Finished";
    }
    }
}