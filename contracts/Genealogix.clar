(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-ALREADY-EXISTS (err u402))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-DNA (err u405))
(define-constant ERR-INVALID-RELATIONSHIP (err u406))
(define-constant ERR-SELF-RELATIONSHIP (err u407))
(define-constant ERR-INVALID-ORACLE (err u408))

(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-data-var contract-owner principal tx-sender)

(define-map users principal {
    name: (string-ascii 50),
    birth-year: uint,
    gender: (string-ascii 10),
    dna-hash: (buff 32),
    verified: bool,
    created-at: uint
})

(define-map relationships {parent: principal, child: principal} {
    relationship-type: (string-ascii 20),
    verified: bool,
    created-at: uint,
    verified-by: (optional principal)
})

(define-map dna-matches principal (list 10 principal))

(define-map family-trees principal {
    generation: uint,
    ancestors: (list 20 principal),
    descendants: (list 50 principal)
})

(define-map oracle-submissions {submitter: principal, timestamp: uint} {
    dna-data: (buff 64),
    subject: principal,
    confidence: uint,
    processed: bool
})

(define-public (register-user (name (string-ascii 50)) (birth-year uint) (gender (string-ascii 10)) (dna-hash (buff 32)))
    (let ((caller tx-sender))
        (asserts! (is-none (map-get? users caller)) ERR-ALREADY-EXISTS)
        (asserts! (> (len name) u0) ERR-INVALID-DNA)
        (asserts! (> birth-year u1900) ERR-INVALID-DNA)
        (map-set users caller {
            name: name,
            birth-year: birth-year,
            gender: gender,
            dna-hash: dna-hash,
            verified: false,
            created-at: stacks-block-height
        })
        (map-set family-trees caller {
            generation: u0,
            ancestors: (list),
            descendants: (list)
        })
        (ok true)
    )
)

(define-public (add-relationship (child principal) (relationship-type (string-ascii 20)))
    (let ((parent tx-sender))
        (asserts! (not (is-eq parent child)) ERR-SELF-RELATIONSHIP)
        (asserts! (is-some (map-get? users parent)) ERR-NOT-FOUND)
        (asserts! (is-some (map-get? users child)) ERR-NOT-FOUND)
        (asserts! (is-none (map-get? relationships {parent: parent, child: child})) ERR-ALREADY-EXISTS)
        (map-set relationships {parent: parent, child: child} {
            relationship-type: relationship-type,
            verified: false,
            created-at: stacks-block-height,
            verified-by: none
        })
        (unwrap! (update-family-tree parent child) ERR-NOT-FOUND)
        (ok true)
    )
)

(define-public (verify-relationship (parent principal) (child principal))
    (let ((relationship-key {parent: parent, child: child}))
        (asserts! (is-some (map-get? relationships relationship-key)) ERR-NOT-FOUND)
        (map-set relationships relationship-key (merge (unwrap-panic (map-get? relationships relationship-key)) {
            verified: true,
            verified-by: (some tx-sender)
        }))
        (ok true)
    )
)

(define-public (submit-dna-oracle (subject principal) (dna-data (buff 64)) (confidence uint))
    (let ((caller tx-sender))
        (asserts! (is-eq caller (var-get oracle-address)) ERR-NOT-AUTHORIZED)
        (asserts! (<= confidence u100) ERR-INVALID-DNA)
        (asserts! (is-some (map-get? users subject)) ERR-NOT-FOUND)
        (map-set oracle-submissions {submitter: caller, timestamp: stacks-block-height} {
            dna-data: dna-data,
            subject: subject,
            confidence: confidence,
            processed: false
        })
        (unwrap! (process-dna-match subject dna-data) ERR-NOT-FOUND)
        (ok true)
    )
)

(define-public (set-oracle-address (new-oracle principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set oracle-address new-oracle)
        (ok true)
    )
)

(define-public (verify-user-dna (user principal))
    (let ((user-data (unwrap! (map-get? users user) ERR-NOT-FOUND)))
        (asserts! (is-eq tx-sender (var-get oracle-address)) ERR-NOT-AUTHORIZED)
        (map-set users user (merge user-data {verified: true}))
        (ok true)
    )
)

(define-private (update-family-tree (parent principal) (child principal))
    (let ((parent-tree (default-to {generation: u0, ancestors: (list), descendants: (list)} (map-get? family-trees parent)))
          (child-tree (default-to {generation: u0, ancestors: (list), descendants: (list)} (map-get? family-trees child))))
        (map-set family-trees parent (merge parent-tree {
            descendants: (unwrap-panic (as-max-len? (append (get descendants parent-tree) child) u50))
        }))
        (map-set family-trees child (merge child-tree {
            generation: (+ (get generation parent-tree) u1),
            ancestors: (unwrap-panic (as-max-len? (append (get ancestors child-tree) parent) u20))
        }))
        (ok true)
    )
)

(define-private (process-dna-match (subject principal) (dna-data (buff 64)))
    (let ((existing-matches (default-to (list) (map-get? dna-matches subject))))
        (ok true)
    )
)

(define-read-only (get-user (user principal))
    (map-get? users user)
)

(define-read-only (get-relationship (parent principal) (child principal))
    (map-get? relationships {parent: parent, child: child})
)

(define-read-only (get-family-tree (user principal))
    (map-get? family-trees user)
)

(define-read-only (get-children (parent principal))
    (let ((family-tree (map-get? family-trees parent)))
        (match family-tree 
            tree (some (get descendants tree))
            none
        )
    )
)

(define-read-only (get-parents (child principal))
    (let ((family-tree (map-get? family-trees child)))
        (match family-tree 
            tree (some (get ancestors tree))
            none
        )
    )
)

(define-read-only (get-generation (user principal))
    (let ((family-tree (map-get? family-trees user)))
        (match family-tree 
            tree (some (get generation tree))
            none
        )
    )
)

(define-read-only (is-related (user1 principal) (user2 principal))
    (let ((tree1 (map-get? family-trees user1))
          (tree2 (map-get? family-trees user2)))
        (match tree1
            t1 (match tree2
                t2 (or (is-some (index-of (get ancestors t1) user2))
                       (is-some (index-of (get descendants t1) user2))
                       (is-some (index-of (get ancestors t2) user1))
                       (is-some (index-of (get descendants t2) user1)))
                false)
            false)
    )
)

(define-read-only (get-common-ancestors (user1 principal) (user2 principal))
    (let ((tree1 (unwrap! (map-get? family-trees user1) (list)))
          (tree2 (unwrap! (map-get? family-trees user2) (list))))
        (filter common-ancestor (get ancestors tree1))
    )
)

(define-private (common-ancestor (ancestor principal))
    (let ((tree2 (unwrap! (map-get? family-trees ancestor) false)))
        true
    )
)

(define-read-only (get-dna-matches (user principal))
    (map-get? dna-matches user)
)

(define-read-only (get-oracle-submission (submitter principal) (timestamp uint))
    (map-get? oracle-submissions {submitter: submitter, timestamp: timestamp})
)

(define-read-only (get-verified-relationships (user principal))
    (ok true)
)

(define-read-only (calculate-relationship-degree (user1 principal) (user2 principal))
    (let ((tree1 (unwrap! (map-get? family-trees user1) u999))
          (tree2 (unwrap! (map-get? family-trees user2) u999)))
        (if (> (get generation tree1) (get generation tree2))
            (- (get generation tree1) (get generation tree2))
            (- (get generation tree2) (get generation tree1))
        )
    )
)


(define-read-only (get-family-statistics (user principal))
    (let ((tree (unwrap! (map-get? family-trees user) {total-ancestors: u0, total-descendants: u0, generation: u0})))
        {
            total-ancestors: (len (get ancestors tree)),
            total-descendants: (len (get descendants tree)),
            generation: (get generation tree)
        }
    )
)

(define-read-only (is-verified-lineage (user1 principal) (user2 principal))
    (let ((relationship-1 (map-get? relationships {parent: user1, child: user2}))
          (relationship-2 (map-get? relationships {parent: user2, child: user1})))
        (or 
            (match relationship-1 rel1 (get verified rel1) false)
            (match relationship-2 rel2 (get verified rel2) false)
        )
    )
)

(define-read-only (get-contract-info)
    {
        oracle-address: (var-get oracle-address),
        contract-owner: (var-get contract-owner),
        current-block: stacks-block-height
    }
)
