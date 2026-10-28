# Aviation Fuel Farm OT Security Demonstration Lab

## Overview

This project is a hands-on OT/ICS cybersecurity lab that models a simplified aviation fuel transfer process.

The objective is to demonstrate a complete industrial control-system engineering and security workflow:

**Process Design → PLC Control → Modbus/TCP → HMI → Network Analysis → Attack Scenarios → Risk Assessment → Security Hardening → Validation**

The lab was intentionally kept small enough to be fully understood while still demonstrating realistic OT cybersecurity concepts.

---

## Project Objectives

The project demonstrates:

- Industrial process and control-system understanding
- PLC programming and interlock design
- Modbus/TCP communication
- HMI development
- OT network traffic analysis
- Cyber-to-process attack scenarios
- OT risk assessment
- Defense-in-depth security design
- Firewall allowlisting
- Monitoring and logging
- PLC logic resilience
- Security-control validation

---

## Simulated Process

The lab represents a simplified aviation fuel transfer system:

```text
Fuel Storage Tank
       |
       v
  Outlet Valve
       |
       v
  Transfer Pump
       |
       v
Filter / Water Separator
       |
       v
Pressure & Flow Monitoring
       |
       v
 Refueling Truck
```

The operator requests a transfer quantity.

Before starting the transfer, the PLC verifies process permissives, available truck capacity and available tank quantity.

During transfer, the PLC continuously monitors process conditions and stops the operation if a critical permissive or protection condition is triggered.

See the simplified process diagram:

[View P&ID](./02_P_and_ID/images/Aviation%20Fuel%20Transfer%20P&ID%20Diagram.png)

---

## Lab Environment

### PLC

- OpenPLC v3
- Structured Text
- Ubuntu 22.04
- Modbus/TCP on TCP port 502

PLC source:

[airport_fuel_pump_v2.st](./04_PLC_Programming/src/airport_fuel_pump_v2.st)

### HMI

- FUXA
- Docker deployment
- Live process visualization
- Operator commands
- Simulation and test controls

HMI evidence:

[HMI Overview](./06_HMI/hmi_overview.md)

### Security Testing

- Kali Linux
- mbpoll
- Wireshark
- UFW host firewall

### Network

| Component | Address |
|---|---|
| OpenPLC | `192.168.56.101` |
| Kali Linux | `192.168.56.102` |
| FUXA Docker Container | `172.17.0.2` |

---

## Control Logic

The PLC implements:

- Transfer permissives
- Requested quantity validation
- Truck capacity validation
- Tank quantity validation
- START edge detection
- STOP handling
- High-pressure protection
- Low-pressure runtime trip
- Truck-full interlock
- Tank-empty protection
- No automatic restart after a trip
- Latched active batch target

The simulated transfer rate during normal operation is approximately:

`120 L/min`

Detailed control logic:

[Control Philosophy](./03_Control_Philosophy/control_philosophy.md)

[PLC Programming](./04_PLC_Programming/plc_logic.md)

---

## Modbus/TCP

Process variables and simulation controls are exposed through Modbus holding registers.

| Variable | mbpoll Reference |
|---|---:|
| Tank Quantity | 1026 |
| Truck Current Quantity | 1027 |
| Truck Maximum Capacity | 1028 |
| Requested Quantity | 1029 |
| Remaining Capacity | 1030 |
| Line Pressure | 1031 |
| Flow Rate | 1032 |
| Transferred Quantity | 1034 |
| START Command | 1040 |
| STOP Command | 1041 |

The project also demonstrates the difference between 1-based client references and 0-based Modbus PDU addressing.

Full register map:

[Modbus Memory Map](./05_Modbus_Memory_Map/modbus_memory_map.md)

---

## Network Analysis

Wireshark was used to observe Modbus/TCP traffic generated during baseline testing.

The captures include:

- FC3 — Read Holding Registers
- FC6 — Write Single Register
- Modbus/TCP addressing behavior
- Direct relationship between network writes and PLC process behavior

Evidence:

[Wireshark Analysis](./08_Wireshark_Captures/wireshark_analysis.md)

---

## Security Findings

The baseline architecture allowed another host on the OT network to communicate directly with the PLC Modbus/TCP service.

Four security scenarios were demonstrated:

### Unauthorized Setpoint Manipulation

An unauthorized host modified `Requested_Qty` through a Modbus FC6 write.

### Unauthorized Process Start

An unauthorized Modbus write generated the START edge required by the PLC.

### Runtime Interlock Manipulation

The `Truck_Full` condition was modified during an active transfer, causing the process to stop.

### Process Data Manipulation

The reported tank quantity was modified, causing the PLC to act on falsified process information.

These tests demonstrated that correct PLC logic alone cannot secure a process if unauthorized hosts can modify trusted control and process data.

Detailed scenarios:

[Attack Scenarios](./10_Attack_Scenarios/attack_scenarios.md)

---

## Security Hardening

The lab was hardened using a default-deny host firewall and explicit source allowlisting.

Authorized communication:

```text
FUXA 172.17.0.2 → OpenPLC TCP/502 = ALLOWED
```

Unauthorized communication:

```text
Kali 192.168.56.102 → OpenPLC TCP/502 = BLOCKED
```

The legitimate HMI remained operational while unauthorized Modbus/TCP access from Kali was prevented.

Security controls:

[Security Controls](./12_Security_Controls/security_controls.md)

---

## Validation Results

The previously demonstrated attack paths were repeated after hardening.

| Test | Result |
|---|---|
| Unauthorized Setpoint Write | PASS — Blocked |
| Unauthorized START Command | PASS — Blocked |
| Runtime Interlock Manipulation | PASS — Blocked |
| Process Data Manipulation | PASS — Blocked |
| Unauthorized Modbus Access Detection | PASS |
| Invalid Setpoint Handling | PASS |
| Truck Capacity Validation | PASS |
| Tank Quantity Validation | PASS |
| No Automatic Restart After Trip | PASS |
| Active Batch Setpoint Isolation | PASS |

Firewall logs recorded blocked TCP/502 connection attempts from the unauthorized Kali host.

Detailed results and evidence:

[Validation Results](./13_Validation_Testing/validation_results.md)

---

## Defense-in-Depth

The project demonstrates three complementary security layers.

### Prevention

- Default-deny firewall policy
- Source allowlisting
- Restricted Modbus/TCP access

### Detection

- UFW logging
- Network traffic analysis
- Identification of unauthorized TCP/502 access attempts

### Impact Limitation

- PLC permissives
- Input validation
- Process constraints
- Fail-safe shutdown behavior
- No automatic restart
- Latched active batch targets

---

## Production-Style Security Design

The lab implementation is intentionally lightweight.

A production OT environment would typically introduce additional controls such as:

- Dedicated OT network segmentation
- Industrial firewalls
- OT DMZ
- Restricted engineering workstation access
- Protocol-aware monitoring
- OT IDS
- Centralized logging
- Controlled remote access
- Formal change management
- Asset inventory and access governance

See:

[Network Architecture](./07_Network_Architecture/network_architecture.md)

---

## Repository Structure

```text
01_System_Overview/
02_P_and_ID/
03_Control_Philosophy/
04_PLC_Programming/
05_Modbus_Memory_Map/
06_HMI/
07_Network_Architecture/
08_Wireshark_Captures/
09_Threat_Model/
10_Attack_Scenarios/
11_Risk_Assessment/
12_Security_Controls/
13_Validation_Testing/
README.md
```

---

## Key Engineering Lesson

> Safe control logic does not guarantee a secure process if the data and commands feeding that logic cannot be trusted.

OT cybersecurity therefore requires both robust process engineering and layered cybersecurity controls.

---

## Project Status

Core process simulation, PLC logic, HMI operation, Modbus/TCP analysis, attack testing, risk assessment, security hardening and validation are complete.

The current repository includes working PLC source code, HMI evidence, packet-analysis evidence, firewall logs and validation results.

Future extensions could include protocol-aware OT monitoring, automated detection logic and controlled Red/Blue agent experimentation within the isolated lab.