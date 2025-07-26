# ChronosMark

⏳ **Immutable Credentialing Across Lifetimes**

ChronosMark is a blockchain-based credentialing system built on Stacks that enables institutions to issue tamper-proof, verifiable certificates as NFTs. The platform provides permanent records of academic, professional, and skill-based achievements with built-in verification, expiration handling, and revocation capabilities.

## Features

- **NFT-Based Certificates**: Each credential is minted as a unique NFT with verifiable metadata
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

### Key Functions

- `issue-certificate`: Create individual credentials
- `batch-issue-certificates`: Mass certificate generation
- `revoke-certificate`: Invalidate credentials with reasons
- `verify-certificate`: Check credential validity and authenticity
- `create-certificate-template`: Define reusable credential formats

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

### Issuing a Certificate

```clarity
(contract-call? .chronosmark issue-certificate
  'ST1HTBVD3JG9C05J7HBJT0CA...  ;; recipient
  u1                            ;; template-id
  u"Bachelor of Computer Science"
  u"Awarded to John Doe for completing..."
  u"https://metadata.university.edu/cert/123"
  (some u1000000))              ;; expiry block height
```

### Verifying a Certificate

```clarity
(contract-call? .chronosmark verify-certificate u1)
```

## API Reference

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `authorize-issuer` | Grant issuer permissions | `issuer`, `org-name` |
| `issue-certificate` | Create new certificate | `recipient`, `template-id`, `title`, `description`, `metadata-uri`, `expiry-date` |
| `batch-issue-certificates` | Create multiple certificates | `recipients`, `template-id`, `title`, `description`, `metadata-uri`, `expiry-date` |
| `revoke-certificate` | Invalidate certificate | `certificate-id`, `reason` |
| `verify-certificate` | Check certificate validity | `certificate-id` |

### Read-Only Functions

| Function | Description | Return Type |
|----------|-------------|-------------|
| `get-certificate` | Retrieve certificate data | `Certificate` |
| `get-issuer-info` | Get issuer details | `IssuerInfo` |
| `is-authorized-issuer` | Check issuer status | `bool` |

## Security Features

- **Immutable Records**: Certificates cannot be altered once issued
- **Cryptographic Verification**: Blockchain-based proof of authenticity  
- **Access Control**: Role-based permissions for issuers
- **Revocation Tracking**: Transparent invalidation with reasons
- **Expiration Management**: Automatic validity checking

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap

- [ ] Web-based verification portal
- [ ] QR code generation for certificates
- [ ] Integration with major educational platforms
- [ ] Mobile app for credential wallet
- [ ] Advanced analytics dashboard