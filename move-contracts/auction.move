address 0x2 {
    module auction {

        use DiemFramework::DiemAccount; 
        use Std::Signer; 
        use DiemFramework::DiemTimestamp;
        use DiemFramework::XUS::XUS;

        struct Auction_res has key{
            currState : vector<u8>
        }

        struct Auction<phantom CoinType> has key { 
            max_bid: u64, 
            bidder: address,
            start_at: u64 
        }

        public fun create (ownerAddr : &signer, auction_addr: &signer)  
        {
            move_to<Auction_res>(ownerAddr, Auction_res {
                currState: b"AB"
            });
            move_to<Auction<XUS>>(auction_addr, Auction<XUS> {
                max_bid: 0, 
                bidder: Signer::address_of(ownerAddr),
                start_at: DiemTimestamp::now_seconds()
            });
        }

        
        public fun bid (ownerAddr : &signer, //owner account for change contract state
                    bidder_addr: &signer, // bidder addr: new bidder
                    auction_owner_addr: address, //extract auction info suppose: a designated address holding the auction
                    bid: u64)  acquires Auction_res, Auction
        {

            let baseResource: &mut Auction_res= borrow_global_mut<Auction_res>(Signer::address_of(ownerAddr));

            assert(*&mut baseResource.currState == b"AB", 1001);
            

            
            //State change
            *&mut baseResource.currState = b"InTransition";

            //Actions
            let auction: &mut Auction<XUS> = borrow_global_mut<Auction<XUS>>(auction_owner_addr); 
            // let bid_amt = Diem::value(&bid); 
            let max_bid = auction.max_bid;  
            assert(bid > max_bid, 101); 
            assert(Signer::address_of(bidder_addr) != auction.bidder, 100); 
            let with_cap = DiemAccount::extract_withdraw_capability(bidder_addr);
            DiemAccount::pay_by_signers<XUS>(&with_cap, ownerAddr, max_bid, b""); 
            DiemAccount::restore_withdraw_capability(with_cap);

            if (max_bid > 0) {       
                let with_cap = DiemAccount::extract_withdraw_capability(ownerAddr);
                DiemAccount::pay_from<XUS>(&with_cap, auction.bidder, max_bid, b"", b""); 
                DiemAccount::restore_withdraw_capability(with_cap);
            };  
            *&mut auction.bidder = Signer::address_of(bidder_addr); 
            *&mut auction.max_bid = bid;
            //State change
            *&mut baseResource.currState = b"AB";
            
        }
        
        public fun finish (ownerAddr : address, auction_owner: address)  acquires Auction_res, Auction
        {

            let baseResource: &mut Auction_res= borrow_global_mut<Auction_res>(ownerAddr);

            assert(*&mut baseResource.currState == b"AB", 1001);
            //State change
            *&mut baseResource.currState = b"InTransition";

            //Actions
            let auction = borrow_global_mut<Auction<XUS>>(auction_owner); 
            assert(auction.start_at + 432000 == DiemTimestamp::now_seconds(), 102); 
            

            
            //State change
            *&mut baseResource.currState = b"F";
            
        }
        
        public fun start (ownerAddr : address, auction_addr: address)  acquires Auction_res
        {

            let baseResource: &mut Auction_res= borrow_global_mut<Auction_res>(ownerAddr);

            assert(*&mut baseResource.currState == b"C", 1001);
            
            assert(exists<Auction<XUS>>(auction_addr), 103);
            

            

            
            //State change
            *&mut baseResource.currState = b"AB";
            
        }
        
        public fun withdraw (ownerAddr : &signer, auction_owner_addr: address, bidder_addr: &signer)  acquires Auction_res, Auction
        {

            let baseResource: &mut Auction_res= borrow_global_mut<Auction_res>(Signer::address_of(ownerAddr));

            assert(*&mut baseResource.currState == b"F", 1001);
            

            
            //State change
            *&mut baseResource.currState = b"InTransition";
            //Actions
            let Auction<XUS> {     
            max_bid,     
            bidder,     
            start_at: _, } = move_from<Auction<XUS>>(auction_owner_addr);  
            assert(bidder == Signer::address_of(bidder_addr), 1001);
            let bid_amount = max_bid; 
            let with_cap = DiemAccount::extract_withdraw_capability(ownerAddr);
            DiemAccount::pay_by_signers<XUS>(&with_cap, bidder_addr, bid_amount, b""); 
            DiemAccount::restore_withdraw_capability(with_cap);
            
            //State change
            *&mut baseResource.currState == b"F";
            
        }
    }
}

