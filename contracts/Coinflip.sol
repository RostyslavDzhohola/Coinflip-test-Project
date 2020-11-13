import "./provableAPI.sol";

pragma solidity  0.5.12;

contract Coinflip is usingProvable{

  struct Player {
    uint betPlayerBalance;
    uint bettingRes;
    bool isWating;
    bool resultReturned;
    address adrPlaying;
  }
  
  mapping(bytes32 => Player) private players_byID;
  mapping(address => bytes32) private bytesId_addr; // change pointer from bool to bytes32
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
  event generatedRandomNumber(uint256 randomNumber, bytes32 Player_ID);

  event coinFlipped(string);
  event coindflipResult(bool result, uint Player_Bet, bool Callback_Returned);
  event PlayerInserted(bytes32 ID, uint bettingBalance, bool Active, address AddressPlaying, uint256 Result);

  function coinflipSet() public payable costs(10000000000 wei){
    require(isPlaying[msg.sender] == false, "Current address is in paly");
    require(msg.value >= 100000000000 wei);
    require(msg.value <= balance);
    isPlaying[msg.sender] = true;
    balance -= 4000000000000000;  // Payment for generating rundom number

    uint256 betBalance = msg.value;
    balance += betBalance;
    emit coinFlipped("CoinflipSet() function successfuly executed");
    update(betBalance, msg.sender);
  }

  function update(uint _betBalance, address _addressPlayig) payable public {
    uint256 QUERY_EXECUTION_DELAY = 0;
    uint256 GAS_FOR_CALLBACK = 200000;
 

    if (provable_getPrice("https://ropsten.etherscan.io/chart/gasprice", GAS_FOR_CALLBACK) > address(this).balance) {
      emit LogNewProvableQuery("Provable query was NOT send, please add some ETH to cover the query fee");
    } else {
      emit LogNewProvableQuery("Provable query was sent, standing by for the answer..");
        bytes32 queryId = provable_newRandomDSQuery(
        QUERY_EXECUTION_DELAY,
        NUM_RANDOM_BYTES_REQUESTED,
        GAS_FOR_CALLBACK
      );
    bytesId_addr[msg.sender] = queryId;
    emit LogNewProvableQuery("Provable query was sent, standing by for the answer...");
    insertPlayer(queryId, _betBalance, _addressPlayig);
    }
  }

  function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
    require(msg.sender == provable_cbAddress());
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 2;
    latestNumber = randomNumber;
    emit generatedRandomNumber(randomNumber, _queryId);
    updateResult(_queryId, randomNumber);
  }

  function updateResult(bytes32 id, uint256 randomNumber) private {
    players_byID[id].bettingRes = randomNumber;
    players_byID[id].resultReturned = true;
    //emit callbackReturned(players_byID[id].betPlayerBalance, players_byID[id].bettingRes, players_byID[id].isWating);
  }

  function insertPlayer(bytes32 _queryId, uint _betBalance, address _addressPlayig) private {
    players_byID[_queryId].betPlayerBalance = _betBalance;
    players_byID[_queryId].isWating = true;
    players_byID[_queryId].adrPlaying = _addressPlayig;
    emit PlayerInserted(_queryId, players_byID[_queryId].betPlayerBalance, players_byID[_queryId].isWating, players_byID[_queryId].adrPlaying, players_byID[_queryId].bettingRes);
  }


  function coinflipGet() public returns(bool){
    require(isPlaying[msg.sender] = true, "Player is not in play");
    require(players_byID[bytesId_addr[msg.sender]].resultReturned == true, "Random number have not been returend.");
    isPlaying[msg.sender] = false;
    bytes32 qId = bytesId_addr[msg.sender];
    Player memory oldPlayer;
    oldPlayer = players_byID[qId];

    uint betBalance = oldPlayer.betPlayerBalance;
    uint toTransafer = 0;
    uint256 luck = oldPlayer.bettingRes;
    address payable returningPlayer = address(uint160(oldPlayer.adrPlaying));

    if(luck == 1){
      win_loose = true;
      toTransafer = betBalance *2;
      balance -= toTransafer;
      returningPlayer.transfer(toTransafer);
    } else {
        win_loose = false;
        toTransafer = 0;
    }
  //  emit returnedPlayer(oldPlayer.betPlayerBalance, oldPlayer.isWating, oldPlayer.adrPlaying);
    emit coindflipResult(win_loose, betBalance, true);
    delete(players_byID[qId]);
    delete(bytesId_addr[msg.sender]);
    return win_loose ;
  }

  function withdrawAll() public onlyOwner returns(uint){
    uint toTransfer = balance;
    balance = 0;
    msg.sender.transfer(toTransfer);
    return toTransfer;
  }
}
