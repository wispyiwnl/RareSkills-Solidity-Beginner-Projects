// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SantanaNFT} from "../src/NFT.sol";
import {SANTANA} from "../src/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EndToEnd is Test {
    SantanaNFT nft;
    SANTANA santana;

    function setUp() public {
        santana = new SANTANA();
        nft = new SantanaNFT(IERC20(santana));
    }

    function test_endToEnd() public {
        santana.mint(55);
        santana.approve(address(nft), 1);
        nft.mint(1);
        assertEq(1, nft.totalSupply());
    }
}
