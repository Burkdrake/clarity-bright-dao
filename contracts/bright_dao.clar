;; BrightDAO Contract
;; Manages decentralized scholarships

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-funds (err u103))
(define-constant err-not-eligible (err u104))

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
        deadline: uint
    }
)

(define-map applications
    { application-id: uint }
    {
        scholarship-id: uint,
        applicant: principal,
        status: (string-ascii 20),
        documents: (string-ascii 500)
    }
)

(define-map donors
    { donor-id: principal }
    {
        total-donated: uint,
        last-donation: uint
    }
)

;; Public Functions
(define-public (create-scholarship (name (string-ascii 100)) (amount uint) (criteria (string-ascii 500)) (deadline uint))
    (let ((scholarship-id (+ (var-get total-scholarships) u1)))
        (if (is-eq tx-sender contract-owner)
            (begin
                (map-set scholarships
                    { scholarship-id: scholarship-id }
                    {
                        name: name,
                        amount: amount,
                        active: true,
                        criteria: criteria,
                        deadline: deadline
                    }
                )
                (var-set total-scholarships scholarship-id)
                (ok scholarship-id)
            )
            err-owner-only
        )
    )
)

(define-public (apply-for-scholarship (scholarship-id uint) (documents (string-ascii 500)))
    (let (
        (application-id (+ (var-get total-applications) u1))
        (scholarship (unwrap! (map-get? scholarships {scholarship-id: scholarship-id}) err-not-found))
    )
    (if (get active scholarship)
        (begin
            (map-set applications
                { application-id: application-id }
                {
                    scholarship-id: scholarship-id,
                    applicant: tx-sender,
                    status: "pending",
                    documents: documents
                }
            )
            (var-set total-applications application-id)
            (ok application-id)
        )
        err-not-eligible
    ))
)

(define-public (donate-to-fund (amount uint))
    (let (
        (donor (default-to { total-donated: u0, last-donation: u0 }
            (map-get? donors {donor-id: tx-sender})))
    )
    (begin
        (map-set donors
            {donor-id: tx-sender}
            {
                total-donated: (+ (get total-donated donor) amount),
                last-donation: block-height
            }
        )
        (var-set total-funds (+ (var-get total-funds) amount))
        (ok true)
    ))
)

(define-public (approve-application (application-id uint))
    (let (
        (application (unwrap! (map-get? applications {application-id: application-id}) err-not-found))
        (scholarship (unwrap! (map-get? scholarships {scholarship-id: (get scholarship-id application)}) err-not-found))
    )
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set applications
                {application-id: application-id}
                (merge application {status: "approved"})
            )
            (ok true)
        )
        err-owner-only
    ))
)

;; Read Only Functions
(define-read-only (get-scholarship (scholarship-id uint))
    (ok (map-get? scholarships {scholarship-id: scholarship-id}))
)

(define-read-only (get-application (application-id uint))
    (ok (map-get? applications {application-id: application-id}))
)

(define-read-only (get-donor-info (donor-id principal))
    (ok (map-get? donors {donor-id: donor-id}))
)

;; Initialize Contract
(define-data-var total-scholarships uint u0)
(define-data-var total-applications uint u0)