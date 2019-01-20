pragma solidity ^0.4.0;

contract SupplyChain{

	enum InvoiceStatus{ New, Approved, Financed, Settled, Rejected } //enum for all states of invoice
	uint currentInvoiceId;
	event InvoiceCreated(address indexed supplier, address indexed buyer,address indexed bank, int amount,uint currentInvoiceId, uint invoice_number,InvoiceStatus status,uint datetime); //event to be triggered after invoice is created
    event InvoiceApproved(address indexed supplier, address indexed buyer, address indexed bank, uint ledgerinvoicenumber, InvoiceStatus status,uint datetime); //event to be triggered after invoice is approved by buyer
    event InvoiceFinanced(address indexed supplier, address indexed buyer, address indexed bank, uint ledgerinvoicenumber, InvoiceStatus status,uint datetime); //event to be triggered after invoice is financed by the bank
    event InvoiceSettled(address indexed supplier, address indexed buyer, address indexed bank, uint ledgerinvoicenumber, InvoiceStatus status,uint datetime); //event to be triggered after invoice is settled by buyer
	struct Invoice{
		uint invoiceId;
		address supplier;
		address buyer;
		address bank;
		int amount;
		uint invoice_number;
		InvoiceStatus status;
	}
	mapping(uint => Invoice) public invoices; // a mapping which will have the currentInvoiceId as the key and the curresponding structure of Invoice as value
    mapping(address => mapping(uint => bool)) supplierInvoices ;
	function SupplyChain() public{ // constructor to initialize the currentInvoiceId to 1
		currentInvoiceId = 1;
	}

	function createInvoice(address buyer, int amount, uint invoice_number ) public {
		address supplier = msg.sender;
		address bank;

		if(amount < 0 || supplierInvoices[supplier][invoice_number])
			revert(); //Negative amount and duplicate invoice check

		invoices[currentInvoiceId] = Invoice(currentInvoiceId, supplier, buyer, bank, amount, invoice_number, InvoiceStatus.New); //update the mapping for currentInvoiceId
        supplierInvoices[supplier][invoice_number]=true;
		InvoiceCreated(supplier,buyer,bank,amount,currentInvoiceId,invoice_number,InvoiceStatus.New,now); //call event for createinvoice
		++currentInvoiceId;
	}
	function viewInvoice(uint ino) public view returns(bool result,uint invoiceId,address supplier,address buyer,address bank,int amount,uint invoice_number,InvoiceStatus status) {
		Invoice storage myinvoice=invoices[ino];
		if(myinvoice.invoiceId!=0)
			return(true,myinvoice.invoiceId,myinvoice.supplier,myinvoice.buyer,myinvoice.bank,myinvoice.amount,myinvoice.invoice_number,myinvoice.status);
		else

			revert();

	}
    function approveInvoice(address bank,uint ledgerinvoicenumber) public {
        address buyer=msg.sender;
        Invoice storage myinvoice=invoices[ledgerinvoicenumber];
        require(myinvoice.buyer==buyer); //validate that the initiator is a buyer mentioned in invoice
        require(myinvoice.status==InvoiceStatus.New);// validate the status of the invoice is New(created)
        invoices[ledgerinvoicenumber].bank=bank; //update the address of the bank selected by the buyer
        invoices[ledgerinvoicenumber].status=InvoiceStatus.Approved; //update the state of invoice to approved
        InvoiceApproved(invoices[ledgerinvoicenumber].supplier,buyer,bank,ledgerinvoicenumber,invoices[ledgerinvoicenumber].status,now); // call event for approveinvoice
    }
    function financeInvoice(bool flag,uint ledgerinvoicenumber) public {
        address bank=msg.sender;
        require(invoices[ledgerinvoicenumber].bank==bank);//validate that the initiator is a bank mentioned in invoice
        require(invoices[ledgerinvoicenumber].status==InvoiceStatus.Approved);// validate the status of the invoice is Approved
        if(flag==true){ //true flag represents successful validation against credit limit
            invoices[ledgerinvoicenumber].status=InvoiceStatus.Financed; // update the state of invoice to financed
            InvoiceFinanced(invoices[ledgerinvoicenumber].supplier,invoices[ledgerinvoicenumber].buyer,bank,ledgerinvoicenumber,invoices[ledgerinvoicenumber].status,now); //call event for financeinvoice
        }
        else { // If flag is false that means the credit limit check has failed
            invoices[ledgerinvoicenumber].status=InvoiceStatus.Rejected;//update the state of invoice to rejected
            InvoiceFinanced(invoices[ledgerinvoicenumber].supplier,invoices[ledgerinvoicenumber].buyer,bank,ledgerinvoicenumber,invoices[ledgerinvoicenumber].status,now); //call event for financeinvoice
        }
    }
    function settleInvoice(bool flag,uint ledgerinvoicenumber) public {
        address buyer=msg.sender;
        require(invoices[ledgerinvoicenumber].buyer==buyer); //validate that the initiator is a buyer mentioned in invoice
        require(invoices[ledgerinvoicenumber].status==InvoiceStatus.Financed); // validate the status of the invoice is Financed
        require(flag==true);//transaction of sending money to bank was successfull
        invoices[ledgerinvoicenumber].status=InvoiceStatus.Settled;// update the state of invoice to settled
        InvoiceSettled(invoices[ledgerinvoicenumber].supplier,buyer,invoices[ledgerinvoicenumber].bank,ledgerinvoicenumber,invoices[ledgerinvoicenumber].status,now); //call event for settleinvoice
    }
}