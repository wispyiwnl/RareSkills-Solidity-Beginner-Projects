// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {SANTANA} from "../src/ERC20.sol";
import {Vesting} from "../src/Vesting.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VestingTest is Test {
    Vesting vesting;
    SANTANA santana;

    address payer = makeAddr("user");
    address receiver = makeAddr("receiver");
    uint256 amount = 1_000;
    uint32 numDays = 5;

    function setUp() public {
        santana = new SANTANA();
        vesting = new Vesting(IERC20(santana));

        vm.prank(payer);
        santana.mint(amount);
    }

    function test_deposit_storesScheduleAndTransfersTokens() public {
        vm.startPrank(payer);

        santana.approve(address(vesting), amount);
        vesting.deposit(amount, numDays, receiver);

        vm.stopPrank();

        assertEq(santana.balanceOf(address(vesting)), amount, "vesting balance incorrect");
        assertEq(santana.balanceOf(payer), 0, "payer should have transferred all");

        (uint256 totalAmount, uint64 start, uint32 daysCount, uint256 released) = vesting.schedules(payer, receiver);

        assertEq(totalAmount, amount, "totalAmount");
        assertEq(daysCount, numDays, "numDays");
        assertEq(released, 0, "released should start at 0");
        assertGt(start, 0, "start must be set");
    }

    function test_deposit_revertsOnZeroAmount() public {
        vm.startPrank(payer);
        santana.approve(address(vesting), amount);

        vm.expectRevert(bytes("amount=0"));
        vesting.deposit(0, numDays, receiver);
    }

    function test_deposit_revertsOnZeroDays() public {
        vm.startPrank(payer);
        santana.approve(address(vesting), amount);

        vm.expectRevert(bytes("days=0"));
        vesting.deposit(amount, 0, receiver);
    }

    function test_deposit_revertsWhenScheduleAlreadyExists() public {
        vm.startPrank(payer);

        santana.approve(address(vesting), amount * 2);
        vesting.deposit(amount, numDays, receiver);

        vm.expectRevert(bytes("schedule exists"));
        vesting.deposit(amount, numDays, receiver);
    }

    function test_vestedAmount_beforeStart_isZero() public {
        vm.startPrank(payer);
        santana.approve(address(vesting), amount);
        vesting.deposit(amount, numDays, receiver);
        vm.stopPrank();

        (, uint64 start,,) = vesting.schedules(payer, receiver);
        vm.warp(start - 1);

        assertEq(vesting.vestedAmount(payer, receiver), 0, "vested before start must be 0");
    }

    function test_vestedAmount_middleOfSchedule() public {
        vm.startPrank(payer);
        santana.approve(address(vesting), amount);
        vesting.deposit(amount, numDays, receiver);
        vm.stopPrank();

        (, uint64 start,,) = vesting.schedules(payer, receiver);

        vm.warp(start + 2 days);

        uint256 expected = (amount * 2) / numDays;
        assertEq(vesting.vestedAmount(payer, receiver), expected, "vested after 2 days");
    }

    function test_vestedAmount_afterEnd_isTotal() public {
        vm.startPrank(payer);
        santana.approve(address(vesting), amount);
        vesting.deposit(amount, numDays, receiver);
        vm.stopPrank();

        (, uint64 start,,) = vesting.schedules(payer, receiver);

        vm.warp(start + uint256(numDays) * 1 days + 1);

        assertEq(vesting.vestedAmount(payer, receiver), amount, "vested after end should be total");
    }

    function test_withdraw_partialAfterSomeDays() public {
        vm.startPrank(payer);
        santana.approve(address(vesting), amount);
        vesting.deposit(amount, numDays, receiver);
        vm.stopPrank();

        (, uint64 start,,) = vesting.schedules(payer, receiver);

        vm.warp(start + 2 days);

        vm.prank(receiver);
        vesting.withdraw(payer);

        uint256 expected = (amount * 2) / numDays;
        assertEq(santana.balanceOf(receiver), expected, "receiver balance");

        (,, uint32 daysCount, uint256 released) = vesting.schedules(payer, receiver);
        assertEq(daysCount, numDays);
        assertEq(released, expected, "released after partial withdraw");
    }

    function test_withdraw_multipleTimes_overWholePeriod() public {
        vm.startPrank(payer);
        santana.approve(address(vesting), amount);
        vesting.deposit(amount, numDays, receiver);
        vm.stopPrank();

        (, uint64 start,,) = vesting.schedules(payer, receiver);

        vm.warp(start + 1 days - 1);
        vm.prank(receiver);
        vm.expectRevert(bytes("nothing to withdraw"));
        vesting.withdraw(payer);

        vm.warp(start + 1 days);
        vm.prank(receiver);
        vesting.withdraw(payer);

        uint256 firstPortion = amount / numDays;
        assertEq(santana.balanceOf(receiver), firstPortion, "after first withdraw");

        vm.warp(start + 3 days);
        vm.prank(receiver);
        vesting.withdraw(payer);

        uint256 totalVestedDay3 = (amount * 3) / numDays;
        assertEq(santana.balanceOf(receiver), totalVestedDay3, "receiver should have vested amount up to day 3");

        vm.warp(start + uint256(numDays) * 1 days + 1);
        vm.prank(receiver);
        vesting.withdraw(payer);

        assertEq(santana.balanceOf(receiver), amount, "receiver final balance must be total");
        assertEq(santana.balanceOf(address(vesting)), 0, "vesting contract should be empty");
    }

    function test_withdraw_revertsWhenNothingToWithdraw() public {
        vm.startPrank(payer);
        santana.approve(address(vesting), amount);
        vesting.deposit(amount, numDays, receiver);
        vm.stopPrank();

        vm.expectRevert(bytes("nothing to withdraw"));
        vm.prank(receiver);
        vesting.withdraw(payer);
    }

    function test_end2end_fullVestingFlow() public {
        vm.startPrank(payer);
        santana.approve(address(vesting), amount);
        vesting.deposit(amount, numDays, receiver);
        vm.stopPrank();

        (, uint64 start,,) = vesting.schedules(payer, receiver);

        vm.warp(start + uint256(numDays) * 1 days + 1);

        vm.prank(receiver);
        vesting.withdraw(payer);

        assertEq(santana.balanceOf(receiver), amount, "receiver should have full amount");
        assertEq(santana.balanceOf(address(vesting)), 0, "vesting contract empty");

        (uint256 totalAmount, uint64 newStart, uint32 daysCount, uint256 released) = vesting.schedules(payer, receiver);
        assertEq(totalAmount, 0, "schedule totalAmount cleared");
        assertEq(newStart, 0, "schedule start cleared");
        assertEq(daysCount, 0, "schedule numDays cleared");
        assertEq(released, 0, "schedule released cleared");
    }
}
