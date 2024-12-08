// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./VulnERC20.sol";
import "../IPSFirewall.sol";
import "../TransactionEventsLib.sol";

/// Reliable Hack Prevention - Firewall contract are for security engineers. business logic contracts are for devs. here security engineers verify that devs implementation follow the specifications using invariant based tests
/// @title VulnERc20FirewallContract is a firewall contract protecting the VulnERC20 implementiation that has no access control on the transfer function.
/// @author theexoticman
/// @dev for now runSecurityChecks is the entrypoint in the firewall contract.
//          This function is automatically trigger after the transaction execution,
//          only if the contract it protects was modified

contract VulnERC20FirewallContract is IPSFirewall {
    //////////////////////////////////////////////////////////////
    //            VulnERC20 Events Signature Hashes             //
    //////////////////////////////////////////////////////////////

    // ERC20 Transfer and Approval Event signature
    // They are used to identify the events emitted during the transaction.
    // All Events emitted by the VulnERC20 are passed to the runSecurityChecks function

    bytes32 erc20TransferEventSig =
        TransactionEventsLib.getEventHash("Transfer(address,address,uint256)");
    bytes32 erc20ApprovalEventSig =
        TransactionEventsLib.getEventHash("Approval(address,address,uint256)");

    //////////////////////////////////////////////////////////////
    //                Invariant State Variables                 //
    //////////////////////////////////////////////////////////////

    // supply calculated from the transactions parameters
    uint public supply = 0;

    // balances calculated from the transactions parameters
    mapping(address account => uint256) private _balances;

    // allowances calculated from the transactions parameters
    mapping(address account => mapping(address spender => uint256))
        private _allowances;

    // we use accumulator variables and compare the current contract state with the expect values changes.
    // Optimization could be possible by calculating invariants using intermediary snapshots.

    // Struct  updated allowances
    struct AllowanceUpdated {
        address[] owners;
        address[] spenders;
    }
    // Struct to log updated allowances
    struct BalanceUpdated {
        address[] froms;
        address[] tos;
    }

    // Struct to log updated allowances
    struct SpenderUpdated {
        address[] owners;
        address[] spenders;
    }

    constructor() {}

    //////////////////////////////////////////////////////////////
    //                   Firewall Entrypoint                    //
    //////////////////////////////////////////////////////////////

    /// @notice This function is called by the Decentralized Firewall Engine in the execution client, at the end of the transaction execution if and only if, the contract it is protecting (SafeNFT) is modified.
    /// @dev implement the logic that analyze how your contract behaved
    /// @param caller the EOA who started the call, mostly unused for now.
    /// @param snapshotAddr the address of the snapshot contract, in the same state it was a the beginning of the transacton.
    /// @param contractAddr the actual address of the  contract it is portecting - the SafeNFT, in its the post-tx state.
    /// @param events The events and parameters emitted during the transaction by the contract this firewall is protecting (SafeNFT). for more details on data structure, check the TransactionEventsLib.sol
    /// for more details on Firewall Contracts and  our Decentralized Firewall check https://docs.ipsprotocol.xyz
    function runSecurityChecks(
        address caller,
        address snapshotAddr,
        address contractAddr,
        TransactionEventsLib.EventData[] memory events
    ) public override {
        // // snapshotContract is the contract in its state from before the start of the transaction.
        VulnERC20 snapshotContract = VulnERC20(snapshotAddr);

        // // currentContract is the current account, with its current state
        VulnERC20 currentContract = VulnERC20(contractAddr);

        AllowanceUpdated memory allowUpd = intiliazeUpdatedAllowance();
        BalanceUpdated memory balUpd = intiliazeUpdatedBalance();
        SpenderUpdated memory spendUpd = intiliazeUpdatedSpender();

        // evaluate all the Events
        for (uint256 i = 0; i < events.length; i++) {
            if (events[i].eventSigHash == erc20ApprovalEventSig) {
                // here: Approval
                processApprovalEvent(events[i], allowUpd);
            }
            if (events[i].eventSigHash == erc20TransferEventSig) {
                // event[i] is ERC20Transfer
                // check for mint event if from it 0x0
                processTransferEvent(events[i], balUpd, spendUpd);
            }
        }
        // all the events ara processing in order of appearans in the tranaciton
        // after everything is updated to match the changes
        // lets compare the results
        verifyAllowanceConsistency(currentContract, spendUpd, allowUpd);
        verifyBalanceConsistency(currentContract,balUpd);
    }

    function processApprovalEvent(
        TransactionEventsLib.EventData memory selfEvent,
        AllowanceUpdated memory allowUpd
    ) internal {
        //events.
        address owner = address(uint160(uint256(selfEvent.parameters[0])));
        address spender = address(uint160(uint256(selfEvent.parameters[1])));
        uint value = uint256(selfEvent.parameters[2]);
        verifyApprovalNotZero(owner);
        updateAllowance(owner, spender, value,allowUpd);
    }

    function processTransferEvent(
        TransactionEventsLib.EventData memory selfEvent,
        BalanceUpdated memory balUpd,
        SpenderUpdated memory spendUpd
    ) internal {
        address from = address(uint160(uint256(selfEvent.parameters[0])));
        address to = address(uint160(uint256(selfEvent.parameters[1])));

        if (from == address(0)) {
            // here: Minting event
            updateSupply(selfEvent);
            verifyMintToNotZero(to);
        } else {
            // here: from != 0x0 => transfer between accounts
            address txCaller = selfEvent.caller;
            uint amount = uint(selfEvent.parameters[2]);

            if (from != txCaller) {
                // caller != from => allowance
                (from, to);
                verifyEnoughAllowance(from, txCaller, amount);
                // here: spender had been approved for amount or more.s
                verifySufficientBalance(from, amount);
                // here: from's balance is amount of more
                updateSpender(from, to, amount, spendUpd);
                // here: the
                updateBalances(from, to, amount, balUpd);
            } else {
                // here: from == caller
                verifySufficientBalance(from, amount);
                updateBalances(from, to, amount, balUpd);
            }
        }
    }

    function intiliazeUpdatedAllowance()
        internal
        returns (AllowanceUpdated memory allowanceUpdated)
    {
        address[] memory owner;
        address[] memory spender;

        allowanceUpdated = AllowanceUpdated(owner, spender);
    }

    function intiliazeUpdatedSpender()
        internal
        returns (SpenderUpdated memory spenderUpdateD)
    {
        address[] memory owner;
        address[] memory spender;

        spenderUpdateD = SpenderUpdated(owner, spender);
    }

    function intiliazeUpdatedBalance()
        internal
        returns (BalanceUpdated memory balanceUpdated)
    {
        address[] memory froms;
        address[] memory tos;

        balanceUpdated = BalanceUpdated(froms, tos);
    }

    //////////////////////////////////////////////////////////////
    //              Invariant Update Functions                  //
    //////////////////////////////////////////////////////////////

    // only run at the end
    function updateBalances(
        address from,
        address to,
        uint amount,
        BalanceUpdated memory balUpd
    ) internal {
        _balances[from] -= amount;
        _balances[to] += amount;

        uint index = balUpd.froms.length;
        balUpd.froms[index] = from;
        balUpd.tos[index] = to;
    }

    function updateAllowance(
        address owner,
        address spender,
        uint value,
        AllowanceUpdated memory allUpd
    ) internal {
        _allowances[owner][spender] = value;

        uint index = allUpd.owners.length;
        allUpd.owners[index] = owner;
        allUpd.spenders[index] = spender;
    }

    function updateSpender(
        address owner,
        address spender,
        uint value,
        SpenderUpdated memory spendUpd
    ) internal {
        _allowances[owner][spender] -= value;

        uint index = spendUpd.owners.length;
        spendUpd.owners[index] = owner;
        spendUpd.spenders[index] = spender;
    }

    function updateSupply(
        TransactionEventsLib.EventData memory mintEvent
    ) internal {
        // mint is transfer event with from == zero address
        uint mintAmount = uint(mintEvent.parameters[2]);

        // accumulate the minting amount
        supply += mintAmount;
    }

    //////////////////////////////////////////////////////////////
    //                     Security tests                       //
    //////////////////////////////////////////////////////////////

    function verifyMintToNotZero(address to) internal pure {
        if (to == address(0)) {
            revert("ipschainsecurity: Invariant: cannot mint to 0X0");
        }
    }

    function verifyApprovalNotZero(
        address owner
    ) internal pure {
        if (owner == address(0)) {
            revert("ipschainsecurity: Invariant: cannot transfer from 0X0");
        }
    }

    // given all the allowance events generated during the transaction,
    // we will iterate over them and apply the changes to the invariant state varibles
    function verifyApprovalConsistency(
        VulnERC20 currentContract,
        AllowanceUpdated memory allUpd
    ) view internal {
        // here: invariant varibles updated
        for (uint i = 0; i < allUpd.owners.length; i++) {
            // second time, compare currentCotnract and expected values here calculcated
            address owner = allUpd.owners[i];
            address spender = allUpd.spenders[i];
            if (
                _allowances[owner][spender] !=
                currentContract.allowance(owner, spender)
            ) {
                revert("ipschainsecurity: Invariant: approval not consistent.");
            }
        }
    }

    function verifyAllowanceConsistency(
        VulnERC20 currentContract,
        SpenderUpdated memory spendUpd,
        AllowanceUpdated memory allUpd
    ) internal {
        // validat the allowance
        for (uint i = 0; i < spendUpd.owners.length; i++) {
            address owner = spendUpd.owners[i];
            address spender = spendUpd.spenders[i];

            if (
                currentContract.allowance(owner, spender) !=
                _allowances[owner][spender]
            ) {
                revert(
                    "ipschainsecurity: Invariant: allowance deduction not consistent"
                );
            }
        }
        // validat the allowance
        for (uint i = 0; i < allUpd.owners.length; i++) {
            address owner = allUpd.owners[i];
            address spender = allUpd.spenders[i];

            if (
                currentContract.allowance(owner, spender) !=
                _allowances[owner][spender]
            ) {
                revert(
                    "ipschainsecurity: Invariant: allowance deduction not consistent"
                );
            }
        }
    }

    function verifyBalanceConsistency(
        VulnERC20 currentContract,
        BalanceUpdated memory balUpd
    ) internal {
        for (uint i = 0; i < balUpd.froms.length; i++) {
            // second time, compare currentCotnract and expected values here calculcated
            address from = balUpd.froms[i];
            address to = balUpd.tos[i];
            if (
                _balances[from] != currentContract.balanceOf(from) ||
                _balances[to] != currentContract.balanceOf(to)
    
            ) {
                revert(
                    "ipschainsecurity: Invariant: balances do not match, transfer is not consistent."
                );
            }
        }
    }

    function verifySufficientBalance(address from, uint amount) internal view {
        if (_balances[from] < amount) {
            revert("ipschainsecurity: Invariant: insufficiant Balance ");
        }
    }

    function verifyTotalSupplyConsistency(
        VulnERC20 currentContract
    ) internal view {
        // compare the actual total supply in the erc20 contract
        // to the accumulated supply calculated from the mint events
        if (currentContract.totalSupply() != supply) {
            // if supply calcaulted from the events and from the contract dont match, it measn the implementation was broken
            revert(
                "ipschainsecurity: Invariant: total supply is not consistent"
            );
        }
    }

    function verifyEnoughAllowance(
        address owner,
        address spender,
        uint value
    ) internal  view {
        if (_allowances[owner][spender] < value) {
            revert("ipschainsecurity: Invariant: insufficient Allowance");
        }
    }
}

//approve(20) approve(20) sum all approvals and calculate at the end
// b
