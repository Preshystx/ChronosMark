# ChronosMark

⏳ **Immutable Credentialing Across Lifetimes**

ChronosMark is a blockchain-based credentialing system built on Stacks that enables institutions to issue tamper-proof, verifiable certificates as NFTs. The platform provides permanent records of academic, professional, and skill-based achievements with built-in verification, expiration handling, revocation capabilities, multi-signature issuance for high-value credentials, and QR code integration for instant verification.

## Features

- **NFT-Based Certificates**: Each credential is minted as a unique NFT with verifiable metadata
- **Multi-Signature Issuance**: Require multiple approvals for high-value credentials with configurable thresholds
- **QR Code Integration**: Generate QR codes for certificates that link to verification portal
- **Public Verification Portal**: Instant verification of credentials by certificate ID or wallet address
- **Expiration & Revocation Logic**: Built-in lifecycle management for credential validity
- **Template System**: Reusable certificate templates for standardized issuance
- **Batch Issuance**: Efficient mass certificate generation for graduation ceremonies
- **Role-Based Permissions**: Granular access control for issuers and template usage
- **Verification Analytics**: Track how often certificates are verified
- **Issuer Management**: Authorization system for trusted credential issuers
- **Approval Workflow**: Complete multi-signature proposal system with audit trails

## Smart Contract Architecture

### Core Components

1. **Certificate Templates**: Standardized formats for different credential types
2. **Authorization System**: Manage trusted issuers and their permissions
3. **Multi-Signature Proposals**: Approval workflow for high-value credentials
4. **NFT Implementation**: Standards-compliant certificate tokens
5. **Verification Engine**: Real-time credential validation
6. **Batch Processing**: Efficient bulk operations
7. **QR Code Generation**: Generate verification URLs for instant certificate checking

### Key Functions

#### Standard Certificate Functions
- `issue-certificate`: Create individual credentials with QR code generation
- `batch-issue-certificates`: Mass certificate generation
- `revoke-certificate`: Invalidate credentials with reasons
- `verify-certificate`: Check credential validity and authenticity
- `create-certificate-template`: Define reusable credential formats
- `generate-qr-verification-url`: Create QR code-compatible verification URL

#### Multi-Signature Functions
- `create-multisig-proposal`: Create certificate issuance proposal requiring multiple approvals
- `approve-multisig-proposal`: Approve a pending certificate proposal
- `reject-multisig-proposal`: Reject a certificate proposal with reason
- `execute-multisig-proposal`: Execute approved proposal to mint certificate
- `set-template-approval-threshold`: Configure required approvals per template
- `add-multisig-signer`: Authorize additional signers for proposals

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for testing

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/chronosmark.git
cd chronosmark
```

2. Initialize Clarinet project:
```bash
clarinet new chronosmark
cd chronosmark
```

3. Add the contract to your `contracts/` directory

4. Run tests:
```bash
clarinet test
```

### Deployment

Deploy to Stacks testnet:
```bash
clarinet deploy --testnet
```

## Usage Examples

### Creating a Certificate Template with Multi-Sig Requirement

```clarity
;; Create template
(contract-call? .chronosmark create-certificate-template 
  u"Master's Degree" 
  u"Master's degree requiring 2 approvals" 
  u"degree,masters,multisig")

;; Set approval threshold
(contract-call? .chronosmark set-template-approval-threshold u1 u2)
```

### Multi-Signature Certificate Issuance

```clarity
;; Create proposal for high-value credential
(contract-call? .chronosmark create-multisig-proposal
  'ST1HTBVD3JG9C05J7HBJT0CA...  ;; recipient
  u1                            ;; template-id
  u"Master of Computer Science"
  u"Awarded to Jane Doe for completing advanced studies..."
  u"https://metadata.university.edu/cert/456"
  (some u1500000))              ;; expiry block height

;; Approve the proposal (requires multiple signers)
(contract-call? .chronosmark approve-multisig-proposal u1)

;; Execute after sufficient approvals
(contract-call? .chronosmark execute-multisig-proposal u1)
```

### Standard Single-Signature Issuance

```clarity
(contract-call? .chronosmark issue-certificate
  'ST1HTBVD3JG9C05J7HBJT0CA...  ;; recipient
  u2                            ;; template-id (single-sig template)
  u"Certificate of Completion"
  u"Awarded to John Doe for completing the course..."
  u"https://metadata.university.edu/cert/123"
  (some u1000000))              ;; expiry block height
```

### Managing Multi-Signature Signers

```clarity
;; Add authorized signer
(contract-call? .chronosmark add-multisig-signer 
  'ST2CY5V39NHDPWSXMW9QDT3HC2Z...
  u"Academic Affairs Director")
```

## Multi-Signature Issuance

ChronosMark now supports multi-signature issuance for high-value credentials, providing enhanced security through distributed approval workflows.

### Key Features:
- **Proposal System**: Create certificate proposals requiring multiple approvals
- **Configurable Thresholds**: Set different approval requirements per template type
- **Authorized Signers**: Manage who can approve proposals
- **Audit Trail**: Complete history of all approval decisions
- **Flexible Execution**: Proposals can be executed once threshold is met

### Use Cases:
- **Academic Degrees**: Require Dean + Registrar approval
- **Professional Certifications**: Multiple board member approvals
- **High-Value Awards**: Committee-based approval process
- **Compliance Requirements**: Meet regulatory multi-party validation needs

### Workflow:
1. **Create Proposal**: Submit certificate for multi-sig approval
2. **Review Period**: Authorized signers review proposal details
3. **Approval Process**: Signers approve or reject with reasons
4. **Threshold Check**: System validates sufficient approvals received
5. **Execution**: Approved proposals mint certificates automatically

## QR Code Integration

ChronosMark includes built-in QR code URL generation that creates verification links for certificates. Each certificate can generate a QR code that:

- Links directly to the verification portal
- Includes the certificate ID for instant lookup
- Provides a mobile-friendly verification experience
- Enables offline verification scanning

### QR Code Usage

1. **Generate Verification URL**: Use `generate-qr-verification-url` to create a verification link
2. **Create QR Code**: Use any QR code library to convert the URL into a scannable QR code
3. **Scan & Verify**: Users can scan the QR code to instantly verify certificate authenticity

## API Reference

### Public Functions

#### Certificate Management
| Function | Description | Parameters |
|----------|-------------|------------|
| `authorize-issuer` | Grant issuer permissions | `issuer`, `org-name` |
| `issue-certificate` | Create new certificate | `recipient`, `template-id`, `title`, `description`, `metadata-uri`, `expiry-date` |
| `batch-issue-certificates` | Create multiple certificates | `recipients`, `template-id`, `title`, `description`, `metadata-uri`, `expiry-date` |
| `revoke-certificate` | Invalidate certificate | `certificate-id`, `reason` |
| `verify-certificate` | Check certificate validity | `certificate-id` |
| `generate-qr-verification-url` | Generate QR code URL | `certificate-id`, `base-url` |

#### Multi-Signature Functions
| Function | Description | Parameters |
|----------|-------------|------------|
| `create-multisig-proposal` | Create approval proposal | `recipient`, `template-id`, `title`, `description`, `metadata-uri`, `expiry-date` |
| `approve-multisig-proposal` | Approve pending proposal | `proposal-id` |
| `reject-multisig-proposal` | Reject proposal | `proposal-id`, `reason` |
| `execute-multisig-proposal` | Execute approved proposal | `proposal-id` |
| `set-template-approval-threshold` | Set approval requirements | `template-id`, `threshold` |
| `add-multisig-signer` | Authorize signer | `signer`, `role` |

### Read-Only Functions

| Function | Description | Return Type |
|----------|-------------|-------------|
| `get-certificate` | Retrieve certificate data | `Certificate` |
| `get-multisig-proposal` | Get proposal details | `MultisigProposal` |
| `get-proposal-approvals` | Get approval status | `ApprovalInfo` |
| `get-template-threshold` | Get approval threshold | `uint` |
| `is-authorized-signer` | Check signer status | `bool` |
| `get-issuer-info` | Get issuer details | `IssuerInfo` |
| `is-authorized-issuer` | Check issuer status | `bool` |
| `get-qr-verification-url` | Get QR code URL | `string-utf8` |

## Security Features

- **Immutable Records**: Certificates cannot be altered once issued
- **Cryptographic Verification**: Blockchain-based proof of authenticity  
- **Multi-Signature Security**: Distributed approval for high-value credentials
- **Access Control**: Role-based permissions for issuers and signers
- **Revocation Tracking**: Transparent invalidation with reasons
- **Expiration Management**: Automatic validity checking
- **QR Code Security**: URLs include certificate ID validation
- **Proposal Audit Trail**: Complete history of approval decisions

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap

1. ✅ QR Code Integration: Generate QR codes for certificates that link to verification portal
2. ✅ Multi-Signature Issuance: Require multiple approvals for high-value credentials
3. Certificate Marketplace: Allow trading of transferable professional certifications
4. Skill Verification API: Integration with LinkedIn and job platforms for automatic verification
5. Biometric Verification: Add fingerprint or facial recognition for certificate access
6. Cross-Chain Compatibility: Bridge certificates to Ethereum and other blockchains
7. AI Fraud Detection: Machine learning to detect suspicious issuance patterns
8. Subscription Model: Recurring credentials that auto-renew (like professional licenses)
9. Certificate Portfolios: Aggregate multiple credentials into verifiable digital portfolios
10. Decentralized Identity Integration: Connect with DID protocols for comprehensive identity management

## Support

For support, email support@chronosmark.com or join our Discord community.