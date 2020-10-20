import "./provableAPI.sol";

pragma solidity  0.5.12;

contract Coinflip is usingProvable{

  struct Player {
    uint betPlayerBalance;
    bool playerResult;
  }

  mapping(bytes32 => Player) private player_id;

  uint public balance;
  address internal owner;
  bool win_loose;

  uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1;
  uint256 public latestNumber;

  constructor() public payable {
    owner = msg.sender;
    balance = msg.value;
    update(0);
  }

  modifier costs(uint cost){
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
  event coindflipResult(bool);

  function coinflipSet() public payable costs(100000000000 wei){
    require(msg.value >= 100000000000 wei);
    require(msg.value <= balance);
    uint betBalance = msg.value;

    update(betBalance);

    emit coinFlipped("CoinflipSet() function successfuly executed");
  }

  function coinflipGet(bytes32 _queryId, uint256 _randomNumber) private {
    uint betBalance = player_id[_queryId].betPlayerBalance;
    uint toTransafer = 0;
    uint luck = _randomNumber;

    if(luck == 1){
      win_loose = true;
      toTransafer = betBalance *2;
      balance -= betBalance;
      msg.sender.transfer(toTransafer);
    }
    else{
        win_loose = false;
        toTransafer = 0;
        balance += betBalance;
    }
    emit coindflipResult(win_loose);
  }

  function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
    //require(msg.sender == provable_cbAddress());
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
    latestNumber = randomNumber;
    coinflipGet(_queryId, randomNumber);
    emit generatedRandomNumber(randomNumber);
  }

  function update(uint betBalance) payable public {
    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;
    //bytes32 queryId = testRandom();

    bytes32 queryId = provable_newRandomDSQuery(
      QUERY_EXECUTION_DELAY,
      NUM_RANDOM_BYTES_REQUESTED,
      GAS_FOR_CALLBACK
    );

    insertPlayer(queryId, betBalance);
    emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
  }


  /* function testRandom() public returns(bytes32){
    bytes32 newqueryId = bytes32(keccak256(abi.encodePacked(msg.sender)));
    __callback(newqueryId, "1", bytes("test"));
    return newqueryId;
  } */

  function insertPlayer(bytes32 _queryId, uint _betBalance) private {
    Player memory newPlayer;
    newPlayer.betPlayerBalance = _betBalance;
    player_id[_queryId] = newPlayer;
  }

  function withdrawAll() public onlyOwner returns(uint){
    uint toTransfer = balance;
    balance = 0;
    msg.sender.transfer(toTransfer);
    return toTransfer;
  }
}
