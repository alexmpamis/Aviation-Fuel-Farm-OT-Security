# Threat Model

## System Scope

The threat model covers the Aviation Fuel Farm OT Security Demonstration Lab.

The system includes:

- OpenPLC controller
- HMI
- Modbus/TCP communications
- Engineering workstation functions
- Simulated process measurements and interlocks
- Kali Linux as an unauthorized or attacker-controlled host

## Critical Assets

The following assets are considered security-relevant:

- PLC control logic
- Operator setpoints
- START and STOP commands
- Process interlocks
- Tank quantity data
- Truck quantity data
- Pressure and flow measurements
- HMI-to-PLC communications
- Engineering access to the PLC

## Security Objectives

The primary security objectives are:

- Maintain process safety
- Maintain availability of fuel transfer operations
- Protect the integrity of control commands
- Protect the integrity of process measurements
- Prevent unauthorized modification of PLC data
- Detect unauthorized OT network activity

## Potential Threat Actors

Potential threat actors include:

- Unauthorized internal network users
- Compromised workstations
- Malicious insiders
- Compromised engineering systems
- External attackers who obtain access to the OT environment

## Trust Boundaries

The primary trust boundary exists between general-purpose or untrusted systems and the OT control environment.

Systems that communicate directly with the PLC should not automatically be considered trusted solely because they are connected to the same network.

## Primary Attack Surface

The primary attack surface identified during testing was the PLC Modbus/TCP service on:

`192.168.56.101:502`

A host with network access to this service was able to perform unauthenticated Modbus write operations.

## Identified Attack Paths

### Attack Path 1 - Unauthorized Setpoint Modification

Attacker host -> Modbus/TCP -> Requested_Qty register -> PLC logic -> HMI/process effect

### Attack Path 2 - Unauthorized Process Start

Attacker host -> Modbus/TCP -> START register -> PLC logic -> Process activation

### Attack Path 3 - Interlock Manipulation

Attacker host -> Modbus/TCP -> Truck_Full register -> PLC safety logic -> Process shutdown

### Attack Path 4 - Process Data Manipulation

Attacker host -> Modbus/TCP -> Tank_Quantity register -> PLC decision logic -> Process shutdown

## Key Security Assumptions

The current baseline environment assumes:

- Modbus/TCP traffic is not authenticated
- Hosts with network access can attempt communication with the PLC
- Process registers are reachable through the PLC Modbus interface
- Network segmentation is not yet enforced
- Firewall allowlisting has not yet been implemented
- PLC logic provides some process-level resilience but does not prevent unauthorized network writes

## Threat Model Conclusion

The primary weakness of the baseline architecture is not the PLC control logic itself.

The main security issue is that network access to the PLC allows unauthorized systems to interact directly with process-control data and commands.

The security redesign should therefore focus on restricting network access, limiting Modbus write capabilities, monitoring abnormal communications, and maintaining resilient PLC behavior.