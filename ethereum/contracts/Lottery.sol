// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import {Ownable} from "./Ownable.sol";


contract Lottery is Ownable {
    
    struct Ticket {
        uint256 amount;
        uint256 probability;
        uint256 blockNumber;
        bool redeemed;
    }
    
    mapping(address => Ticket[]) public tickets;
    
    uint256 safetyFactor = 10;
    uint256 constant ownerFees = 1000;
    uint256 constant pMax = 100;
    
    constructor () payable { }
    
    receive() external payable { }
    
    /*Redeem a winning ticket*/
    function redeemTicket(uint256 index) public {
        Ticket storage ticket = tickets[msg.sender][index];
        (, uint256 winAmount) = computeFeeAndWins(ticket.amount, ticket.probability);
        require(!ticket.redeemed, "Ticket already opened");
        requireBlockRangeIsValird(block.number, ticket.blockNumber);
        require(hasWin(ticket.probability, ticket.blockNumber), "Not a winning ticket.");
        winAmount = min(winAmount, address(this).balance); //fund can be emptied
        (bool success,) = msg.sender.call{value: winAmount}("");
        require(success, "Not payable address");
        ticket.redeemed = true;
    }
    
    /*Buy a ticket*/
    function buyTicket(uint256 p) public payable {
        require(p > 0 && p < pMax, "Invalid probability.");
        (uint256 fee, uint256 winAmount) = computeFeeAndWins(msg.value, p);
        require(msg.value > 2 * fee, "The bid amount is too low");
        require(winAmount - msg.value < address(this).balance / safetyFactor, "The potential win exeed the safety limit.");
        tickets[msg.sender].push(Ticket(msg.value, p, block.number, false));
        (bool success,) = owner().call{value: fee}("");
        require(success, "Fee payment failed.");
    }
    
    /*Public views*/
    function viewFundBalance() external view returns(uint256) {
        return address(this).balance;
    }
    
    function isWinningTicket(uint256 index) external view returns(bool) {
        Ticket memory ticket = tickets[msg.sender][index];
        requireBlockRangeIsValird(block.number, ticket.blockNumber);
        return hasWin(ticket.probability, ticket.blockNumber);
    }
    
    /* Utilities */
    function computeFeeAndWins(uint256 amount, uint256 p) private pure returns (uint256, uint256) {
        uint256 pureWinAmount = (amount * pMax) / p;
        uint256 fee = (pureWinAmount - amount) / ownerFees;
        uint256 winAmount = pureWinAmount - (fee * 2);
        return (fee, winAmount);
    }
    
    function random(uint256 i) private view returns (uint256) {
        bytes32 seed = blockhash(i) ^ blockhash(i + 1) ^ blockhash(i + 2) ^ blockhash(i + 3) ^ blockhash(i + 4);
        return uint256(seed);
    }
    
    function requireBlockRangeIsValird(uint256 blockNumber, uint256 ticketBlockNumber) private pure {
        require(blockNumber - ticketBlockNumber >= 5, "Need more blocks.");
        require(blockNumber - ticketBlockNumber <= 255, "The ticket is expired.");
    }
    
    function hasWin(uint256 p, uint256 i) private view returns (bool) {
        return p > (random(i) % pMax);
    }
    
    function min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }
    
    /* Governance */
    function changeSafetyFactor(uint256 factor) external onlyOwner {
        require(factor > 0, "Safety factor can't be 0.");
        require(factor < 10000, "Safety factor too high.");
        safetyFactor = factor;
    }
    
}
