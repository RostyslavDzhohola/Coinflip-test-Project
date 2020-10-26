import "./provableAPI.sol";

pragma solidity  0.5.12;

contract Coinflip is usingProvable{

  struct Player {
    uint256 betPlayerBalance;
    uint256 bettingRes;
    bool isWating;
    address adrPlaying;
  }

  mapping(bytes32 => Player) private players_byID;
  //bytes32[] private playersArray;

  uint256 public balance;
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
  event coindflipResult(bool result, uint256 balance);
  event PlayerInserted(bytes32 ID, uint256 bettingBalance, bool Active, address AddressPlaying, uint256 Result);
  event testRandomExecuted(string, bytes32);
  event returnedPlayer(uint256 balance, bool Active, address AddressPlaying);
  event callbackReturned(uint256 balance, uint256 randomNumber, bool Active);
  event PlayerAfterInserted(bytes32 ID, uint256 bettingBalance, uint256 Result, bool Active, address AddressPlaying);

  function coinflipSet() public payable costs(100000000000 wei){
    require(msg.value >= 100000000000 wei);
    require(msg.value <= balance);
    uint256 betBalance = msg.value;
    emit coinFlipped("CoinflipSet() function successfuly executed");
    update(betBalance, msg.sender);
  }

  function update(uint256 _betBalance, address _addressPlayig) payable public {
    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;
    bytes32 queryId = testRandom();

    /* bytes32 queryId = provable_newRandomDSQuery(
      QUERY_EXECUTION_DELAY,
      NUM_RANDOM_BYTES_REQUESTED,
      GAS_FOR_CALLBACK
    ); */
    emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
    insertPlayer(queryId, _betBalance, _addressPlayig);
    //playersArray.push(queryId);
  }

  function testRandom() public returns(bytes32){
    bytes32 newqueryId = bytes32(keccak256(abi.encodePacked(msg.sender)));
    emit testRandomExecuted("The testRandom() function is successfuly executed ", newqueryId);
    __callback(newqueryId, "0", bytes("test"));
    return newqueryId;
  }

  function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
    //require(msg.sender == provable_cbAddress());
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
    latestNumber = randomNumber;
    emit generatedRandomNumber(randomNumber);
    updateResult(_queryId, randomNumber);
    //playersArray.push(_queryId);
  }

  function updateResult(bytes32 id, uint256 randomNumber) private {
    players_byID[id].bettingRes = randomNumber;
    emit callbackReturned(players_byID[id].betPlayerBalance, players_byID[id].bettingRes, players_byID[id].isWating);
  }

  function insertPlayer(bytes32 _queryId, uint256 _betBalance, address _addressPlayig) private {
    players_byID[_queryId].betPlayerBalance = _betBalance;
    players_byID[_queryId].isWating = true;
    players_byID[_queryId].adrPlaying = _addressPlayig;
    emit PlayerInserted(_queryId, players_byID[_queryId].betPlayerBalance, players_byID[_queryId].isWating, players_byID[_queryId].adrPlaying, players_byID[_queryId].bettingRes);
    testInsertedPlayer(_queryId);
  }

  function testInsertedPlayer(bytes32 _id) public {
    Player memory dummyPlayer;
    dummyPlayer = players_byID[_id];
    emit PlayerAfterInserted(_id, dummyPlayer.betPlayerBalance, dummyPlayer.bettingRes, dummyPlayer.isWating, dummyPlayer.adrPlaying);
  }

  function coinflipGet(bytes32 _queryId) public {
    Player memory oldPlayer;
    oldPlayer = players_byID[_queryId];

    uint256 betBalance = oldPlayer.betPlayerBalance;
    uint256 toTransafer = 0;
    uint256 luck = oldPlayer.bettingRes;
    address payable returningPlayer = address(uint160(oldPlayer.adrPlaying));

    if(luck == 1){
      win_loose = true;
      toTransafer = betBalance *2;
      balance -= betBalance;
      returningPlayer.transfer(toTransafer);
    }
    else{
        win_loose = false;
        toTransafer = 0;
        balance += betBalance;
    }
    emit returnedPlayer(oldPlayer.betPlayerBalance, oldPlayer.isWating, oldPlayer.adrPlaying);
    emit coindflipResult(win_loose, betBalance);
  }

  function withdrawAll() public onlyOwner returns(uint256){
    uint256 toTransfer = balance;
    balance = 0;
    msg.sender.transfer(toTransfer);
    return toTransfer;
  }
}
