pragma solidity ^0.5.2;

contract Kyc{

	enum KycStatus{ New, Approved } //enum for all states of UserKyc
	uint currentUserId;
	  event KycCreated(address indexed user, address indexed bank,string userId,uint currentUserId, string bankName,string userAddress,KycStatus status,uint datetime); //event to be triggered after invoice is created
//    event KycApproved(address indexed supplier, address indexed buyer, address indexed bank, uint ledgerinvoicenumber, InvoiceStatus status,uint datetime); //event to be triggered after invoice is approved by buyer
//    event InvoiceFinanced(address indexed supplier, address indexed buyer, address indexed bank, uint ledgerinvoicenumber, InvoiceStatus status,uint datetime); //event to be triggered after invoice is financed by the bank
//    event InvoiceSettled(address indexed supplier, address indexed buyer, address indexed bank, uint ledgerinvoicenumber, InvoiceStatus status,uint datetime); //event to be triggered after invoice is settled by buyer
	struct UserKyc{
	    
	    uint usersrno;
		string  userId;
		address user;
		address bank;
		string bankName;
		string doc;
		string userAddress;
		KycStatus status;
	}
	mapping(uint => UserKyc) public UserKycs; // a mapping which will have the currentUserId as the key and the curresponding structure of UserKyc as value
    mapping(address => mapping(string => bool)) userKycList ;
    mapping(string => uint) useridsrno;
	constructor() public{ // constructor to initialize the currentUserId to 1
		currentUserId = 1;
	}

	function createKyc(address bankaddress, string memory userId, string memory userAddress, string memory doc, string memory bankName) public {
		address user = msg.sender;
		address bank=bankaddress;
 
		if(userKycList[user][userId])
			revert(); //duplicate kyc check

		UserKycs[currentUserId] = UserKyc(currentUserId,userId, user, bank, bankName, doc, userAddress, KycStatus.New); //update the mapping for currentInvoiceId
        userKycList[user][userId]=true;
        useridsrno[userId]=currentUserId;
		emit KycCreated(user,bank,userId,currentUserId,bankName,userAddress,KycStatus.New,now); //call event for createinvoice
		++currentUserId;
	}
	function viewKyc(string memory userId) public view returns(bool result,string memory userid,address user,string memory bankName, string memory doc, string memory userAddress,KycStatus status) {
		uint usersrno = useridsrno[userId];
		UserKyc storage mykyc=UserKycs[usersrno];
		if(mykyc.usersrno!= 0)
			return(true,mykyc.userId,mykyc.user,mykyc.bankName,mykyc.doc,mykyc.userAddress,mykyc.status);
		else

			revert();

	}
    function approveKyc(string memory userId) public {
        address bank=msg.sender;
        uint usersrno = useridsrno[userId];
        UserKyc storage mykyc=UserKycs[usersrno];
 //       require(bytes(mykyc.userId)==bytes(userId)); //validate that the initiator is a buyer mentioned in invoice
        require(mykyc.bank==bank);
        require(mykyc.status==KycStatus.New);// validate the status of the invoice is New(created)
        UserKycs[usersrno].status=KycStatus.Approved; //update the state of invoice to approved
//        KycApproved(invoices[ledgerinvoicenumber].supplier,buyer,bank,ledgerinvoicenumber,invoices[ledgerinvoicenumber].status,now); // call event for approveinvoice
    }

}
