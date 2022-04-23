pragma solidity >=0.4.16 <0.7.0;

contract Paylock {
    
    enum State { Working , Completed , Done_1 , Delay , Done_2 , Forfeit }
    
    int disc;
    int clock;
    int first_ddl_passed_time;
    address timeAdd;
    State st;
    
    constructor(address trusted_user) public {
        st = State.Working;
        disc = 0;
        clock = 0;
        timeAdd = trusted_user;
    }
    
    function tick() public {
        require( msg.sender == timeAdd );
        clock = clock + 1;
    }
    
    function getSender() public view returns(address) {
        return msg.sender;
    }
    
    function getOwner() public view returns(address) {
        return timeAdd;
    }
    
    function getTick() public view returns(int) {
        return clock;
    }

    function signal() public {
        require( st == State.Working );
        st = State.Completed;
        disc = 10;
    }

    function collect_1_Y() public {
        require( st == State.Completed );
        require( clock < 4 );
        st = State.Done_1;
        disc = 10;
    }

    function collect_1_N() external {
        require( st == State.Completed );
        require( clock >= 4 );
        first_ddl_passed_time = clock;
        st = State.Delay;
        disc = 5;
    }

    function collect_2_Y() external {
        require( st == State.Delay );
        require( clock < first_ddl_passed_time+4);
        st = State.Done_2;
        disc = 5;
    }

    function collect_2_N() external {
        require( st == State.Delay );
        require( clock >= first_ddl_passed_time+4);
        st = State.Forfeit;
        disc = 0;
    }

}

contract Supplier {
    
    Paylock p;
    
    enum State { Working , Completed }
    
    State st;
    
    enum rent_status {Initial, Rent, Returned}
    
    rent_status rts;
    
    Rental rental;
    
    constructor(address pp, address rt) public {
        p = Paylock(pp);
        st = State.Working;
        rts = rent_status.Initial;
        
        rental = Rental(rt);
        
    }
    
    function getrtAddress() public view returns (address) {
        return address(rental);
    }
    
    function getrtBalance() public view returns (uint) {
        return address(rental).balance;
    }
    
    function gethisBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function aquire_resource() public {
        require( rts == rent_status.Initial );
        rental.rent_out_resource.value(1 wei)();
        rts = rent_status.Rent;
    }
    
    function return_resource() public {
        require( rts == rent_status.Rent );
        rental.retrieve_resource();
        rts = rent_status.Returned;
    }
    
    function finish() external {
        require (st == State.Working);
        require ( rts == rent_status.Returned );
        p.signal();
        st = State.Completed;
    }
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}

contract Rental {
    
    address payable resource_owner;
    bool resource_available;
    
    constructor(address payable pp) public {
        resource_available = true;
        resource_owner = pp;
    }
    
    function rent_out_resource() payable external {
        require(resource_available == true);
        //CHECK FOR PAYMENT HERE
        require(msg.value == 1 wei);
        resource_owner = msg.sender;
        resource_available = false;
    }

    function retrieve_resource() external {
        require(resource_available == false && msg.sender == resource_owner);
        
        msg.sender.call.value(1 wei)("");
        
        resource_available = true;
    }
    
    function getMemoryBalance() public view returns (uint){
        return(address(this).balance);
    }
    
    function getOwner() public view returns (address){
        return(resource_owner);
    }
    
}