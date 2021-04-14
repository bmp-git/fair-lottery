// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import {SafeMath} from "./SafeMath.sol";
import {Ownable} from "./Ownable.sol";


contract Lottery is Ownable {
    
    struct Ticket {
        uint256 amount;
        uint256 probability;
        uint256 blockNumber;
        bool opened;
        bool winner;
    }
    
    mapping(address => Ticket[]) public tickets;
    
    uint256 safetyFactor = 10;
    uint256 constant ownerFees = 1000;
    uint256 constant pMax = 100;
    
    constructor () payable { }
    
    receive() external payable { }
    
    /*Redeem a (winning) ticket*/
    function redeemTicket(uint256 index) public {
        Ticket storage ticket = tickets[msg.sender][index];

        (, uint256 winAmount) = ticketWins(ticket.amount, ticket.probability);

        require(!ticket.opened, "Ticket already opened");
        require(block.number - ticket.blockNumber >= 5, "Need more blocks.");
        require(block.number - ticket.blockNumber <= 255, "The ticket is expired.");
        
        bytes32 seed = blockhash(ticket.blockNumber) ^ blockhash(ticket.blockNumber + 1) ^ blockhash(ticket.blockNumber + 2) ^ blockhash(ticket.blockNumber + 3) ^ blockhash(ticket.blockNumber + 4);
        uint256 rand = uint256(seed) % pMax;

        if(ticket.probability >= rand) {
            winAmount = SafeMath.min(winAmount, address(this).balance); //fund can be emptied
            (bool success,) = msg.sender.call{value: winAmount}("");
            require(success, "Not payable address");
            ticket.winner = true;
        }
        ticket.opened = true;
    }
    
    /*Buy a ticket*/
    function buyTicket(uint256 p) public payable {
        require(p > 0 && p < pMax, "Invalid probability.");
        uint256 amount = msg.value;
        (uint256 fee, uint256 winAmount) = ticketWins(amount, p);
        require(amount > fee, "The bid amount is too low"); //only needed if pMax is greater than ownerFees
        require(winAmount - amount < SafeMath.div(address(this).balance, safetyFactor), "The potential win exeed the safety factor.");
        tickets[msg.sender].push(Ticket(msg.value, p, block.number, false, false));
        (bool success,) = owner().call{value: fee}("");
        require(success, "Fee payment failed.");
    }
    
    /*Views*/
    function viewFundBalance() external view returns(uint256) {
        return address(this).balance;
    }
    
    function isWinningTicket(uint256 index) external view returns(bool) {
        Ticket memory ticket = tickets[msg.sender][index];
        require(block.number - ticket.blockNumber >= 5, "Need more blocks.");
        require(block.number - ticket.blockNumber <= 255, "The ticket is expired.");
        bytes32 seed = blockhash(ticket.blockNumber) ^ blockhash(ticket.blockNumber + 1) ^ blockhash(ticket.blockNumber + 2) ^ blockhash(ticket.blockNumber + 3) ^ blockhash(ticket.blockNumber + 4);
        uint256 rand = uint256(seed) % pMax;
        return ticket.probability >= rand;
    }
    
    /* Utilities */
    function ticketWins(uint256 amount, uint256 p) private pure returns (uint256, uint256) {
        uint256 pureWinAmount = SafeMath.div(SafeMath.mul(amount, pMax), p);
        uint256 fee = SafeMath.div(pureWinAmount, ownerFees);
        uint256 winAmount = pureWinAmount - fee * 2;
        return (fee, winAmount);
    }
    
    /* Governance */
    function changeSafetyFactor(uint256 factor) external onlyOwner {
        require(factor > 0, "Safety factor can't be 0.");
        require(factor < 10000, "Safety factor too high.");
        safetyFactor = factor;
    }
    
}