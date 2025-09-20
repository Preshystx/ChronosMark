;; ChronosMark - Immutable Credentialing Across Lifetimes
;; NFT-based certificate system with verifiable metadata, lifecycle management, QR code integration, and multi-signature issuance

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
(define-constant err-invalid-url (err u108))
(define-constant err-proposal-not-found (err u109))
(define-constant err-already-approved (err u110))
(define-constant err-insufficient-approvals (err u111))
(define-constant err-proposal-already-executed (err u112))
(define-constant err-proposal-rejected (err u113))
(define-constant err-invalid-threshold (err u114))
(define-constant err-not-multisig-signer (err u115))
(define-constant err-invalid-proposal-status (err u116))

;; NFT Definition
(define-non-fungible-token chronos-certificate uint)

;; Data Variables
(define-data-var next-certificate-id uint u1)
(define-data-var next-template-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var max-batch-size uint u50)

;; Certificate Templates
(define-map certificate-templates
  { template-id: uint }
  {
    creator: principal,
    template-name: (string-utf8 64),
    description: (string-utf8 256),
    metadata-schema: (string-utf8 512),
    is-active: bool,
    requires-multisig: bool
  }
)

;; Template Approval Thresholds for Multi-Sig
(define-map template-approval-thresholds
  { template-id: uint }
  { required-approvals: uint }
)

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
    revocation-reason: (optional (string-utf8 256)),
    qr-verification-url: (optional (string-utf8 256)),
    is-multisig: bool
  }
)

;; Multi-Signature Proposals
(define-map multisig-proposals
  { proposal-id: uint }
  {
    proposer: principal,
    recipient: principal,
    template-id: uint,
    certificate-title: (string-utf8 128),
    certificate-description: (string-utf8 512),
    metadata-uri: (string-utf8 256),
    expiry-date: (optional uint),
    created-at: uint,
    status: (string-utf8 16),
    required-approvals: uint,
    current-approvals: uint,
    executed-at: (optional uint)
  }
)

;; Proposal Approvals Tracking
(define-map proposal-approvals
  { proposal-id: uint, signer: principal }
  { 
    approved: bool,
    approved-at: uint,
    rejection-reason: (optional (string-utf8 256))
  }
)

;; Multi-Signature Authorized Signers
(define-map multisig-signers
  { signer: principal }
  {
    authorized-by: principal,
    role: (string-utf8 64),
    is-active: bool,
    authorized-at: uint
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

;; QR Code Settings
(define-map qr-verification-urls
  { certificate-id: uint }
  { 
    verification-url: (string-utf8 256),
    generated-at: uint,
    generated-by: principal
  }
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

(define-private (validate-proposal-id (proposal-id uint))
  (and 
    (> proposal-id u0)
    (< proposal-id (var-get next-proposal-id))
  )
)

(define-private (validate-expiry-date (expiry-date (optional uint)))
  (match expiry-date
    expiry (> expiry stacks-block-height)
    true
  )
)

(define-private (validate-url (url (string-utf8 256)))
  (and 
    (> (len url) u7)
    (or 
      (is-eq (unwrap-panic (slice? url u0 u7)) u"http://")
      (is-eq (unwrap-panic (slice? url u0 u8)) u"https://")
    )
  )
)

(define-private (is-certificate-expired (certificate-id uint))
  (if (validate-certificate-id certificate-id)
    (let ((cert-option (map-get? certificates { certificate-id: certificate-id })))
      (match cert-option
        cert (match (get expiry-date cert)
          expiry (>= stacks-block-height expiry)
          false
        )
        false
      )
    )
    false
  )
)

;; Simple uint to string conversion for certificate IDs
(define-private (uint-to-string (value uint))
  (if (is-eq value u0) u"0"
    (if (< value u10) 
      (if (is-eq value u1) u"1"
        (if (is-eq value u2) u"2"
          (if (is-eq value u3) u"3"
            (if (is-eq value u4) u"4"
              (if (is-eq value u5) u"5"
                (if (is-eq value u6) u"6"
                  (if (is-eq value u7) u"7"
                    (if (is-eq value u8) u"8"
                      u"9"))))))))
      (convert-large-uint-to-string value)
    )
  )
)

(define-private (convert-large-uint-to-string (value uint))
  (let 
    (
      (ones (mod value u10))
      (tens (mod (/ value u10) u10))
      (hundreds (mod (/ value u100) u10))
      (thousands (mod (/ value u1000) u10))
      (ten-thousands (mod (/ value u10000) u10))
      (hundred-thousands (mod (/ value u100000) u10))
    )
    (if (>= value u100000)
      (concat 
        (digit-to-char hundred-thousands)
        (concat 
          (digit-to-char ten-thousands)
          (concat 
            (digit-to-char thousands)
            (concat 
              (digit-to-char hundreds)
              (concat 
                (digit-to-char tens)
                (digit-to-char ones))))))
      (if (>= value u10000)
        (concat 
          (digit-to-char ten-thousands)
          (concat 
            (digit-to-char thousands)
            (concat 
              (digit-to-char hundreds)
              (concat 
                (digit-to-char tens)
                (digit-to-char ones)))))
        (if (>= value u1000)
          (concat 
            (digit-to-char thousands)
            (concat 
              (digit-to-char hundreds)
              (concat 
                (digit-to-char tens)
                (digit-to-char ones))))
          (if (>= value u100)
            (concat 
              (digit-to-char hundreds)
              (concat 
                (digit-to-char tens)
                (digit-to-char ones)))
            (if (>= value u10)
              (concat 
                (digit-to-char tens)
                (digit-to-char ones))
              (digit-to-char ones))))))
  )
)

(define-private (digit-to-char (digit uint))
  (if (is-eq digit u0) u"0"
    (if (is-eq digit u1) u"1"
      (if (is-eq digit u2) u"2"
        (if (is-eq digit u3) u"3"
          (if (is-eq digit u4) u"4"
            (if (is-eq digit u5) u"5"
              (if (is-eq digit u6) u"6"
                (if (is-eq digit u7) u"7"
                  (if (is-eq digit u8) u"8"
                    u"9")))))))))
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
        authorization-date: stacks-block-height
      }
    ))
  )
)

(define-public (revoke-issuer-authorization (issuer principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (validate-principal issuer) err-invalid-issuer)
    
    (let ((issuer-info-option (map-get? authorized-issuers { issuer: issuer })))
      (asserts! (is-some issuer-info-option) err-invalid-issuer)
      (let ((issuer-info (unwrap-panic issuer-info-option)))
        (ok (map-set authorized-issuers
          { issuer: issuer }
          (merge issuer-info { is-active: false })
        ))
      )
    )
  )
)

;; Multi-Signature Signer Management
(define-public (add-multisig-signer (signer principal) (role (string-utf8 64)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (validate-principal signer) err-invalid-issuer)
    (asserts! (validate-text-length role u1 u64) err-invalid-title)
    
    (ok (map-set multisig-signers
      { signer: signer }
      {
        authorized-by: tx-sender,
        role: role,
        is-active: true,
        authorized-at: stacks-block-height
      }
    ))
  )
)

(define-public (revoke-multisig-signer (signer principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (validate-principal signer) err-invalid-issuer)
    
    (let ((signer-info-option (map-get? multisig-signers { signer: signer })))
      (asserts! (is-some signer-info-option) err-not-multisig-signer)
      (let ((signer-info (unwrap-panic signer-info-option)))
        (ok (map-set multisig-signers
          { signer: signer }
          (merge signer-info { is-active: false })
        ))
      )
    )
  )
)

;; Template Management
(define-public (create-certificate-template 
  (template-name (string-utf8 64))
  (description (string-utf8 256))
  (metadata-schema (string-utf8 512))
  (requires-multisig bool)
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
        is-active: true,
        requires-multisig: requires-multisig
      }
    )
    
    (var-set next-template-id (+ template-id u1))
    (ok template-id)
  )
)

(define-public (set-template-approval-threshold (template-id uint) (threshold uint))
  (begin
    (asserts! (validate-template-id template-id) err-invalid-template)
    (asserts! (validate-uint threshold) err-invalid-threshold)
    (asserts! (<= threshold u10) err-invalid-threshold)
    
    (let ((template-option (map-get? certificate-templates { template-id: template-id })))
      (asserts! (is-some template-option) err-invalid-template)
      (let ((template (unwrap-panic template-option)))
        (asserts! (is-eq tx-sender (get creator template)) err-not-authorized)
        (asserts! (get requires-multisig template) err-invalid-template)
        
        (ok (map-set template-approval-thresholds
          { template-id: template-id }
          { required-approvals: threshold }
        ))
      )
    )
  )
)

(define-public (grant-template-permission (issuer principal) (template-id uint))
  (begin
    (asserts! (validate-principal issuer) err-invalid-issuer)
    (asserts! (validate-template-id template-id) err-invalid-template)
    
    (let ((template-option (map-get? certificate-templates { template-id: template-id })))
      (asserts! (is-some template-option) err-invalid-template)
      (let ((template (unwrap-panic template-option)))
        (asserts! (is-eq tx-sender (get creator template)) err-not-authorized)
        
        (ok (map-set issuer-template-permissions
          { issuer: issuer, template-id: template-id }
          { can-issue: true }
        ))
      )
    )
  )
)

;; Multi-Signature Proposal Functions
(define-public (create-multisig-proposal
  (recipient principal)
  (template-id uint)
  (cert-title (string-utf8 128))
  (cert-description (string-utf8 512))
  (metadata-uri (string-utf8 256))
  (expiry-date (optional uint))
)
  (let 
    (
      (proposal-id (var-get next-proposal-id))
      (validated-expiry (if (is-some expiry-date) expiry-date none))
    )
    
    ;; Input validation
    (asserts! (validate-principal recipient) err-invalid-recipient)
    (asserts! (validate-template-id template-id) err-invalid-template)
    (asserts! (validate-text-length cert-title u1 u128) err-invalid-title)
    (asserts! (validate-text-length cert-description u1 u512) err-invalid-description)
    (asserts! (validate-text-length metadata-uri u1 u256) err-invalid-description)
    (asserts! (validate-expiry-date expiry-date) err-invalid-template)
    
    ;; Check template requires multi-sig and get threshold
    (let 
      (
        (template-option (map-get? certificate-templates { template-id: template-id }))
        (threshold-option (map-get? template-approval-thresholds { template-id: template-id }))
        (issuer-auth-option (map-get? authorized-issuers { issuer: tx-sender }))
        (permission (default-to { can-issue: false } 
          (map-get? issuer-template-permissions { issuer: tx-sender, template-id: template-id })))
      )
      
      (asserts! (is-some template-option) err-invalid-template)
      (asserts! (is-some issuer-auth-option) err-not-authorized)
      (asserts! (is-some threshold-option) err-invalid-threshold)
      
      (let 
        (
          (template (unwrap-panic template-option))
          (threshold (unwrap-panic threshold-option))
          (issuer-auth (unwrap-panic issuer-auth-option))
        )
        
        (asserts! (get is-active template) err-invalid-template)
        (asserts! (get requires-multisig template) err-invalid-template)
        (asserts! (get is-active issuer-auth) err-not-authorized)
        (asserts! (get can-issue permission) err-not-authorized)
        
        ;; Create proposal
        (map-set multisig-proposals
          { proposal-id: proposal-id }
          {
            proposer: tx-sender,
            recipient: recipient,
            template-id: template-id,
            certificate-title: cert-title,
            certificate-description: cert-description,
            metadata-uri: metadata-uri,
            expiry-date: validated-expiry,
            created-at: stacks-block-height,
            status: u"pending",
            required-approvals: (get required-approvals threshold),
            current-approvals: u0,
            executed-at: none
          }
        )
        
        (var-set next-proposal-id (+ proposal-id u1))
        (ok proposal-id)
      )
    )
  )
)

(define-public (approve-multisig-proposal (proposal-id uint))
  (begin
    (asserts! (validate-proposal-id proposal-id) err-proposal-not-found)
    
    (let 
      (
        (proposal-option (map-get? multisig-proposals { proposal-id: proposal-id }))
        (signer-option (map-get? multisig-signers { signer: tx-sender }))
        (existing-approval (map-get? proposal-approvals { proposal-id: proposal-id, signer: tx-sender }))
      )
      
      (asserts! (is-some proposal-option) err-proposal-not-found)
      (asserts! (is-some signer-option) err-not-multisig-signer)
      (asserts! (is-none existing-approval) err-already-approved)
      
      (let 
        (
          (proposal (unwrap-panic proposal-option))
          (signer-info (unwrap-panic signer-option))
        )
        
        (asserts! (get is-active signer-info) err-not-multisig-signer)
        (asserts! (is-eq (get status proposal) u"pending") err-invalid-proposal-status)
        
        ;; Record approval
        (map-set proposal-approvals
          { proposal-id: proposal-id, signer: tx-sender }
          {
            approved: true,
            approved-at: stacks-block-height,
            rejection-reason: none
          }
        )
        
        ;; Update proposal approval count
        (let ((updated-approvals (+ (get current-approvals proposal) u1)))
          (map-set multisig-proposals
            { proposal-id: proposal-id }
            (merge proposal { current-approvals: updated-approvals })
          )
          
          (ok updated-approvals)
        )
      )
    )
  )
)

(define-public (reject-multisig-proposal (proposal-id uint) (reason (string-utf8 256)))
  (begin
    (asserts! (validate-proposal-id proposal-id) err-proposal-not-found)
    (asserts! (validate-text-length reason u1 u256) err-invalid-description)
    
    (let 
      (
        (proposal-option (map-get? multisig-proposals { proposal-id: proposal-id }))
        (signer-option (map-get? multisig-signers { signer: tx-sender }))
        (existing-approval (map-get? proposal-approvals { proposal-id: proposal-id, signer: tx-sender }))
      )
      
      (asserts! (is-some proposal-option) err-proposal-not-found)
      (asserts! (is-some signer-option) err-not-multisig-signer)
      (asserts! (is-none existing-approval) err-already-approved)
      
      (let 
        (
          (proposal (unwrap-panic proposal-option))
          (signer-info (unwrap-panic signer-option))
        )
        
        (asserts! (get is-active signer-info) err-not-multisig-signer)
        (asserts! (is-eq (get status proposal) u"pending") err-invalid-proposal-status)
        
        ;; Record rejection
        (map-set proposal-approvals
          { proposal-id: proposal-id, signer: tx-sender }
          {
            approved: false,
            approved-at: stacks-block-height,
            rejection-reason: (some reason)
          }
        )
        
        ;; Update proposal status to rejected
        (map-set multisig-proposals
          { proposal-id: proposal-id }
          (merge proposal { status: u"rejected" })
        )
        
        (ok true)
      )
    )
  )
)

(define-public (execute-multisig-proposal (proposal-id uint))
  (begin
    (asserts! (validate-proposal-id proposal-id) err-proposal-not-found)
    
    (let ((proposal-option (map-get? multisig-proposals { proposal-id: proposal-id })))
      (asserts! (is-some proposal-option) err-proposal-not-found)
      
      (let ((proposal (unwrap-panic proposal-option)))
        (asserts! (is-eq (get status proposal) u"pending") err-invalid-proposal-status)
        (asserts! (>= (get current-approvals proposal) (get required-approvals proposal)) err-insufficient-approvals)
        
        ;; Create certificate
        (let ((certificate-id (var-get next-certificate-id)))
          ;; Mint NFT
          (try! (nft-mint? chronos-certificate certificate-id (get recipient proposal)))
          
          ;; Store certificate data
          (map-set certificates
            { certificate-id: certificate-id }
            {
              issuer: (get proposer proposal),
              recipient: (get recipient proposal),
              template-id: (get template-id proposal),
              certificate-title: (get certificate-title proposal),
              certificate-description: (get certificate-description proposal),
              metadata-uri: (get metadata-uri proposal),
              issue-date: stacks-block-height,
              expiry-date: (get expiry-date proposal),
              is-revoked: false,
              revocation-reason: none,
              qr-verification-url: none,
              is-multisig: true
            }
          )
          
          ;; Initialize verification stats
          (map-set verification-stats
            { certificate-id: certificate-id }
            { verification-count: u0 }
          )
          
          ;; Update proposal status
          (map-set multisig-proposals
            { proposal-id: proposal-id }
            (merge proposal { 
              status: u"executed",
              executed-at: (some stacks-block-height)
            })
          )
          
          (var-set next-certificate-id (+ certificate-id u1))
          (ok certificate-id)
        )
      )
    )
  )
)

;; Standard Certificate Issuance (for non-multisig templates)
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
        (issuer-auth-option (map-get? authorized-issuers { issuer: tx-sender }))
        (template-option (map-get? certificate-templates { template-id: template-id }))
        (permission (default-to { can-issue: false } 
          (map-get? issuer-template-permissions { issuer: tx-sender, template-id: template-id })))
      )
      
      (asserts! (is-some issuer-auth-option) err-not-authorized)
      (asserts! (is-some template-option) err-invalid-template)
      
      (let 
        (
          (issuer-auth (unwrap-panic issuer-auth-option))
          (template (unwrap-panic template-option))
        )
        
        (asserts! (get is-active issuer-auth) err-not-authorized)
        (asserts! (get is-active template) err-invalid-template)
        (asserts! (not (get requires-multisig template)) err-invalid-template)
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
            issue-date: stacks-block-height,
            expiry-date: validated-expiry,
            is-revoked: false,
            revocation-reason: none,
            qr-verification-url: none,
            is-multisig: false
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
)

;; QR Code URL Generation
(define-public (generate-qr-verification-url (certificate-id uint) (base-url (string-utf8 128)))
  (begin
    (asserts! (validate-certificate-id certificate-id) err-certificate-not-found)
    (asserts! (validate-text-length base-url u8 u128) err-invalid-url)
    
    (let ((cert-option (map-get? certificates { certificate-id: certificate-id })))
      (asserts! (is-some cert-option) err-certificate-not-found)
      (let ((cert (unwrap-panic cert-option)))
        ;; Only certificate owner or issuer can generate QR codes
        (asserts! (or 
          (is-eq tx-sender (get recipient cert))
          (is-eq tx-sender (get issuer cert))
        ) err-not-authorized)
        
        ;; Create verification URL using certificate ID
        (let ((cert-id-str (uint-to-string certificate-id)))
          (let ((verification-url (unwrap-panic (as-max-len? 
            (concat (concat base-url u"/verify/") cert-id-str) u256))))
            
            ;; Store QR verification URL
            (map-set qr-verification-urls
              { certificate-id: certificate-id }
              {
                verification-url: verification-url,
                generated-at: stacks-block-height,
                generated-by: tx-sender
              }
            )
            
            ;; Update certificate with QR URL
            (map-set certificates
              { certificate-id: certificate-id }
              (merge cert { qr-verification-url: (some verification-url) })
            )
            
            (ok verification-url)
          )
        )
      )
    )
  )
)

;; Batch Certificate Issuance (for non-multisig templates)
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
        (issuer-auth-option (map-get? authorized-issuers { issuer: tx-sender }))
        (template-option (map-get? certificate-templates { template-id: template-id }))
        (permission (default-to { can-issue: false } 
          (map-get? issuer-template-permissions { issuer: tx-sender, template-id: template-id })))
      )
      
      (asserts! (is-some issuer-auth-option) err-not-authorized)
      (asserts! (is-some template-option) err-invalid-template)
      
      (let 
        (
          (issuer-auth (unwrap-panic issuer-auth-option))
          (template (unwrap-panic template-option))
        )
        
        (asserts! (get is-active issuer-auth) err-not-authorized)
        (asserts! (get is-active template) err-invalid-template)
        (asserts! (not (get requires-multisig template)) err-invalid-template)
        (asserts! (get can-issue permission) err-not-authorized)
        
        (ok (map issue-certificate-for-recipient recipients))
      )
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
      u0
    )
  )
)

;; Certificate Revocation
(define-public (revoke-certificate (certificate-id uint) (reason (string-utf8 256)))
  (begin
    (asserts! (validate-certificate-id certificate-id) err-certificate-not-found)
    (asserts! (validate-text-length reason u1 u256) err-invalid-description)
    
    (let ((cert-option (map-get? certificates { certificate-id: certificate-id })))
      (asserts! (is-some cert-option) err-certificate-not-found)
      (let ((cert (unwrap-panic cert-option)))
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
)

;; Verification Functions
(define-public (verify-certificate (certificate-id uint))
  (begin
    (asserts! (validate-certificate-id certificate-id) err-certificate-not-found)
    
    (let 
      (
        (cert-option (map-get? certificates { certificate-id: certificate-id }))
        (stats (default-to { verification-count: u0 } 
          (map-get? verification-stats { certificate-id: certificate-id })))
      )
      
      (asserts! (is-some cert-option) err-certificate-not-found)
      (let ((cert (unwrap-panic cert-option)))
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
)

;; Read-only Functions
(define-read-only (get-certificate (certificate-id uint))
  (if (validate-certificate-id certificate-id)
    (map-get? certificates { certificate-id: certificate-id })
    none
  )
)

(define-read-only (get-multisig-proposal (proposal-id uint))
  (if (validate-proposal-id proposal-id)
    (map-get? multisig-proposals { proposal-id: proposal-id })
    none
  )
)

(define-read-only (get-proposal-approval (proposal-id uint) (signer principal))
  (if (and (validate-proposal-id proposal-id) (validate-principal signer))
    (map-get? proposal-approvals { proposal-id: proposal-id, signer: signer })
    none
  )
)

(define-read-only (get-template-threshold (template-id uint))
  (if (validate-template-id template-id)
    (match (map-get? template-approval-thresholds { template-id: template-id })
      threshold (some (get required-approvals threshold))
      none
    )
    none
  )
)

(define-read-only (is-authorized-multisig-signer (signer principal))
  (if (validate-principal signer)
    (match (map-get? multisig-signers { signer: signer })
      signer-info (get is-active signer-info)
      false
    )
    false
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

(define-read-only (get-qr-verification-url (certificate-id uint))
  (if (validate-certificate-id certificate-id)
    (let ((cert-option (map-get? certificates { certificate-id: certificate-id })))
      (match cert-option
        cert (get qr-verification-url cert)
        none
      )
    )
    none
  )
)

(define-read-only (get-qr-url-info (certificate-id uint))
  (if (validate-certificate-id certificate-id)
    (map-get? qr-verification-urls { certificate-id: certificate-id })
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
    (let ((cert-option (map-get? certificates { certificate-id: certificate-id })))
      (match cert-option
        cert (ok (some (get metadata-uri cert)))
        err-certificate-not-found
      )
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

;; Certificate Transfer
(define-public (transfer-certificate (certificate-id uint) (recipient principal))
  (begin
    (asserts! (validate-certificate-id certificate-id) err-certificate-not-found)
    (asserts! (validate-principal recipient) err-invalid-recipient)
    
    (let 
      (
        (cert-option (map-get? certificates { certificate-id: certificate-id }))
        (current-owner (nft-get-owner? chronos-certificate certificate-id))
      )
      
      (asserts! (is-some cert-option) err-certificate-not-found)
      (asserts! (is-some current-owner) err-certificate-not-found)
      (asserts! (is-eq tx-sender (unwrap-panic current-owner)) err-not-authorized)
      
      (try! (nft-transfer? chronos-certificate certificate-id tx-sender recipient))
      (ok true)
    )
  )
)