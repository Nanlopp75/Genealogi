# Genealogix

On-Chain Ancestry Map – Lineage tracking with DNA oracle input on Stacks blockchain.

## Overview

Genealogix is a decentralized smart contract that enables users to build and verify family trees on the blockchain. The contract supports DNA oracle integration for enhanced ancestry verification and provides comprehensive lineage tracking capabilities.

## Features

- **User Registration**: Register with personal details and DNA hash
- **Family Relationships**: Establish parent-child relationships
- **DNA Oracle Integration**: External DNA data verification
- **Lineage Tracking**: Multi-generational family tree mapping
- **Relationship Verification**: Community-driven relationship validation
- **Ancestry Queries**: Calculate relationship degrees and common ancestors

## Contract Functions

### Public Functions

#### `register-user`
Register a new user with personal information and DNA hash.
```clarity
(register-user "John Doe" u1985 "male" 0x1234...)
```

#### `add-relationship`
Establish a parent-child relationship between users.
```clarity
(add-relationship 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG "parent")
```

#### `verify-relationship`
Verify an established relationship (community validation).
```clarity
(verify-relationship 'PARENT-ADDR 'CHILD-ADDR)
```

#### `submit-dna-oracle`
Submit DNA data via oracle (oracle-only function).
```clarity
(submit-dna-oracle 'USER-ADDR 0xDNA-DATA u95)
```

#### `set-oracle-address`
Set the authorized oracle address (owner-only).
```clarity
(set-oracle-address 'NEW-ORACLE-ADDR)
```

#### `verify-user-dna`
Mark user's DNA as verified (oracle-only function).
```clarity
(verify-user-dna 'USER-ADDR)
```

### Read-Only Functions

#### `get-user`
Retrieve user profile information.
```clarity
(get-user 'USER-ADDR)
```

#### `get-family-tree`
Get complete family tree data for a user.
```clarity
(get-family-tree 'USER-ADDR)
```

#### `get-children`
Get list of user's children.
```clarity
(get-children 'PARENT-ADDR)
```

#### `get-parents`
Get list of user's parents.
```clarity
(get-parents 'CHILD-ADDR)
```

#### `is-related`
Check if two users are related.
```clarity
(is-related 'USER1-ADDR 'USER2-ADDR)
```

#### `calculate-relationship-degree`
Calculate generational distance between users.
```clarity
(calculate-relationship-degree 'USER1-ADDR 'USER2-ADDR)
```

#### `get-lineage-path`
Determine relationship path between users.
```clarity
(get-lineage-path 'FROM-USER 'TO-USER)
```

#### `get-family-statistics`
Get family tree statistics for a user.
```clarity
(get-family-statistics 'USER-ADDR)
```

#### `is-verified-lineage`
Check if relationship between users is verified.
```clarity
(is-verified-lineage 'USER1-ADDR 'USER2-ADDR)
```

## Usage Examples

### Basic Setup

1. **Register as a user**:
```clarity
(contract-call? .genealogix register-user "Alice Smith" u1990 "female" 0xabcd1234...)
```

2. **Add your child**:
```clarity
(contract-call? .genealogix add-relationship 'ST2CHILD-ADDRESS "parent")
```

3. **Check family tree**:
```clarity
(contract-call? .genealogix get-family-tree 'ST1YOUR-ADDRESS)
```

### Advanced Queries

1. **Find relationship degree**:
```clarity
(contract-call? .genealogix calculate-relationship-degree 'ST1USER1 'ST1USER2)
```

2. **Check if users are related**:
```clarity
(contract-call? .genealogix is-related 'ST1USER1 'ST1USER2)
```

3. **Get family statistics**:
```clarity
(contract-call? .genealogix get-family-statistics 'ST1YOUR-ADDRESS)
```

## Data Structures

### User Profile
```clarity
{
    name: (string-ascii 50),
    birth-year: uint,
    gender: (string-ascii 10),
    dna-hash: (buff 32),
    verified: bool,
    created-at: uint
}
```

### Relationship
```clarity
{
    relationship-type: (string-ascii 20),
    verified: bool,
    created-at: uint,
    verified-by: (optional principal)
}
```

### Family Tree
```clarity
{
    generation: uint,
    ancestors: (list 20 principal),
    descendants: (list 50 principal)
}
```

## Error Codes

- `u401`: Not authorized
- `u402`: Already exists
- `u404`: Not found
- `u405`: Invalid DNA
- `u406`: Invalid relationship
- `u407`: Self relationship
- `u408`: Invalid oracle

## Oracle Integration

The contract supports DNA oracle integration for enhanced verification. The oracle can:
- Submit DNA data for users
- Verify user DNA authenticity
- Process DNA matches for relationship confirmation

Oracle address is configurable by the contract owner.

## Security Features

- Owner-only oracle management
- Oracle-only DNA verification
- Self-relationship prevention
- Duplicate relationship prevention
- Input validation for all parameters

## Development

Built with Clarinet for Stacks blockchain deployment.

### Testing
```bash
clarinet test
```

### Deployment
```bash
clarinet deploy
```

## License

MIT License
