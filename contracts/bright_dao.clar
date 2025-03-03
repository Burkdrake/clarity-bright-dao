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
(define-constant err-invalid-amount (err u108))
(define-constant minimum-application-window u24)
(define-constant maximum-application-window u5000)
(define-constant minimum-scholarship-amount u100)
(define-constant maximum-scholarship-amount u1000000)

;; Data Variables 
(define-data-var dao-name (string-ascii 50) "BrightDAO")
(define-data-var total-funds uint u0)
(define-data-var total-scholarships uint u0)
(define-data-var total-applications uint u0)

(define-public (create-scholarship (name (string-ascii 100)) (amount uint) (criteria (string-ascii 500)) (deadline uint))
    (let ((scholarship-id (+ (var-get total-scholarships) u1)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (>= deadline (+ block-height minimum-application-window)) err-invalid-deadline)
        (asserts! (<= deadline (+ block-height maximum-application-window)) err-invalid-deadline)
        (asserts! (and (>= amount minimum-scholarship-amount) 
                     (<= amount maximum-scholarship-amount)) 
                err-invalid-amount)
        
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
)
