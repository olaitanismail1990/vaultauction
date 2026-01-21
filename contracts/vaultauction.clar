;; ============================================================
;; Contract Name: vault-auction-dao
;; Description:
;; A full Clarity smart contract implementing:
;; - Secure STX vault (deposit & withdraw)
;; - Time-based auctions
;; - DAO-controlled parameter updates
;; - Reputation & activity tracking
;; - Fee collection treasury
;; ============================================================

;; -------------------------
;; Errors
;; -------------------------
(define-constant ERR-AUTH (err u1))
(define-constant ERR-NOT-FOUND (err u2))
(define-constant ERR-STATE (err u3))
(define-constant ERR-BALANCE (err u4))

;; -------------------------
;; Data Variables
;; -------------------------
(define-data-var auction-count uint u0)
(define-data-var dao-fee uint u25) ;; 2.5% default fee
(define-data-var treasury uint u0)

;; -------------------------
;; Maps
;; -------------------------

;; User vault balances
(define-map vault principal uint)

;; User reputation
(define-map reputation principal uint)

;; Auctions
(define-map auctions
  uint
  {
    seller: principal,
    highest-bidder: (optional principal),
    highest-bid: uint,
    end-block: uint,
    settled: bool
  }
)

;; DAO votes for fee change
(define-map fee-votes principal uint)

;; -------------------------
;; Private Helpers
;; -------------------------

(define-private (add-rep (user principal))
  (let ((current (default-to u0 (map-get? reputation user))))
    (map-set reputation user (+ current u1))))

;; -------------------------
;; Vault Functions
;; -------------------------

(define-public (deposit (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set vault tx-sender (+ (default-to u0 (map-get? vault tx-sender)) amount))
    (ok true)))

(define-public (withdraw (amount uint))
  (let ((balance (default-to u0 (map-get? vault tx-sender))))
    (if (< balance amount)
        ERR-BALANCE
        (begin
          (map-set vault tx-sender (- balance amount))
          (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
          (ok true)))))

;; -------------------------
;; Auction Functions
;; -------------------------

(define-public (create-auction (starting-bid uint) (duration uint))
  (let ((id (+ (var-get auction-count) u1)))
    (begin
      (map-set auctions id {
        seller: tx-sender,
        highest-bidder: none,
        highest-bid: starting-bid,
        end-block: (+ burn-block-height duration),
        settled: false
      })
      (var-set auction-count id)
      (ok id))))

(define-public (bid (auction-id uint) (amount uint))
  (let ((auction (unwrap! (map-get? auctions auction-id) ERR-NOT-FOUND)))
    (if (or (>= burn-block-height (get end-block auction))
            (<= amount (get highest-bid auction)))
        ERR-STATE
        (let ((balance (default-to u0 (map-get? vault tx-sender))))
          (if (< balance amount)
              ERR-BALANCE
              (begin
                (map-set vault tx-sender (- balance amount))
                (if (is-some (get highest-bidder auction))
                    (map-set vault
                      (unwrap-panic (get highest-bidder auction))
                      (+ (default-to u0 (map-get? vault (unwrap-panic (get highest-bidder auction))))
                         (get highest-bid auction)))
                    true)
                (map-set auctions auction-id
                  (merge auction {highest-bidder: (some tx-sender), highest-bid: amount}))
                (ok true)))))))

(define-public (settle-auction (auction-id uint))
  (let ((auction (unwrap! (map-get? auctions auction-id) ERR-NOT-FOUND)))
    (if (or (< burn-block-height (get end-block auction)) (get settled auction))
        ERR-STATE
        (begin
          (map-set auctions auction-id (merge auction {settled: true}))
          (if (is-some (get highest-bidder auction))
              (let ((fee (/ (* (get highest-bid auction) (var-get dao-fee)) u1000))
                    (payout (- (get highest-bid auction)
                               (/ (* (get highest-bid auction) (var-get dao-fee)) u1000))))
                (var-set treasury (+ (var-get treasury) fee))
                (try! (stx-transfer? payout (as-contract tx-sender) (get seller auction)))
                (add-rep (unwrap-panic (get highest-bidder auction)))
                (add-rep (get seller auction)))
              true)
          (ok true)))))

;; -------------------------
;; DAO Fee Governance
;; -------------------------

(define-public (vote-fee (new-fee uint))
  (begin
    (map-set fee-votes tx-sender new-fee)
    (ok true)))

(define-public (apply-fee (new-fee uint))
  (let ((votes (map-get? fee-votes tx-sender)))
    (if (is-none votes)
        ERR-AUTH
        (begin
          (var-set dao-fee new-fee)
          (ok true)))))

;; -------------------------
;; Read-only Functions
;; -------------------------

(define-read-only (get-vault (user principal))
  (default-to u0 (map-get? vault user)))

(define-read-only (get-reputation (user principal))
  (default-to u0 (map-get? reputation user)))

(define-read-only (get-auction (auction-id uint))
  (map-get? auctions auction-id))

;; ============================================================
;; End of vault-auction-dao
;; ============================================================
