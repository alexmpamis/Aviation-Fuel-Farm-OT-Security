# Network Architecture

## Baseline Architecture

The initial lab architecture allowed direct communication between the Kali Linux host and the OpenPLC controller over the OT network.


Kali Linux
192.168.56.102
      |
      | Modbus/TCP
      | TCP/502
      v
OpenPLC
192.168.56.101
      ^
      |
      | Modbus/TCP
      |
FUXA HMI
172.17.0.2


In the baseline configuration:

- Kali could directly reach the PLC on TCP port `502`
- Unauthorized Modbus reads and writes were possible
- No source allowlisting was enforced
- Modbus/TCP communication was not authenticated
- The PLC trusted requests received from reachable network hosts

This architecture enabled the demonstrated attack scenarios.

## Hardened Lab Architecture

The hardened architecture introduced host-based firewall controls on the Ubuntu/OpenPLC system.


                 Ubuntu / OpenPLC Host
                    192.168.56.101
                           |
                     +-------------+
                     |     UFW     |
                     |  Firewall   |
                     +-------------+
                      /           \
                     /             \
          ALLOW TCP/502             BLOCK TCP/502
                 |                       |
                 |                       |
          FUXA HMI                  Kali Linux
          172.17.0.2              192.168.56.102


The implemented firewall policy follows a default-deny approach for incoming connections.

Authorized communication:

`FUXA 172.17.0.2 -> OpenPLC TCP/502 = ALLOWED`

Unauthorized communication:

`Kali 192.168.56.102 -> OpenPLC TCP/502 = BLOCKED`

The firewall also records blocked connection attempts, providing basic detection and forensic evidence.

## Security Improvement

The hardened architecture changed the security model from:

**Network access implies PLC access**

to:

**Only explicitly authorized sources can access the PLC control service**

This significantly reduces the likelihood of unauthorized Modbus/TCP interaction while maintaining legitimate HMI-to-PLC communication.

## Current Lab Limitation

The implemented control is a host-based firewall and does not represent a complete production OT network architecture.

A production environment would typically include additional controls such as:

- Dedicated OT network segmentation
- Industrial firewall or routed security boundary
- Separate HMI, PLC and engineering zones
- Controlled engineering workstation access
- OT DMZ where required
- Protocol-aware monitoring or OT IDS
- Centralized logging and alerting

The current implementation demonstrates the security principle at lab scale without claiming full production equivalence.


## Proposed Production-Style OT Architecture

The lab implementation demonstrates the security principle using a host-based firewall.

A production-style OT environment would typically separate systems into security zones and tightly control communication between them.


Corporate / Enterprise Network
            |
            |
        [ OT DMZ ]
            |
     [ Industrial Firewall ]
            |
    +----------------------+
    |      OT Network      |
    |                      |
    |   +-------------+    |
    |   |     HMI     |    |
    |   +-------------+    |
    |          |           |
    |          | Modbus    |
    |          v           |
    |   +-------------+    |
    |   |     PLC     |    |
    |   +-------------+    |
    |                      |
    |   +-------------+    |
    |   | Engineering |    |
    |   | Workstation |    |
    |   +-------------+    |
    +----------------------+


### Security Zones

**Enterprise Zone**

Contains general-purpose corporate systems and users.

Direct access from this zone to PLC control services should not be permitted.

**OT DMZ**

Provides a controlled boundary between enterprise and OT environments.

Systems that require data exchange between the two environments should terminate or broker communication through this zone where appropriate.

**OT Control Zone**

Contains the HMI, PLC and other process-control assets.

Communication within this zone should be limited to required operational flows.

**Engineering Access**

Engineering workstations should be treated as privileged OT assets.

PLC programming and configuration access should be restricted, monitored and enabled only for authorized maintenance activities.

### Example Communication Policy

| Source | Destination | Service | Policy |
|---|---|---|---|
| HMI | PLC | Modbus/TCP 502 | Allow |
| Authorized Engineering Workstation | PLC | Required engineering services | Allow when required |
| Enterprise User Host | PLC | Modbus/TCP 502 | Deny |
| Unknown OT Host | PLC | Modbus/TCP 502 | Deny |
| PLC | Internet | Any | Deny by default |

### Defense-in-Depth Model

The proposed architecture combines several independent security layers:

- Network segmentation
- Firewall allowlisting
- Restricted engineering access
- Protocol-aware monitoring
- Centralized logging
- PLC process validation
- Fail-safe control logic
- Administrative change control

The objective is not to rely on a single security mechanism.

If one layer fails, additional controls should continue to reduce the likelihood or impact of unauthorized process manipulation.