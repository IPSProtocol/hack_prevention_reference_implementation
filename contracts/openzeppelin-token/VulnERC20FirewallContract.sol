// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./MyVulnERC20.sol";
import "../IPSFirewall.sol";
import "../TransactionEventsLib.sol";

/// Reliable Hack Prevention - Firewall contract are for security engineers. business logic contracts are for devs. here security engineers verify that devs implementation follow the specifications using invariant based tests
/// @title VulnERC20FirewallContract is a firewall contract protecting the VulnERC20 implementiation which only implements business logic and no security verifications. All security verifications are done here using invariant based approach based on a ERC20 specification.
/// @author theexoticman
/// @dev for now runFirewallContract is the entrypoint in the firewall contract.
//          This function is automatically trigger after the transaction execution,
//          only if the contract it protects was modified
// Assumptions:
//              - events list appears in the time order
//              - We assume Events integry and that its logic follow the specs and therefore can be trusted.

contract VulnERC20FirewallContract is IPSFirewall {
    //////////////////////////////////////////////////////////////
    //            VulnERC20 Events Signature Hashes             //
    //////////////////////////////////////////////////////////////

    // ERC20 Transfer and Approval Event signature
    // They are used to identify the events emitted during the transaction.
    // All Events emitted by the VulnERC20 are passed to the runFirewallContract function

    bytes32 erc20TransferEventSig =
        TransactionEventsLib.getEventHash("Transfer(address,address,uint256)");
    bytes32 erc20ApprovalEventSig =
        TransactionEventsLib.getEventHash("Approval(address,address,uint256)");

    //////////////////////////////////////////////////////////////
    //                Invariant State Variables                 //
    //////////////////////////////////////////////////////////////
    event NEWADDR(address addr);
    // supply calculated from the transactions parameters
    uint public _supply = 0;

    // ensure sum of all balances are consistent.
    uint public _balancesSum = 0;

    // balances calculated from the transactions parameters
    mapping(address account => uint256) public _balances;

    // balances calculated from the transactions parameters
    mapping(address owner => mapping(address spender => bool)) public _hasMaxApproval;


    // allowances calculated from the transactions parameters
    mapping(address owner => mapping(address spender => uint256))
        public _allowances;

    // we use accumulator variables and compare the current contract state with the expect values changes.
    // Optimization could be possible by calculating invariants using intermediary snapshots.

    // Struct  updated allowances
    struct AllowanceUpdated {
        address[] owners;
        address[] spenders;
    }

    struct LatestApprovalDetails {
        // store the latest approval event details
        // only needed to verify allowance update is consistent with transferFrom data
        // the allowance is reduced by amount defined in the transfer from.
        // only if approval isnt infinite
        uint approvalEventNumber;
        uint transferFromEventNumber;
        uint prevAllowance;
        uint newAllowance;
        address owner;
        address spender;
    }

    // Struct to log updated allowances
    struct BalanceUpdated {
        address[] froms;
        address[] tos;
    }

    constructor() {}

    //////////////////////////////////////////////////////////////
    //                   Firewall Entrypoint                    //
    //////////////////////////////////////////////////////////////

    /// @notice This function is called by the Decentralized Firewall Engine in the execution client, at the end of the transaction execution if and only if, the contract it is protecting (VulnNFT) is modified.
    /// @dev implement the logic that analyze how your contract behaved
    /// @param caller the EOA who started the call, mostly unused for now.
    /// @param snapshotAddr the address of the snapshot contract, in the same state it was a the beginning of the transacton.
    /// @param contractAddr the actual address of the  contract it is portecting - the VulnNFT, in its the post-tx state.
    /// @param events The events and parameters emitted during the transaction by the contract this firewall is protecting (VulnNFT). for more details on data structure, check the TransactionEventsLib.sol
    /// for more details on Firewall Contracts and  our Decentralized Firewall check https://docs.ipsprotocol.xyz
    function runFirewallContract(
        address caller,
        address snapshotAddr,
        address contractAddr,
        TransactionEventsLib.EventData[] memory events
    ) public override {
      
        // // snapshotContract is the contract in its state from before the start of the transaction.
        // VulnERC20 snapshotContract = VulnERC20(snapshotAddr);

        // // // currentContract is the current account, with its current state
        // VulnERC20 currentContract = VulnERC20(contractAddr);

        // AllowanceUpdated memory allowUpd = initializeUpdatedAllowance();
        // BalanceUpdated memory balUpd = initializeUpdatedBalance();
        // LatestApprovalDetails memory lad;

        // // evaluate all the Events
        // for (uint256 i = 0; i < events.length; i++) {
        //     if (events[i].eventSigHash == erc20ApprovalEventSig) {
        //         // here: Approval
        //         (allowUpd, lad) = processApprovalEvent(events[i], allowUpd);
        //         // event array start at 0, but it is the first event.
        //         lad.approvalEventNumber = i + 1;
        //     } else if (events[i].eventSigHash == erc20TransferEventSig) {
        //         // This is only required for because of TransferFrom Approval + Transfer event
        //         // could be easily simplified with better Event structuring.
        //         lad.transferFromEventNumber = i + 1;
        //         // event[i] is Transfer
                
        //         (balUpd, allowUpd, lad) = processTransferEvent(
        //             events[i],
        //             balUpd,
        //             allowUpd,
        //             lad
        //         );
        //     } else {
        //         revert("untracked event");
        //     }
        // }
        // // all the events ara processed in order emission in the EVM during Tx Execution.
        // // after each function call is verified and applied
        // // we compare the final results for:
        // // - balances
        // // - allowances
        // // - supply
        // verifyBalanceConsistency(currentContract, balUpd);
        // verifyAllowanceConsistency(currentContract, allowUpd);
        // //verifyBalanceSumConsistency(currentContract);
        // verifyTotalSupplyConsistency(currentContract);
    }

    function processApprovalEvent(
        TransactionEventsLib.EventData memory selfEvent,
        AllowanceUpdated memory allowUpd
    )
        internal
        
        returns (AllowanceUpdated memory, LatestApprovalDetails memory)
    {
        
        //events.
        address caller = address(selfEvent.caller);
        address owner = address(uint160(uint256(selfEvent.parameters[0])));
        address spender = address(uint160(uint256(selfEvent.parameters[1])));
        uint newAllowance = uint256(selfEvent.parameters[2]);
        uint prevAllowance = _allowances[owner][spender];
        
        if (newAllowance==type(uint256).max){
            _hasMaxApproval[owner][spender]=true;
        }

        verifyValidApprover(owner);
        allowUpd = updateAllowance(owner, spender, allowUpd);
        return (
            allowUpd,
            setupLatestApprovalDetails(
                owner,
                spender,
                prevAllowance,
                newAllowance
            )
        );
    }

    function setupLatestApprovalDetails(
        address owner,
        address spender,
        uint prevAllowance,
        uint newAllowance
    ) internal pure returns (LatestApprovalDetails memory) {
        return
            LatestApprovalDetails(
                0,
                0,
                prevAllowance,
                newAllowance,
                owner,
                spender
            );
    }

    function processTransferEvent(
        TransactionEventsLib.EventData memory selfEvent,
        BalanceUpdated memory balUpd,
        AllowanceUpdated memory allowanceUpd,
        LatestApprovalDetails memory lad
    )
        internal
        returns (
            BalanceUpdated memory,
            AllowanceUpdated memory,
            LatestApprovalDetails memory
        )
    {
        address caller = selfEvent.caller; //msg.sender in the context if the triggered event
        address from = address(uint160(uint256(selfEvent.parameters[0])));
        address to = address(uint160(uint256(selfEvent.parameters[1])));
        uint amount = uint(selfEvent.parameters[2]);
        if (isTransfer(caller, from)) {
            verifyTransferPreconditions(from, to, amount);
            balUpd = applyTransferChanges(from, to, amount, balUpd);
        }
        else if (isTransferFrom(caller, from)) {
            verifyTransferFromFollowsApproval(from, to, amount, lad);
            balUpd = applyTransferFromChanges(from, to, amount, balUpd);
        }
       else  if (isMint(from)) {
            // here: Minting event
            verifyMintPreconditions(to);
            applyMintChanges(from, to, amount, balUpd);
        }
        else if (isBurn(to)) {
            // here: Burn event
            verifyBurnPreconditions(to);
            updateSupply(amount, false);
        }
        return (balUpd, allowanceUpd, lad);
    }

    function verifyMintPreconditions(address to) internal pure {
        verifyValidReceiver(to);
    }

    function verifyBurnPreconditions(address from) internal pure {
        verifyValidSender(from);
    }

    function verifyTransferPreconditions(
        address from,
        address to,
        uint amount
    ) internal view {
        verifyValidSender(from);
        verifyValidReceiver(to);
        verifyEnoughBalance(from, amount);
    }

    function applyMintChanges(
        address from,
        address to,
        uint amount,
        BalanceUpdated memory balUpd
    ) internal {
        updateSupply(amount, true);
        updateBalances(from, to, amount);
        trackBalance(from, to, balUpd);
    }

    function applyTransferChanges(
        address from,
        address to,
        uint amount,
        BalanceUpdated memory balUpd
    ) internal returns (BalanceUpdated memory) {
        updateBalances(from, to, amount);
        return trackBalance(from, to, balUpd);
    }

    function verifyEnoughApproval(
        address owner,
        address spender,
        uint amount
    ) internal {}

    function verifyTransferFromFollowsApproval(
        address owner,
        address spender,
        uint amount,
        LatestApprovalDetails memory lad
    ) internal view {
        if (_hasMaxApproval[owner][spender]){
            // 
        }
        address ownerInPrevApprovalEvent = lad.owner;
        address spenderInPrevApprovalEvent = lad.spender;
        uint currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            // here: currentAllowance not max
            // assumption: it had to be updated in an approval event just before the current transferevent
            if (
                (lad.approvalEventNumber == lad.transferFromEventNumber - 1) &&
                (ownerInPrevApprovalEvent == owner &&
                    spenderInPrevApprovalEvent == spender)
            ) {
                // here: previous event is an approvel from the same approver and same spender
                //  assumption: check if the allowance as been calculated according to the expected logic
                if (currentAllowance != lad.prevAllowance - amount) {
                    // here: the allowance calculation dont respect the specs.
                    revert(
                        "DecentralizedFirewall: Approval deduction inconsistent."
                    );
                }
            } else {
                // here:  the last approval is not followed by the current transfer event. example Approval Transfer Tranfer event
                // and the allowance isnt infinity.
                // conclusion: the approval should have been exec
                revert(
                    "DecentralizedFirewall: Allowances not updated when using 'transferFrom'"
                );

                // here: either the last approval is not
            }
        } else {
            // here:        the current allowance is max.
            if (
                (lad.approvalEventNumber == lad.transferFromEventNumber - 1) &&
                (ownerInPrevApprovalEvent == owner &&
                    spenderInPrevApprovalEvent == spender)
            ) {
                if (lad.newAllowance != type(uint256).max) {
                    revert(
                        "DecentralizedFirewall: Previous approval and current allowance dont match."
                    );
                }
            }
            // assumption:  we should check that if there is an approval with same approver and spender it should be an infinite one.
            // doable but would increase complexity considerably as we would need to keep track of all the approvals and iterate over them to check
            // for assessment.
            // NOTE: this is complexity only exists because of the logic and events used in ERC20.
            // This could be heavily simplified by making small changes in the ERC20 events.
            // or improving our execution logic
        }
    }

    function applyTransferFromChanges(
        address from,
        address to,
        uint amount,
        BalanceUpdated memory balUpd
    ) internal returns (BalanceUpdated memory) {
        updateBalances(from, to, amount);
        return trackBalance(from, to, balUpd);
    }

    function trackBalance(
        address from,
        address to,
        BalanceUpdated memory balUpd
    ) internal pure returns (BalanceUpdated memory) {
        uint index = balUpd.froms.length;
        balUpd.froms[index] = from;
        balUpd.tos[index] = to;
        return balUpd;
    }

    function isMint(address from) internal pure returns (bool) {
        return from == address(0);
    }

    function isTransfer(
        address caller,
        address from
    ) internal pure returns (bool) {
        return from == caller;
    }

    function isTransferFrom(
        address caller,
        address from
    ) internal pure returns (bool) {
        return from != caller;
    }

    function isBurn(address to) internal pure returns (bool) {
        return to == address(0);
    }

    function initializeUpdatedAllowance()
        internal
        pure
        returns (AllowanceUpdated memory allowanceUpdated)
    {
        address[] memory owner;
        address[] memory spender;

        allowanceUpdated = AllowanceUpdated(owner, spender);
    }

    function initializeUpdatedBalance()
        internal
        pure
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
    function updateBalances(address from, address to, uint amount) internal {
        if (from != address(0)) {
            _balances[from] -= amount;
        }
        _balances[to] += amount;
    }

    function updateAllowance(
        address owner,
        address spender,
        AllowanceUpdated memory allUpd
    ) internal pure returns (AllowanceUpdated memory) {
        uint index = allUpd.owners.length;
        allUpd.owners[index] = owner;
        allUpd.spenders[index] = spender;
        return allUpd;
    }

    function updateSupply(uint amount, bool isMintEvent) internal {
        // mint is transfer event with from == zero address
        if (isMintEvent) {
            // accumulate the minting amount
            _supply += amount;
        } else {
            // here: Burn
            _supply -= amount;
        }
    }

    //////////////////////////////////////////////////////////////
    //                     Security tests                       //
    //////////////////////////////////////////////////////////////
    function notZero(address addr, string memory revertMsg) internal pure {
        if (addr == address(0)) {
            revert(revertMsg);
        }
    }

    function verifyValidSender(address from) internal pure {
        notZero(from, "DecentralizedFirewall: Invalid sender");
    }

    function verifyValidReceiver(address to) internal pure {
        notZero(to, "DecentralizedFirewall: Invalid receiver");
    }

    // approval
    function verifyValidSpender(address spender) internal pure {
        notZero(spender, "DecentralizedFirewall: Invalid Spender");
    }

    function verifyValidApprover(address owner) internal pure {
        notZero(owner, "DecentralizedFirewall: Invalid Approver");
    }

    // given all the allowance events generated during the transaction,
    // we will iterate over them and apply the changes to the invariant state varibles
    function verifyApprovalConsistency(
        VulnERC20 currentContract,
        AllowanceUpdated memory allUpd
    ) internal view {
        // here: invariant varibles updated
        for (uint i = 0; i < allUpd.owners.length; i++) {
            // second time, compare currentCotnract and expected values here calculcated
            address owner = allUpd.owners[i];
            address spender = allUpd.spenders[i];
            if (
                _allowances[owner][spender] !=
                currentContract.allowance(owner, spender)
            ) {
                revert("DecentralizedFirewall: Invariant: approval not consistent.");
            }
        }
    }

    function verifyAllowanceConsistency(
        VulnERC20 currentContract,
        AllowanceUpdated memory allUpd
    ) internal view {
        // validat the allowance
        for (uint i = 0; i < allUpd.owners.length; i++) {
            address owner = allUpd.owners[i];
            address spender = allUpd.spenders[i];

            if (
                currentContract.allowance(owner, spender) !=
                _allowances[owner][spender]
            ) {
                revert(
                    "DecentralizedFirewall: updated allowances do not match expected allowances"
                );
            }
        }
    }

    /// @notice ensures consistency between specificaitons and balance management in the ERC20 this contract protects.
    /// @dev calculates expected results using the events emitted by the contract and compares with the actual changes done in the contract.
    /// @param currentContract, an ERC20 contract which doesnt implement security verifications.
    /// @param balUpd, a struct tracking all the balances updates that happened in the transaction extracted from ERC20 events.
    // Assumption, at the end of the EVM transaction, several Transfers, Mint, Burn events may have been done. After applying all the changes, in order, to the invariant state variables
    // We compare all the accounts that have been modified and compare to the expected state we calculated using the events, stored in the invariant state variables.
    function verifyBalanceConsistency(
        VulnERC20 currentContract,
        BalanceUpdated memory balUpd
    ) internal view {
        for (uint i = 0; i < balUpd.froms.length; i++) {
            // iterates over all the addresses that had a their balances modified.
            // TODO - Verify what events modify the balance
            address from = balUpd.froms[i];
            address to = balUpd.tos[i];
            if (
                // at the end of the EVM transaction.
                // compares the expected balance with calculated using invariants and emitted events.
                _balances[from] != currentContract.balanceOf(from) ||
                _balances[to] != currentContract.balanceOf(to)
            ) {
                // if they don't match means that the ERC20  contract does not respect specifications.
                // something went wrong and transaction should not proceed.
                revert(
                    "DecentralizedFirewall: Invariant: balances do not match, balances are not consistent."
                );
            }
        }
    }

    function verifySufficientBalance(address from, uint amount) internal view {
        if (_balances[from] < amount) {
            revert("DecentralizedFirewall: Invariant: insufficiant Balance ");
        }
    }

    function verifyTotalSupplyConsistency(
        VulnERC20 currentContract
    ) internal view {
        // compare the actual total supply in the erc20 contract
        // to the accumulated supply calculated from the mint events
        if (currentContract.totalSupply() != _supply) {
            // if supply calcaulted from the events and from the contract dont match, it measn the implementation was broken
            revert(
                "DecentralizedFirewall: Invariant: total supply is not consistent"
            );
        }
    }

    function verifyBalanceSumConsistency(
        address from,
        uint amount
    ) internal view {}

    function verifyEnoughBalance(address from, uint amount) internal view {
        if (_balances[from] < amount) {
            revert(
                "DecentralizedFirewall: Invariant: insufficient balance for transfer"
            );
        }
    }

    function verifyEnoughAllowance(
        address owner,
        address spender,
        uint value
    ) internal view {
        if (_allowances[owner][spender] < value) {
            revert("DecentralizedFirewall: Invariant: insufficient Allowance");
        }
    }
}
