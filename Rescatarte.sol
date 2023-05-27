// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Rescatarte is ERC721Enumerable, Ownable {
  using Strings for uint256; //se usa para el abiencode string en tokenuri

  string public baseURI; 
  uint256 public cost = 0.00001 ether;
  string public baseExtension = ".json";
  bool public paused = false;
  address public foundationwallet; 
  bool public payment = false;

  mapping(address => uint256) public addressMintedBalance;

  struct Walletpermitedstruct{
    string nombre;
    address wallet;
    }

  struct Walletpaymentstruct{
    uint amountfunding;
    uint amountpounds;
    uint amounteachpound;
    uint Nwalletspounds;
    }

  Walletpermitedstruct[] public walletspermited;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) 
    ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint() public payable {
    uint256 supply = totalSupply(); //funcion ya incluida
    require(!paused, "the contract is paused");

    if (payment && msg.sender != owner()) {
        require(msg.value >= cost, "insufficient funds");
    }

    addressMintedBalance[msg.sender]++;
    _safeMint(msg.sender, supply + 1);
  }
  
  //
  function walletOfOwner(address _owner) public view returns (uint256[] memory){
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function donate_tocontract()public payable returns(uint256){
    uint256 valuedonated = msg.value;
    return valuedonated;
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
    require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    string memory currentBaseURI = _baseURI();
    //[Operador ternario (condicion ? res : else) ]condicion lenght > 0 
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI,"/", tokenId.toString(), baseExtension))
        : "";
  }

  //-----------------------------------------------------------------------only owner
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function activatepayment(bool _state) public onlyOwner {
    payment = _state;
  }
  
  function setnew_Cost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  //wallets----------------------------------------------------------------------

  function set_fundationwallet(address _wallet) public onlyOwner {
    foundationwallet = _wallet;
  }
    
  function add_payablewallet(string memory _nombrex , address _walletaddress) public onlyOwner{
    walletspermited.push(Walletpermitedstruct({nombre:_nombrex, wallet:_walletaddress}));
  }

  function payday() public onlyOwner returns(Walletpaymentstruct memory){
        //gas tiende a crecer dependiendo el array de wallets
        uint tempbalance = address(this).balance;
        uint chunk_balance = (tempbalance)/10;
        uint payment_pounds = (chunk_balance*7)/walletspermited.length;
        require(payable(foundationwallet).send(chunk_balance*3));
        for(uint i = 0; i < walletspermited.length; i++) {
            require(payable(walletspermited[i].wallet).send(payment_pounds));
        }
        return Walletpaymentstruct({
          amountfunding:chunk_balance*3, 
          amountpounds:chunk_balance*7,
          amounteachpound:payment_pounds,
          Nwalletspounds: walletspermited.length});     
    }

  function get_payablewallets_byid(uint _id) public view onlyOwner returns(Walletpermitedstruct memory){
        return (walletspermited[_id]);   
    }

}