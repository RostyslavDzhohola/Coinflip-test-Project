const Coinflip = artifacts.require("Coinflip");


module.exports = function(deployer, networks, accounts) {
  deployer.deploy(Coinflip, {from: accounts[0], value: web3.utils.toWei("0.1", "ether")}).then(async () =>{
    let instance = await Coinflip.deployed();
    let balance = await instance.balance();
    console.log("The contact balance is: " + balance.toString());
  });
};
