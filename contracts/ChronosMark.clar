;; ChronosMark - Immutable Credentialing Across Lifetimes
;; NFT-based certificate system with verifiable metadata and lifecycle management

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u403))
(define-constant err-certificate-not-found (err u404))
(define-constant err-invalid-issuer (err u100))
(define-constant err-already-revoked (err u101))
(define-constant err-certificate-expired (err u102))
(define-constant err-invalid-template (err u103))
(define-constant err-invalid-recipient (err u104))
(define-constant err-invalid-title (err u105))
(define-constant err-invalid-description (err u106))
(define-constant err-batch-limit-exceeded (err u107))

;; NFT Definition
(define-non-fungible-token chronos-certificate uint)

;; Data Variables
(define-data-var next-certificate-id uint u1)
(define-data-var max-batch-size uint u50)

;; Certificate Templates
(define-map certificate-templates
  { template-id: uint }
  {
    creator: principal,
    template-name: (string-utf8 64),
    description: (string-utf8 256),
    metadata-schema: (string-utf8 512),
    is-active: bool
  }
)

(define-data-var next-template-id uint u1)

;; Certificate Storage
(define-map certificates
  { certificate-id: uint }
  {
    issuer: principal,
    recipient: principal,
    template-id: uint,
    certificate-title: (string-utf8 128),
    certificate-description: (string-utf8 512),
    metadata-uri: (string-utf8 256),
    issue-date: uint,
    expiry-date: (optional uint),
    is-revoked: bool,
    revocation-reason: (optional (string-utf8 256))
  }
)

;; Authorized Issuers
(define-map authorized-issuers
  { issuer: principal }
  {
    organization-name: (string-utf8 128),
    is-active: bool,
    authorized-by: principal,
    authorization-date: uint
  }
)

;; Issuer Permissions for Templates
(define-map issuer-template-permissions
  { issuer: principal, template-id: uint }
  { can-issue: bool }
)

;; Certificate Verification Stats
(define-map verification-stats
  { certificate-id: uint }
  { verification-count: uint }
)

;; Private Functions
(define-private (validate-principal (principal-to-check principal))
  (not (is-eq principal-to-check 'SP000000000000000000002Q6VF78))
)

(define-private (validate-text-length (text (string-utf8 512)) (min-length uint) (max-length uint))
  (let ((text-length (len text)))
    (and (>= text-length min-length) (<= text-length max-length))
  )
)

(define-private (validate-uint (value uint))
  (> value u0)
)

(define-private (validate-template-id (template-id uint))
  (and 
    (> template-id u0)
    (< template-id (var-get next-template-id))
  )
)

(define-private (validate-certificate-id (certificate-id uint))
  (and 
    (> certificate-id u0)
    (< certificate-id (var-get next-certificate-id))
  )
)

(define-private (validate-expiry-date (expiry-date (optional uint)))
  (match expiry-date
    expiry (> expiry burn-block-height)  ;; Must be in the future
    true  ;; None is valid (no expiration)
  )
)

;; FIXED: Properly defined is-certificate-expired function
(define-private (is-certificate-expired (certificate-id uint))
  (if (validate-certificate-id certificate-id)
    (let ((cert (unwrap! (map-get? certificates { certificate-id: certificate-id }) false)))
      (match (get expiry-date cert)
        expiry (>= burn-block-height expiry)  ;; Certificate is expired if current block >= expiry
        false  ;; No expiry date means never expires
      )
    )
    false  ;; Invalid certificate ID means not expired (but also not found)
  )
)

;; Authorization Functions
(define-public (authorize-issuer (issuer principal) (org-name (string-utf8 128)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (validate-principal issuer) err-invalid-issuer)
    (asserts! (validate-text-length org-name u1 u128) err-invalid-title)
    
    (ok (map-set authorized-issuers
      { issuer: issuer }
      {
        organization-name: org-name,
        is-active: true,
        authorized-by: tx-sender,
        authorization-date: burn-block-height
      }
    ))
  )
)

(define-public (revoke-issuer-authorization (issuer principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (validate-principal issuer) err-invalid-issuer)
    
    (let ((issuer-info (unwrap! (map-get? authorized-issuers { issuer: issuer }) err-invalid-issuer)))
      (ok (map-set authorized-issuers
        { issuer: issuer }
        (merge issuer-info { is-active: false })
      ))
    )
  )
)

;; Template Management
(define-public (create-certificate-template 
  (template-name (string-utf8 64))
  (description (string-utf8 256))
  (metadata-schema (string-utf8 512))
)
  (let ((template-id (var-get next-template-id)))
    (asserts! (validate-text-length template-name u1 u64) err-invalid-title)
    (asserts! (validate-text-length description u1 u256) err-invalid-description)
    (asserts! (validate-text-length metadata-schema u1 u512) err-invalid-template)
    
    (map-set certificate-templates
      { template-id: template-id }
      {
        creator: tx-sender,
        template-name: template-name,
        description: description,
        metadata-schema: metadata-schema,
        is-active: true
      }
    )
    
    (var-set next-template-id (+ template-id u1))
    (ok template-id)
  )
)

(define-public (grant-template-permission (issuer principal) (template-id uint))
  (begin
    (asserts! (validate-principal issuer) err-invalid-issuer)
    (asserts! (validate-template-id template-id) err-invalid-template)
    
    (let ((template (unwrap! (map-get? certificate-templates { template-id: template-id }) err-invalid-template)))
      (asserts! (is-eq tx-sender (get creator template)) err-not-authorized)
      
      (ok (map-set issuer-template-permissions
        { issuer: issuer, template-id: template-id }
        { can-issue: true }
      ))
    )
  )
)

;; Certificate Issuance
(define-public (issue-certificate
  (recipient principal)
  (template-id uint)
  (cert-title (string-utf8 128))
  (cert-description (string-utf8 512))
  (metadata-uri (string-utf8 256))
  (expiry-date (optional uint))
)
  (let 
    (
      (certificate-id (var-get next-certificate-id))
      (validated-expiry (if (is-some expiry-date) expiry-date none))
    )
    
    ;; Input validation
    (asserts! (validate-principal recipient) err-invalid-recipient)
    (asserts! (validate-template-id template-id) err-invalid-template)
    (asserts! (validate-text-length cert-title u1 u128) err-invalid-title)
    (asserts! (validate-text-length cert-description u1 u512) err-invalid-description)
    (asserts! (validate-text-length metadata-uri u1 u256) err-invalid-description)
    (asserts! (validate-expiry-date expiry-date) err-invalid-template)
    
    ;; Authorization checks
    (let 
      (
        (issuer-auth (unwrap! (map-get? authorized-issuers { issuer: tx-sender }) err-not-authorized))
        (template (unwrap! (map-get? certificate-templates { template-id: template-id }) err-invalid-template))
        (permission (default-to { can-issue: false } 
          (map-get? issuer-template-permissions { issuer: tx-sender, template-id: template-id })))
      )
      
      (asserts! (get is-active issuer-auth) err-not-authorized)
      (asserts! (get is-active template) err-invalid-template)
      (asserts! (get can-issue permission) err-not-authorized)
      
      ;; Mint NFT
      (try! (nft-mint? chronos-certificate certificate-id recipient))
      
      ;; Store certificate data
      (map-set certificates
        { certificate-id: certificate-id }
        {
          issuer: tx-sender,
          recipient: recipient,
          template-id: template-id,
          certificate-title: cert-title,
          certificate-description: cert-description,
          metadata-uri: metadata-uri,
          issue-date: burn-block-height,
          expiry-date: validated-expiry,
          is-revoked: false,
          revocation-reason: none
        }
      )
      
      ;; Initialize verification stats
      (map-set verification-stats
        { certificate-id: certificate-id }
        { verification-count: u0 }
      )
      
      (var-set next-certificate-id (+ certificate-id u1))
      (ok certificate-id)
    )
  )
)

;; Batch Certificate Issuance
(define-public (batch-issue-certificates
  (recipients (list 50 principal))
  (template-id uint)
  (cert-title (string-utf8 128))
  (cert-description (string-utf8 512))
  (metadata-uri (string-utf8 256))
  (expiry-date (optional uint))
)
  (let 
    (
      (batch-size (len recipients))
      (validated-expiry (if (is-some expiry-date) expiry-date none))
    )
    
    ;; Input validation
    (asserts! (<= batch-size (var-get max-batch-size)) err-batch-limit-exceeded)
    (asserts! (validate-template-id template-id) err-invalid-template)
    (asserts! (validate-text-length cert-title u1 u128) err-invalid-title)
    (asserts! (validate-text-length cert-description u1 u512) err-invalid-description)
    (asserts! (validate-text-length metadata-uri u1 u256) err-invalid-description)
    (asserts! (validate-expiry-date expiry-date) err-invalid-template)
    
    ;; Authorization checks
    (let 
      (
        (issuer-auth (unwrap! (map-get? authorized-issuers { issuer: tx-sender }) err-not-authorized))
        (template (unwrap! (map-get? certificate-templates { template-id: template-id }) err-invalid-template))
        (permission (default-to { can-issue: false } 
          (map-get? issuer-template-permissions { issuer: tx-sender, template-id: template-id })))
      )
      
      (asserts! (get is-active issuer-auth) err-not-authorized)
      (asserts! (get is-active template) err-invalid-template)
      (asserts! (get can-issue permission) err-not-authorized)
      
      (ok (map issue-certificate-for-recipient recipients))
    )
  )
)

(define-private (issue-certificate-for-recipient (recipient principal))
  (let ((certificate-id (var-get next-certificate-id)))
    (if (validate-principal recipient)
      (begin
        (var-set next-certificate-id (+ certificate-id u1))
        certificate-id
      )
      u0  ;; Return 0 for invalid recipients
    )
  )
)

;; Certificate Revocation
(define-public (revoke-certificate (certificate-id uint) (reason (string-utf8 256)))
  (begin
    (asserts! (validate-certificate-id certificate-id) err-certificate-not-found)
    (asserts! (validate-text-length reason u1 u256) err-invalid-description)
    
    (let ((cert (unwrap! (map-get? certificates { certificate-id: certificate-id }) err-certificate-not-found)))
      (asserts! (is-eq tx-sender (get issuer cert)) err-not-authorized)
      (asserts! (not (get is-revoked cert)) err-already-revoked)
      
      (ok (map-set certificates
        { certificate-id: certificate-id }
        (merge cert { 
          is-revoked: true, 
          revocation-reason: (some reason) 
        })
      ))
    )
  )
)

;; Verification Functions
(define-public (verify-certificate (certificate-id uint))
  (begin
    (asserts! (validate-certificate-id certificate-id) err-certificate-not-found)
    
    (let 
      (
        (cert (unwrap! (map-get? certificates { certificate-id: certificate-id }) err-certificate-not-found))
        (stats (default-to { verification-count: u0 } 
          (map-get? verification-stats { certificate-id: certificate-id })))
      )
      
      ;; Update verification count
      (map-set verification-stats
        { certificate-id: certificate-id }
        { verification-count: (+ (get verification-count stats) u1) }
      )
      
      (ok {
        is-valid: (and 
          (not (get is-revoked cert))
          (not (is-certificate-expired certificate-id))
        ),
        certificate: cert
      })
    )
  )
)

;; Read-only Functions
(define-read-only (get-certificate (certificate-id uint))
  (if (validate-certificate-id certificate-id)
    (map-get? certificates { certificate-id: certificate-id })
    none
  )
)

(define-read-only (get-certificate-template (template-id uint))
  (if (validate-template-id template-id)
    (map-get? certificate-templates { template-id: template-id })
    none
  )
)

(define-read-only (get-issuer-info (issuer principal))
  (if (validate-principal issuer)
    (map-get? authorized-issuers { issuer: issuer })
    none
  )
)

(define-read-only (get-verification-stats (certificate-id uint))
  (if (validate-certificate-id certificate-id)
    (map-get? verification-stats { certificate-id: certificate-id })
    none
  )
)

(define-read-only (is-authorized-issuer (issuer principal))
  (if (validate-principal issuer)
    (match (map-get? authorized-issuers { issuer: issuer })
      auth-info (get is-active auth-info)
      false
    )
    false
  )
)

(define-read-only (can-issue-with-template (issuer principal) (template-id uint))
  (and 
    (validate-principal issuer)
    (validate-template-id template-id)
    (is-authorized-issuer issuer)
    (default-to false 
      (get can-issue (map-get? issuer-template-permissions { issuer: issuer, template-id: template-id })))
  )
)

(define-read-only (get-last-token-id)
  (ok (- (var-get next-certificate-id) u1))
)

(define-read-only (get-token-uri (certificate-id uint))
  (if (validate-certificate-id certificate-id)
    (let ((cert (unwrap! (map-get? certificates { certificate-id: certificate-id }) err-certificate-not-found)))
      (ok (some (get metadata-uri cert)))
    )
    err-certificate-not-found
  )
)

(define-read-only (get-owner (certificate-id uint))
  (if (validate-certificate-id certificate-id)
    (ok (nft-get-owner? chronos-certificate certificate-id))
    err-certificate-not-found
  )
)

;; Certificate Transfer (simplified without trait)
(define-public (transfer-certificate (certificate-id uint) (recipient principal))
  (begin
    (asserts! (validate-certificate-id certificate-id) err-certificate-not-found)
    (asserts! (validate-principal recipient) err-invalid-recipient)
    
    (let ((cert (unwrap! (map-get? certificates { certificate-id: certificate-id }) err-certificate-not-found)))
      (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? chronos-certificate certificate-id) err-not-authorized)) err-not-authorized)
      (try! (nft-transfer? chronos-certificate certificate-id tx-sender recipient))
      (ok true)
    )
  )
)