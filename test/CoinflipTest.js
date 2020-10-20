const Coinflip = artifacts.require("Coinflip");
const truffleAssert = require("truffle-assert");
const Web3 = require("web3");

contract("Coinflip", async function(accounts){

  let instance;

  before(async function(){
    instance = await Coinflip.deployed();
  });

  let smallBet = web3.utils.toWei("0.1", "ether");
  let bigBet = web3.utils.toWei("10", "ether");

  it("should increase or decrease the Coinflip value by the betting amount", async function(){

    console.log("The balance before is: " + await instance.balance());

    await instance.coinflip({from: accounts[1], value: smallBet});

    let balance = await instance.balance();
    let floatBalance = parseFloat(balance);
    let realBalance = await web3.eth.getBalance(instance.address);

    console.log("Did you win? " + (((await instance.win_loose() == 1)? true : false   )? "Yes" : "No"));
    console.log("The balance after is: " + await instance.balance());

    if(await instance.win_loose() == true){
      assert(floatBalance == web3.utils.toWei("9.6", "ether") && floatBalance == realBalance, "Amount didn't decrease ");
    } else {
      assert(floatBalance == web3.utils.toWei("10.4", "ether") && floatBalance == realBalance, "Amount didn't increase");
    }

    console.log("The balance after is: " + await instance.balance());
    console.log("Did you win? " + (((await instance.win_loose() == 1)? true : false   )? "Yes" : "No" + "\n"));

  });
  it("should pass the coinflip function", async function(){
    console.log("The balance() before is: " + await instance.balance());
    await truffleAssert.passes(instance.coinflip({from: accounts[1], value: smallBet}));
    console.log("The balance() after is: " + await instance.balance());
    console.log("Did you win? " + (((await instance.win_loose() == 1)? true : false   )? "Yes" : "No" + "\n"));
  });
  it("should fail to pass with bet which is lower than the contract balance", async function(){
    await truffleAssert.fails(instance.coinflip({from: accounts[1], value: web3.utils.toWei("0", "ether")})
      , truffleAssert.ErrorType.REVERT);
    console.log("The balance() is: " + await instance.balance());
  });
  it("should fail to prcess coinflip() with bet bigger than the account balance", async function(){
    await truffleAssert.fails(instance.coinflip({from: accounts[1], value: bigBet})
    , truffleAssert.ErrorType.REVERT);
  });
  it("shlould allow owner to withdraw the balance", async function(){
    await truffleAssert.passes(instance.withdrawAll({from: accounts[0]}));
    console.log("The balance() is: " + await instance.balance());
  });
  it("should not allow non owner to withdraw the balance", async function(){
    let instance = await Coinflip.new({from: accounts[0], value: web3.utils.toWei("3", "ether")});
    await truffleAssert.fails(instance.withdrawAll({from: accounts[5]}), truffleAssert.ErrorType.REVERT);
    console.log("The balance() is: " + await instance.balance());
  });
  it("the contract balance() after the withdrawAll should be 0 ", async function(){
    let instance = await Coinflip.new({from: accounts[0], value: web3.utils.toWei("3", "ether")});
    await instance.withdrawAll({from: accounts[0]});

    let balance = await instance.balance();
    let floatBalance = parseFloat(balance);
    let realBalance = await web3.eth.getBalance(instance.address);

    assert(floatBalance == web3.utils.toWei("0", "ether") && floatBalance == realBalance, "Contract balance wasn't 0 after withdrawAll()");
    console.log("The balance() is: " + await instance.balance());
  });
  it("owner balance should increase", async function(){
    let instance = await Coinflip.new({from: accounts[0], value: web3.utils.toWei("3", "ether")});

    let balanceBefore = parseFloat(await web3.eth.getBalance(accounts[0]));
    await instance.withdrawAll({from: accounts[0]});
    let balanceAfter = parseFloat(await web3.eth.getBalance(accounts[0]));

    assert(balanceBefore < balanceAfter, "Balance of the owner did not increase");
  });
});
