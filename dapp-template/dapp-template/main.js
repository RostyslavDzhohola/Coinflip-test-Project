var web3 = new Web3(Web3.givenProvider);
var contractInstance;
var queryId;
var contract_addr = "0x262122972D4c5Df3b2190843a63E6106E327e404";
var contractBalance = web3.eth.getBalance(contract_addr);
var blockOnCreation = 9018914;
var resultChecked = false;
var complete;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
      contractInstance = new web3.eth.Contract(abi, contract_addr, {from: accounts[0]});
      fetchBalance();
      console.log(contractInstance);
    });

    $("#bet_button").on("click", placeBet);
    $("#withdrawAll_button").on("click", withdrawAllFromContract);
    $("#check_button").on("click", getResult);
});

function fetchBalance(){

  //var contract_balance = web3.eth.getBalance("contract_addr");
  contractInstance.methods.balance().call().then(function(contract_balance){
    $("#balance_output").text((contract_balance/1000000000000000000)+ " Ether");
    console.log(contract_balance);
  });
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
    $("#win_output").text("Processing...");
    $("#loader").show();
  })
  .on("confirmation", function(confirmationNr){
    console.log(confirmationNr);
    if (confirmationNr % 3 == 0 && confirmationNr <= 21 ) {fetchBalance();}

  })
  .on("receipt", function(receipt){
  console.log(receipt);
  })
  .then(function(res){
    console.log(res.events.coinFlipped.returnValues);
    queryId = res.events.PlayerInserted.returnValues.ID;

    console.log("Queary ID of the player is: " + queryId);
    if (res.events.PlayerInserted.returnValues.Active == true){
      alert("Your play has been accepted!");
    }
    console.log(web3.eth.getBalance(contract_addr));
    complete = true;
    fetchBalance();
  });
};

function getResult(){
  $("#loader2").show();
  $("#bet_result").text("processing...");
  contractInstance.methods.coinflipGet().send()
  .on("transactionHash", function(hash){
    console.log(hash);
  })
  .on("receipt", function(receipt){
    console.log(receipt);
  })
  .then(function(res){
    var luck = res.events.coindflipResult.returnValues.result;
    var money = res.events.coindflipResult.returnValues.Player_Bet;
    alert("The result is: " + (luck ? "You Won" : "You Lost"));
    $("#loader").hide();
    $("#loader2").hide();
    $("#win_output").text(luck ? "Yes" : "No");
    $("#bet_result").text((luck ?("You won "+ 2*money/1000000000000000000) :("You lost "+ money/1000000000000000000)) + " Ether" );
  });
  console.log("getResult() executed...");
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

function checkCallback(){
  var returnedId;
  contractInstance.events.generatedRandomNumber({
      fromBlock: blockOnCreation
  }, function(error, event){})
  .on('data', function(event){
    returnedId = event.returnValues.Player_ID;
    if (queryId == returnedId && complete == true){
      alert("Your result is ready");
      $("#bet_result").text("is ready for review.");
      complete = false;
    }
     // same results as the optional callback above
  })
  .on('changed', function(event){
      // remove event from local database
  })
  .on('error', console.error);


}


window.setInterval(function(){
  //var contract_balance = web3.eth.getBalance("contract_addr");
  contractInstance.methods.balance().call().then(function(contract_balance){
    $("#balance_output").text((contract_balance/1000000000000000000)+ " Ether");
    checkCallback();
  });
}, 5000);
