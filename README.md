# Fair Lottery
Fair Lottery aims to be a decentralized application (dApp) that implements the lottery game in a "fair" way. A user can bet any amount of money and choose the probability of winning. The maximum possible win is calculated on the basis of the bet amount and the chosen probability. After about a minute from purchasing the ticket, it is possible to determine whether it is a winner or not, getting the reward. No third-party entity can control or manipulate the lottery by rigging the tickets or removing funds belonging to the lottery itself. The lottery code itself is written on the blockchain and it's immutable. Once deployed no one can change it.


## How it works

You buy a `X` ethereum ticket and select a `P in ]0,1[` probability that the ticket will be a winning ticket. 
If you bought a winning ticket you will get back `X/P - fee` Ethereum back. Where the fees are a total of `0.002*(X/P-X)`.
More on fees later.
Example: 
1) I buy a 1 Ethereum ticket with a winning probability of 10%. If it's a winning ticket i can redeem it and get back `1/0.1 - 0.002*(1/0.1 - 1) = 9.98` Ethereum to my account. If i lose i get back nothing. 1 times out of 10 i will win.
2) I buy a 10 Ethereum ticket with a winning probability of 99%. If it's a winning ticket i can redeem it and get back `10/0.99 - 0.002*(10/0.99 - 10) = 10,100808` Ethereum to my account. If i lose i get back nothing. 99 times out of 100 i will win.

**You can redeem the ticket after at least 5 blocks of its purchase.**
**You must redeem the ticket within 255 blocks of its purchase otherwise you can no longer collect the reward.** This is because the contract has a limited view of 256 blocks behind and the random function is based on the blocks hash.


## Randomness
True randomness in a deterministic environment (EVM) is not possible. However, this system guarantees a generation of random numbers that cannot be tampered by anyone. The randomness is generated in a distributed ways by the miners. Until there isn't a miner that control 100% of the block generation the randomness is guaranteed. 

### How it works
The random function is implemented as follows:
```solidity
function random(uint256 i) private view returns (uint256) {
    bytes32 seed = blockhash(i) ^ blockhash(i + 1) ^ blockhash(i + 2) ^ blockhash(i + 3) ^ blockhash(i + 4);
    return uint256(seed);
}
```
Where `i` is the index of the block in which the ticket was bought. It is possible to find out if the ticket is a winner only after 5 blocks from the purchase. In this way the miners competing to find the next block increase the entropy of the random function.

### Why 5 blocks and not more?

### Importance of safety factor

### Attack vector
Scenario 1: pool da sola cerca di vincere il 100% dei ticket, ovvero, gioca solo ticket vincenti
Scenario 2: la pool decide di influenzare soltanto l'ultimo blocco, decidendo se scartarlo o meno.
Scenario 3: si svuota la pool e qualcuno perde anche se vince.

## Owner
The lottery owner is the one that deploy the smart contract in the blockchain and the whom that puts the funds for the ethereum pool. The owner gets 0.1% of the potential win as a fee for each bet. The pool also gets 0.1% of the potential win as a fee for each bet.
The owner can't manipulate the fairness of the lottery. The owner can only change the safety factor of the pool.

## Contributors
Edoardo Barbieri
Emanuele Pansici