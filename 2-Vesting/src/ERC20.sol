// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title SANTANA ERC20 token used to purchase NFTs
/// @author wispyiwnl
/// @notice Simple mintable ERC20 token used as the payment token for SantanaNFT
/// @dev Anyone can mint tokens to their own address for testing/demo purposes
contract SANTANA is ERC20 {
    /// @notice Deploys the token with name and symbol "SANTANA"
    constructor() ERC20("SANTANA", "SANTANA") {}

    /// @notice Mints `amount` tokens to the caller
    /// @dev No access control, intended only for testing and local development
    /// @param amount Number of tokens to mint to the caller
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
