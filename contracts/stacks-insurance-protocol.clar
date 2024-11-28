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
