# STX Insurance Protocol Manual Block Tracking

The STX Insurance Protocol is a decentralized insurance platform deployed on the Stacks blockchain, enabling transparent, fair, and tamper-resistant insurance mechanisms. This smart contract provides comprehensive functionality for creating insurance policies, submitting claims, and managing payouts while incorporating manual block height tracking for enhanced flexibility and governance.

## Key Features

- **Decentralized Insurance Policies**: Users can create policies with customizable coverage amounts, premiums, and durations.
- **Manual Block Tracking**: Block height is tracked manually within the contract, allowing governance to control the progression of time-sensitive operations.
- **Transparent Claims Processing**: Submit, track, and process claims with detailed logging and DAO-ready governance mechanisms.
- **Risk and Premium Pools**: Maintain separate pools for collective risk and accumulated premiums, ensuring sustainable payouts.
- **Built on Stacks Blockchain**: Leveraging the Stacks blockchain ensures security, transparency, and Bitcoin finality.

## How It Works

### Core Components

#### Policy Creation

- Users create policies by specifying the coverage type, coverage amount, premium, and policy duration (in blocks).
- Premium payments are transferred to the contract and added to the premium pool.

#### Claims Management

- Users can submit claims against their active policies.
- Claims are logged as PENDING and require governance (e.g., the contract owner or a DAO) to approve or reject them.

#### Manual Block Height

- The contract tracks block height manually through the `update-block-height` function. Only the contract owner can update this, ensuring controlled and accountable operations.

#### Premium and Risk Pools

- Premiums collected from policies are stored in the `premium-pool`.
- Risk payouts are managed directly from the contract.

#### Governance Mechanisms

- Restricted functions (e.g., processing claims, updating block height) are accessible only to the contract owner, providing a path for DAO integration.

## Contract Functions

### Public Functions

1. **Update Block Height**

    ```clojure
    (update-block-height (new-height uint))
    ```

    - **Purpose**: Updates the manually tracked block height.
    - **Access**: Contract owner only.
    - **Parameters**:
        - `new-height`: New block height to set.
    - **Errors**:
        - `ERR-UNAUTHORIZED`: If the sender is not the contract owner.
        - `ERR-INVALID-BLOCK`: If the new height is less than or equal to the current height.

2. **Create Policy**

    ```clojure
    (create-policy 
      (coverage-type (string-ascii 50)) 
      (coverage-amount uint) 
      (premium uint) 
      (policy-duration uint)
    )
    ```

    - **Purpose**: Creates a new insurance policy.
    - **Parameters**:
        - `coverage-type`: Description of the insurance coverage.
        - `coverage-amount`: Maximum payout amount.
        - `premium`: Premium to be paid for the policy.
        - `policy-duration`: Duration of the policy in blocks.
    - **Returns**: Policy ID.
    - **Errors**:
        - `ERR-INSUFFICIENT-FUNDS`: If the coverage amount or premium is zero.

3. **Submit Claim**

    ```clojure
    (submit-claim (policy-id uint) (claim-amount uint))
    ```

    - **Purpose**: Submits a claim against an active insurance policy.
    - **Parameters**:
        - `policy-id`: ID of the policy.
        - `claim-amount`: Amount to claim.
    - **Errors**:
        - `ERR-POLICY-NOT-FOUND`: If the policy does not exist or is not owned by the sender.
        - `ERR-INVALID-CLAIM`: If the policy is expired or inactive, or the claim exceeds coverage.
        - `ERR-ALREADY-CLAIMED`: If a claim has already been submitted.

4. **Process Claim**

    ```clojure
    (process-claim (policy-id uint) (claimer principal) (is-approved bool))
    ```

    - **Purpose**: Approves or rejects a submitted claim.
    - **Access**: Contract owner only.
    - **Parameters**:
        - `policy-id`: ID of the policy.
        - `claimer`: Principal of the claimer.
        - `is-approved`: Approval status (true or false).
    - **Errors**:
        - `ERR-UNAUTHORIZED`: If the sender is not the contract owner.

5. **Withdraw Expired Premiums**

    ```clojure
    (withdraw-expired-premiums)
    ```

    - **Purpose**: Withdraws accumulated premiums.
    - **Access**: Contract owner only.

## Data Structures

### Insurance Policies

Tracks policies with attributes like coverage type, premium, coverage amount, start and expiry block, and active status.

### Claims

Tracks claims with attributes like claim amount, status (PENDING, APPROVED, or REJECTED), and claim block.

### Pools

- **Risk Pool**: Reserved for collective insurance payouts.
- **Premium Pool**: Accumulated premiums from policies.

## Stacks Ecosystem Integration

### Why Stacks?

- **Smart Contracts with Bitcoin Security**: Stacks leverages the Clarity language for transparent and predictable smart contracts, anchored to Bitcoin.
- **Built-in Decentralization**: By operating on Stacks, this protocol inherits blockchain-based transparency and trust.
- **Cost-Efficiency**: The low gas fees of the Stacks ecosystem make insurance interactions affordable for all participants.

## Deployment

- **Stacks Blockchain**: The contract is deployed on the Stacks network, ensuring trustless execution and high security.
- **Clarity Language**: Written in Clarity, a decidable language that eliminates unexpected contract behavior.

## Governance and Roadmap

### Current Governance

The current implementation allows the contract owner to:

- Update the block height.
- Approve or reject claims.
- Withdraw expired premiums.

### Future Enhancements

- **DAO Integration**: Replace the contract owner role with a decentralized governance model.
- **Dynamic Risk Management**: Introduce algorithms for premium and risk pool adjustments based on real-time data.
- **Automated Block Tracking**: Allow optional reliance on Stacks’ native block height for block-sensitive operations.

## Getting Started

1. **Deploy Contract**: Deploy the smart contract on the Stacks blockchain using a compatible Clarity development environment.
2. **Initialize**: Use the `initialize` function to set up default variables.
3. **Create Policies**: Users can start creating policies by calling `create-policy`.
4. **Submit and Process Claims**: Claims can be submitted and reviewed by the governance mechanism.
