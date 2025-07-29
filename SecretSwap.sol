// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SecretSwap
 * @dev A smart contract for exchanging encrypted messages between two users that are unlockable after a specific time.
 */
contract SecretSwap {
    struct Vault {
        address userA;
        address userB;
        bytes encryptedA;
        bytes encryptedB;
        uint256 unlockTime;
        bool submittedA;
        bool submittedB;
    }

    uint256 public vaultCount;
    mapping(uint256 => Vault) public vaults;

    event VaultCreated(uint256 vaultId, address indexed userA, address indexed userB, uint256 unlockTime);
    event PayloadSubmitted(uint256 vaultId, address indexed sender);
    event PayloadRevealed(uint256 vaultId, address indexed viewer, bytes revealedContent);

    /// @notice Create a new time-locked encrypted swap vault
    function createVault(address _userB, uint256 _unlockTime) external returns (uint256) {
        require(msg.sender != _userB, "Cannot create vault with yourself");
        require(_unlockTime > block.timestamp, "Unlock time must be in the future");

        vaultCount++;
        vaults[vaultCount] = Vault(msg.sender, _userB, "", "", _unlockTime, false, false);
        emit VaultCreated(vaultCount, msg.sender, _userB, _unlockTime);
        return vaultCount;
    }

    /// @notice Submit your encrypted message to the vault
    function submitPayload(uint256 vaultId, bytes calldata encryptedData) external {
        Vault storage v = vaults[vaultId];
        require(msg.sender == v.userA || msg.sender == v.userB, "Not a participant");

        if (msg.sender == v.userA) {
            require(!v.submittedA, "Already submitted");
            v.encryptedA = encryptedData;
            v.submittedA = true;
        } else {
            require(!v.submittedB, "Already submitted");
            v.encryptedB = encryptedData;
            v.submittedB = true;
        }

        emit PayloadSubmitted(vaultId, msg.sender);
    }

    /// @notice Reveal the encrypted content from the other user after unlock time
    function reveal(uint256 vaultId) external view returns (bytes memory) {
        Vault storage v = vaults[vaultId];
        require(block.timestamp >= v.unlockTime, "Vault not unlocked yet");
        require(msg.sender == v.userA || msg.sender == v.userB, "Not a participant");

        if (msg.sender == v.userA) {
            return v.encryptedB;
        } else {
            return v.encryptedA;
        }
    }
}
