%%%
title = "DNS Protocol Modifications for Delegation Extensions"
abbrev = "DELEXT"
docName = "draft-ietf-dnsop-delext-08-candidate"
category = "std"
updates = [6895]

ipr = "trust200902"
area = "General"
workgroup = "DNSOP"
keyword = ["Internet-Draft"]

[seriesInfo]
name = "Internet-Draft"
value = "draft-ietf-dnsop-delext-08-candidate"
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
The Domain Name System (DNS) protocol permits Delegation Signer (DS) records at delegation points. This document specifies modifications to the DNS protocol to permit a range of resource record types at delegation points. These modifications are designed to maintain compatibility with existing DNS resolution mechanisms and provide a secure method for processing these records at delegation points.

This document updates RFC 6895.

{mainmatter}

# Introduction

Existing DNS protocol semantics permit only the Delegation Signer (DS) RR type to exist as authoritative data at a delegation point [@RFC4034]. New delegation mechanisms such as [@I-D.ietf-deleg] require additional RR types with the same semantics. Rather than defining special protocol handling for each such RR type independently, this document defines a generic class of Delegation Types, reserves a range of RR type codes for that purpose, and specifies the protocol behavior common to all such types.

Support for Delegation Types is negotiated using the EDNS(0) [@!RFC6891] Delegation Extensions (DE) flag, specified in (#DE). This ensures that implementations that do not support this specification continue to interoperate using existing DNS delegation semantics.

To protect the negotiation mechanism against downgrade attacks, a DNSKEY flag is introduced in (#ADT).

# Conventions and Definitions {#term}
This document makes use of the terms defined in [@!RFC9499]. In addition, this document defines the following terms:

* Delegation Types: Designates the set of RR types allocated from the ranges reserved in (#alloc) of this document. NS and DS types are not Delegation Types.

* Delegation-Extension-aware name server, resolver, forwarder or stub resolver: A client or server that implements this specification.

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

(#deleg-service) describes potential services provided by Delegation Types.

## Updates to Allocation Policy

[@!RFC6895] establishes the allocation policy for DNS Resource Record type numbers and defines the Expert Review process governing that allocation. (#crit) updates that policy to account for the Delegation Types subcategory and (#alloc-crit) specifies the criteria that apply to allocation requests within the ranges 0xF000-0xF1EF and 0xF1F0-0xF1FF.

### Criteria for Delegation Type Allocation {#crit}

A Resource Record type MUST be allocated as a Delegation Type, rather than as a Data Type, if and only if all of the following conditions are met:

*  The RR type is intended to appear at a delegation point as authoritative data in the delegating zone, in a manner analogous to the DS record as defined in [@!RFC4034].

* The RR type carries information that is intended to be acted upon by a resolver during the process of following a referral. This includes information used prior to sending queries to the authoritative servers for the delegated zone, or after the referral has been followed, such as material used to authenticate a DNSKEY in the delegated zone.

*  The RR type is not intended to appear as authoritative data within the delegated zone itself.

RR types that do not meet all of these criteria MUST NOT be allocated from the Delegation Types range.

A record type may be useful in the context of delegation, but that does not by itself qualify it for allocation as a Delegation Type. Record types that convey information useful to resolvers but that are intended to appear within a zone rather than at its delegation point in the delegating zone are Data Types and MUST be allocated accordingly.

(#alloc-crit) specifies additional Expert Review criteria.

### Private Use Range

The range 0xF1F0-0xF1FF is reserved for Private Use in accordance with [@!RFC8126]. 

# Name Server Requirements {#NSREQ}
Delegation-Extension-aware name servers MUST copy the value of the EDNS(0) DE flag from the request to the response. 

When the value of the EDNS(0) DE flag is 0, the server behaves as a server that does not implement this specification, i.e., Delegation Types are treated as data TYPEs.  

## Including Delegation Types in a Referral Response {#INCLUDEDT}
When the DE flag is set to 1, the server includes Delegation Types in referrals and omits the NS RRset. When there are no Delegation Types for a referral, it includes the NS RRset. For DNSSEC-signed zones, the response MUST include DNSSEC proof of the presence or absence of Delegation Types for the delegated name.

Note that when the DE flag is clear (i.e., set to 0), and no NS RRset exists at a delegation point, there is no referral from the perspective of a non Delegation-Extension-Aware resolver and the server SHOULD include the Delegation Extension Required INFO-CODE (TBD) Extended DNS Error [@!RFC8914] specified in (#ede) absent a local policy requiring otherwise.

## Explicit queries for Delegation Types
When the DE flag is set to 1, a query for a Delegation Type MUST result in an authoritative answer if the Delegation Type exists, or a NODATA response (AA flag set, RCODE=0, empty answer section).

Note that when the DE flag is clear, presence of an NS RRset at the delegation point occludes other types, as clarified in [@!RFC2136], Section 7.18, i.e., if an NS RRset exists at the delegation point, a query for a Delegation Type will result in a referral containing the NS RRset, regardless of whether the queried Delegation Type exists at that name. 

# Resolver Requirements {#RESREQ}

## The EDNS(0) DE Flag {#DE}

EDNS(0) [@!RFC6891] defines 16 bits as extended flags in the OPT record. These bits are encoded into the TTL field of the OPT record.

 
               +0 (MSB)                            +1 (LSB)
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
The presence of one or more Delegation Types in the Authority section identifies the response as a referral. 

Delegation Types, together with existing DNS protocol elements such as DS, provide all information required to process the delegation. Accordingly, NS records that appear in addition to Delegation Types MUST be ignored. These NS records MUST NOT be validated or cached. 

The purpose of this restriction is to avoid leakage of DNS messages over unencrypted transport (i.e., Do53) when servers, indicated by Delegation Types, fail to respond.

When the referral contains no Delegation Types, the resolver MUST use NS records. Note that DNSSEC can prove the presence and absence of Delegation Types at a delegation.

# DNSSEC Requirements {#DNSSECREQ}
In a DNSSEC-signed zone, Delegation Type RRsets MUST be signed. 

To avoid a downgrade attack, where the Delegation Types and NSEC (or NSEC3) records can be replaced by unsigned NS records, causing the resolver to use unencrypted transport, a secure signal in the form of a DNSKEY flag is introduced. This secure signal indicates that NSEC or NSEC3 records MUST be present in a referral response. 

## The DNSKEY-ADT Flag {#ADT}
The DNSKEY Flags field consists of 16 bits shown in Figure 2.

                                              1   1   1   1   1   1 
      0   1   2   3   4   5   6   7   8   9   0   1   2   3   4   5 
    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
    |                           |ZON|REV|                   |ADT|SEP|
    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

Figure 2: DNSKEY Flags Field

The description of the ZONE (ZON) and Secure Entry Point (SEP) flags are provided in [@!RFC4034]. The description of the REVOKE (REV) flag is provided in [@!RFC5011].

(#ADTFLAG) requests IANA to assign the DNSKEY-ADT flag to bit 14.

When set to 1, it indicates to a validator that a referral MUST contain an NSEC or NSEC3 record to prove the presence or absence of types for the delegated name.

## Validating a Referral {#ADTREQ}
When the DNSKEY-ADT flag is set to 1 in any DNSKEY record in the DNSKEY RRset of the delegating zone, the validator MUST check the Delegation Types in the Authority section of the referral against the Type Bit Maps of the NSEC or NSEC3 record that matches the delegated name. If any are absent, the referral MUST be considered tampered with, and the response MUST be ignored.

# Operational Considerations

A security-aware stub resolver that is Delegation-Extension-aware MUST only use security-aware resolvers that are Delegation-Extension aware. A Delegation-Extension-aware Validating Resolver that uses forwarders MUST only use Delegation-Extension-aware and security-aware forwarders. Otherwise DNSSEC-secure zones might fail to validate and DNSSEC-insecure zones might observe inconsistent answers.

#  Security Considerations

This section discusses the security properties of the mechanisms defined in this document, identifies attack surfaces, and describes the mitigations provided or required.

##  Threat Model
The threat model assumed by this document includes an on-path attacker capable of intercepting, modifying, dropping, and injecting DNS messages in transit between a resolver and an authoritative name server. Off-path attackers capable of response forgery (e.g., via birthday attacks on UDP) are also considered. Attackers may attempt to cause a resolver to use unencrypted transport, to resolve names incorrectly, or to be denied service entirely.

##  Downgrade Attacks {#DOWNGRADE}
Two classes of downgrade attack are relevant to this specification.
###  Stripping of Delegation Types from Referrals {#DSTRIP}

An on-path attacker may remove Delegation Types and associated NSEC or NSEC3 records from a referral response, leaving only unsigned NS records. A resolver that accepts such a modified referral would proceed to resolve the delegated name using unencrypted transport, defeating the purpose of Delegation Types, such as those indicating encrypted transport parameters.

The DNSKEY-ADT flag defined in (#ADT) provides a mitigation against this attack for validating resolvers. When the ADT flag is set in any DNSKEY of the delegating zone's DNSKEY RRset, a validating resolver MUST verify that the referral contains NSEC or NSEC3 records proving the presence or absence of Delegation Types for the delegated name. A referral lacking this proof MUST be treated as tampered with and MUST be ignored.

This mitigation is effective only when all of the following conditions hold:

*  The delegating zone is signed with DNSSEC.
*  The ADT flag is set in the delegating zone's DNSKEY RRset.
*  The resolver performs DNSSEC validation.
*  The resolver enforces the ADT requirement as specified in (#ADTREQ).

Operators of zones that publish Delegation Types MUST set the ADT flag in their DNSKEY RRset to ensure that validating resolvers can detect this form of tampering. Zones that have not set the ADT flag provide no cryptographic protection against this attack.

###  Stripping of the DE Flag from Queries {#DESTRIP}

The DE flag is carried in the EDNS(0) OPT record of query messages sent by resolvers. An on-path attacker may remove this flag from a query before it reaches the authoritative name server. A server that receives a query with DE clear will respond without Delegation Types, returning NS records only.

However, when the ADT flag is set in the delegating zone's DNSKEY RRset, a validating resolver expects that NSEC or NSEC3 proof of Delegation Types MUST accompany any referral from that zone. This obligation is established by the DNSKEY, not negotiated per-query via the DE flag. Consequently, a referral response lacking the required NSEC or NSEC3 records MUST be rejected by a validating resolver, whether or not the DE flag was stripped from the outgoing query. In this case, the ADT mechanism defeats the DE-stripping attack.

This mitigation is subject to the same conditions as those listed in (#DSTRIP): the delegating zone must be signed, ADT must be set, and the resolver must validate. In the absence of these conditions, no cryptographic protection against DE-flag stripping is available, and the considerations in (#PARTIAL) apply.

###  Interaction Between Flag Stripping Attacks

The two downgrade attacks described above may be attempted in combination. An attacker who strips the DE flag from a query causes the authoritative server to respond with NS records only and no Delegation Types. Without Delegation Types in the response, the resolver cannot apply the NS-ignoring rule defined in (#REFS), and would ordinarily follow the NS records to resolve the delegated name, potentially over unencrypted transport.

As described in (#DESTRIP), the ADT flag defeats this combined attack for validating resolvers in zones where ADT is set. The resolver's obligation to require NSEC or NSEC3 proof derives from the previously validated DNSKEY RRset, not from the contents of the referral itself. A referral containing only NS records, with no NSEC or NSEC3 proof, will be rejected regardless of whether Delegation Types were present.

The residual risk in both (#DESTRIP) and this section therefore reduces to the same condition: zones in which ADT is not set, or in which DNSSEC is not deployed, provide no cryptographic protection against either attack. This is a deployment risk, addressed in (#PARTIAL).

##  Injection of Delegation Types

(#REFS) specifies that when Delegation Types are present in a referral response, accompanying NS records are ignored. An attacker capable of injecting or forging a referral response could exploit this rule by introducing a fabricated Delegation Type into the response, causing the resolver to ignore legitimate NS records and use only the attacker-supplied Delegation Type, which may point to an attacker-controlled server.

This attack is mitigated by DNSSEC. In a DNSSEC-signed zone, Delegation Type RRsets must be signed as specified in (#DNSSECREQ). A validating resolver will reject responses containing unsigned or incorrectly signed Delegation Types.

In unsigned zones, no cryptographic protection against this attack is available. 

##  Denial-Of-Service via NXDOMAIN for non Delegation-Extension-aware Resolvers

(#INCLUDEDT) specifies that when the DE flag is clear and no NS RRset exists for a referral, the authoritative name server must return an NXDOMAIN response. This behavior is intended to prevent a non Delegation-Extension-aware resolver from exhausting other authoritative servers for information it cannot act upon.

An attacker may attempt to exploit this behavior by stripping the DE flag from a query directed at a zone that publishes only Delegation Types and no NS RRsets, causing the server to return NXDOMAIN for a name that legitimately exists.

However, a resolver that sets the DE flag expects NSEC or NSEC3 proof in any NXDOMAIN response, demonstrating that the queried name does not exist or that no Delegation Types are present at or above it. A bare NXDOMAIN response lacking such proof is therefore detectable by a validating resolver. When the ADT flag is set in the delegating zone's DNSKEY RRset, the resolver MUST reject an NXDOMAIN response that does not include the required NSEC or NSEC3 records, as the absence of proof indicates tampering.

As with the attacks described in (#DOWNGRADE), this mitigation depends on the delegating zone being DNSSEC-signed, ADT being set, and the resolver performing validation. In zones where these conditions do not hold, a DE-stripping attack may result in an NXDOMAIN response that the resolver cannot distinguish from a legitimate one, causing a denial of service for the queried name. This residual risk is addressed in (#PARTIAL).

Authoritative servers SHOULD include an Extended DNS Error [@!RFC8914] code in NXDOMAIN responses returned when the DE flag is clear and no NS RRset exists, to assist in diagnosing misconfiguration or attack, absent a local policy requiring otherwise. 

##  Partial Deployment and Transition Risks {#PARTIAL}

The mechanisms defined in this document are effective only when deployed end-to-end. During the transition period in which some resolvers, authoritative servers, and zones have adopted this specification and others have not, a number of residual risks apply.

The ADT flag provides protection against the downgrade attacks described in (#DOWNGRADE) only when the delegating zone is DNSSEC- signed, the ADT flag is set in the zone's DNSKEY RRset, and the resolver performs validation. In zones that publish Delegation Types but have not set the ADT flag in the DNSKEY RRset, or that are not DNSSEC signed, no cryptographic protection against referral-stripping or DE-flag-stripping attacks is available. 

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

## The Delegation Extension Support Required Extended DNS Error Code {#ede}

IANA is requested to assign INFO-CODE (TBD) to the "Extended DNS Error Codes" registry under the "Domain Name System (DNS) Parameters" available at [](https://www.iana.org/assignments/dns-parameters) with a Purpose of Delegation Extension Support Required with this document as the Reference.

```
INFO-CODE  Purpose                                 Reference
(TBD)      Delegation Extension Support Required   This-document
```

# Acknowledgments

This document is heavily based on past work done by Tim April in
   [@I-D.tapril-ns2] and thus extends the thanks to the people helping on
   this which are: John Levine, Erik Nygren, Jon Reed, Ben Kaduk,
   Mashooq Muhaimen, Jason Moreau, Jerrod Wiesman, Billy Tiemann, Gordon
   Marx and Brian Wellington.

   Work on the Delegation Extensions protocol was started at IETF 118 Hackaton.  Hackaton
   participants: Christian Elmerot, David Blacka, David Lawrence, Edward
   Lewis, Erik Nygren, George Michaelson, Jan Včelák, Klaus Darilion,
   Libor Peltan, Manu Bretelle, Peter van Dijk, Petr Špaček, Philip
   Homburg, Ralf Weber, Roy Arends, Shane Kerr, Shumon Huque, Vandan
   Adhvaryu, Vladimír Čunát, Andreas Schulze.

   Other people joined the effort after the initial hackaton: Ben
   Schwartz, Bob Halley, Paul Hoffman, Miek Gieben, Ray Hunter, Håvard
   Eidnes, Ted Hardie, Michael Richardson, Florian Obser, Evan Hunt, ...

   The idea of allocating a range of delegation types was proposed by Petr Špaček [@I-D.peetterr-dnsop-parent-side-auth-types]. His contribution is rewarded by listing him as an author so he can take equal parts credit and blame.

{backmatter}

# Services Provided by Delegation Types {#deleg-service}
Services provided by Delegation Types consist of useful information about the delegated namespace. This can include, but is not limited to, secure transport parameters, policy information about zones, and DNSSEC security parameters. 





