// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.25;

contract TransferTokens {
    address owner; // Address of the owner of the contract
    uint256 tokens; // Total number of tokens
    mapping (address => uint256) fondos; // Mapping to store balances of addresses

    constructor() {
        owner = msg.sender; // Set the owner of the contract as the deployer
        tokens = 1000; // Initialize total tokens to 1000
        fondos[owner] = tokens; // Assign all tokens to the owner initially
    }

    event Transfer(address from, address to, uint256 value); // Event emitted when tokens are transferred
    event CheckTokens(address account, uint256 tokensAccount); // Event emitted to check tokens of an external account
    event CreateTokens(uint256 newTokens, uint256 totalTokens); // Event emitted when new tokens are added

    function transferTokens(address to, uint256 value) external payable {
        require(fondos[msg.sender] > 0, "You have not enough tokens for this transaction"); // Check if the sender has enough tokens
        fondos[msg.sender] -= value; // Deduct tokens from the sender
        fondos[to] += value; // Add tokens to the recipient
        emit Transfer(owner, to, value); // Emit transfer event
    }

    function checkTokensExternalAccount(address account) external {
        emit CheckTokens(account, fondos[account]); // Emit event to check tokens of an external account
    }

    function checkTokensInternalAccount() external returns (uint256) {
        emit CheckTokens(msg.sender, fondos[msg.sender]); // Emit event to check tokens of the sender
        return fondos[msg.sender]; // Return the balance of the sender
    }

    function addTokens(uint newTokens) external payable {
        if (msg.sender == owner) { // Check if the caller is the owner
            fondos[owner] += newTokens; // Add new tokens to the owner's balance
            emit CreateTokens(newTokens, fondos[owner]); // Emit event for new tokens creation
        }
    }
}
