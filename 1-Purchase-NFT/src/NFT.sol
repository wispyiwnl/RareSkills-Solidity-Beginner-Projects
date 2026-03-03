// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title ERC721 purchasable with a specific ERC20 token
/// @author wispyiwnl
/// @notice Allows users to mint NFTs only by paying with a predefined ERC20 token
/// @dev Simple example where each NFT costs exactly 1 unit of the ERC20 token
contract SantanaNFT is ERC721 {
    using SafeERC20 for IERC20;
    /// @notice Total number of NFTs minted
    uint256 public totalSupply;

    /// @notice ERC20 token accepted as payment for minting
    /// @dev Immutable reference to the ERC20 used to pay for mints
    IERC20 immutable token;

    /// @notice Sets the ERC20 token used to pay for minting
    /// @param _token Address of the ERC20 token contract
    constructor(IERC20 _token) ERC721("SantanaNFT", "SANFT") {
        token = IERC20(_token);
    }

    /// @notice Mints exactly one NFT in exchange for ERC20 tokens
    /// @dev Requires the caller to have at least 1 token and to have approved this contract
    /// @param amount Amount of ERC20 tokens to pay (must be exactly 1)
    function mint(uint256 amount) external {
        require(amount == 1, "invalid amount");
        require(token.allowance(msg.sender, address(this)) >= amount, "insufficient allowance");

        token.safeTransferFrom(msg.sender, address(this), amount);

        totalSupply++;
        _safeMint(msg.sender, totalSupply);
    }
}
