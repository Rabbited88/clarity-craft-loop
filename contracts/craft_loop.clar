;; CraftLoop NFT Marketplace
(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-owner (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-wrong-price (err u103))
(define-constant err-already-listed (err u104))
(define-constant err-transfer-blocked (err u105))
(define-constant royalty-percentage u5) ;; 5% royalty

;; Data Variables
(define-data-var last-token-id uint u0)

;; NFT Definition
(define-non-fungible-token craft-nft uint)

;; Data Maps
(define-map token-metadata uint {
    name: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    uri: (optional (string-utf8 256))
})

(define-map listings uint {
    price: uint,
    seller: principal
})

;; Events
(define-public (print-nft-event (event-type (string-ascii 20)) (token-id uint) (sender principal) (recipient (optional principal)))
    (ok (print { event-type: event-type, token-id: token-id, sender: sender, recipient: recipient }))
)

;; SIP-009 Required Functions
(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

(define-read-only (get-token-owner (token-id uint))
    (ok (nft-get-owner? craft-nft token-id))
)

(define-read-only (get-token-uri (token-id uint))
    (ok none)
)

;; Transfer Function with Restrictions
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) err-not-owner)
        (asserts! (is-none (map-get? listings token-id)) err-transfer-blocked)
        (try! (nft-transfer? craft-nft token-id sender recipient))
        (try! (print-nft-event "transfer" token-id sender (some recipient)))
        (ok true)
    )
)

;; Mint new NFT
(define-public (mint-nft (name (string-ascii 100)) (description (string-ascii 500)) (price uint) (recipient principal))
    (let 
        ((token-id (+ (var-get last-token-id) u1)))
        (try! (nft-mint? craft-nft token-id recipient))
        (var-set last-token-id token-id)
        (map-set token-metadata token-id {
            name: name,
            description: description,
            creator: tx-sender,
            uri: none
        })
        (try! (print-nft-event "mint" token-id tx-sender (some recipient)))
        (ok token-id)
    )
)

;; List NFT for sale
(define-public (list-nft (token-id uint) (price uint))
    (let ((owner (unwrap! (nft-get-owner? craft-nft token-id) err-listing-not-found)))
        (asserts! (is-eq tx-sender owner) err-not-owner)
        (asserts! (is-none (map-get? listings token-id)) err-already-listed)
        (map-set listings token-id {
            price: price,
            seller: tx-sender
        })
        (try! (print-nft-event "list" token-id tx-sender none))
        (ok true)
    )
)

;; Purchase NFT with Royalties
(define-public (purchase-nft (token-id uint))
    (let (
        (listing (unwrap! (map-get? listings token-id) err-listing-not-found))
        (price (get price listing))
        (seller (get seller listing))
        (metadata (unwrap! (map-get? token-metadata token-id) err-listing-not-found))
        (creator (get creator metadata))
        (royalty (/ (* price royalty-percentage) u100))
        )
        (try! (stx-transfer? royalty tx-sender creator))
        (try! (stx-transfer? (- price royalty) tx-sender seller))
        (try! (nft-transfer? craft-nft token-id seller tx-sender))
        (map-delete listings token-id)
        (try! (print-nft-event "purchase" token-id seller (some tx-sender)))
        (ok true)
    )
)

[... rest of the original functions remain unchanged ...]
