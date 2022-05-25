address 0x2{

 module BlindAuction {
    use DiemFramework::DiemAccount; 
    use Std::Signer; 
    use DiemFramework::DiemTimestamp;
    use DiemFramework::XUS::XUS;
//   u64 private creationTime = now;
//   //States definition
//   enum States {
//     ABB, 
//     C, 
//     F, 
//     RB 
//  }
  struct Auction_res has key{
      state: vector<u8>,
      highestBidder: address,
      creationTime:u64, 
      highestBid: u64
  }
  States private state = States.ABB;
  //Insert variable definitions
  struct Bid has key{ 
    blindedBid: vector<u8>;        
    deposit:u64;    
  }  
  fun create(ownerAddr: &signer){
      move_to<Auction_res>(ownerAddr, Auction_res{
          currstate:b"ABB",
          highestBidder:Signer::address_of(ownerAddr),
          creationTime: DiemTimestamp::now_microseconds(),
          highestBid: 0
      });
  }
//   mapping(address => Bid[]) private bids;  
//   mapping(address => u64)  private pendingReturns;  
//   address private highestBidder;  
//   u64 private highestBid;
//Transitions 

fun bid (blindedBid:vector<u8>, ownerAddr: address, bidder: &Signer, bid_amount:u64) acquires Auction_res
 payable  
{
    let state = borrow_global_mut<Auction_res>(ownerAddr);
    assert(*&mut state.currstate == b"ABB",100);

    //Actions
    let with_cap = DiemAccount::extract_withdraw_capability(bidder);
        DiemAccount::pay_from<XUS>(&with_cap, ownerAddr, bid_amount, b"", b""); 
        DiemAccount::restore_withdraw_capability(with_cap);
    move_to<Bid>(Signer::address_of(bidder), Bid{
        blindedBid: blindedBid, 
        deposit: bid_amount
    });

//        bids[msg.sender].push(Bid({
//        blindedBid: blindedBid,
//        deposit: msg.value
//    }));
//    pendingReturns[msg.sender] += msg.value;   
}

fun cancelABB (ownerAddr: address)  acquires Auction_res
 
{
    let state = borrow_global_mut<Auction_res>(ownerAddr);
    assert(*&mut state.currstate == b"ABB",100);
      
    //State change
    *&mut state.currstate = b"C";
}

fun cancelRB (ownerAddr: address)  acquires Auction_res  
 
{
    let state = borrow_global_mut<Auction_res>(ownerAddr);
    assert(*&mut state.currstate == b"RB",100);
      
    //State change
    *&mut state.currstate = b"C";
}

fun close  (ownerAddr: address)  acquires Auction_res  
 
{
    let state = borrow_global_mut<Auction_res>(ownerAddr);
    assert(*&mut state.currstate == b"ABB",100);
    assert(DiemTimestamp::now_microseconds() > *&mut state.creationTime + 5*24*60*60, 100);  
    //State change
    *&mut state.currstate = b"RB";

}

fun finish (ownerAddr: address)  acquires Auction_res     
{
    let state = borrow_global_mut<Auction_res>(ownerAddr);
    assert(*&mut state.currstate == b"RB",100);
    assert(DiemTimestamp::now_microseconds() > *&mut state.creationTime + 10*24*60*60, 100);  
    //State change
    *&mut state.currstate = b"F";
}

fun reveal (  vector<u64> values,  vector<u8>secrets,ownerAddr: address, bidder:&Signer)  acquires Auction_res, Bid    
 
{
    let state = borrow_global_mut<Auction_res>(ownerAddr);
    assert(*&mut state.currstate == b"RB",100);
    
    //State change
    *&mut state.currstate = b"RB";
   //Guards
   let l1 = Vector::length(&values); 
   let l2 = Vector::length(&secrets);
    assert(l1 == l2);   
    //Actions
    for (u64 i = 0; i < (bids[msg.sender].length < values.length ? 
    bids[msg.sender].length : values.length); i++) {
        var bid = bids[msg.sender][i];
        var (value, secret) = (values[i], secrets[i]);
        if (bid.blindedBid != keccak256(value, secret)) {
            // Do not add to refund value.
            continue;
        }
        if (bid.deposit >= value && value > highestBid) {
                highestBid = value;
                highestBidder = msg.sender;
        }
    }   
}

fun unbid ()   
 
{
    assert(state == States.C);
    
    //Actions
        u64 amount;
    amount = pendingReturns[msg.sender];
        if (amount > 0) {
            msg.sender.transfer(amount);
            pendingReturns[msg.sender] = 0;
        }       
}

fun withdraw ()   
 
{
    assert(state == States.F);
    
    //Actions
      u64 amount;
   amount = pendingReturns[msg.sender];
    if (amount > 0 && msg.sender!= highestBidder) {
      msg.sender.transfer(amount);
      pendingReturns[msg.sender] = 0;
    } else {
      msg.sender.transfer(amount - highestBid);
      pendingReturns[msg.sender] = 0;
    }       
}


}
}