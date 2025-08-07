# ChronosMark

⏳ **Immutable Credentialing Across Lifetimes**

ChronosMark is a blockchain-based credentialing system built on Stacks that enables institutions to issue tamper-proof, verifiable certificates as NFTs. The platform provides permanent records of academic, professional, and skill-based achievements with built-in verification, expiration handling, revocation capabilities, and QR code integration for instant verification.

## Features

- **NFT-Based Certificates**: Each credential is minted as a unique NFT with verifiable metadata
- **QR Code Integration**: Generate QR codes for certificates that link to verification portal
- **Public Verification Portal**: Instant verification of credentials by certificate ID or wallet address
- **Expiration & Revocation Logic**: Built-in lifecycle management for credential validity
- **Template System**: Reusable certificate templates for standardized issuance
- **Batch Issuance**: Efficient mass certificate generation for graduation ceremonies
- **Role-Based Permissions**: Granular access control for issuers and template usage
- **Verification Analytics**: Track how often certificates are verified
- **Issuer Management**: Authorization system for trusted credential issuers

## Smart Contract Architecture

### Core Components

1. **Certificate Templates**: Standardized formats for different credential types
2. **Authorization System**: Manage trusted issuers and their permissions
3. **NFT Implementation**: Standards-compliant certificate tokens
4. **Verification Engine**: Real-time credential validation
5. **Batch Processing**: Efficient bulk operations
6. **QR Code Generation**: Generate verification URLs for instant certificate checking

### Key Functions

- `issue-certificate`: Create individual credentials with QR code generation
- `batch-issue-certificates`: Mass certificate generation
- `revoke-certificate`: Invalidate credentials with reasons
- `verify-certificate`: Check credential validity and authenticity
- `create-certificate-template`: Define reusable credential formats
- `generate-qr-verification-url`: Create QR code-compatible verification URL

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

### Creating a Certificate Template

```clarity
(contract-call? .chronosmark create-certificate-template 
  u"Computer Science Degree" 
  u"Bachelor's degree in Computer Science" 
  u"degree,computer-science,bachelor")
```

### Issuing a Certificate with QR Code

```clarity
(contract-call? .chronosmark issue-certificate
  'ST1HTBVD3JG9C05J7HBJT0CA...  ;; recipient
  u1                            ;; template-id
  u"Bachelor of Computer Science"
  u"Awarded to John Doe for completing..."
  u"https://metadata.university.edu/cert/123"
  (some u1000000))              ;; expiry block height
```

### Generating QR Code Verification URL

```clarity
(contract-call? .chronosmark generate-qr-verification-url u1 u"https://verify.chronosmark.com")
```

### Verifying a Certificate

```clarity
(contract-call? .chronosmark verify-certificate u1)
```

## QR Code Integration

ChronosMark now includes built-in QR code URL generation that creates verification links for certificates. Each certificate can generate a QR code that:

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

| Function | Description | Parameters |
|----------|-------------|------------|
| `authorize-issuer` | Grant issuer permissions | `issuer`, `org-name` |
| `issue-certificate` | Create new certificate | `recipient`, `template-id`, `title`, `description`, `metadata-uri`, `expiry-date` |
| `batch-issue-certificates` | Create multiple certificates | `recipients`, `template-id`, `title`, `description`, `metadata-uri`, `expiry-date` |
| `revoke-certificate` | Invalidate certificate | `certificate-id`, `reason` |
| `verify-certificate` | Check certificate validity | `certificate-id` |
| `generate-qr-verification-url` | Generate QR code URL | `certificate-id`, `base-url` |

### Read-Only Functions

| Function | Description | Return Type |
|----------|-------------|-------------|
| `get-certificate` | Retrieve certificate data | `Certificate` |
| `get-issuer-info` | Get issuer details | `IssuerInfo` |
| `is-authorized-issuer` | Check issuer status | `bool` |
| `get-qr-verification-url` | Get QR code URL | `string-utf8` |

## Security Features

- **Immutable Records**: Certificates cannot be altered once issued
- **Cryptographic Verification**: Blockchain-based proof of authenticity  
- **Access Control**: Role-based permissions for issuers
- **Revocation Tracking**: Transparent invalidation with reasons
- **Expiration Management**: Automatic validity checking
- **QR Code Security**: URLs include certificate ID validation

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap

1. ✅ QR Code Integration: Generate QR codes for certificates that link to verification portal
2. Multi-Signature Issuance: Require multiple approvals for high-value credentials
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