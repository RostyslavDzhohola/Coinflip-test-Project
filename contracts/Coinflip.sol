import "./provableAPI.sol";

pragma solidity  0.5.12;

contract Coinflip is usingProvable{

  struct Player {
    uint betPlayerBalance;
    uint bettingRes;
    bool isWating;
    address adrPlaying;
  }

  mapping(bytes32 => Player) private players_byID;
  mapping(address => bool) private isPlaying;


  uint public balance;
  address internal owner;
  bool public win_loose;
  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
  uint256 public latestNumber;

  constructor() public payable {
    owner = msg.sender;
    balance = msg.value;
    update(0, 0x03992365B313433960EaD13FC56A9E650b6a07bb);
  }

  modifier costs(uint256 cost){
      require(msg.value >= cost);
      _;
  }

  modifier onlyOwner(){
      require(msg.sender == owner);
      _;
  }

  event LogNewProvableQuery(string description);
  event generatedRandomNumber(uint256 randomNumber);

  event coinFlipped(string);
  event coindflipResult(bool result, uint balance);
  event PlayerInserted(bytes32 ID, uint bettingBalance, bool Active, address AddressPlaying, uint256 Result);
  //event testRandomExecuted(string, bytes32);
  //event returnedPlayer(uint balance, bool Active, address AddressPlaying);
  //event callbackReturned(uint balance, uint256 randomNumber, bool Active);
  //event PlayerAfterInserted(bytes32 ID, uint bettingBalance, uint256 Result, bool Active, address AddressPlaying);

  function coinflipSet() public payable costs(10000000000 wei){
    require(isPlaying[msg.sender] == false, "Current address is in paly");
    require(msg.value >= 100000000000 wei);
    require(msg.value <= balance);
    balance -= 4000000000000000;
    isPlaying[msg.sender] = true;
    uint256 betBalance = msg.value;
    emit coinFlipped("CoinflipSet() function successfuly executed");
    update(betBalance, msg.sender);
  }

  function update(uint _betBalance, address _addressPlayig) payable public {
    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;
    //bytes32 queryId = testRandom(); // Comment this line on the Ropsten network.

    if (provable_getPrice("https://ropsten.etherscan.io/chart/gasprice", GAS_FOR_CALLBACK) > address(this).balance) {
      emit LogNewProvableQuery("Provable query was NOT send, please add some ETH to cover the query fee");
    } else {
      emit LogNewProvableQuery("Provable query was sent, standing by for the answer..");
        bytes32 queryId = provable_newRandomDSQuery(
        QUERY_EXECUTION_DELAY,
        NUM_RANDOM_BYTES_REQUESTED,
        GAS_FOR_CALLBACK
      );


    emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
    insertPlayer(queryId, _betBalance, _addressPlayig);
    }
  }
  /* function testRandom() public returns(bytes32){
   bytes32 newqueryId = bytes32(keccak256(abi.encodePacked(msg.sender)));
   emit testRandomExecuted("The testRandom() function is successfuly executed ", newqueryId);
   __callback(newqueryId, "0", bytes("test"));
   return newqueryId;
  } */

  function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
    require(msg.sender == provable_cbAddress());
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
    latestNumber = randomNumber;
    emit generatedRandomNumber(randomNumber);
    updateResult(_queryId, randomNumber);
  }

  function updateResult(bytes32 id, uint256 randomNumber) private {
    players_byID[id].bettingRes = randomNumber;
    //emit callbackReturned(players_byID[id].betPlayerBalance, players_byID[id].bettingRes, players_byID[id].isWating);
    coinflipGet(id);
  }

  function insertPlayer(bytes32 _queryId, uint _betBalance, address _addressPlayig) private {
    players_byID[_queryId].betPlayerBalance = _betBalance;
    players_byID[_queryId].isWating = true;
    players_byID[_queryId].adrPlaying = _addressPlayig;
    emit PlayerInserted(_queryId, players_byID[_queryId].betPlayerBalance, players_byID[_queryId].isWating, players_byID[_queryId].adrPlaying, players_byID[_queryId].bettingRes);
    //testInsertedPlayer(_queryId);  //Comment out when deploying to Ropsten network
  }

  /* function testInsertedPlayer(bytes32 _id) public {
    Player memory dummyPlayer;
    dummyPlayer = players_byID[_id];
    emit PlayerAfterInserted(_id, dummyPlayer.betPlayerBalance, dummyPlayer.bettingRes, dummyPlayer.isWating, dummyPlayer.adrPlaying);
  } */

  function coinflipGet(bytes32 _queryId) public {

    Player memory oldPlayer;
    oldPlayer = players_byID[_queryId];

    isPlaying[oldPlayer.adrPlaying] = false;

    uint betBalance = oldPlayer.betPlayerBalance;
    uint toTransafer = 0;
    uint256 luck = oldPlayer.bettingRes;
    address payable returningPlayer = address(uint160(oldPlayer.adrPlaying));

    if(luck == 1){
      win_loose = true;
      toTransafer = betBalance *2;
      balance -= betBalance;
      returningPlayer.transfer(toTransafer);
    } else {
        win_loose = false;
        toTransafer = 0;
        balance += betBalance;
    }

  //  emit returnedPlayer(oldPlayer.betPlayerBalance, oldPlayer.isWating, oldPlayer.adrPlaying);
    emit coindflipResult(win_loose, betBalance);
  }

  function withdrawAll() public onlyOwner returns(uint){
    uint toTransfer = balance;
    balance = 0;
    msg.sender.transfer(toTransfer);
    return toTransfer;
  }
}
