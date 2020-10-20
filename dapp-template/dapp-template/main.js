var web3 = new Web3(Web3.givenProvider);
var contractInstance;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
      contractInstance = new web3.eth.Contract(abi, "0xA304Fa6707aa067aE33ddAB2E3A4A301E7f08927", {from: accounts[0]});
      fetchBalance();
      console.log(contractInstance);
    })

    $("#bet_button").on("click", placeBet);
    $("#withdrawAll_button").on("click", withdrawAllFromContract);

});

function fetchBalance(){
  console.log(web3.eth.getBalance("0xA304Fa6707aa067aE33ddAB2E3A4A301E7f08927"));
  var contract_balance = web3.eth.getBalance("0xA304Fa6707aa067aE33ddAB2E3A4A301E7f08927");
  contractInstance.methods.balance().call().then(function(contract_balance){
    $("#balance_output").text((contract_balance/1000000000000000000)+ " Ether");
  })
}

function placeBet(){
  var bet = $("#bet_input").val();

  var result;
  var bet_to_ether = {
    value: web3.utils.toWei(bet, "ether")
  }

  contractInstance.methods.coinflipSet().send(bet_to_ether)
  .on("transactionHash", function(hash){
    console.log(hash);
  })
  .on("confirmation", function(confirmationNr){
    console.log(confirmationNr);
  })
  .on("receipt", function(receipt){
  console.log(receipt);
  })
  .then(function(res){
    console.log("Result is: " + (res.events.coinFlipped.returnValues.win_loose ? "Win" : "Lose"));
    //alert("The result is: " + (res.events.coinFlipped.returnValues.win_loose ? "Yes" : "No"));
    $("#win_output").text(res.events.coinFlipped.returnValues.win_loose ? "Yes" : "No");
    $("#bet_result").text((res.events.coinFlipped.returnValues.win_loose ?("You won "+ 2*bet) :("You lost "+ bet)) + " Ether" );

    fetchBalance();
  })
};

function withdrawAllFromContract(){
  contractInstance.methods.withdrawAll().send()
  .on("transactionHash", function(hash){
    console.log(hash);
  })
  .on("confirmation", function(confirmationNr){
    console.log(confirmationNr);
  })
  .on("receipt", function(receipt){
    fetchBalance();
    console.log(receipt);
    alert("Withdrawl complete");
  })
}
