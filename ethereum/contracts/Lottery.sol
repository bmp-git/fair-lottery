// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import {Ownable} from "./Ownable.sol";


contract Lottery is Ownable {
    
    struct Ticket {
        uint256 amount;
        uint256 probability;
        uint256 blockNumber;
        bool redeemed;
        bool signed;
    }
    
    mapping(address => Ticket[]) public tickets;
    
    uint256 safetyFactor = 10;
    uint256 constant ownerFees = 1000;
    uint256 constant pMax = 100;
    
    constructor () payable { }
    
    receive() external payable { }
    
    /*Sign a winning ticket*/
    function signTicket(address ticketOwner, uint256 index) public {
        Ticket storage ticket = tickets[ticketOwner][index];
        require(!ticket.redeemed, "Ticket already redeemed");
        require(!ticket.signed, "Ticket already signed.");
        requireBlockRangeIsValid(block.number, ticket.blockNumber);
        require(hasWin(ticket, ticketOwner, index), "Not a winning ticket.");
        ticket.signed = true;
    }
    
    /*Redeem a winning ticket*/
    function redeemTicket(address ticketOwner, uint256 index) public {
        Ticket storage ticket = tickets[ticketOwner][index];
        (, uint256 winAmount) = computeFeeAndWins(ticket.amount, ticket.probability);
        require(!ticket.redeemed, "Ticket already redeemed.");
        if(!ticket.signed) {
            requireBlockRangeIsValid(block.number, ticket.blockNumber);
            require(hasWin(ticket, ticketOwner, index), "Not a winning ticket.");
        }
        winAmount = winAmount < address(this).balance ? winAmount : address(this).balance;
        (bool success,) = ticketOwner.call{value: winAmount}("");
        require(success, "Not payable address");
        ticket.redeemed = true;
        ticket.signed = true;
    }
    
    /*Buy a ticket*/
    function buyTicket(address ticketOwner, uint256 p) public payable {
        require(p > 0 && p < pMax, "Invalid probability.");
        (uint256 fee, uint256 winAmount) = computeFeeAndWins(msg.value, p);
        require(msg.value > 2 * fee, "The bid amount is too low");
        require(winAmount - msg.value < address(this).balance / safetyFactor, "The potential win exeed the safety limit.");
        tickets[ticketOwner].push(Ticket(msg.value, p, block.number, false, false));
        (bool success,) = owner().call{value: fee}("");
        require(success, "Fee payment failed.");
    }
    
    /*Public views*/
    function viewFundBalance() external view returns(uint256) {
        return address(this).balance;
    }
    
    function isWinningTicket(address ticketOwner, uint256 index) external view returns(bool) {
        Ticket memory ticket = tickets[ticketOwner][index];
        requireBlockRangeIsValid(block.number, ticket.blockNumber);
        return hasWin(ticket, ticketOwner, index);
    }
    
    /* Utilities */
    function computeFeeAndWins(uint256 amount, uint256 p) private pure returns (uint256, uint256) {
        uint256 pureWinAmount = (amount * pMax) / p;
        uint256 fee = (pureWinAmount - amount) / ownerFees;
        uint256 winAmount = pureWinAmount - (fee * 2);
        return (fee, winAmount);
    }
    
    function random(uint256 i, address ticketOwner, uint256 ticketIndex) private view returns (uint256) {
        bytes32 ticketId = keccak256(abi.encode(ticketOwner, ticketIndex));
        bytes32 seed = blockhash(i) ^ blockhash(i + 1) ^ blockhash(i + 2) ^ blockhash(i + 3) ^ blockhash(i + 4) ^ ticketId;
        return uint256(seed);
    }
    
    function requireBlockRangeIsValid(uint256 blockNumber, uint256 ticketBlockNumber) private pure {
        require(blockNumber - ticketBlockNumber >= 5, "Need more blocks.");
        require(blockNumber - ticketBlockNumber <= 255, "The ticket is expired.");
    }
    
    function hasWin(Ticket memory ticket, address ticketOwner, uint256 ticketIndex) private view returns (bool) {
        return ticket.probability > (random(ticket.blockNumber, ticketOwner, ticketIndex) % pMax);
    }
    
    
    /* Governance */
    function changeSafetyFactor(uint256 factor) external onlyOwner {
        require(factor > 0, "Safety factor can't be 0.");
        require(factor < 10000, "Safety factor too high.");
        safetyFactor = factor;
    }
    
}
