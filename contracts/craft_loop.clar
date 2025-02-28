;; CraftLoop NFT Marketplace
(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-owner (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-wrong-price (err u103))
(define-constant err-already-listed (err u104))

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
        (ok true)
    )
)

;; Purchase NFT
(define-public (purchase-nft (token-id uint))
    (let ((listing (unwrap! (map-get? listings token-id) err-listing-not-found))
          (price (get price listing))
          (seller (get seller listing)))
        (try! (stx-transfer? price tx-sender seller))
        (try! (nft-transfer? craft-nft token-id seller tx-sender))
        (map-delete listings token-id)
        (ok true)
    )
)

;; Update listing price
(define-public (update-price (token-id uint) (new-price uint))
    (let ((listing (unwrap! (map-get? listings token-id) err-listing-not-found)))
        (asserts! (is-eq tx-sender (get seller listing)) err-not-owner)
        (map-set listings token-id {
            price: new-price,
            seller: tx-sender
        })
        (ok true)
    )
)

;; Remove listing
(define-public (remove-listing (token-id uint))
    (let ((listing (unwrap! (map-get? listings token-id) err-listing-not-found)))
        (asserts! (is-eq tx-sender (get seller listing)) err-not-owner)
        (map-delete listings token-id)
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-token-metadata (token-id uint))
    (map-get? token-metadata token-id)
)

(define-read-only (get-listing (token-id uint))
    (map-get? listings token-id)
)

(define-read-only (get-token-uri (token-id uint))
    (ok none)
)
