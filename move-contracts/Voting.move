address 0x2{
    module Voting {
        use Std::Signer;
        use DiemFramework::DiemTimestamp;
        use Std::Vector;
        struct Voting_res has key{
            num_part : u64,
            num_vote : u64,
            create_time: u64,
            ops: vector<vector<u8>>,
            currState : vector<u8>,
            votes: vector<u64>
        }
        struct Participants has key{
            participate : bool
        }
    public fun create(ownerAddr: &signer) 
    {
        move_to<Voting_res>(ownerAddr, Voting_res{
            currState: b"Setup",
            num_part: 0,
            num_vote: 0,
            create_time:DiemTimestamp::now_microseconds(),
            ops:Vector::empty<vector<u8>>(),
            votes: Vector::empty<u64>()
        });

    }

//   //States definition
//   enum States {
//     InTransition,
//     Setup, 
//     Canceled, 
//     Casting, 
//     Closed  
//   }
//   States private state = States.Setup;
//   //Insert variable definitions

//   mapping(address => bool) private Participants;
//   uint private numParticipants; // total number of Participants
//   uint private numVoters; // number of Participants who have voted
//   string[] private options;
//   mapping(uint => uint) votes; // vote for each option (index of option in array)
// //Transitions 
public fun addOption (option: vector<u8>, ownerAddr: address)  acquires Voting_res
{
    let baseResource: &mut Voting_res = borrow_global_mut<Voting_res>(ownerAddr);
    //let opt: &mut Options = borrow_global_mut<Voting_res>(ownerAddr);
    assert(*&mut baseResource.currState == b"Setup", 100);
    *&mut baseResource.currState = b"InTransition";
    Vector::push_back(&mut baseResource.ops, option);
    Vector::push_back(&mut baseResource.votes, 0);
    //Actions
    *&mut baseResource.currState = b"Setup";
    //State change
}

public fun addParticipant (  participant:&signer , ownerAddr:address) acquires Participants,Voting_res
 
{
    let baseResource: &mut Voting_res = borrow_global_mut<Voting_res>(ownerAddr);
    assert(*&mut baseResource.currState == b"Setup", 100);
    let part: &mut Participants = borrow_global_mut<Participants>(Signer::address_of(participant));
    assert(*&mut part.participate == false, 101);
    *&mut baseResource.currState = b"InTransition";
    move_to<Participants>(participant, Participants{
        participate: true
    });
    //*&mut part.participate = true;
   //Guards
    *&mut baseResource.num_part = *&mut baseResource.num_part+1;   
    //State change
    *&mut baseResource.currState = b"Setup";
}

public fun cancel (ownerAddr: address) acquires Voting_res
 
{
    let baseResource: &mut Voting_res = borrow_global_mut<Voting_res>(ownerAddr);
    assert(*&mut baseResource.currState == b"Casting", 100);

   //Guards
    assert( *&mut  baseResource.num_vote < *&mut baseResource.num_vote /2, 100);     
    //State change
    *&mut baseResource.currState = b"InTransition";
    *&mut baseResource.currState = b"Canceled";
}

public fun cast ( option:u64 , ownerAddr:address, caster:address) acquires Voting_res,Participants
 
{
    let baseResource: &mut Voting_res = borrow_global_mut<Voting_res>(ownerAddr);
    assert(*&mut baseResource.currState == b"Casting", 100);
    let part: &mut Participants = borrow_global_mut<Participants>(caster);
   //Guards
    assert( *&mut part.participate== true && option < Vector::length(&mut baseResource.ops), 100);   
    //State change
    *&mut baseResource.currState = b"InTransition";
    //Actions
    *Vector::borrow_mut(&mut baseResource.votes, option) =*Vector::borrow_mut(&mut baseResource.votes, option)+1;
    *&mut part.participate = false;
    *&mut baseResource.num_vote =*&mut baseResource.num_vote+1;   
    //State change
    *&mut baseResource.currState = b"Casting";
}

public fun close (ownerAddr:address) acquires Voting_res
 
{
    let baseResource: &mut Voting_res = borrow_global_mut<Voting_res>(ownerAddr);
    assert(*&mut baseResource.currState == b"Casting", 100);
   //Guards
    assert( DiemTimestamp::now_microseconds() >= *&mut baseResource.create_time + 10000, 100 );     
    //State change
    *&mut baseResource.currState = b"Closed";
}

public fun open (ownerAddr:address) acquires Voting_res
 
{
    let baseResource: &mut Voting_res = borrow_global_mut<Voting_res>(ownerAddr);
    assert(*&mut baseResource.currState == b"Setup", 100);
   //Guards
    assert( DiemTimestamp::now_microseconds() <= *&mut baseResource.create_time + 100, 100);     
    //State change
    *&mut baseResource.currState = b"Casting";
}

public fun removeOption (option:u64, ownerAddr: address) acquires Voting_res
 
{
    let baseResource: &mut Voting_res = borrow_global_mut<Voting_res>(ownerAddr);
    assert(*&mut baseResource.currState == b"Setup", 100);
   //Guards
    assert(     option < Vector::length(&mut baseResource.ops),100);   
    //State change
    *&mut baseResource.currState == b"InTransition";
    //Actions
    let last = Vector::length(&mut baseResource.ops)-1;
    *Vector::borrow_mut(&mut baseResource.ops, option) =  *Vector::borrow_mut(&mut baseResource.ops, last);
    Vector::pop_back(&mut baseResource.ops ); 
    //State change
    *&mut baseResource.currState = b"Setup";
}

public fun removeParticipant (  participant:address, ownerAddr:address)acquires Voting_res,Participants
{
    let baseResource: &mut Voting_res = borrow_global_mut<Voting_res>(ownerAddr);
    assert(*&mut baseResource.currState == b"Setup", 100);
   //Guards
    let part: &mut Participants = borrow_global_mut<Participants>(participant);
    assert( *&mut part.participate,100);   
    //State change
    *&mut baseResource.currState = b"InTransition";
    //Actions
    part.participate= false;
    *&mut baseResource.num_part = *&mut baseResource.num_part-1;
    //State change
    *&mut baseResource.currState = b"Setup"; 
}


}
}
