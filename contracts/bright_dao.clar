;; BrightDAO Contract
;; Manages decentralized scholarships

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-not-eligible (err u104))
(define-constant err-payment-failed (err u105))
(define-constant err-invalid-deadline (err u106))
(define-constant err-duplicate-application (err u107))

;; Data Variables 
(define-data-var dao-name (string-ascii 50) "BrightDAO")
(define-data-var total-funds uint u0)

;; Data Maps
(define-map scholarships
    { scholarship-id: uint }
    {
        name: (string-ascii 100),
        amount: uint,
        active: bool,
        criteria: (string-ascii 500),
        deadline: uint,
        distributed: bool
    }
)

(define-map applications
    { application-id: uint }
    {
        scholarship-id: uint,
        applicant: principal,
        status: (string-ascii 20),
        documents: (string-ascii 500),
        payout-txid: (optional (string-ascii 64)),
        timestamp: uint
    }
)

;; Track applicant's applications per scholarship
(define-map applicant-scholarship-applications
    { scholarship-id: uint, applicant: principal }
    { applied: bool }
)

(define-map donors
    { donor-id: principal }
    {
        total-donated: uint,
        last-donation: uint
    }
)

;; Funding Distribution
(define-map fund-distributions
    { distribution-id: uint }
    {
        scholarship-id: uint,
        recipient: principal,
        amount: uint,
        status: (string-ascii 20),
        timestamp: uint
    }
)

(define-data-var total-distributions uint u0)

;; Public Functions
(define-public (create-scholarship (name (string-ascii 100)) (amount uint) (criteria (string-ascii 500)) (deadline uint))
    (let ((scholarship-id (+ (var-get total-scholarships) u1)))
        (if (is-eq tx-sender contract-owner)
            (if (> deadline block-height)
                (begin
                    (map-set scholarships
                        { scholarship-id: scholarship-id }
                        {
                            name: name,
                            amount: amount,
                            active: true,
                            criteria: criteria,
                            deadline: deadline,
                            distributed: false
                        }
                    )
                    (var-set total-scholarships scholarship-id)
                    (ok scholarship-id)
                )
                err-invalid-deadline
            )
            err-owner-only
        )
    )
)

(define-public (apply-for-scholarship (scholarship-id uint) (documents (string-ascii 500)))
    (let (
        (application-id (+ (var-get total-applications) u1))
        (scholarship (unwrap! (map-get? scholarships {scholarship-id: scholarship-id}) err-not-found))
        (previous-application (map-get? applicant-scholarship-applications {scholarship-id: scholarship-id, applicant: tx-sender}))
    )
    (if (and (get active scholarship) 
             (> (get deadline scholarship) block-height)
             (is-none previous-application))
        (begin
            (map-set applications
                { application-id: application-id }
                {
                    scholarship-id: scholarship-id,
                    applicant: tx-sender,
                    status: "pending",
                    documents: documents,
                    payout-txid: none,
                    timestamp: block-height
                }
            )
            (map-set applicant-scholarship-applications
                {scholarship-id: scholarship-id, applicant: tx-sender}
                {applied: true}
            )
            (var-set total-applications application-id)
            (ok application-id)
        )
        (if (is-some previous-application)
            err-duplicate-application
            err-not-eligible
        )
    ))
)

[Rest of contract remains unchanged]
