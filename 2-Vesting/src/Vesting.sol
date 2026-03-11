// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Linear ERC20 vesting
/// @author wispyiwnl
/// @notice Linearly vests ERC20 so the receiver can withdraw 1/n per day.
/// @dev Stores one schedule per (payer -> receiver) and escrows the tokens.
contract Vesting {
    using SafeERC20 for IERC20;
    /// @dev ERC20 token being vested.
    IERC20 public immutable token;

    struct Schedule {
        /// @dev Total amount to be vested.
        uint256 totalAmount;
        /// @dev Timestamp (seconds) when vesting starts.
        uint64 start;
        /// @dev Number of vesting days (n).
        uint32 numDays;
        /// @dev Amount already withdrawn.
        uint256 released;
    }

    /// @dev One schedule per (payer => receiver).
    mapping(address payer => mapping(address receiver => Schedule schedule)) public schedules;

    /// @dev Emitted when a new schedule is created.
    event Deposited(address indexed payer, address indexed receiver, uint256 amount, uint64 start, uint32 numDays);

    /// @dev Emitted each time the receiver withdraws vested tokens.
    event Withdrawn(address indexed payer, address indexed receiver, uint256 amount);

    /// @notice Set the ERC20 token to be vested.
    /// @param _token ERC20 token address.
    constructor(IERC20 _token) {
        require(address(_token) != address(0), "token=0");
        token = _token;
    }

    /**
     * @notice Create a linear vesting schedule.
     * @param amount Total tokens to vest.
     * @param numDays Number of vesting days (n).
     * @param receiver Beneficiary of the schedule.
     */
    function deposit(uint256 amount, uint32 numDays, address receiver) external {
        require(receiver != address(0), "receiver=0");
        require(amount > 0, "amount=0");
        require(numDays > 0, "days=0");

        Schedule storage s = schedules[msg.sender][receiver];
        require(s.totalAmount == 0, "schedule exists");

        token.safeTransferFrom(msg.sender, address(this), amount);

        schedules[msg.sender][receiver] =
            Schedule({totalAmount: amount, start: uint64(block.timestamp), numDays: numDays, released: 0});

        emit Deposited(msg.sender, receiver, amount, uint64(block.timestamp), numDays);
    }

    /**
     * @notice Withdraw the currently available vested amount.
     * @param payer Address that created the schedule.
     */
    function withdraw(address payer) external {
        Schedule storage s = schedules[payer][msg.sender];
        require(s.totalAmount > 0, "no schedule");

        uint256 amountNow = withdrawable(payer, msg.sender);
        require(amountNow > 0, "nothing to withdraw");

        s.released += amountNow;

        token.safeTransfer(msg.sender, amountNow);
        emit Withdrawn(payer, msg.sender, amountNow);

        if (s.released == s.totalAmount) {
            delete schedules[payer][msg.sender];
        }
    }

    /**
     * @notice Compute total vested amount so far.
     * @param payer Schedule creator.
     * @param receiver Schedule beneficiary.
     * @return Total vested amount (including what was withdrawn).
     */
    function vestedAmount(address payer, address receiver) public view returns (uint256) {
        Schedule memory s = schedules[payer][receiver];
        if (s.totalAmount == 0) return 0;

        if (block.timestamp <= s.start) return 0;

        uint256 elapsed = block.timestamp - uint256(s.start);
        uint256 daysPassed = elapsed / 1 days;

        if (daysPassed >= s.numDays) return s.totalAmount;

        return (s.totalAmount * daysPassed) / s.numDays;
    }

    /// @notice Compute how much can be withdrawn right now.
    /// @param payer Schedule creator.
    /// @param receiver Schedule beneficiary.
    /// @return Amount currently withdrawable.
    function withdrawable(address payer, address receiver) public view returns (uint256) {
        Schedule memory s = schedules[payer][receiver];
        uint256 vested = vestedAmount(payer, receiver);
        if (vested <= s.released) return 0;
        return vested - s.released;
    }
}
