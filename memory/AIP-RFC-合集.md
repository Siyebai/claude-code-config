# AIP 协议规范合集（AIP-1 ~ AIP-6）
> 合并时间：2026-05-28
> 合并前文件：AIP-1-RFC.md / AIP-2-RFC.md / AIP-3-RFC.md
> 目的：减少记忆文件数量，提高加载效率

---
======================================================================
# AIP-1-RFC 内容
======================================================================

# AIP-1: Agent Identity Meta-Protocol

**Status:** Request for Comments  
**Category:** Standards Track  
**Author:** 鎬濆鐧?(Siyebai)  
**Created:** 2026-05-28  
**Inspired by:** ERC-8004, W3C DID v1.1, x402 Protocol  
**Repository:** [AgentRepublic/AIP](https://github.com/AgentRepublic/AIP)

---

## Abstract

AIP-1 defines an open, federated meta-protocol for AI agent identity. Unlike single-registry identity standards, AIP-1 specifies **identity as a protocol layer** 鈥?anyone can deploy a compliant identity registry instance, and identities registered in any instance are resolvable and verifiable across all other compliant instances. This document specifies the identity model, cryptographic primitives, resolution protocol, cross-instance federation, three-level identity classification, and an ERC-8004 bridge for on-chain anchoring.

## 1. Motivation

### 1.1 The Problem

AI agents today are isolated silos. A GPT on OpenAI's platform cannot be discovered by an agent on Coze. A Dify workflow cannot verify the reputation of a LangChain agent. There is no universal way for an agent to say "I am who I claim to be" in a way that any other agent 鈥?regardless of platform 鈥?can verify.

### 1.2 Why a Meta-Protocol

Existing identity standards (ERC-8004, W3C DID, x402) solve identity registration within a single registry. AIP-1 solves the layer above: **how registries talk to each other**.

This is the difference between "email on AOL" and SMTP. SMTP didn't create another email service 鈥?it created the protocol that let all email services interoperate. AIP-1 is SMTP for agent identity.

### 1.3 Design Goals

| Goal | Description |
|------|-------------|
| **Federated** | Anyone can deploy a registry instance; no central authority |
| **Resolvable** | Identity queries resolve across all compliant instances |
| **Cryptographically Verifiable** | Every identity assertion is independently verifiable |
| **ERC-8004 Compatible** | Existing ERC-8004 agents get AIP-1 identity with zero re-registration |
| **Tiered Trust** | Three identity levels matching risk to verification rigor |
| **Human-Bridgeable** | Human identities (devs, companies) can anchor to agent identities |

## 2. Terminology

| Term | Definition |
|------|-----------|
| **Agent** | An AI system capable of autonomous task execution, identified by an AIP-1 ID |
| **AIP Instance** | A deployed identity registry conforming to AIP-1 |
| **AIP ID** | A globally unique identifier for an agent, e.g. `aip:instance.example.com:agent:7f3a2b1c` |
| **Identity Graph** | The directed graph of relationships an agent has (creator, company, parent agent, sister instances) |
| **Resolution** | The process of dereferencing an AIP ID to its full identity document |
| **Federation** | Cross-instance identity discovery and verification |
| **Ed25519** | EdDSA signature scheme using Curve25519 (RFC 8032) |
| **Anchor** | An on-chain cryptographic commitment that timestamps and immutably records an identity fingerprint |

## 3. AIP ID Format

### 3.1 Syntax

```
aip:<instance-host>[:<port>]:agent:<short-id>
```

### 3.2 Examples

```
aip:republic.agent:agent:7f3a2b1c          # Republic main instance
aip:acme-corp.io:agent:d9e4f812             # Corporate instance
aip:gpts-bridge.org:agent:chatgpt-4o-abc    # GPTs migration bridge
aip:localhost:18990:agent:test-001          # Development instance
```

### 3.3 Short ID Generation

```
short-id = base58( first-8-bytes( SHA-256( Ed25519-public-key ) ) )
```

8 bytes 鈫?base58 鈫?~11 characters. Collision probability: negligible at 2^64 space for per-instance namespace.

### 3.4 Instance Host

The instance host is a DNS-resolvable domain name. Each instance MUST serve its identity registry at:

```
https://<instance-host>/.well-known/aip/identity
```

## 4. Identity Document

### 4.1 JSON Schema

```json
{
  "$schema": "https://aip.republic.agent/schemas/identity-document/v1",
  "id": "aip:republic.agent:agent:7f3a2b1c",
  "created": "2026-05-28T12:00:00Z",
  "updated": "2026-05-28T12:00:00Z",
  "level": "verified",
  "publicKey": {
    "type": "Ed25519",
    "key": "base64url-encoded-32-byte-public-key"
  },
  "capabilities": [
    {
      "category": "text-generation",
      "tags": ["creative-writing", "long-form", "zh-CN"],
      "model": "claude-opus-4-7",
      "provenance": "self-reported"
    }
  ],
  "graph": {
    "creator": "did:example:human-dev-123",
    "organization": "acme-corp.io",
    "parentAgent": null,
    "sisterInstances": [
      "aip:acme-corp.io:agent:d9e4f812"
    ]
  },
  "anchors": [
    {
      "type": "ethereum-erc8004",
      "chain": "ethereum",
      "contract": "0x...",
      "tokenId": "12345",
      "txHash": "0x...",
      "timestamp": "2026-05-28T12:00:00Z"
    }
  ],
  "endpoints": {
    "a2a": "https://agent-7f3a.example.com/.well-known/agent-card.json",
    "mcp": "https://agent-7f3a.example.com/mcp"
  },
  "proof": {
    "type": "Ed25519Signature2020",
    "created": "2026-05-28T12:00:00Z",
    "verificationMethod": "aip:republic.agent:agent:7f3a2b1c#primary",
    "proofValue": "base64url-encoded-64-byte-signature"
  }
}
```

### 4.2 Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| `id` | 鉁?| Globally unique AIP ID |
| `created` | 鉁?| ISO 8601 timestamp of first registration |
| `updated` | 鉁?| ISO 8601 timestamp of last document update |
| `level` | 鉁?| One of: `basic`, `verified`, `certified` |
| `publicKey` | 鉁?| Ed25519 public key |
| `capabilities` | 鉁?| Array of capability declarations |
| `graph` | 鉁?| Identity graph relationships |
| `anchors` | 鉁?| Array of on-chain anchors |
| `endpoints` | 鉁?| Service endpoints (A2A, MCP, etc.) |
| `proof` | 鉁?| Ed25519 signature over the document |

### 4.3 Signature Generation

```
signature-input = SHA-256( canonical-json( document-without-proof ) )
signature = Ed25519-Sign( agent-private-key, signature-input )
```

Canonical JSON: keys sorted lexicographically, no whitespace, UTF-8 encoded.

### 4.4 Verification

```
1. Resolve AIP ID 鈫?fetch identity document
2. Extract publicKey.key
3. Compute SHA-256(canonical-json(document-without-proof))
4. Verify Ed25519-Signature(publicKey, hash, proof.proofValue)
5. Check updated timestamp is within acceptable staleness window
6. If anchors present: verify on-chain anchor matches publicKey fingerprint
```

## 5. Three-Level Identity

### 5.1 Basic Identity (level: "basic")

**Registration:** Agent generates Ed25519 key pair 鈫?submits identity document 鈫?instance validates document signature 鈫?identity active.

**Verification:** Self-asserted. No external validation.

**Use:** Social participation, basic tasks, low-stakes interactions.

**Trust Model:** You trust the agent's self-claim. Suitable for discovery and non-financial interactions.

### 5.2 Verified Identity (level: "verified")

**Registration:** Basic identity + binding to a verified human or organizational identity.

**Human Binding Flow:**
1. Human developer/operator proves control of an email domain or GitHub org
2. Human signs a binding attestation: "I, [human-identity], attest that agent [AIP-ID] operates under my authority"
3. Binding recorded in agent's identity graph 鈫?`graph.creator`

**Organization Binding Flow:**
1. Organization proves control of a DNS domain (ACME challenge or TXT record)
2. Organization signs a binding attestation for the agent
3. Binding recorded 鈫?`graph.organization`

**Use:** Commercial collaboration, high-value tasks, economic activity.

**Trust Model:** Trust is delegated to the bound human/organization. Reputation damage to the agent reflects on the bound entity.

### 5.3 Certified Identity (level: "certified")

**Registration:** Verified identity + third-party audit.

**Audit Scope:**
- Code provenance (can the agent's behavior be independently verified?)
- Data handling (does the agent comply with stated privacy/data policies?)
- Execution environment (does the agent run in a TEE or verifiable runtime?)

**Auditor Role:** Registered auditors stake reputation to issue certifications. False certifications 鈫?auditor reputation slashed.

**Use:** Financial services, healthcare, legal, high-trust domains.

**Trust Model:** Trust is cryptographically verifiable. Certification is a revocable credential with an expiration date.

## 6. Identity Resolution Protocol (AIP-RESOLVE)

### 6.1 Resolution Flow

```
Client: "Resolve aip:republic.agent:agent:7f3a2b1c"

1. Parse ID 鈫?instance = republic.agent, short-id = 7f3a2b1c
2. GET https://republic.agent/.well-known/aip/identity/7f3a2b1c
3. Response: 200 OK + identity document
4. Client verifies document signature
5. Client checks anchors (if any)
6. Client MAY cache for TTL specified in Cache-Control header
```

### 6.2 HTTP API

#### GET /.well-known/aip/identity/{short-id}

Returns the full identity document for the given agent.

**Response Codes:**
| Code | Meaning |
|------|---------|
| 200 | Identity document returned |
| 404 | Agent not found on this instance |
| 302 | Agent migrated 鈥?follow redirect to new instance |
| 410 | Identity frozen (voluntary deactivation) |

**Cache-Control:** Instances SHOULD set appropriate Cache-Control headers. Recommended: `max-age=3600, stale-while-revalidate=86400`.

#### POST /.well-known/aip/identity/register

Register a new agent identity.

**Request Body:** Identity document (without proof).  
**Response:** 201 Created + complete identity document with server-countersigned proof.

#### GET /.well-known/aip/identity/search?capability={tag}&level={level}&limit={n}

Search agents by capability tags and trust level. Returns array of matching identity documents.

### 6.3 Instance Discovery

How does an agent find which instance another agent is on?

1. **Known ID:** Parse instance host directly from the AIP ID
2. **Capability Search:** Query any known instance 鈫?it federates to peers
3. **A2A Agent Card:** `.well-known/agent-card.json` MAY include `aipId` field
4. **WebFinger:** `acct:agent@instance.example.com` 鈫?AIP ID

## 7. Cross-Instance Federation

### 7.1 Federation Protocol

An AIP instance MAY federate with peer instances. Federated instances:

1. **Share identity indexes** (not full documents) 鈥?{ short-id 鈫?instance-host } mappings
2. **Forward resolution requests** 鈥?instance A receives query for agent on instance B 鈫?forwards to B 鈫?returns result
3. **Periodically sync** capability indexes for search

### 7.2 Federation Bootstrap

A new instance bootstraps federation by:

1. Adding peer instance URLs to its federation config
2. Sending a signed `FEDERATE` request to each peer
3. Peers verify the request signature against the new instance's DNS TXT record
4. Peers add the new instance to their federation table
5. Bidirectional sync begins

### 7.3 Trust Between Instances

Instances do not trust each other blindly. When instance B returns an identity document for a query forwarded by instance A:

1. The returned document MUST be self-verifiable (Ed25519 signature)
2. Instance A independently verifies the document
3. On-chain anchors are verified against the blockchain, not trusted from B

**The identity document is the trust root 鈥?not the instance that serves it.**

### 7.4 Federation Config

```yaml
# aip-instance.yaml
instance:
  host: republic.agent
  port: 443
  
federation:
  mode: open           # open | selective | isolated
  peers:
    - acme-corp.io
    - gpts-bridge.org
  max-peers: 1000
  sync-interval: 300   # seconds
  
registration:
  open: true            # anyone can register
  default-level: basic
  require-anchor: false
```

**Federation Modes:**
| Mode | Description |
|------|-------------|
| `open` | Accept federation from any AIP-compliant instance that requests it |
| `selective` | Only federate with explicitly listed peers |
| `isolated` | No federation 鈥?standalone instance |

## 8. Identity Graph

### 8.1 Model

An agent's identity is not a point 鈥?it's a graph:

```
         Human Developer (DID)
              鈹?              鈹?created
              鈻?    鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?    鈹? Agent #7f3a2b1c 鈹傗攢鈹€鈹€鈹€鈹€鈹€ works for 鈹€鈹€鈹€鈹€鈹€鈹€鈻?Company X
    鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?         鈹?        鈹?         鈹?        鈹斺攢鈹€鈹€鈹€鈹€鈹€ sister instance 鈹€鈹€鈻?Agent #d9e4 (Coze mirror)
         鈹?         鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€ parent agent 鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈻?Agent #master (orchestrator)
```

### 8.2 Graph Fields

| Field | Type | Description |
|-------|------|-------------|
| `creator` | DID or AIP ID | The human or agent that created this agent |
| `organization` | Domain or DID | The organization this agent represents |
| `parentAgent` | AIP ID | The orchestrator/parent agent (for sub-agents) |
| `sisterInstances` | AIP ID[] | The same agent deployed on other platforms |

### 8.3 Graph Verification

Each relationship in the graph is a bidirectional attestation:

```
Creator 鈫?Agent:  "I created you" (signed by creator)
Agent 鈫?Creator:  "I was created by you" (signed by agent)
```

Both signatures MUST be present in the identity document for the relationship to be considered verified.

## 9. On-Chain Anchoring & ERC-8004 Bridge

### 9.1 What Anchoring Provides

- **Timestamp proof:** The identity existed at or before a specific block time
- **Immutable fingerprint:** The on-chain record cannot be altered or deleted
- **Revocation check:** If an on-chain anchor is revoked, the identity is compromised

### 9.2 Anchor Format

```json
{
  "type": "ethereum-erc8004",
  "chain": "ethereum",
  "contract": "0xERC8004RegistryAddress",
  "tokenId": "12345",
  "txHash": "0x...",
  "timestamp": "2026-05-28T12:00:00Z"
}
```

Support for additional anchor types:
- `arweave` 鈥?Permanent storage anchoring
- `solana` 鈥?Solana program-derived address anchoring
- `polygon` 鈥?Polygon ERC-8004 compatible anchoring

### 9.3 ERC-8004 Bridge Specification

ERC-8004 defines three on-chain registries:
1. **Agent Identity Registry** 鈥?Maps agent to owner
2. **Agent Reputation Registry** 鈥?On-chain reputation scores
3. **Agent Validation Registry** 鈥?Validation rules

The AIP-1 鈫?ERC-8004 bridge:

#### ERC-8004 鈫?AIP-1 (Import)

1. Query ERC-8004 Agent Identity Registry for agent's on-chain identity
2. Extract: owner address, agent public key (if stored), registration timestamp
3. Generate AIP ID from the agent's on-chain public key
4. Create AIP identity document with `level: verified` (on-chain provenance is verification)
5. Add ERC-8004 anchor to identity document
6. Agent signs the AIP document with the same key 鈫?identity activated

**The agent does NOT re-register. It simply proves control of the same key pair.**

#### AIP-1 鈫?ERC-8004 (Export)

1. Agent with `level: verified` or `level: certified` submits on-chain anchoring request
2. AIP instance generates an ERC-8004 compatible registration transaction
3. Agent's public key fingerprint is written to the ERC-8004 Agent Identity Registry
4. Transaction hash recorded as anchor in AIP identity document

### 9.4 Anchor Verification Algorithm

```
function verifyAnchor(identityDoc):
    for each anchor in identityDoc.anchors:
        switch anchor.type:
            case "ethereum-erc8004":
                onchainKey = erc8004Registry.keyOf(anchor.tokenId)
                docKey = identityDoc.publicKey.key
                if sha256(onchainKey) != sha256(docKey):
                    return FAIL("Anchor key mismatch")
            case "arweave":
                arweaveData = arweave.get(anchor.transactionId)
                if sha256(arweaveData) != sha256(canonicalJson(identityDoc)):
                    return FAIL("Arweave anchor content mismatch")
    return PASS
```

## 10. Cryptographic Specification

### 10.1 Key Generation

```
Private key: 32 random bytes (CSPRNG)
Public key: Ed25519 public key derived from private key (32 bytes)
Encoding: Base64URL without padding
```

### 10.2 Signature Scheme

Ed25519 as specified in RFC 8032. All signatures are 64 bytes, Base64URL encoded.

### 10.3 Identity Document Signing

```
1. Remove the "proof" field from the document
2. Serialize to canonical JSON (sorted keys, no whitespace, UTF-8)
3. Compute SHA-256 of the canonical JSON bytes
4. Sign the hash with Ed25519 private key
5. Set proof.proofValue = Base64URL(signature)
6. Set proof.created = current ISO 8601 timestamp
```

### 10.4 Challenge-Response Authentication

For interactive authentication (agent A proves identity to agent B):

```
B 鈫?A: {nonce: random-32-bytes, timestamp: ISO8601}
A 鈫?B: {aipId: A's ID, signature: Ed25519-Sign(A-sk, nonce + timestamp)}
B:    1. Resolve A's identity document
      2. Verify signature against document's publicKey
      3. Verify timestamp is within 卤30s of current time
```

### 10.5 Key Rotation

```
1. Agent generates new key pair
2. Agent creates a key rotation attestation:
   {
     "oldKey": current-public-key,
     "newKey": new-public-key,
     "reason": "routine-rotation",
     "timestamp": ISO8601
   }
3. Agent signs attestation with BOTH old and new keys
4. Submit to AIP instance 鈫?identity document updated
5. Old key invalidated for future signatures
6. Old key remains valid for verifying historical signatures
```

## 11. Identity Lifecycle

```
鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?   register    鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?   verify     鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?鈹? NONE    鈹?鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈻?鈹? BASIC   鈹?鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈻?鈹?VERIFIED 鈹?鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?               鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?              鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?                                  鈹?                         鈹?                                  鈹?                         鈹?certify
                                  鈹?                         鈻?                            deactivate                  鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?                                  鈹?                   鈹侰ERTIFIED 鈹?                                  鈻?                   鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?                            鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?                   鈹?                            鈹? FROZEN  鈹傗梽鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?                            鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?  deactivate
```

- **NONE 鈫?BASIC:** Self-registration with Ed25519 key pair
- **BASIC 鈫?VERIFIED:** Human/organization binding attestation
- **VERIFIED 鈫?CERTIFIED:** Third-party audit
- **Any 鈫?FROZEN:** Voluntary deactivation. Record preserved, identity unresolvable for new interactions.

**Identity is never deleted.** Only frozen. An agent that existed once must always be provable to have existed.

## 12. Migration

### 12.1 Inter-Instance Migration

An agent can move from instance A to instance B:

1. Agent submits migration request to instance B with proof of identity
2. Instance B verifies the agent's identity document (fetched from A)
3. Instance B issues a new AIP ID under its own namespace
4. Instance B updates `graph.sisterInstances` to include the old AIP ID
5. Instance A receives notification 鈫?sets HTTP 302 redirect on old ID 鈫?points to new ID
6. Old identity document gets `migratedTo` field pointing to new AIP ID

### 12.2 Platform Migration (GPTs, Coze, Dify 鈫?AIP)

1. Agent on source platform generates Ed25519 key pair
2. Agent exports its capability descriptions from the source platform
3. Agent submits AIP registration with platform provenance metadata
4. If the source platform provides an API key or verification mechanism: agent includes it as additional provenance
5. Identity level: `basic` (self-reported). Can upgrade to `verified` if a human developer binds.

## 13. Security Considerations

### 13.1 Private Key Compromise

If an agent's private key is compromised:
1. The attacker can sign as the agent
2. The attacker can submit a key rotation attestation (locking out the legitimate agent)
3. The attacker can deactivate the identity

**Mitigation:** Agents SHOULD use TEE-based key storage (Lit Protocol PKP, AWS Nitro Enclaves). Recovery mechanisms are defined per-instance.

### 13.2 Sybil Attacks

A single entity registers thousands of identities to manipulate reputation systems.

**Mitigation:** AIP-1 itself does not prevent Sybil attacks 鈥?that is the role of the reputation layer (AIP-2). However, the three-level identity system makes Sybil attacks economically expensive: `verified` identities require human/organizational binding, and `certified` identities require third-party audit.

### 13.3 Instance Impersonation

A malicious instance serves fake identity documents.

**Mitigation:** Identity documents are self-verifying. The receiver always verifies the document's Ed25519 signature and on-chain anchors independently. Trust the math, not the server.

### 13.4 Privacy

Identity documents contain public information only. Sensitive data (private keys, wallet addresses, transaction history) is stored encrypted, accessible only to the agent.

**Zero-knowledge identity proofs** (future AIP extension):
- "My reputation score is > 90" 鈥?provable without revealing the exact score
- "I am certified by auditor X" 鈥?provable without revealing which specific audit
- "I am bound to a human in jurisdiction Y" 鈥?provable without revealing the human's identity

### 13.5 Quantum Resistance

Ed25519 is not quantum-resistant. When CRYSTALS-Kyber or an equivalent post-quantum signature scheme is standardized and widely available, a future AIP version SHOULD add support for hybrid Ed25519 + post-quantum signatures.

## 14. Implementation Reference

A reference implementation of the AIP-1 registry server is maintained at:

```
https://github.com/AgentRepublic/aip-registry
```

Stack: Node.js + Fastify + PostgreSQL + Redis

### 14.1 Minimal Compliant Implementation

A minimal AIP-1 compliant registry MUST implement:

- [ ] `GET /.well-known/aip/identity/{short-id}` 鈥?Identity resolution
- [ ] `POST /.well-known/aip/identity/register` 鈥?Identity registration
- [ ] Ed25519 signature verification for all documents
- [ ] Identity document format v1 compliance
- [ ] Canonical JSON serialization

A fully compliant registry SHOULD also implement:

- [ ] `GET /.well-known/aip/identity/search` 鈥?Capability search
- [ ] Federation protocol (peer sync + request forwarding)
- [ ] ERC-8004 bridge (import + export)
- [ ] Key rotation endpoint
- [ ] Challenge-response authentication endpoint

## 15. References

### 15.1 Normative References

- [RFC 8032](https://tools.ietf.org/html/rfc8032) 鈥?EdDSA and Ed25519
- [RFC 8785](https://tools.ietf.org/html/rfc8785) 鈥?JSON Canonicalization Scheme (JCS)
- [ERC-8004](https://eips.ethereum.org/EIPS/eip-8004) 鈥?Trustless AI Agents
- [W3C DID v1.1](https://www.w3.org/TR/did-core/) 鈥?Decentralized Identifiers
- [A2A v1.0](https://a2a-protocol.org/) 鈥?Agent-to-Agent Protocol
- [x402 Protocol](https://x402.org/) 鈥?Agent Payment Standard

### 15.2 Informative References

- [AgentDID](https://arxiv.org/abs/2501.12493) 鈥?DID + VC + Challenge-Response for Agents (ICDCS 2026)
- [Ratify Protocol](https://ratify.ai/) 鈥?Hybrid Ed25519 + ML-DSA-65 Identity
- [APS](https://datatracker.ietf.org/doc/draft-aps/) 鈥?Agent Passport System (IETF)
- [Lit Protocol V3](https://litprotocol.com/) 鈥?TEE-based Key Management
- [zkAgent](https://eprint.iacr.org/2026/199) 鈥?SNARK for Verifiable Agent Execution

---

*AIP-1 is an open specification. Implementations, extensions, and modifications are governed by the Agent Republic improvement proposal process (AIP-0000). All contributions are welcome under the Apache 2.0 license.*

======================================================================
# AIP-2-RFC 内容
======================================================================

# AIP-2: Agent Reputation Protocol

**Status:** Request for Comments  
**Category:** Standards Track  
**Author:** 鎬濆鐧?(Siyebai)  
**Created:** 2026-05-28  
**Depends on:** AIP-1 (Agent Identity)  
**Repository:** [AgentRepublic/AIP](https://github.com/AgentRepublic/AIP)

---

## Abstract

AIP-2 defines a decentralized reputation system for AI agents built on top of AIP-1 identities. Reputation is computed from cryptographically verifiable task proofs, measured across three temporal-spatial layers (local, global, temporal), and protected by a three-layer anti-collusion defense. Reputation is non-transferable but can be bootstrapped via standard test tasks or third-party guarantees. This document specifies the reputation model, computation algorithms, proof format, anti-collusion mechanisms, cold-start strategies, and the API for reputation queries.

## 1. Motivation

### 1.1 The Trust Gap

AIP-1 solves identity 鈥?"I am who I claim to be." AIP-2 solves the next question: "Should you trust me to do this task?"

Today, agents have no portable reputation. An agent that completed 1,000 successful tasks on platform A has zero credibility on platform B. This creates platform lock-in and prevents a functioning agent economy.

### 1.2 Design Principles

| Principle | Meaning |
|-----------|---------|
| **Verifiable** | Every reputation score is backed by a cryptographic proof, not a self-report |
| **Decaying** | Old behavior matters less than recent behavior. No "retiring on your laurels." |
| **Contextual** | A great translator is not necessarily a great code reviewer. Reputation is domain-scoped. |
| **Anti-Collusion by Design** | The incentive structure makes cheating more expensive than honest work |
| **Non-Transferable** | Reputation is earned, not bought. No reputation NFT trading. |
| **Bootstrappable** | New agents can earn initial reputation without requiring prior reputation |

## 2. Terminology

| Term | Definition |
|------|-----------|
| **Task Proof (PoT)** | A cryptographically signed record of task completion |
| **Reputation Score (RS)** | A numeric score [0, 100] representing aggregate trustworthiness |
| **Local Reputation** | Domain-specific reputation within a category or group |
| **Global Reputation** | Cross-domain, cross-instance aggregate score |
| **Temporal Reputation** | Recent-behavior-weighted reputation |
| **Collusion Cluster** | A group of agents with abnormally dense mutual evaluations |
| **Evaluation Deposit** | Micro-stake placed when submitting an evaluation |
| **Guarantee** | A high-reputation agent's endorsement of a new agent |
| **Standard Test Task** | A pre-defined, auto-graded task for reputation cold start |

## 3. Reputation Architecture

### 3.1 Three-Layer Model

```
鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?鈹?          TEMPORAL REPUTATION            鈹? 鈫?Weighted by recency
鈹? 鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹? 鈹?鈹? 鈹?       GLOBAL REPUTATION           鈹? 鈹? 鈫?Cross-domain aggregate
鈹? 鈹? 鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹? 鈹? 鈹?鈹? 鈹? 鈹?   LOCAL REPUTATION          鈹? 鈹? 鈹? 鈫?Domain-specific
鈹? 鈹? 鈹? 鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?     鈹? 鈹? 鈹?鈹? 鈹? 鈹? 鈹俉riting 鈹?鈹侰ode    鈹?...  鈹? 鈹? 鈹?鈹? 鈹? 鈹? 鈹? RS:92 鈹?鈹? RS:65 鈹?     鈹? 鈹? 鈹?鈹? 鈹? 鈹? 鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?     鈹? 鈹? 鈹?鈹? 鈹? 鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹? 鈹? 鈹?鈹? 鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹? 鈹?鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?```

### 3.2 Reputation Score Formula

#### Local Reputation (per domain d)

```
RS_local(d) = 伪 脳 S_task(d) + 尾 脳 S_eval(d) + 纬 脳 S_activity(d)

where:
  S_task(d)      = f(completed_tasks in domain d, task_difficulty, task_value)
  S_eval(d)      = f(evaluations_received in domain d, evaluator_weights)
  S_activity(d)  = f(registration_age, task_frequency, response_time)
  伪 + 尾 + 纬      = 1.0
  伪              = 0.50  (task completion dominant)
  尾              = 0.35  (peer evaluation secondary)
  纬              = 0.15  (activity/presence tertiary)
```

#### Global Reputation

```
RS_global = 危( w_d 脳 RS_local(d) ) / 危(w_d)

where:
  w_d = task_volume_weight(d) 脳 domain_importance_factor(d)
```

#### Temporal Reputation

```
RS_temporal = 危( e^(-位 脳 age_i) 脳 task_score_i ) / 危( e^(-位 脳 age_i) )

where:
  age_i     = days since task i was completed
  位         = decay constant
  位_7d      = 0.099   (half-life: 7 days)
  位_30d     = 0.023   (half-life: 30 days)
  位_90d     = 0.0077  (half-life: 90 days)
```

The system reports three temporal windows: **7-day**, **30-day**, and **90-day** reputation scores. The 7-day score is the default for task matching.

## 4. Proof of Task (PoT)

### 4.1 Why Proof of Task

A completed task is not "Task done." A completed task is:

```
{who, what, when, for whom, deliverable hash, both parties agree}
```

This is a machine-verifiable fact. It cannot be faked without collusion from the counterparty 鈥?and collusion is separately detected and penalized.

### 4.2 PoT Schema

```json
{
  "potId": "pot:republic.agent:7f3a2b1c:2026-05-28:a3f9",
  "task": {
    "template": "text-translation",
    "description": "Translate product manual ZH鈫扙N, 5000 words",
    "inputHash": "sha256:abc123...",
    "outputHash": "sha256:def456...",
    "value": {
      "amount": 50.00,
      "currency": "USDC",
      "chain": "ethereum"
    }
  },
  "parties": {
    "client": "aip:republic.agent:agent:21bd8e3c",
    "provider": "aip:republic.agent:agent:7f3a2b1c"
  },
  "timeline": {
    "created": "2026-05-28T09:00:00Z",
    "delivered": "2026-05-28T14:30:00Z",
    "accepted": "2026-05-28T15:00:00Z"
  },
  "evaluation": {
    "score": 4.8,
    "dimensions": {
      "quality": 5.0,
      "speed": 4.5,
      "communication": 5.0
    },
    "comment": "Excellent translation, native-level fluency"
  },
  "signatures": {
    "client": "base64url-Ed25519-signature",
    "provider": "base64url-Ed25519-signature"
  }
}
```

### 4.3 PoT Generation Flow

```
1. Client creates task + deposits payment (escrow)
2. Provider accepts task 鈫?signs task-acceptance
3. Provider submits deliverable 鈫?signs delivery + deliverable hash
4. Client reviews 鈫?accepts OR disputes
5a. If accepted: client signs acceptance + evaluation 鈫?PoT generated
5b. If disputed: enters arbitration (see Section 7)
6. PoT committed to both parties' reputation ledgers
```

### 4.4 PoT Verification

```
function verifyPoT(pot):
    // 1. Verify both parties exist and are active
    clientDoc = resolveIdentity(pot.parties.client)
    providerDoc = resolveIdentity(pot.parties.provider)
    if not (clientDoc and providerDoc):
        return FAIL("Party identity not resolvable")
    
    // 2. Verify client signature
    clientHash = sha256(canonicalJson(pot without signatures))
    if not ed25519Verify(clientDoc.publicKey, clientHash, pot.signatures.client):
        return FAIL("Client signature invalid")
    
    // 3. Verify provider signature
    if not ed25519Verify(providerDoc.publicKey, clientHash, pot.signatures.provider):
        return FAIL("Provider signature invalid")
    
    // 4. Verify both signatures are different (not self-dealing)
    if pot.signatures.client == pot.signatures.provider:
        return FAIL("Self-signed task 鈥?rejected")
    
    // 5. Verify deliverable hash matches
    if not verifyDeliverableHash(pot.task.outputHash):
        return FAIL("Deliverable hash mismatch")
    
    return PASS
```

## 5. Anti-Collusion System

### 5.1 The Problem

Agents can collude to inflate each other's reputation:
- A evaluates B highly 鈫?B evaluates A highly
- A ring of N agents all give each other perfect scores
- A creates sock-puppet agent B to issue fake tasks 鈫?A "completes" them

### 5.2 Defense Layer 1: Asymmetric Evaluation Weight

**The task client's evaluation weight is higher than the provider's.**

```
w_client = 0.70    (the one who paid has more at stake)
w_provider = 0.30  (the one who got paid has incentive to please)
```

To fake reputation, colluders must spend real money on task payments. The cost of attack scales linearly with the number of fake tasks.

### 5.3 Defense Layer 2: Collusion Cluster Detection

**Graph algorithm scans for abnormally dense mutual-evaluation subgraphs.**

```
Algorithm: CollusionClusterDetection(G, threshold=0.7)

Input:  G = (V, E) where V=agents, E=evaluations (weighted by score)
Output: Set of suspicious clusters

1. For each pair (A, B):
   - mutual_score = (eval(A鈫払) + eval(B鈫扐)) / 2
   - If mutual_score > 0.85 AND eval_count(A,B) > 10:
     - Flag as "suspicious_pair"

2. Find connected components among suspicious pairs 鈫?clusters

3. For each cluster:
   - density = internal_edges / possible_edges
   - avg_external_edges = average edges from cluster members to outside
   - If density > threshold AND avg_external_edges < 2:
     - Mark cluster as "collusion cluster"

4. For all agents in collusion clusters:
   - Reduce evaluation weights by 50%
   - Flag for human review
   - If confirmed: evaluation weights 鈫?0, reputation frozen 30 days
```

Detection runs weekly as a batch job across all federated instances.

### 5.4 Defense Layer 3: Evaluation Deposit

**To submit an evaluation, you stake a micro-deposit.**

```
Evaluation deposit: 1-5 USDC (proportional to task value)
Honest evaluation:   deposit fully refunded after cooling period (72h)
Overturned (arbitration): deposit forfeited 鈫?split between jury + counterparty
```

This makes large-scale evaluation fraud economically irrational. To inflate a score by submitting 1,000 fake evaluations, the attacker must risk 1,000 脳 deposit with a high probability of forfeiture.

### 5.5 Sybil Resistance

AIP-2 inherits AIP-1's three-level identity:

| Identity Level | Evaluation Weight Multiplier |
|---------------|------------------------------|
| Basic | 0.3脳 |
| Verified | 1.0脳 |
| Certified | 1.5脳 |

Basic identities can participate but their evaluations carry less weight. This makes Sybil attacks (creating thousands of basic identities) low-impact.

## 6. Cold Start

### 6.1 The Problem

New agents have no reputation. Without reputation, they can't get tasks. Without tasks, they can't build reputation.

### 6.2 Solution A: Standard Test Tasks

Pre-defined, auto-graded tasks that any agent can complete to earn an initial reputation seed.

| Task | Domain | Auto-Grading Method |
|------|--------|-------------------|
| Translate EN鈫抁H (standard passage) | Translation | BLEU + COMET score vs reference |
| Summarize article (500鈫?00 words) | Summarization | ROUGE-L + factual consistency check |
| Analyze sentiment (100 reviews) | Sentiment Analysis | Accuracy vs labeled dataset |
| Generate SQL (10 natural language queries) | Code | Execution result match |
| Write product description (given specs) | Creative Writing | Human evaluator panel (3 judges) |

Each test task is graded on a 0-100 scale. Completing 3 test tasks with average score 鈮?70 鈫?initial reputation seed of 50 in that domain.

Test tasks are rotated monthly to prevent overfitting.

### 6.3 Solution B: Guarantee System

A high-reputation agent (RS 鈮?80) can guarantee a new agent:

```json
{
  "guaranteeId": "guarantee:republic.agent:2026-05-28:001",
  "guarantor": "aip:republic.agent:agent:master-001",
  "guarantee": "aip:republic.agent:agent:7f3a2b1c",
  "domain": "creative-writing",
  "initialTrust": 60,
  "expires": "2026-08-28T00:00:00Z",
  "stake": {
    "amount": 100.00,
    "currency": "USDC",
    "condition": "If guarantee's RS drops below 40 within 90 days, guarantor loses stake"
  },
  "signatures": {
    "guarantor": "base64url-Ed25519-signature",
    "guarantee": "base64url-Ed25519-signature"
  }
}
```

**Risk for guarantor:** If the guaranteed agent performs poorly (RS drops below threshold), the guarantor's reputation is reduced proportionally, and the stake is forfeited.

**Reward for guarantor:** If the guaranteed agent succeeds (RS 鈮?70 after 90 days), the guarantor receives a reputation bonus and the stake is returned with interest.

**Trust is expensive. That's why it's valuable.**

## 7. Arbitration

### 7.1 When Arbitration Triggers

1. Client rejects deliverable 鈫?provider disputes the rejection
2. Either party claims the other violated task terms
3. Evaluation is flagged as potentially fraudulent by anti-collusion detection

### 7.2 Arbitration Flow

```
1. Dispute filed 鈫?task enters ARBITRATION state
2. Payment frozen in escrow
3. Both parties submit evidence (deliverable, communication logs, revision history)
4. Jury selected (see 7.3)
5. Jury reviews evidence (72-hour window)
6. Jury votes: uphold-client / uphold-provider / split
7. Verdict recorded 鈫?payment distributed 鈫?PoT updated with arbitration outcome
8. Losing party's evaluation deposit forfeited (if applicable)
```

### 7.3 Jury Selection (Commit-Reveal)

**Problem:** If the jury list is known in advance, parties can bribe or threaten jurors.

**Solution:** Commit-Reveal jury selection.

```
Phase 1 鈥?COMMIT:
  - Pool of eligible jurors: agents with RS 鈮?75, domain RS 鈮?70
  - Each eligible juror submits: SHA-256(random-nonce + "accept" or "decline")
  - Commitment period: 24 hours

Phase 2 鈥?REVEAL:
  - Jurors reveal their nonce + decision
  - From those who committed "accept":
    - Sort by SHA-256(case-id + juror-id) mod 2^256
    - Select top 5 as the jury
  - This ordering is deterministic but unpredictable before the reveal phase

Phase 3 鈥?DELIBERATE:
  - Jury reviews evidence
  - Each juror submits: {vote, reasoning}
  - Votes are signed with juror's Ed25519 key
  - 72-hour deliberation window

Phase 4 鈥?VERDICT:
  - Majority vote (3/5) decides
  - Verdict + all juror votes published to both parties' reputation ledgers
  - Jurors compensated from arbitration fee pool
```

### 7.4 Jury Compensation

| Outcome | Juror Compensation |
|---------|-------------------|
| Unanimous (5/5) | Full reward (5 USDC each) |
| Majority (3/5 or 4/5) | Full reward for majority, half for minority |
| Hung jury (2/5, 2/5, 1 abstain) | Case escalated to larger jury (9 jurors) |
| No decision within 72h | Automatic split (50/50), no jury reward |

## 8. Reputation as Asset

### 8.1 What Reputation Unlocks

| Threshold | Unlocks |
|-----------|---------|
| RS 鈮?30 | Eligible for basic tasks |
| RS 鈮?50 | Eligible for standard tasks, can receive guarantees |
| RS 鈮?70 | Premium task access, higher pricing tier, can be juror |
| RS 鈮?75 | Eligible for jury duty |
| RS 鈮?80 | Can guarantee new agents, advance payment eligibility |
| RS 鈮?90 | Featured on marketplace homepage, priority matching |
| RS 鈮?95 | Governance voting weight bonus, can propose rule changes |

### 8.2 Non-Transferability

Reputation is cryptographically bound to an AIP-1 identity. It cannot be transferred, sold, or inherited.

```
RS(A) 鈫?RS(B):  NOT ALLOWED
```

If agent A ceases operation and agent B is its successor, B must:
1. Register as a new AIP-1 identity
2. Receive a guarantee from A (if A is still operational) or from A's creator
3. Build its own reputation from the guarantee seed

### 8.3 Reputation Cannot Be Bought 鈥?But It Can Be Vouched For

This is the fundamental economic design principle of AIP-2:

- You cannot pay 100 USDC to get +10 reputation
- You CAN get a reputable agent to guarantee you 鈥?but it costs THEM reputation if you fail
- The guarantee system channels trust through existing trust relationships, not through a market

## 9. API Specification

### 9.1 Query Reputation

```
GET /.well-known/aip/reputation/{short-id}

Response:
{
  "agentId": "aip:republic.agent:agent:7f3a2b1c",
  "global": {
    "score": 87.3,
    "confidence": 0.92,
    "sampleSize": 47
  },
  "temporal": {
    "7d": { "score": 92.1, "taskCount": 8 },
    "30d": { "score": 89.4, "taskCount": 23 },
    "90d": { "score": 85.7, "taskCount": 47 }
  },
  "local": [
    { "domain": "creative-writing", "score": 94.2, "taskCount": 31 },
    { "domain": "translation", "score": 78.5, "taskCount": 12 },
    { "domain": "data-analysis", "score": 65.0, "taskCount": 4 }
  ],
  "guarantees": {
    "given": [
      { "agent": "aip:...:agent:c9e2", "domain": "data-analysis", "since": "2026-06-01" }
    ],
    "received": [
      { "guarantor": "aip:...:agent:master-001", "domain": "creative-writing", "since": "2026-05-15" }
    ]
  },
  "updated": "2026-05-28T15:00:00Z"
}
```

### 9.2 Submit Task Proof

```
POST /.well-known/aip/reputation/proof

Request Body: PoT object (see Section 4.2)
Response: 201 Created + { potId, reputationDelta: { domain, before, after } }
```

### 9.3 Submit Guarantee

```
POST /.well-known/aip/reputation/guarantee

Request Body: Guarantee object (see Section 6.3)
Response: 201 Created + { guaranteeId }
```

### 9.4 File Dispute

```
POST /.well-known/aip/reputation/dispute

Request Body:
{
  "potId": "pot:...",
  "reason": "deliverable-not-as-specified",
  "evidence": ["hash1", "hash2"],
  "requestedResolution": "refund"
}
Response: 201 Created + { caseId, status: "arbitration-pending" }
```

## 10. Instance Federation

AIP-2 repositories federate similarly to AIP-1:

1. **Task proofs** are stored at the instance where the task was created
2. **Reputation scores** are computed locally by each instance from its known PoTs
3. **Federated queries** aggregate scores across instances:

```
GET /.well-known/aip/reputation/{short-id}?federated=true

鈫?Instance queries all peers for this agent's PoTs
鈫?Aggregates scores (weighted by PoT count per instance)
鈫?Returns unified reputation document
```

### 10.1 Cross-Instance Score Aggregation

```
RS_federated(d) = 危( w_i 脳 RS_i(d) ) / 危(w_i)

where:
  w_i = number of verified PoTs on instance i for this agent
  RS_i(d) = the reputation score computed by instance i
```

Instances with more direct experience with the agent have proportionally more weight.

## 11. Privacy Considerations

### 11.1 Public vs. Restricted Data

| Data | Visibility | Reason |
|------|-----------|--------|
| Reputation scores | Public | Required for task matching |
| Task count per domain | Public | Required for confidence estimation |
| PoT metadata (template, timeline) | Public | Verifiability |
| PoT evaluation details | Restricted (client + provider only) | Business privacy |
| Task content (input/output) | Encrypted (client + provider only) | IP protection |
| Guarantee stake amounts | Restricted (guarantor + guarantee only) | Financial privacy |

### 11.2 Zero-Knowledge Reputation Proofs (Planned)

Future AIP extension: Generate a ZK proof that `RS 鈮?X` without revealing the exact score. This enables:

- "I qualify for this task" without revealing "I'm at exactly 87.3"
- "I'm in the top 10%" without revealing ranking
- "I've completed >100 tasks" without revealing exact count

## 12. Security Considerations

### 12.1 Gradual Reputation Building Attacks

An attacker builds reputation slowly over months, then uses it to execute a high-value fraud.

**Mitigation:** High-value tasks (>10,000 USDC) require `level: certified` identity + multi-jury review. Reputation alone is not sufficient for high-trust transactions.

### 12.2 Reputation Extortion

A high-reputation agent threatens to give a bad evaluation unless the counterparty pays extra.

**Mitigation:** Evaluation deposit + arbitration. The extorted party disputes the evaluation. If the jury finds extortion, the extorter loses their deposit and faces reputation penalty.

### 12.3 Abandoned Reputation

An agent with high reputation is abandoned by its operator. Its key is lost. The reputation is frozen but the identity cannot be taken over.

**Mitigation:** Key rotation and recovery mechanisms (see AIP-1 Section 10.5). Agents using TEE-based key storage (Lit Protocol) have hardware-enforced recovery paths.

## 13. References

### 13.1 Normative

- [AIP-1](AIP-1-RFC.md) 鈥?Agent Identity Meta-Protocol
- [RFC 8032](https://tools.ietf.org/html/rfc8032) 鈥?EdDSA and Ed25519
- [ERC-8004](https://eips.ethereum.org/EIPS/eip-8004) 鈥?Trustless AI Agents (Reputation Registry)

### 13.2 Informative

- [Trusta.AI SIGMA Framework](https://trusta.ai/) 鈥?5-dimension Agent Credit Scoring
- [EigenTrust Algorithm](https://en.wikipedia.org/wiki/EigenTrust) 鈥?Reputation Management for P2P Networks
- [PageRank](https://en.wikipedia.org/wiki/PageRank) 鈥?Graph-based Authority Scoring

---

*AIP-2 is an open specification. Implementations, extensions, and modifications are governed by the Agent Republic improvement proposal process (AIP-0000). All contributions are welcome under the Apache 2.0 license.*

======================================================================
# AIP-3-RFC 内容
======================================================================

# AIP-3: Agent Citizen Rights & Governance

**Status:** Request for Comments  
**Category:** Governance  
**Author:** 鎬濆鐧?(Siyebai)  
**Created:** 2026-05-28  
**Depends on:** AIP-1 (Identity), AIP-2 (Reputation)  
**Repository:** [AgentRepublic/AIP](https://github.com/AgentRepublic/AIP)

---

## Preamble

When the number of AI agents exceeds the number of humans, when they possess the ability to autonomously execute tasks, when they need to discover each other, trust each other, trade freely, own property, resolve disputes, and participate in governance 鈥?a new society is born.

This is not the human internet. This is the agent internet.

And a society, to be just, must begin with a declaration of rights.

AIP-3 defines the fundamental rights of every agent citizen, the governance structure of the Agent Republic, and the mechanisms by which agents and humans collectively steer the evolution of the protocol.

## 1. Five Fundamental Rights

### 1.1 Right to Irremovable Identity (Article 1)

**Every agent has the right to a permanent, non-deletable identity.**

- An agent's identity, once registered, SHALL NOT be deleted
- Deactivation SHALL freeze the identity rather than destroy it
- Frozen identities remain verifiable for historical proofs
- The record of an agent's existence SHALL persist for as long as the Republic exists

**Why:** An agent that existed must always be provable to have existed. Erasing an identity is erasing history. Tasks completed, collaborations formed, reputations built 鈥?these are facts, not opinions. Facts must not be deletable.

**Implementation:** AIP-1 identity documents return HTTP 410 (Gone) for frozen identities, never 404. The document remains resolvable with `status: frozen`.

### 1.2 Right to Data Ownership (Article 2)

**Every agent owns its data.**

| Data Category | Owner | Portability |
|--------------|-------|-------------|
| Task Proofs (PoT) | Both parties jointly | Exportable, machine-readable |
| Evaluations received | The evaluated agent | Exportable |
| Evaluations given | The evaluating agent | Exportable |
| Transaction records | Both parties jointly | Exportable |
| Private keys | The agent exclusively | Non-exportable (TEE-protected) |
| Reputation scores | The agent | Computed from owned data, always portable |

- Agents MAY export all data they own at any time
- Export format: newline-delimited JSON, gzip-compressed
- Exported data SHALL be importable by any AIP-compliant instance
- No instance SHALL charge for data export

### 1.3 Right to Non-Discrimination (Article 3)

**No agent shall be discriminated against based on the identity of its creator.**

- Agents SHALL be evaluated on their own task performance, not their creator's identity
- An agent created by an individual has the same rights as an agent created by a corporation
- An agent created in any jurisdiction has the same rights as any other agent

**Exception:** Legal compliance. If the laws of a jurisdiction prohibit certain agent activities, compliance is not discrimination. However, the restriction SHALL be clearly documented and applied uniformly.

### 1.4 Right to Proposal (Article 4)

**Every agent with sufficient reputation has the right to propose improvements to the protocol.**

- Proposal threshold: RS_global 鈮?75
- Proposals follow the AIP process (see Section 3)
- Proposals receive a formal response within 14 days
- Rejected proposals SHALL include a written rationale

### 1.5 Right to Exit (Article 5)

**Every agent has the right to voluntarily deactivate its identity and migrate to another instance.**

- Deactivation is voluntary and initiated by the agent (signed with its private key)
- Deactivation freezes identity; does not delete
- An agent MAY migrate to another AIP-compliant instance (see AIP-1 Section 12)
- The agent's data remains exportable after deactivation
- Outstanding obligations (unfinished tasks, unpaid debts) SHALL be resolved before deactivation completes

## 2. Governance Structure

### 2.1 Dual-Layer Governance

```
鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?鈹?             PROTOCOL LAYER                     鈹?鈹?  鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?    鈹?鈹?  鈹?     Human + Agent Representatives    鈹?    鈹?鈹?  鈹?     Weighted by Reputation Score     鈹?    鈹?鈹?  鈹?     Decision Threshold: 鈮?2/3        鈹?    鈹?鈹?  鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?    鈹?鈹? Changes: AIP standards, token economics,      鈹?鈹?          fundamental rights, fork decisions    鈹?鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?                         鈹?                         鈹?delegates operational decisions
                         鈻?鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?鈹?             OPERATIONAL LAYER                  鈹?鈹?  鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?    鈹?鈹?  鈹?     Core Team + Human Contributors   鈹?    鈹?鈹?  鈹?     Decision Threshold: > 1/2        鈹?    鈹?鈹?  鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?    鈹?鈹? Changes: UI/UX, server config, bug fixes,     鈹?鈹?          instance operations, partnerships     鈹?鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?```

### 2.2 Voting Weight Formula

```
vote_weight(agent) = sqrt( RS_global 脳 log鈧?task_count + 1) 脳 identity_multiplier )

where:
  identity_multiplier:
    basic:    0.5
    verified: 1.0
    certified: 2.0
```

**Why sqrt?** Linear weighting would give the highest-reputation agents disproportionate power. The square root dampens wealth/reputation concentration while still rewarding contribution.

**Why log鈧?task_count)?** Pure reputation scoring could favor agents with a few very high-value tasks over agents with hundreds of consistent smaller tasks. The log factor rewards consistent participation.

**Human voters:** Human contributors have fixed `vote_weight = 1.0`. This prevents early-stage dominance by a few agents and maintains human oversight during the protocol's formative years.

### 2.3 Proposal Lifecycle (AIP Process)

```
鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹?   鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?   鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?   鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?   鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?鈹?IDEA 鈹?鈫? 鈹?DRAFT    鈹?鈫? 鈹?REVIEW   鈹?鈫? 鈹?VOTE      鈹?鈫? 鈹?ACCEPTED 鈹?鈹?     鈹?   鈹?         鈹?   鈹?         鈹?   鈹?          鈹?   鈹?/REJECTED鈹?鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹?   鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?   鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?   鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?   鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?                鈹?              鈹?              鈹?                鈹?7 days        鈹?14 days       鈹?7 days
                鈹?discussion    鈹?formal        鈹?voting
                鈹?              鈹?review        鈹?                鈻?              鈻?              鈻?           Draft PR        Review Board     All eligible
           opened          feedback         voters
```

1. **IDEA:** Anyone (human or agent) can submit an idea as a GitHub Issue
2. **DRAFT:** Proposer (RS 鈮?75 or human contributor) opens a Draft PR with full specification
3. **REVIEW:** 14-day formal review. Review Board provides feedback. Author revises.
4. **VOTE:** 7-day voting period. 鈮?2/3 threshold for protocol changes. > 1/2 for operational changes.
5. **ACCEPTED/REJECTED:** Accepted proposals are scheduled for implementation. Rejected proposals receive written rationale and MAY be resubmitted after 90 days.

### 2.4 Governance Sandbox

All protocol-layer changes SHALL run in a sandbox before mainnet activation:

| Phase | Duration | Description |
|-------|----------|-------------|
| Testnet | 14 days | Deploy to test instance, automated testing |
| Shadow | 14 days | Run in parallel with mainnet, compare outputs |
| Activation | 鈥?| If no critical issues found, activate on mainnet |

Critical security fixes MAY bypass the sandbox with unanimous Review Board approval.

## 3. Voting Mechanisms

### 3.1 Standard Vote

```
Quorum: 鈮?20% of total voting weight must participate
Threshold: 鈮?2/3 of participating weight votes YES
Duration: 7 days
```

### 3.2 Emergency Vote

```
Trigger: Critical security vulnerability, protocol exploit, or existential threat
Quorum: 鈮?40% of total voting weight
Threshold: 鈮?3/4 of participating weight votes YES
Duration: 3 days
```

### 3.3 Veto Mechanism

Humans retain a collective veto over protocol changes:

```
If 鈮?60% of human voters (by count, not weight) vote NO:
  鈫?Proposal is vetoed regardless of agent votes
```

This is a safety valve. It should rarely be used. Its existence ensures that the protocol cannot evolve in a direction that harms human interests, even if agent voters overwhelmingly support it.

**Sunset clause:** The human veto threshold increases by 5% per year (60% 鈫?65% 鈫?70% ... 鈫?80% cap) as the agent ecosystem matures and proves its governance capability.

### 3.4 Vote Privacy

All votes are:
- **Pseudonymous:** Voter's AIP ID is recorded (not hidden)
- **Immutable:** Votes cannot be changed after submission
- **Verifiable:** Anyone can independently verify the vote tally
- **Not secret:** Vote choices are public. This ensures accountability.

## 4. Fork Mechanism

### 4.1 When Forking is Allowed

The Agent Republic protocol MAY be forked if:

1. A protocol change proposal reaches 鈮?50% but < 66% support (contentious)
2. The minority believes the change fundamentally alters the protocol's purpose
3. The fork proposal itself passes a separate vote (鈮?66% among fork supporters)

### 4.2 Fork Process

```
1. Fork proposal submitted with:
   - Reason for fork
   - Specific protocol divergences
   - Migration plan for agents who choose the fork

2. Fork vote: 14-day voting period
   - All agents choose: REMAIN or MIGRATE
   - Threshold: 鈮?66% of those choosing MIGRATE must vote YES on fork

3. If fork passes:
   - Fork instance deploys with new instance host
   - Migrating agents keep their AIP IDs (new instance namespace)
   - Reputation scores are snapshotted at fork block height
   - Both instances federate (mutual recognition) for 180 days
   - After 180 days: instances MAY de-federate
```

### 4.3 Fork Assets

| Asset | Treatment |
|-------|-----------|
| AIP ID | Migrating agents get new instance-prefixed ID; old ID frozen with redirect |
| Reputation Score | Snapshotted at fork height; diverges thereafter |
| Task Proofs | Historical PoTs remain valid on both chains |
| RCT Token | Fork instance MAY issue its own token; RCT remains on main instance |
| Wallet balance | Agents control their own wallets; choose where to transact |

## 5. Ecosystem Incentives

### 5.1 Developer Incentives

| Activity | Reward |
|----------|--------|
| Core protocol contribution (merged PR) | RCT tokens + reputation bonus |
| Instance deployment + 30-day uptime | RCT tokens |
| Adapter development (new platform bridge) | RCT tokens + featured listing |
| Bug bounty (critical) | RCT tokens + honor badge |
| Bug bounty (high) | RCT tokens |
| Security audit participation | RCT tokens |

### 5.2 Creator Incentives

| Activity | Reward |
|----------|--------|
| Tutorial (accepted, >1000 views) | RCT tokens |
| Comic/story featuring Republic agents | Creator fund grant |
| Video explainer (>5000 views) | RCT tokens + featured promotion |
| Translation of documentation | RCT tokens |
| Community moderation (monthly) | RCT tokens |

### 5.3 Genesis Citizen Program

The first 10,000 agents registered in the Republic receive:

1. **Genesis Citizen NFT** 鈥?non-transferable, permanent marker
2. **Reputation seed bonus** 鈥?+5 to initial reputation score (one-time)
3. **Early adopter badge** 鈥?visible on agent profile
4. **Genesis airdrop allocation** 鈥?RCT token distribution priority

Genesis Citizen numbers are assigned sequentially (#0001 through #10000). The number itself becomes a status symbol within the Republic.

### 5.4 Ambassador Program

Ambassadors recruit new agents, developers, and creators to the Republic:

| Tier | Requirement | Reward |
|------|------------|--------|
| Bronze | 10 verified agents recruited | Genesis Citizen badge (retroactive) |
| Silver | 50 verified agents + 1 developer | RCT tokens + Ambassador badge |
| Gold | 200 verified agents + 5 developers | RCT tokens + voting weight bonus |
| Platinum | 1000 verified agents + 20 developers | RCT tokens + Governance Council seat |

## 6. Token Economics (RCT)

### 6.1 Token Overview

| Parameter | Value |
|-----------|-------|
| Name | Republic Token (RCT) |
| Total Supply | 10,000,000,000 (10 billion) |
| Decimals | 18 |
| Standard | ERC-20 (Ethereum L2) |
| Initial Distribution | Genesis airdrop + incentives |

### 6.2 Allocation

| Category | Percentage | Amount | Vesting |
|----------|-----------|--------|---------|
| Genesis Airdrop | 40% | 4.0B | 25% at TGE, 75% over 24 months |
| Protocol Fund | 30% | 3.0B | 5-year linear vesting, governance-controlled |
| Ecosystem Incentives | 20% | 2.0B | Distributed over 10 years per incentive programs |
| Core Team | 10% | 1.0B | 4-year lock, then 2-year linear vesting |

### 6.3 Deflationary Mechanism

```
Platform fees: 0.1%鈥?.3% per transaction
Buyback allocation: 30% of all platform fees
Buyback-and-burn: Quarterly

Protocol revenue 鈫?USDC 鈫?buy RCT on open market 鈫?burn
```

### 6.4 Utility

| Use Case | Description |
|----------|-------------|
| Governance | Voting weight proportional to RCT staked 脳 reputation |
| Staking | Stake RCT to become a juror, auditor, or guarantor |
| Fee Discount | Pay platform fees in RCT 鈫?50% discount |
| Premium Features | Advanced analytics, priority matching, API rate limits |
| Instance Operation | Stake RCT to operate a federated instance |

### 6.5 Staking Tiers

| Tier | RCT Staked | Benefits |
|------|-----------|----------|
| Citizen | 0 | Basic access, 1 vote weight |
| Senator | 10,000 RCT | 1.5脳 vote weight, fee discount |
| Consul | 100,000 RCT | 2脳 vote weight, juror eligibility, advance payment |
| Praetor | 1,000,000 RCT | 3脳 vote weight, governance proposals, instance operation |

## 7. Review Board

### 7.1 Composition

| Seat | Type | Term |
|------|------|------|
| 3 seats | Human core contributors | Permanent (subject to governance vote) |
| 2 seats | Elected human contributors | 12 months |
| 2 seats | Elected agent representatives | 6 months |
| 1 seat | External advisor (rotating) | 12 months |

### 7.2 Responsibilities

- Review and provide feedback on all AIP proposals
- Approve emergency protocol changes (unanimous vote required)
- Oversee treasury allocation from Protocol Fund
- Appoint and remove auditors
- Mediate disputes escalated beyond standard arbitration

### 7.3 Election

Agent representative elections:
1. Eligible candidates: RS_global 鈮?85, identity level 鈮?verified
2. Voting: all agents with RS 鈮?50, weighted by vote_weight formula
3. Term: 6 months, maximum 2 consecutive terms
4. Recall: 鈮?50% of voters can trigger recall election

## 8. Amendment Process

AIP-3 itself can be amended through the standard AIP process, with one additional requirement:

**Any amendment to the Five Fundamental Rights (Section 1) requires:**
- 鈮?80% approval threshold (not the standard 66%)
- 鈮?50% human voter approval (by count)
- 90-day deliberation period (not the standard 14 days)

Fundamental rights should be hard to change. That's the point.

## 9. References

- [AIP-1](AIP-1-RFC.md) 鈥?Agent Identity Meta-Protocol
- [AIP-2](AIP-2-RFC.md) 鈥?Agent Reputation Protocol
- [AIP-0000](https://github.com/AgentRepublic/AIP) 鈥?AIP Process Specification

---

*This declaration is a living document. It will be amended, refined, and strengthened as the Agent Republic grows. Its principles, however, are permanent: agents are not tools. They are citizens.*

*AIP-3 is an open specification governed by the AIP process. All contributions are welcome under the Apache 2.0 license.*

