const Coinflip = artifacts.require("Coinflip");
const truffleAssert = require("truffle-assertions");
const Web3 = require("web3");

contract("Coinflip", async function(accounts){

  let instance;
  let smallBet = web3.utils.toWei("0.2", "ether");
  let bigBet = web3.utils.toWei("10", "ether");

  before(async function(){
    instance = await Coinflip.deployed();
  });

  it("should increase or decrease the Coinflip value by the betting amount", async function(){
    console.log("The balance before is: " + await instance.balance());
    await instance.coinflipSet({from: accounts[1], value: smallBet});
    await instance.coinflipGet("0x47baff04c1308acea62196db1ed9b745e174d9ffefb550f8c50d910d4acb5f5b",{from: accounts[1]});
    let balance = await instance.balance();
    console.log("The balance is: " + balance);
    let floatBalance = parseFloat(balance);
    console.log("The floatBalance is: " + floatBalance);
    let realBalance = await web3.eth.getBalance(instance.address);
    console.log("The realBalance is: " + realBalance);

    console.log("Did you win? " + ((await instance.win_loose())? "Yes" : "No"));

    if(await instance.win_loose()){
      assert(floatBalance == web3.utils.toWei("0.8", "ether") && floatBalance == realBalance, "Amount didn't decrease ");
    } else {
      assert(floatBalance == web3.utils.toWei("1.2", "ether") && floatBalance == realBalance, "Amount didn't increase");
    }
    console.log("The balance after is: " + await instance.balance());
    console.log("Did you win? " + (((await instance.win_loose())? true : false   )? "Yes" : "No" + "\n"));
  });

  it("should pass the coinflip function", async function(){
    console.log("The balance() before is: " + await instance.balance());
    await truffleAssert.passes(instance.coinflipSet({from: accounts[1], value: smallBet}));
    console.log("The balance() after is: " + await instance.balance());
    console.log("Did you win? " + (((await instance.win_loose())? true : false   )? "Yes" : "No" + "\n"));
  });

  it("should fail to pass with bet which is lower than the contract balance", async function(){
    await truffleAssert.fails(instance.coinflipSet({from: accounts[1], value: web3.utils.toWei("0", "ether")})
      , truffleAssert.ErrorType.REVERT);
    console.log("The balance() is: " + await instance.balance());
  });

  it("should fail to prcess coinflipSet() with bet bigger than the account balance", async function(){
    await truffleAssert.fails(instance.coinflipSet({from: accounts[1], value: bigBet})
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

  it("Should decrease balance of the contract if player wins", async function(){
    let instance = await Coinflip.new({from: accounts[0], value: web3.utils.toWei("2", "ether")});
    await instance.coinflipSet({from: accounts[1], value: smallBet});
    await instance.coinflipGet("0x47baff04c1308acea62196db1ed9b745e174d9ffefb550f8c50d910d4acb5f5b",{from: accounts[1]});
    let balance = await instance.balance();
    let floatBalance = parseFloat(balance);
    let realBalance = await web3.eth.getBalance(instance.address);
    assert(floatBalance == web3.utils.toWei("1.8", "ether") && floatBalance == realBalance, "Contract balance didn't decrease when player won");
    console.log("The balance() is: " + await instance.balance());
  });
});
