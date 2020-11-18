# Coinflip-test-Project

It is a simple gambeling project on the ropsten network where you can put your stake for a 50% of winning probability. Main skills that I have learned here are contract development, oracle integration, and web3 integration. 

How to Install. 
1. Copy this reposytory on your machine. 
2. In the root folder create file named ".secret" and input there seed phrase from your metamask (please be careful not to share your seed phrase, use expendable metamask account. 
3. Install truffle suite. 
4. Install python 2 . 
5. Get some free Eth from ropsten faucet. 
6. In the PowerShell go to the root folder of the project and run "truffle migrate".
7. After deployment copy the address of the Coinflip contract into main.js file to a variable named "contract_addr" and to "blockOnCreation" the block number where thre contract instruction was mined. 
8. Next in the PowerShell window go to "...dapp-template\dapp-template" and run "python -m http.server".
9. In you browser go to the address "http://localhost:8000/"
10. Try it out. 
