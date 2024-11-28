;; title: stx-insurance-protocol-manual-block

;; Decentralized Insurance Protocol with Manual Block Tracking
;; A comprehensive insurance platform on the Stacks blockchain

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INSUFFICIENT-FUNDS (err u2))
(define-constant ERR-POLICY-NOT-FOUND (err u3))
(define-constant ERR-INVALID-CLAIM (err u4))
(define-constant ERR-ALREADY-CLAIMED (err u5))
(define-constant ERR-INVALID-BLOCK (err u6))

;; Manual Block Height Tracking
(define-data-var current-block-height uint u0)
(define-data-var next-policy-id uint u1)


;; Function to manually update block height
(define-public (update-block-height (new-height uint))
  (begin
    ;; Only contract owner can update block height
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)

    ;; Ensure new height is greater than current height
    (asserts! (> new-height (var-get current-block-height)) ERR-INVALID-BLOCK)

    (var-set current-block-height new-height)
    (ok true)
  )
)

;; Insurance Policy Structure
(define-map insurance-policies 
  { 
    policy-id: uint, 
    owner: principal 
  }
  {
    coverage-type: (string-ascii 50),
    premium: uint,
    coverage-amount: uint,
    start-block: uint,
    expiry-block: uint,
    is-active: bool
  }
)

;; Claims Tracking
(define-map insurance-claims
  {
    policy-id: uint,
    claimer: principal
  }
  {
    claim-amount: uint,
    claim-status: (string-ascii 20),
    claim-block: uint,
    approved: bool
  }
)

;; Risk Pool for Collective Insurance
(define-data-var risk-pool uint u0)

;; Premium Accumulation Pool
(define-data-var premium-pool uint u0)

;; Create an Insurance Policy
(define-public (create-policy 
  (coverage-type (string-ascii 50))
  (coverage-amount uint)
  (premium uint)
  (policy-duration uint)
)
  (let (
    (policy-id (var-get next-policy-id))
    (current-block (var-get current-block-height))
  )
  (begin
    ;; Validate premium and coverage
    (asserts! (> coverage-amount u0) ERR-INSUFFICIENT-FUNDS)
    (asserts! (> premium u0) ERR-INSUFFICIENT-FUNDS)

    ;; Transfer premium to contract
    (try! (stx-transfer? premium tx-sender (as-contract tx-sender)))

    ;; Create policy entry
    (map-set insurance-policies 
      { policy-id: policy-id, owner: tx-sender }
      {
        coverage-type: coverage-type,
        premium: premium,
        coverage-amount: coverage-amount,
        start-block: current-block,
        expiry-block: (+ current-block policy-duration),
        is-active: true
      }
    )

    ;; Update premium pool
    (var-set premium-pool (+ (var-get premium-pool) premium))

    ;; Increment policy ID
    (var-set next-policy-id (+ policy-id u1))

    (ok policy-id)
  ))
)

;; Submit an Insurance Claim
(define-public (submit-claim 
  (policy-id uint)
  (claim-amount uint)
)
  (let (
    (policy (unwrap! 
      (map-get? insurance-policies 
        { policy-id: policy-id, owner: tx-sender }
      ) 
      ERR-POLICY-NOT-FOUND
    ))
    (current-block (var-get current-block-height))
  )
  (begin
    ;; Validate policy is active
    (asserts! (get is-active policy) ERR-INVALID-CLAIM)

    ;; Check policy hasn't expired
    (asserts! (< current-block (get expiry-block policy)) ERR-INVALID-CLAIM)

    ;; Check claim amount doesn't exceed coverage
    (asserts! (<= claim-amount (get coverage-amount policy)) ERR-INVALID-CLAIM)

    ;; Check no previous claim exists
    (asserts! 
      (is-none 
        (map-get? insurance-claims 
          { policy-id: policy-id, claimer: tx-sender }
        )
      ) 
      ERR-ALREADY-CLAIMED
    )

    ;; Record claim
    (map-set insurance-claims
      { policy-id: policy-id, claimer: tx-sender }
      {
        claim-amount: claim-amount,
        claim-status: "PENDING",
        claim-block: current-block,
        approved: false
      }
    )

    (ok true)
  ))
)

;; Approve or Reject Claim (Only by DAO or Governance)
(define-public (process-claim 
  (policy-id uint)
  (claimer principal)
  (is-approved bool)
)
  (let (
    (claim (unwrap! 
      (map-get? insurance-claims 
        { policy-id: policy-id, claimer: claimer }
      ) 
      ERR-POLICY-NOT-FOUND
    ))
    (policy (unwrap! 
      (map-get? insurance-policies 
        { policy-id: policy-id, owner: claimer }
      ) 
      ERR-POLICY-NOT-FOUND
    ))
  )
  (begin
    ;; Ensure only contract owner can process claims (can be replaced with DAO mechanism)
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)

    ;; Update claim status
    (map-set insurance-claims
      { policy-id: policy-id, claimer: claimer }
      (merge claim { 
        claim-status: (if is-approved "APPROVED" "REJECTED"),
        approved: is-approved 
      })
    )

    ;; If approved, transfer funds
    (if is-approved
      (try! (as-contract (stx-transfer? (get claim-amount claim) tx-sender claimer)))
      false
    )

    (ok true)
  ))
)

;; Withdraw Expired Premiums
(define-public (withdraw-expired-premiums)
  (begin
    ;; Only contract owner can withdraw
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)

    ;; Transfer accumulated premiums
    (try! (as-contract (stx-transfer? (var-get premium-pool) tx-sender CONTRACT-OWNER)))

    ;; Reset premium pool
    (var-set premium-pool u0)

    (ok true)
  ))


;; Contract Initialization
(define-private (initialize)
  (begin
    (var-set next-policy-id u1)
    (var-set premium-pool u0)
    (var-set current-block-height u1)
    true
  )
)
