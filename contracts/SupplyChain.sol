// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  address public owner = msg.sender;
  
  uint public skuCount;
  
  enum State{ ForSale, Sold, Shipped, Received }

  mapping(uint => Item) public items;

  struct Item { 
     string name;
     uint price;
     uint sku;
     State state;
     address payable seller;
     address payable buyer;
  }
  
  /* 
   * Events
   */

   event LogForSale(uint sku);
   event LogSold(uint sku);
   event LogShipped(uint sku);
   event LogReceived(uint sku);

  /* 
   * Modifiers
   */
  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier forSale(uint _sku) {
    require(items[_sku].price > 0); 
    require(items[_sku].state == State.ForSale); 
    _;
  }

  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold); 
    _;
  }

  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped); 
    _;
  }

  modifier received(uint _sku) {
    require(items[_sku].state == State.Received); 
    _;
  }

  constructor() public {}

  function addItem(string memory _name, uint _price) public returns (bool) {
    items[skuCount] = Item({
      name: _name, 
      sku: skuCount, 
      price: _price, 
      state: State.ForSale, 
      seller: msg.sender, 
      buyer: address(0)
    });
    skuCount = skuCount + 1;
    emit LogForSale(skuCount);
    return true;
  }

  function buyItem(uint sku) payable public paidEnough(items[sku].price) forSale(sku) checkValue(sku) {
    items[sku].seller.transfer(items[sku].price);
    items[sku].buyer = msg.sender;
    items[sku].state = State.Sold;
    emit LogSold(skuCount);
  }

  function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller) {
    items[sku].state = State.Shipped;
    emit LogShipped(skuCount);
  }

  function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer) {
    items[sku].state = State.Received;
    emit LogReceived(skuCount);
  }

  function fetchItem(uint _sku) public view
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) 
  { 
    name = items[_sku].name; 
    sku = items[_sku].sku; 
    price = items[_sku].price; 
    state = uint(items[_sku].state); 
    seller = items[_sku].seller; 
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  } 
}
