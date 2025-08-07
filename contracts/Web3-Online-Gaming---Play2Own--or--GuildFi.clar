(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-TOKEN (err u101))
(define-constant ERR-TOURNAMENT-NOT-FOUND (err u102))
(define-constant ERR-ALREADY-JOINED (err u103))
(define-constant ERR-TOURNAMENT-FULL (err u104))
(define-constant ERR-TOURNAMENT-ENDED (err u105))
(define-constant ERR-INSUFFICIENT-FUNDS (err u106))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u107))
(define-constant ERR-ALREADY-VOTED (err u108))
(define-constant ERR-LISTING-NOT-FOUND (err u109))
(define-constant ERR-NOT-ASSET-OWNER (err u110))
(define-constant ERR-INVALID-PRICE (err u111))
(define-constant ERR-CANNOT-BUY-OWN-ASSET (err u112))

(define-non-fungible-token game-asset uint)
(define-fungible-token guild-token)

(define-data-var token-id-nonce uint u0)
(define-data-var tournament-id-nonce uint u0)
(define-data-var proposal-id-nonce uint u0)
(define-data-var listing-id-nonce uint u0)

(define-map asset-metadata uint {
    name: (string-ascii 32),
    rarity: (string-ascii 16),
    power: uint,
    game-type: (string-ascii 16)
})

(define-map tournaments uint {
    name: (string-ascii 32),
    entry-fee: uint,
    prize-pool: uint,
    max-players: uint,
    current-players: uint,
    winner: (optional principal),
    is-active: bool,
    end-block: uint
})

(define-map tournament-players {tournament-id: uint, player: principal} bool)

(define-map loot-pools principal {
    staked-amount: uint,
    rewards-earned: uint,
    last-claim-block: uint
})

(define-map dao-proposals uint {
    title: (string-ascii 64),
    description: (string-ascii 256),
    proposer: principal,
    votes-for: uint,
    votes-against: uint,
    end-block: uint,
    executed: bool
})

(define-map dao-votes {proposal-id: uint, voter: principal} bool)

(define-map marketplace-listings uint {
    seller: principal,
    token-id: uint,
    price-stx: uint,
    price-guild: uint,
    currency-type: (string-ascii 8),
    is-active: bool,
    listed-block: uint
})

(define-map asset-listings {token-id: uint} uint)

(define-public (mint-asset (recipient principal) (name (string-ascii 32)) (rarity (string-ascii 16)) (power uint) (game-type (string-ascii 16)))
    (let ((token-id (+ (var-get token-id-nonce) u1)))
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (try! (nft-mint? game-asset token-id recipient))
        (map-set asset-metadata token-id {
            name: name,
            rarity: rarity,
            power: power,
            game-type: game-type
        })
        (var-set token-id-nonce token-id)
        (ok token-id)
    )
)

(define-public (transfer-asset (token-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
        (nft-transfer? game-asset token-id sender recipient)
    )
)

(define-public (create-tournament (name (string-ascii 32)) (entry-fee uint) (max-players uint) (duration uint))
    (let ((tournament-id (+ (var-get tournament-id-nonce) u1)))
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (map-set tournaments tournament-id {
            name: name,
            entry-fee: entry-fee,
            prize-pool: u0,
            max-players: max-players,
            current-players: u0,
            winner: none,
            is-active: true,
            end-block: (+ stacks-block-height duration)
        })
        (var-set tournament-id-nonce tournament-id)
        (ok tournament-id)
    )
)

(define-public (join-tournament (tournament-id uint))
    (let ((tournament (unwrap! (map-get? tournaments tournament-id) ERR-TOURNAMENT-NOT-FOUND)))
        (asserts! (get is-active tournament) ERR-TOURNAMENT-ENDED)
        (asserts! (< (get current-players tournament) (get max-players tournament)) ERR-TOURNAMENT-FULL)
        (asserts! (is-none (map-get? tournament-players {tournament-id: tournament-id, player: tx-sender})) ERR-ALREADY-JOINED)
        (asserts! (>= (ft-get-balance guild-token tx-sender) (get entry-fee tournament)) ERR-INSUFFICIENT-FUNDS)
        
        (try! (ft-transfer? guild-token (get entry-fee tournament) tx-sender (as-contract tx-sender)))
        (map-set tournament-players {tournament-id: tournament-id, player: tx-sender} true)
        (map-set tournaments tournament-id (merge tournament {
            current-players: (+ (get current-players tournament) u1),
            prize-pool: (+ (get prize-pool tournament) (get entry-fee tournament))
        }))
        (ok true)
    )
)

(define-public (declare-winner (tournament-id uint) (winner principal))
    (let ((tournament (unwrap! (map-get? tournaments tournament-id) ERR-TOURNAMENT-NOT-FOUND)))
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (asserts! (get is-active tournament) ERR-TOURNAMENT-ENDED)
        
        (try! (as-contract (ft-transfer? guild-token (get prize-pool tournament) tx-sender winner)))
        (map-set tournaments tournament-id (merge tournament {
            winner: (some winner),
            is-active: false
        }))
        (ok true)
    )
)

(define-public (stake-in-loot-pool (amount uint))
    (let ((current-pool (default-to {staked-amount: u0, rewards-earned: u0, last-claim-block: stacks-block-height} 
                                   (map-get? loot-pools tx-sender))))
        (asserts! (>= (ft-get-balance guild-token tx-sender) amount) ERR-INSUFFICIENT-FUNDS)
        (try! (ft-transfer? guild-token amount tx-sender (as-contract tx-sender)))
        (map-set loot-pools tx-sender {
            staked-amount: (+ (get staked-amount current-pool) amount),
            rewards-earned: (get rewards-earned current-pool),
            last-claim-block: stacks-block-height
        })
        (ok true)
    )
)

(define-public (claim-loot-rewards)
    (let ((pool-data (unwrap! (map-get? loot-pools tx-sender) ERR-INSUFFICIENT-FUNDS)))
        (let ((blocks-staked (- stacks-block-height (get last-claim-block pool-data)))
              (rewards (/ (* (get staked-amount pool-data) blocks-staked) u1000)))
            (try! (ft-mint? guild-token rewards tx-sender))
            (map-set loot-pools tx-sender (merge pool-data {
                rewards-earned: (+ (get rewards-earned pool-data) rewards),
                last-claim-block: stacks-block-height
            }))
            (ok rewards)
        )
    )
)

(define-public (create-dao-proposal (title (string-ascii 64)) (description (string-ascii 256)) (duration uint))
    (let ((proposal-id (+ (var-get proposal-id-nonce) u1)))
        (asserts! (>= (ft-get-balance guild-token tx-sender) u100) ERR-INSUFFICIENT-FUNDS)
        (map-set dao-proposals proposal-id {
            title: title,
            description: description,
            proposer: tx-sender,
            votes-for: u0,
            votes-against: u0,
            end-block: (+ stacks-block-height duration),
            executed: false
        })
        (var-set proposal-id-nonce proposal-id)
        (ok proposal-id)
    )
)

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
    (let ((proposal (unwrap! (map-get? dao-proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
          (voting-power (ft-get-balance guild-token tx-sender)))
        (asserts! (< stacks-block-height (get end-block proposal)) ERR-TOURNAMENT-ENDED)
        (asserts! (is-none (map-get? dao-votes {proposal-id: proposal-id, voter: tx-sender})) ERR-ALREADY-VOTED)
        (asserts! (> voting-power u0) ERR-INSUFFICIENT-FUNDS)
        
        (map-set dao-votes {proposal-id: proposal-id, voter: tx-sender} true)
        (if vote-for
            (map-set dao-proposals proposal-id (merge proposal {
                votes-for: (+ (get votes-for proposal) voting-power)
            }))
            (map-set dao-proposals proposal-id (merge proposal {
                votes-against: (+ (get votes-against proposal) voting-power)
            }))
        )
        (ok true)
    )
)

(define-public (mint-guild-tokens (recipient principal) (amount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (ft-mint? guild-token amount recipient)
    )
)

(define-private (calculate-suggested-price (token-id uint))
    (let ((metadata (unwrap! (map-get? asset-metadata token-id) u0)))
        (let ((base-price u100)
              (power-multiplier (get power metadata))
              (rarity-bonus (if (is-eq (get rarity metadata) "legendary") u500
                            (if (is-eq (get rarity metadata) "epic") u300
                            (if (is-eq (get rarity metadata) "rare") u150
                            u50)))))
            (+ base-price (* power-multiplier u10) rarity-bonus)
        )
    )
)

(define-public (list-asset-for-sale (token-id uint) (price uint) (currency (string-ascii 8)))
    (let ((listing-id (+ (var-get listing-id-nonce) u1))
          (asset-owner (unwrap! (nft-get-owner? game-asset token-id) ERR-INVALID-TOKEN)))
        (asserts! (is-eq tx-sender asset-owner) ERR-NOT-ASSET-OWNER)
        (asserts! (> price u0) ERR-INVALID-PRICE)
        (asserts! (is-none (map-get? asset-listings {token-id: token-id})) ERR-ALREADY-JOINED)
        (asserts! (or (is-eq currency "STX") (is-eq currency "GUILD")) ERR-INVALID-PRICE)
        
        (let ((price-stx (if (is-eq currency "STX") price u0))
              (price-guild (if (is-eq currency "GUILD") price u0)))
            (map-set marketplace-listings listing-id {
                seller: tx-sender,
                token-id: token-id,
                price-stx: price-stx,
                price-guild: price-guild,
                currency-type: currency,
                is-active: true,
                listed-block: stacks-block-height
            })
            (map-set asset-listings {token-id: token-id} listing-id)
            (var-set listing-id-nonce listing-id)
            (ok listing-id)
        )
    )
)

(define-public (cancel-listing (listing-id uint))
    (let ((listing (unwrap! (map-get? marketplace-listings listing-id) ERR-LISTING-NOT-FOUND)))
        (asserts! (is-eq tx-sender (get seller listing)) ERR-NOT-AUTHORIZED)
        (asserts! (get is-active listing) ERR-TOURNAMENT-ENDED)
        
        (map-set marketplace-listings listing-id (merge listing {is-active: false}))
        (map-delete asset-listings {token-id: (get token-id listing)})
        (ok true)
    )
)

(define-public (buy-asset (listing-id uint))
    (let ((listing (unwrap! (map-get? marketplace-listings listing-id) ERR-LISTING-NOT-FOUND)))
        (asserts! (get is-active listing) ERR-TOURNAMENT-ENDED)
        (asserts! (not (is-eq tx-sender (get seller listing))) ERR-CANNOT-BUY-OWN-ASSET)
        
        (let ((token-id (get token-id listing))
              (seller (get seller listing))
              (currency (get currency-type listing)))
            (if (is-eq currency "STX")
                (let ((price (get price-stx listing)))
                    (try! (stx-transfer? price tx-sender seller))
                    (try! (nft-transfer? game-asset token-id seller tx-sender))
                    (map-set marketplace-listings listing-id (merge listing {is-active: false}))
                    (map-delete asset-listings {token-id: token-id})
                    (ok true)
                )
                (let ((price (get price-guild listing)))
                    (asserts! (>= (ft-get-balance guild-token tx-sender) price) ERR-INSUFFICIENT-FUNDS)
                    (try! (ft-transfer? guild-token price tx-sender seller))
                    (try! (nft-transfer? game-asset token-id seller tx-sender))
                    (map-set marketplace-listings listing-id (merge listing {is-active: false}))
                    (map-delete asset-listings {token-id: token-id})
                    (ok true)
                )
            )
        )
    )
)

(define-read-only (get-asset-metadata (token-id uint))
    (map-get? asset-metadata token-id)
)

(define-read-only (get-tournament-info (tournament-id uint))
    (map-get? tournaments tournament-id)
)

(define-read-only (get-loot-pool-info (player principal))
    (map-get? loot-pools player)
)

(define-read-only (get-dao-proposal (proposal-id uint))
    (map-get? dao-proposals proposal-id)
)

(define-read-only (get-asset-owner (token-id uint))
    (nft-get-owner? game-asset token-id)
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
    (is-some (map-get? dao-votes {proposal-id: proposal-id, voter: voter}))
)

(define-read-only (is-tournament-player (tournament-id uint) (player principal))
    (is-some (map-get? tournament-players {tournament-id: tournament-id, player: player}))
)

(define-read-only (get-marketplace-listing (listing-id uint))
    (map-get? marketplace-listings listing-id)
)

(define-read-only (get-asset-listing (token-id uint))
    (map-get? asset-listings {token-id: token-id})
)

(define-read-only (get-suggested-price (token-id uint))
    (calculate-suggested-price token-id)
)
