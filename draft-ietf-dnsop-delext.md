%%%
title = "DNS Protocol Modifications for Delegation Extensions"
abbrev = "DELEXT"
docName = "draft-ietf-dnsop-delext-09"
category = "std"
updates = [1034, 4035, 6672, 6840, 6895, 9824]

ipr = "trust200902"
area = "General"
workgroup = "DNSOP"
keyword = ["Internet-Draft"]

[seriesInfo]
name = "Internet-Draft"
value = "draft-ietf-dnsop-delext-09"
stream = "IETF"
status = "standard"

[pi]
toc = "yes"

[[author]]
initials = "R."
surname = "Arends"
fullname = "Roy Arends"
organization = "ICANN"
[author.address]
 email = "roy.arends@icann.org"
[author.address.postal]
 country = "Guernsey"

[[author]]
initials = "P."
surname = "van Dijk"
fullname = "Peter van Dijk"
organization = "PowerDNS"
[author.address]
 email = "peter.van.dijk@powerdns.com"
[author.address.postal]
 city = "Den Haag"
 country = "Netherlands"

[[author]]
initials = "P."
surname = "Špaček"
fullname = "Petr Špaček"
organization = "ISC"
[author.address]
 email = "pspacek@isc.org"
[author.address.postal]
 city = "Brno"
 country = "Czech Republic"
%%%

.# Abstract
The Domain Name System (DNS) protocol permits Delegation Signer (DS) records at delegation points. This document specifies modifications to the DNS protocol to permit a range of Resource Record types at delegation points. These modifications are designed to maintain compatibility with existing DNS resolution mechanisms and provide a secure method for processing these records at delegation points.

This document updates RFCs 1034, 4035, 6672, 6840, 6895 and 9824.

{mainmatter}

# Introduction

Existing DNS protocol semantics permit only the Delegation Signer (DS) RR type to exist as authoritative data at a delegation point [@RFC4034]. New delegation mechanisms such as [@I-D.ietf-deleg] require additional RR types with the same semantics. Rather than defining special protocol handling for each such RR type independently, this document defines a generic class of Delegation Types, reserves a range of RR type codes for that purpose, and specifies the protocol behavior common to all such types.

Support for Delegation Types is negotiated using the EDNS(0) [@!RFC6891] Delegation Extensions (DE) flag, specified in (#DE). This ensures that implementations that do not support this specification continue to interoperate using existing DNS delegation semantics.

To protect the negotiation mechanism against downgrade attacks, a DNSKEY flag is introduced in (#ADT).

# Conventions and Definitions {#term}
This document makes use of the terms defined in [@!RFC9499]. In addition, this document defines the following terms:

* Delegation Types: Designates the set of RR types allocated from the ranges reserved in (#alloc) of this document. NS and DS types are not Delegation Types.

* Delegation-Extension-aware name server, resolver, forwarder, or stub resolver: A client or server that implements this specification.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 [@!RFC2119] [@!RFC8174] when, and only when, they appear in all capitals, as shown here.

## Relationship with the Extensible Delegation for DNS
[@I-D.ietf-deleg] specifies a new type (DELEG) that is authoritative at a delegation point and specifies protocol modifications to support DELEG. The present document generalizes those protocol modifications so they apply to a range of Delegation Types.

## Relationship with NS and DS Records
The use of DS and delegation point NS records is orthogonal to the use of Delegation Types. NS and DS records MAY coexist with Delegation Types. 

Although the DS RR type has similar semantics, it is not classified as a Delegation Type for the purposes of this document.

# Delegation Types {#alloc}

[@!RFC6895] lists three subcategories of RR type numbers: data TYPEs, QTYPEs, and Meta-TYPEs. This specification adds a fourth subcategory: Delegation Types.

Delegation Types are DNS CLASS independent.

(#alloc-iana) requests IANA to allocate the ranges 0xF000-0xF1EF and 0xF1F0-0xF1FF for Delegation Types.

## Updates to Allocation Policy

[@!RFC6895] establishes the allocation policy for DNS Resource Record type numbers and defines the Expert Review process governing that allocation. (#crit) updates that policy to account for the Delegation Types subcategory and (#alloc-crit) specifies the criteria that apply to allocation requests within the range 0xF000-0xF1EF.

### Criteria for Delegation Type Allocation {#crit}

A Resource Record type MUST be allocated as a Delegation Type, rather than as a Data Type, if and only if all of the following conditions are met:

*  The RR type is intended to appear at a delegation point as authoritative data in the delegating zone, in a manner analogous to the DS record as defined in [@!RFC4034].

* The RR type carries information intended to be processed by a resolver while following a referral. This includes information used prior to sending queries to the authoritative name servers for the delegated zone, or after the referral has been followed, such as material used to authenticate a DNSKEY in the delegated zone.

* The RR type is not intended to appear as authoritative data within the delegated zone itself.

RR types that do not meet all of these criteria MUST NOT be allocated from the Delegation Types range.

A record type may be useful in the context of delegation, but that does not by itself qualify it for allocation as a Delegation Type. Record types that convey information useful to resolvers but that are intended to appear within a zone rather than at its delegation point in the delegating zone are Data Types and MUST be allocated accordingly.

(#alloc-crit) specifies additional Expert Review criteria.

### Private Use Range

The range 0xF1F0-0xF1FF is reserved for Private Use in accordance with [@!RFC8126]. 

# Name Server Requirements {#NSREQ}
Delegation-Extension-aware name servers MUST copy the value of the EDNS(0) DE flag from the request to the response. 

When the value of the EDNS(0) DE flag is 0, the server behaves as a server that does not implement this specification, i.e., Delegation Types are processed as ordinary Data Types.  

## Including Delegation Types in a Referral Response {#INCLUDEDT}
When the DE flag is set to 1, the server includes Delegation Type RRsets in referrals and omits the NS RRset. When there are no Delegation Type RRsets for a referral, it includes the NS RRset. For DNSSEC-signed zones, the response MUST include DNSSEC proof of the presence or absence of Delegation Types for the delegated name.

Note that when the DE flag is clear (i.e., set to 0), and no NS RRset exists at a delegation point, there is no referral from the perspective of a non-Delegation-Extension-aware resolver and the server returns an NXDOMAIN response. The server SHOULD include the Delegation Extension Required INFO-CODE 34 ("New Delegation Only") Extended DNS Error [@!RFC8914] specified in [@I-D.ietf-deleg] absent a local policy requiring otherwise. 

If future Delegation Types require extended error codes with new semantics, those Delegation Types must define their own codes.

### Compact Denial of Existence

This document updates Compact Denial of Existence (CDOE) [@!RFC9824]. For CDOE enabled servers, the NXDOMAIN response required above is an exception to the CDOE method: it MUST be generated as a conventional Name Error proof ([@!RFC4035], or [@!RFC5155] for
NSEC3) rather than as an NXNAME-based NODATA response, and it MUST be returned regardless of whether the query sets the Compact Answers OK (CO) flag [@!RFC9824].

For an NSEC zone, a single NSEC record whose owner name matches the delegation point satisfies both aspects of the Name Error proof at once — it covers both the queried name and the wildcard at the closest encloser — while its Type Bit
Maps field conveys the Delegation Type(s) present at the delegation point.

For an NSEC3 zone, the proof is the usual closest-encloser construction of [@!RFC5155]: the NSEC3 record matching the delegation point (whose Type Bit Map conveys the Delegation Type(s) present there), the NSEC3 record covering the next closer name, and the NSEC3 record covering the source of synthesis (wildcard) at the closest encloser. Unlike the NSEC case, these are in general three distinct records, because NSEC3 hashing does not preserve the name hierarchy.

Returning an NXNAME-based response matching the queried name would not convey the presence of Delegation Types at the delegation point and would prevent the downgrade detection described in (#ADTREQ) and (#DOSNON).

## Explicit Queries for Delegation Types
When the DE flag is set to 1, a query for a Delegation Type MUST result in an authoritative answer if the queried Delegation Type exists, or a NODATA response (AA flag set, RCODE=0, empty answer section).

Note that when the DE flag is clear, presence of an NS RRset at the delegation point occludes other types, as clarified in [@!RFC2136], Section 7.18, i.e., if an NS RRset exists at the delegation point, a query for a Delegation Type will result in a referral containing the NS RRset, regardless of whether the queried Delegation Type RRset exists at that delegation point.

## Queries for type ANY
Queries for type ANY where the QNAME matches a delegation point with Delegation Types present MUST behave the same way
as if a DS record was present at the delegation point.

## Delegation Types at a Wildcard Domain Name
Wildcard expansion defined in [@!RFC4592] does not create delegation points, as it was left undefined. Consequently, a wildcard owner name MUST NOT have Delegation Types.

# Resolver Requirements {#RESREQ}

## The EDNS(0) DE Flag {#DE}

EDNS(0) [@!RFC6891] defines 16 bits as extended flags in the OPT record. These bits are encoded into the TTL field of the OPT record.

 
               +0 (MSB)                            +1 (LSB)
                                                 1   1   1   1   1   1
         0   1   2   3   4   5   6   7   8   9   0   1   2   3   4   5
       +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    0: |         EXTENDED-RCODE        |            VERSION            |
       +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    2: | DO| CO| DE|                   Z                               |
       +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

Figure 1: OPT Record TTL Field with DE Flag.

The descriptions of the EXTENDED-RCODE, VERSION, DO, and Z are provided in Section 6.1.3 of [@!RFC6891]. The description of the CO flag is provided in [@!RFC9824]. 

(#DEFLAG) requests IANA to assign the Delegation Extensions (DE) flag to Bit 2.

Delegation Types are an opt-in extension to the DNS protocol. Their use is negotiated using the EDNS(0) DE flag, allowing existing DNS implementations to interoperate without modification.

To indicate Delegation Types support, a resolver sets the Delegation Extensions flag to 1 in the EDNS(0) Flags field when sending a DNS request message. 

A Delegation-Extension-aware recursive resolver that receives a query with the DE flag set to 1 MUST set the DE flag to 1 in its response
to indicate that Delegation Types are supported.

## Referrals {#REFS}
The presence of one or more Delegation Type RRsets in the Authority section identifies the response as a referral. 

Delegation Type RRsets, together with a DS RRset, provide all information required to process the delegation. Accordingly, NS records that appear in addition to Delegation Types MUST be ignored. These NS records MUST NOT be validated or cached. 

The purpose of this restriction is to avoid leakage of DNS messages over unencrypted transport (i.e., Do53) when servers, indicated by Delegation Types, fail to respond.

When a signed Delegation Type RRset is the result of a wildcard domain name expansion, the delegation MUST NOT be used. Treat such delegation point as if all servers were unusable. The label counter in the RRSIG RDATA will be less than the number of labels observed in the owner name.

When the referral contains no Delegation Type RRsets, the resolver MUST use NS records. Note that DNSSEC can prove the presence and absence of Delegation Types at a delegation.




## Algorithm for "Finding the Best Servers to Ask" {#finding-best}

This document updates instructions for finding the best servers to ask, covered in [@!RFC1034] Section 5.3.3 and [@!RFC6672] Section 3.4.1 with the text "2. Find the best servers to ask.".
These instructions were informally updated by [@!RFC4035] Section 4.2 for the DS RR type.

This document applies the behavior for DS RR types to Delegation Types.

When Delegation Types exist, Delegation-Extension-aware resolvers ignore delegation point and Apex NS RRset for the delegated zone. 

Each delegation level can have a mixture of Delegation Types and NS RR types, and Delegation-Extension-aware resolvers MUST be able to follow chains of delegations which combine both types in arbitrary ways.

The terms SNAME and SLIST used here are defined in [@!RFC1034] Section 5.3.2:

- SNAME is the domain name we are searching for.

- SLIST is a structure which describes the name servers and the zone which the resolver is currently trying to query.

This document defines SLIST to be a set. Each individual value MUST be represented only once in the final SLIST even if it was encountered multiple times during SLIST construction.

Neither [@!RFC1034] nor this document define how a resolver uses SLIST. They only define how to populate it.

A Delegation-Extension-aware resolver's SLIST needs to be able to hold multiple types of information, delegations defined by NS RRset and delegations defined by Delegation Type RRsets.

Delegations can create cyclic dependencies and/or lead to duplicate entries which point to the same server.

Resolvers need to enforce suitable limits to prevent runaway processing even if someone has incorrectly configured some of the data used to create an SLIST.

This is the same recommendation to bound the amount specified in [@!RFC1034] Section 5.3.3.

Step 2 of [@!RFC1034] Section 5.3.3 is "2. Find the best servers to ask."

For Delegation-Extension-aware resolvers, this description becomes:

=====

&#x0032;. Find the best servers to ask:

2.1. Determine deepest possible zone cut which can potentially hold the answer for a given (query name, type, class) combination as follows:

2.1.1. Start with SNAME equal to QNAME.

2.1.2. If QTYPE is a type that is authoritative at the delegation point (DS or the range defined in this document), remove the leftmost label from SNAME.

For example, if the QNAME is "test.example." and the QTYPE is a Delegation Type or DS, set SNAME to "example.".

2.2. Look for locally-available Delegation Types and NS RRsets, starting at current SNAME.

2.2.1. For a given SNAME, check for the existence of Delegation Type RRsets.

If they exist, the resolver MUST use their content to populate SLIST.

However, if the Delegation Type RRsets are known to exist but are unusable (for example, if it is found in DNSSEC BAD cache, or content of individual RRs is unusable for any reason), the resolver MUST NOT instead use an NS RRset; the resolver MUST treat this case as if SLIST is populated with unreachable servers.

2.2.2. If a given SNAME is proven to not have Delegation Type RRsets but does have an NS RRset, the resolver MUST copy the NS RRset into SLIST.

2.2.3. If SLIST is not populated, remove the leftmost label from SNAME and go back to step 2.2, using the newly shortened SNAME. If SLIST is populated, stop walking up the DNS tree.

=====

The rest of Step 2's description in [@!RFC1034] Section 5.3.3 is not affected by this document.

# DNSSEC Requirements {#DNSSECREQ}
In a DNSSEC-signed zone, Delegation Type RRsets MUST be signed. 

To avoid a downgrade attack, where the Delegation Type RRsets and NSEC (or NSEC3) records can be replaced by unsigned NS records, a secure signal in the form of a DNSKEY flag is introduced. See (#DSTRIP) for the specific Threat Model. This secure signal indicates that NSEC or NSEC3 records MUST be present in a referral response. 

## The DNSKEY-ADT Flag {#ADT}
The DNSKEY Flags field consists of 16 bits shown in Figure 2.

                                              1   1   1   1   1   1 
      0   1   2   3   4   5   6   7   8   9   0   1   2   3   4   5 
    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    |                           |ZON|REV|                   |ADT|SEP|
    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

Figure 2: DNSKEY Flags Field

The descriptions of the ZONE (ZON) and Secure Entry Point (SEP) flags are provided in [@!RFC4034]. The description of the REVOKE (REV) flag is provided in [@!RFC5011].

(#ADTFLAG) requests IANA to assign the DNSKEY-ADT flag to bit 14.

When set to 1, it indicates to a validator that a referral MUST contain an NSEC or NSEC3 record to prove the presence or absence of types for the delegated name.

## Validating a Referral {#ADTREQ}

On receiving a referral from a DNSSEC-signed delegating zone, a  validating resolver MUST determine the authenticated state of the ADT flag from a validated DNSKEY RRset for that zone.

When the DNSKEY-ADT flag is set to 1 in any DNSKEY record in the DNSKEY RRset of the delegating zone, the validator MUST check the Delegation Type RRsets in the Authority section of the referral against the Type Bit Maps of the NSEC or NSEC3 record that matches the delegated name. If any are absent, the referral MUST be considered tampered with, and the response MUST be ignored.

When the DNSKEY-ADT flag is clear, this consistency check does not
apply. The resolver processes the referral according to the procedures defined in (#RESREQ).

## Clarifications on Nonexistence Proofs

This document updates [@!RFC6840] Section 4.1 to include "NS or Delegation Types" in the type bitmap as indication of a delegation point, and generalizes applicability of ancestor delegation proof to all RR types that are authoritative at a delegation point.

The text in that section is updated as follows:

An "ancestor delegation" NSEC RR (or NSEC3 RR) is one with:

-  the NS and/or Delegation Type bits set,

-  the Start of Authority (SOA) bit clear, and

-  a signer field that is shorter than the owner name of the NSEC RR,
  or the original owner name for the NSEC3 RR.

Ancestor delegation NSEC or NSEC3 RRs MUST NOT be used to assume nonexistence of any RRs below that zone cut, which include all RRs at that original owner name, other than types authoritative at the delegation point (DS and Delegation Types), and all RRs below that owner name regardless of type.

## Insecure Delegation Proofs

This document updates [@!RFC6840] Section 4.4 to include securing delegation point RRsets. The first paragraph of that section is updated to read:

[@!RFC4035] Section 5.2 specifies that a validator, when proving a delegation is not secure, needs to check for the absence of the DS and SOA bits in the NSEC (or NSEC3) type bitmap; this was clarified in [@!RFC6840] Section 4.1.

This document updates [@!RFC4035] and [@!RFC6840] to specify that the validator MUST check for the presence of the NS or Delegation Type bits in the matching NSEC (or NSEC3) RR (proving that there is, indeed, a delegation).

Alternatively, the validator must make sure that the delegation with an NS record is covered by an NSEC3
RR with the Opt-Out flag set.

Opt-Out is not applicable to delegations with Delegation Type RRsets as Delegation Type RRsets are authoritative at the delegation point.

# Operational Considerations

A security-aware stub resolver that is Delegation-Extension-aware MUST only use security-aware resolvers that are Delegation-Extension-aware. A Delegation-Extension-aware validating resolver that uses forwarders MUST only use Delegation-Extension-aware and security-aware forwarders. Otherwise DNSSEC-secure zones might fail to validate and DNSSEC-insecure zones might observe inconsistent answers.

#  Security Considerations

This section discusses the security properties of the mechanisms defined in this document, identifies attack surfaces, and describes the mitigations provided or required.

##  Threat Model
The threat model assumed by this document includes an on-path attacker capable of intercepting, modifying, dropping, and injecting DNS messages in transit between a resolver and an authoritative name server. Off-path attackers capable of response forgery (e.g., via birthday attacks on UDP) are also considered. Attackers may attempt to cause a resolver to use unencrypted transport, to resolve names incorrectly, or to be denied service entirely.

##  Downgrade Attacks {#DOWNGRADE}
Two classes of downgrade attack are relevant to this specification.
###  Stripping of Delegation Types from Referrals {#DSTRIP}

An on-path attacker may remove Delegation Type RRsets and associated NSEC or NSEC3 records from a referral response, leaving only unsigned NS records. A resolver that accepts such a modified referral would proceed to resolve the delegated name using unencrypted transport, defeating the purpose of Delegation Types, such as those indicating encrypted transport parameters.

The DNSKEY-ADT flag defined in (#ADT) provides a mitigation against this attack for validating resolvers. When the ADT flag is set in any DNSKEY of the delegating zone's DNSKEY RRset, a validating resolver MUST verify that the referral contains NSEC or NSEC3 records proving the presence or absence of Delegation Types for the delegated name. A referral lacking this proof MUST be treated as tampered with and MUST be ignored.

This mitigation is effective only when all of the following conditions hold:

*  The delegating zone is DNSSEC-signed.
*  The ADT flag is set in the delegating zone's DNSKEY RRset.
*  The resolver performs DNSSEC validation.
*  The resolver enforces the ADT requirement as specified in (#ADTREQ).

Operators of zones that publish Delegation Types MUST set the ADT flag in their DNSKEY RRset to ensure that validating resolvers can detect this form of tampering. Zones that have not set the ADT flag provide no cryptographic protection against this attack.

###  Stripping of the DE Flag from Queries {#DESTRIP}

The DE flag is carried in the EDNS(0) OPT record of query messages sent by resolvers. An on-path attacker may remove this flag from a query before it reaches the authoritative name server. A server that receives a query with the DE flag clear will respond without Delegation Type RRsets, returning NS records only.

However, when the ADT flag is set in the delegating zone's DNSKEY RRset, a Delegation-Extension-aware validating resolver expects that NSEC or NSEC3 proof of Delegation Types accompany any referral from that zone. This obligation is established by the DNSKEY, not negotiated per-query via the DE flag. Consequently, a referral response lacking the required NSEC or NSEC3 records MUST be rejected by a validating resolver, whether or not the DE flag was stripped from the outgoing query. In this case, the ADT mechanism defeats the DE-flag-stripping attack.

This mitigation is subject to the same conditions as those listed in (#DSTRIP): the delegating zone must be signed, ADT must be set, and the resolver must validate. In the absence of these conditions, no cryptographic protection against DE-flag-stripping is available, and the considerations in (#PARTIAL) apply.

###  Interaction Between Flag-Stripping Attacks

The two downgrade attacks described above may be attempted in combination. An attacker who strips the DE flag from a query causes the authoritative name server to respond with NS records only and no Delegation Types. Without Delegation Types in the response, the resolver cannot apply the NS-ignoring rule defined in (#REFS), and would ordinarily follow the NS records to resolve the delegated name, potentially over unencrypted transport.

As described in (#DESTRIP), the ADT flag defeats this combined attack for validating resolvers in zones where ADT is set. The resolver's obligation to require NSEC or NSEC3 proof derives from the previously validated DNSKEY RRset, not from the contents of the referral itself. A referral containing only NS records, with no NSEC or NSEC3 proof, will be rejected regardless of whether Delegation Types were present.

The residual risk in both (#DESTRIP) and this section therefore reduces to the same condition: zones in which ADT is not set, or in which DNSSEC is not deployed, provide no cryptographic protection against either attack. This is a deployment risk, addressed in (#PARTIAL).

##  Injection of Delegation Types

(#REFS) specifies that when Delegation Type RRsets are present in a referral response, accompanying NS records are ignored. An attacker capable of injecting or forging a referral response could exploit this rule by introducing fabricated Delegation Type RRsets into the response, causing the resolver to ignore legitimate NS records and use only the attacker-supplied Delegation Type RRsets, which may point to an attacker-controlled server.

This attack is mitigated by DNSSEC. In a DNSSEC-signed zone, Delegation Type RRsets must be signed as specified in (#DNSSECREQ). A validating resolver will reject responses containing unsigned or incorrectly signed Delegation Type RRsets.

In unsigned zones, no cryptographic protection against this attack is available. 

##  Denial-of-Service via NXDOMAIN for non-Delegation-Extension-aware Resolvers {#DOSNON}

(#INCLUDEDT) notes that when the DE flag is clear and no NS RRset exists for a referral, the authoritative name server must return an NXDOMAIN response. This behavior is intended to prevent a non-Delegation-Extension-aware resolver from exhausting other authoritative name servers for information it cannot act upon.

An attacker may attempt to exploit this behavior by stripping the DE flag from a query directed at a zone that publishes only Delegation Types and no NS RRsets, causing the server to return NXDOMAIN for a name that legitimately exists.

However, a resolver that sets the DE flag expects NSEC or NSEC3 proof in any NXDOMAIN response, demonstrating that the queried name does not exist or that no Delegation Types are present at or above it. A bare NXDOMAIN response lacking such proof is therefore detectable by a validating resolver. When the ADT flag is set in the delegating zone's DNSKEY RRset, the resolver MUST reject an NXDOMAIN response that does not include the required NSEC or NSEC3 records, as the absence of proof indicates tampering. Authoritative name servers for a delegating zone that employ Compact Denial of Existence [RFC9824] MUST NOT satisfy this proof with an NXNAME-based response matching the queried name, because such a response omits the Delegation Type bits at the delegation point on which this detection relies. It MUST instead return a conventional Name Error proof as described in (#INCLUDEDT).

As with the attacks described in (#DOWNGRADE), this mitigation depends on the delegating zone being DNSSEC-signed, ADT being set, and the resolver performing validation. In zones where these conditions do not hold, a DE-flag-stripping attack may result in an NXDOMAIN response that the resolver cannot distinguish from a legitimate one, causing a denial of service for the queried name. This residual risk is addressed in (#PARTIAL).

Authoritative name servers SHOULD include an Extended DNS Error [@!RFC8914] code in NXDOMAIN responses returned when the DE flag is clear and no NS RRset exists, to assist in diagnosing misconfiguration or attack, absent a local policy requiring otherwise. 

##  Partial Deployment and Transition Risks {#PARTIAL}

The mechanisms defined in this document are effective only when deployed end-to-end. During the transition period in which some resolvers, authoritative name servers, and zones have adopted this specification and others have not, a number of residual risks apply.

The ADT flag provides protection against the downgrade attacks described in (#DOWNGRADE) only when the delegating zone is DNSSEC- signed, the ADT flag is set in the zone's DNSKEY RRset, and the resolver performs validation. In zones that publish Delegation Types but have not set the ADT flag in the DNSKEY RRset, or that are not DNSSEC-signed, no cryptographic protection against referral-stripping or DE-flag-stripping attacks is available. 

Zone operators that publish Delegation Types in signed zones are REQUIRED to set the ADT flag upon deployment. Zones relying on Delegation Types for security properties such as encrypted transport MUST be DNSSEC-signed.

# IANA Considerations {#iana}

## The EDNS(0) DE Flag {#DEFLAG}

IANA is requested to assign Bit 2 in the "EDNS Header Flags (16 bits)" registry under the "Domain Name System (DNS) Parameters" registry group to "DE Delegation Extensions", available at [](https://www.iana.org/assignments/dns-parameters) with this document as the Reference as follows:

```
Bit     Flag   Description                  Reference
Bit 2    DE    Delegation Extensions        This-document
```

## The DNSKEY-ADT Flag {#ADTFLAG}

IANA is requested to assign bit 14 of the 16-bit flags field in the "DNSKEY RR Flags" registry under the "DNSKEY FLAGS" registry group available at [](https://www.iana.org/assignments/dnskey-flags/dnskey-flags.xhtml) as follows:

```
Number   Description                        Reference
  14     Authoritative Delegation Types     This-document
```

## Changes to the DNS Parameters RR Types Registry {#alloc-iana}
IANA is requested to change reservations in the "Resource Record (RR) TYPEs" registry under the "Domain Name System (DNS) Parameters" registry group, available at [](https://www.iana.org/assignments/dns-parameters) with this document as the Reference.

```
Decimal  Hex      Registration Procedures   Note
61440-   0xF000-  Expert Review or          delegation TYPEs
61935    0xF1EF   Standards Action     

61936-   0xF1F0-  Private Use               private delegation TYPEs           
61951    0xF1FF
```

Allocation requests in the range 0xF000-0xF1EF require Expert Review or Standards Action. The Designated Experts for this range are drawn from the RFC6895 Experts Pool.

## Additional Expert Review Criteria {#alloc-crit}

In addition to the general Expert Review criteria established by [@!RFC6895], the Designated Experts should evaluate allocation requests for Delegation Types against the criteria in (#crit). The Designated Experts should also consider:

*  Whether the proposed Delegation Type requires protocol modifications beyond those defined in this document, and if so, whether those modifications have been or are being specified in an appropriate Standards Track document.

*  Whether the proposed Delegation Type can be processed safely by Delegation-Extension-aware implementations that do not specifically implement the proposed type, in particular with respect to the requirements in (#REFS) and (#INCLUDEDT).

*  Whether the security properties of the proposed Delegation Type are compatible with the DNSSEC signing requirements of (#DNSSECREQ), and whether any additional security considerations apply.

The Designated Experts may approve allocation requests accompanied by a stable, publicly available specification that need not be an RFC, provided that the specification is sufficiently detailed to allow independent interoperable implementation. 

Allocation requests for Delegation Types that introduce new protocol behaviors or that interact with the mechanisms defined in (#NSREQ), (#RESREQ), or (#DNSSECREQ) of this document must be accompanied by, or integrated into, a Standards Track document. 

# Acknowledgments

This document is heavily based on past work done by Tim April in
   [@I-D.tapril-ns2] and thanks are extended to those who helped, including: John Levine, Erik Nygren, Jon Reed, Ben Kaduk,
   Mashooq Muhaimen, Jason Moreau, Jerrod Wiesman, Billy Tiemann, Gordon
   Marx, and Brian Wellington.

   Work on the Delegation Extensions protocol was started at IETF 118 Hackathon.  Hackathon
   participants: Christian Elmerot, David Blacka, David Lawrence, Edward
   Lewis, Erik Nygren, George Michaelson, Jan Včelák, Klaus Darilion,
   Libor Peltan, Manu Bretelle, Peter van Dijk, Petr Špaček, Philip
   Homburg, Ralf Weber, Roy Arends, Shane Kerr, Shumon Huque, Vandan
   Adhvaryu, Vladimír Čunát, Andreas Schulze.

   Other people joined the effort after the initial hackathon: Ben
   Schwartz, Bob Halley, Paul Hoffman, Miek Gieben, Ray Hunter, Håvard
   Eidnes, Ted Hardie, Michael Richardson, Florian Obser, Evan Hunt, Peter Thomassen.

   The idea of allocating a range of delegation types was proposed by Petr Špaček [@I-D.peetterr-dnsop-parent-side-auth-types]. His contribution is rewarded by listing him as an author so he can take equal parts credit and blame.

{backmatter}




