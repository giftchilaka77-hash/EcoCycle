;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  EcoCycle Protocol
;;  Functionality: Decentralized Recycling Reward System
;;  Description: Incentivizes recycling with token rewards for verified deposits.
;;  Author: [Your Name]
;;  Submitted to: Code-for-STX
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ------------------------------------------------------------
;; CONSTANTS & GLOBAL VARIABLES
;; ------------------------------------------------------------

(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_REGISTERED (err u101))
(define-constant ERR_NOT_FOUND (err u102))

(define-data-var owner principal tx-sender)
(define-data-var deposit-counter uint u0)

;; ------------------------------------------------------------
;; DATA STRUCTURES
;; ------------------------------------------------------------

(define-map recyclers
  {user: principal}
  {total-weight: uint, is-verified: bool})

(define-map deposits
  {id: uint}
  {user: principal, material: (string-ascii 30), weight: uint, verified: bool})

(define-fungible-token eco-token)

;; ------------------------------------------------------------
;; ADMIN FUNCTIONS
;; ------------------------------------------------------------

(define-public (initialize)
  (begin
    (if (is-eq (var-get owner) tx-sender)
        (ok "Already initialized")
        (begin
          (var-set owner tx-sender)
          (ok "EcoCycle Protocol initialized successfully")
        )
    )
  )
)

(define-public (register-recycler (user principal))
  (begin
    (if (is-eq tx-sender (var-get owner))
        (begin
          (map-set recyclers {user: user} {total-weight: u0, is-verified: true})
          (ok "Recycler registered successfully")
        )
        ERR_UNAUTHORIZED
    )
  )
)

;; ------------------------------------------------------------
;; RECYCLER FUNCTIONS
;; ------------------------------------------------------------

(define-public (submit-deposit (material (string-ascii 30)) (weight uint))
  (let ((user tx-sender))
    (if (is-some (map-get? recyclers {user: user}))
        (let ((id (+ (var-get deposit-counter) u1)))
          (begin
            (map-set deposits
              {id: id}
              {user: user, material: material, weight: weight, verified: false})
            (var-set deposit-counter id)
            (ok id)
          )
        )
        ERR_NOT_REGISTERED
    )
  )
)

;; ------------------------------------------------------------
;; VERIFICATION & REWARDS
;; ------------------------------------------------------------

(define-public (verify-deposit (id uint))
  (let ((record (map-get? deposits {id: id})))
    (if (is-some record)
        (let ((data (unwrap-panic record)))
          (begin
            (map-set deposits {id: id} (merge data {verified: true}))
            (mint-reward (get user data) (get weight data))
          )
        )
        ERR_NOT_FOUND
    )
  )
)

(define-private (mint-reward (recipient principal) (amount uint))
  (match (ft-mint? eco-token amount recipient)
    success (ok success)
    error (err error)
  )
)

;; ------------------------------------------------------------
;; READ-ONLY FUNCTIONS
;; ------------------------------------------------------------

(define-read-only (get-deposit (id uint))
  (map-get? deposits {id: id})
)

(define-read-only (get-recycler (user principal))
  (map-get? recyclers {user: user})
)

(define-read-only (get-total-deposits)
  (var-get deposit-counter)
)
