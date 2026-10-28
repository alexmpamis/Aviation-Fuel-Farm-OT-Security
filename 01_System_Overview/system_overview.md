# System Overview

## Project Purpose

The Aviation Fuel Farm OT Security Demonstration Lab is a small-scale OT/ICS project that models a simplified aviation fuel transfer process and its cybersecurity risks.

The project connects process engineering, PLC control, Modbus/TCP communication, HMI operation, attack testing, security hardening and validation in a single end-to-end lab.

## Process Overview

The simulated process represents fuel transfer from a storage tank to a refueling truck.

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

The operator enters a requested transfer quantity.

Before transfer begins, the PLC checks process permissives, available truck capacity and available tank quantity.

During operation, critical process conditions continue to be monitored and the PLC can stop the transfer if a required condition is lost.

## Main Components

### OpenPLC

OpenPLC executes the Structured Text control logic and manages:

- Transfer authorization
- Process permissives and interlocks
- Batch control
- Process simulation
- START and STOP commands
- Safety-related shutdown behavior

### FUXA HMI

FUXA provides the operator interface for:

- Process visualization
- Requested quantity entry
- START and STOP commands
- Simulation and test controls

### Kali Linux

Kali Linux is used as the unauthorized or attacker-controlled host for:

- Modbus/TCP testing
- Register reads and writes
- Attack scenarios
- Security-control validation

### Ubuntu

Ubuntu hosts:

- OpenPLC
- FUXA Docker container
- Host-based firewall used during hardening

## Lab Network

| Component | Address |
|---|---|
| OpenPLC / Ubuntu | `192.168.56.101` |
| Kali Linux | `192.168.56.102` |
| FUXA Docker Container | `172.17.0.2` |

OpenPLC exposes Modbus/TCP on:

`TCP/502`

## Project Scope

The project demonstrates the full OT security workflow:

**Process Understanding -> Control Logic -> HMI -> Network Traffic -> Attack Scenarios -> Risk Assessment -> Security Controls -> Validation**

The main security focus is unauthorized access to PLC control and process data through Modbus/TCP.

The lab evaluates whether an unauthorized host can:

- Modify operator setpoints
- Issue process commands
- Manipulate interlock conditions
- Alter trusted process data

The same scenarios are then repeated after hardening to verify whether the implemented controls reduce the risk.

## Design Philosophy

The project follows one core principle:

**Small system, deeply understood.**

The objective is not to simulate an entire airport fuel infrastructure.

Instead, the lab provides enough process, control and network complexity to demonstrate realistic OT cybersecurity behavior while keeping every major system interaction understandable and testable.