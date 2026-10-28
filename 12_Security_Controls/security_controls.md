# Security Controls and Hardening

## Objective
The purpose of this section is to reduce the likelihood and impact of the risks identified during the attack scenarios and risk assessment.

## Security Strategy
The hardening approach follows defense-in-depth principles.

No single control is expected to eliminate all risk. Multiple technical and procedural controls are combined to reduce attack opportunities, limit unauthorized access, detect malicious activity, and reduce process impact.

## Risk-to-Control Mapping

| Risk ID | Risk | Primary Security Objective | Proposed Controls |
|---|---|---|---|
| R1 | Unauthorized Setpoint Manipulation | Protect command and data integrity | Network Segmentation, Firewall and Access Control, Modbus/TCP Traffic Restriction, Monitoring and Detection, PLC Logic Validation |
| R2 | Unauthorized START Command | Prevent unauthorized process control | Network Segmentation, Firewall and Access Control, Engineering Workstation Access Control, Modbus/TCP Traffic Restriction, Monitoring and Detection, PLC Permissives |
| R3 | Runtime Interlock Manipulation | Protect interlock integrity | Network Segmentation, Firewall and Access Control, Modbus/TCP Traffic Restriction, Monitoring and Detection, PLC Fail-Safe Logic |
| R4 | Sensor / Process Data Integrity Manipulation | Protect trusted process data | Network Segmentation, Firewall and Access Control, Modbus/PLC Traffic Restriction, Monitoring and Detection, PLC Sanity Checks and Process Validation |

## Proposed Security Controls

### 1. Network Segmentation

The current lab architecture allows any host with access to the OT network to communicate directly with the PLC over Modbus/TCP.

This creates a large attack surface because network access effectively provides direct access to process-control services.

The proposed architecture separates general-purpose user systems from the OT control network using a firewall or routed security boundary.

Only explicitly authorized systems should be able to communicate with the PLC.

Proposed communication policy:

- HMI -> PLC TCP/502: Allowed
- Engineering Workstation -> PLC TCP/502: Allowed only when required
- General User Hosts -> PLC TCP/502: Blocked
- Unauthorized OT Hosts -> PLC TCP/502: Blocked
- PLC -> Internet: Blocked unless explicitly required

The objective is to reduce the likelihood of unauthorized Modbus communication by limiting which systems can reach the PLC.

This control directly reduces the likelihood of risks R1, R2, R3 and R4 because all four demonstrated attacks required network access to the PLC.

### 2. Firewall and Access Control

A firewall should enforce explicit communication rules between the general-purpose network and the OT control network.

The default approach should be:

**Deny by default, allow only required communication.**

For the fuel farm lab, the PLC should not accept Modbus/TCP connections from arbitrary hosts.

Example access policy:

- HMI -> PLC TCP/502: Allow
- Authorized Engineering Workstation -> PLC TCP/502: Allow
- Kali / General User Hosts -> PLC TCP/502: Deny
- Unknown Hosts -> PLC TCP/502: Deny
- Unnecessary inbound connections to the PLC: Deny

Where possible, firewall rules should be based on:

- Source IP address
- Destination IP address
- Destination port
- Protocol
- Direction of communication

For example, only the authorized HMI and engineering workstation should be able to initiate Modbus/TCP connections to the PLC.

This significantly reduces the attack surface because an attacker cannot rely only on being present somewhere inside the broader network.

Even if a host is compromised, the firewall can prevent it from directly reaching the PLC control service.

This control reduces the likelihood of R1, R2, R3 and R4 by restricting unauthorized access to TCP port 502.

### 3. Engineering Workstation Access Control

Engineering workstations should be treated as privileged OT assets because they can modify PLC programs, configurations and control parameters.

Access to engineering functions should therefore be restricted to authorized personnel and controlled systems.

Recommended controls include:

- Dedicated engineering workstation for OT administration
- Strong user authentication
- Least-privilege user accounts
- No shared administrative accounts
- Restricted network access to PLCs
- Engineering access enabled only when required
- Logging of configuration and programming changes
- Controlled software installation
- Removal of unnecessary services and applications
- Regular patching according to OT operational requirements

The engineering workstation should not be used for general-purpose activities such as web browsing, personal email or unrelated software.

Where practical, engineering access should be performed through a controlled maintenance process and monitored network path.

This reduces the likelihood that a compromised general-purpose workstation can directly modify PLC logic or configuration.

It also limits the number of systems that are trusted to perform high-impact changes within the OT environment.

### 4. Modbus/TCP Traffic Restriction

Modbus/TCP communication should be restricted to only the systems and operations required for normal process control.

The protocol does not provide native authentication or encryption in the demonstrated configuration. Therefore, protection must be provided by the surrounding network architecture and security controls.

Recommended controls include:

- Allow Modbus/TCP only between explicitly authorized hosts
- Restrict access to TCP port 502
- Block Modbus communication from general-purpose user networks
- Monitor Modbus write operations
- Detect unexpected Function Code usage
- Alert on unauthorized or unusual register writes
- Restrict engineering access to approved maintenance systems
- Where supported, use industrial firewalls capable of protocol-aware filtering

Special attention should be given to Modbus write operations such as:

- FC6 - Write Single Register
- FC16 - Write Multiple Registers

The demonstrated attack scenarios relied on unauthorized FC6 write requests to modify:

- Operator setpoints
- START commands
- Interlock conditions
- Process measurement values

If the operational design allows it, read-only monitoring systems should not be permitted to issue Modbus write commands.

This control directly addresses R1, R2, R3 and R4 by reducing the ability of unauthorized systems to modify PLC data and control values.

### 5. Monitoring and Detection

Network monitoring should be used to detect unauthorized or abnormal Modbus/TCP activity within the OT environment.

Because the demonstrated attack scenarios generated identifiable Modbus write traffic, monitoring systems can be configured to detect similar behavior.

Recommended monitoring controls include:

- Capture and inspect Modbus/TCP traffic
- Monitor communications to PLC TCP port 502
- Alert on unexpected Modbus write operations
- Detect FC6 - Write Single Register activity from unauthorized hosts
- Detect FC16 - Write Multiple Registers where not operationally required
- Monitor access to critical registers
- Detect communication from unknown or unapproved source IP addresses
- Establish a baseline of normal HMI-to-PLC communication
- Investigate deviations from normal communication patterns
- Retain logs and packet captures for incident investigation

High-value detection events in this lab include:

- Unauthorized modification of `Requested_Qty`
- Unauthorized writes to `Start_Transfer_Sim`
- Changes to `Truck_Full_Sim`
- Unexpected modification of `Tank_Quantity`

For example, an FC6 request originating from a host other than the authorized HMI or engineering workstation should be treated as suspicious.

Monitoring does not prevent the attack by itself, but it improves visibility, detection and incident response.

This control supports the detection of R1, R2, R3 and R4.

### 6. PLC and Process Logic Resilience

PLC control logic should be designed to maintain safe and predictable behavior even when abnormal or malicious input values are received.

Cybersecurity controls should not be treated as a replacement for robust process-control logic.

Recommended resilience measures include:

- Validate operator setpoints before use
- Reject zero, negative or out-of-range transfer requests
- Verify available truck capacity before starting transfer
- Verify available tank quantity before starting transfer
- Enforce process permissives before activating equipment
- Stop the process when critical permissives are lost
- Require a new START command after a trip or fault condition
- Prevent automatic restart after safety-related shutdowns
- Latch critical operating values when appropriate
- Separate active batch parameters from live operator inputs
- Use fail-safe behavior for abnormal process conditions
- Perform sanity checks on critical process measurements

The current PLC implementation already demonstrates several resilience features.

For example:

- `Requested_Qty` is validated before transfer
- The active batch quantity is latched at START
- Changing the live requested quantity does not modify the active batch target
- Loss of a critical permissive stops the transfer
- Clearing a fault does not automatically restart the process
- High pressure, low pressure, truck-full and tank-empty conditions can stop the transfer

These controls do not prevent unauthorized Modbus writes, but they can reduce the physical impact of compromised commands or process data.

This provides an additional defense layer when preventive cybersecurity controls fail.

### 7. Operator and Administrative Controls

Operational and administrative controls should support the technical security architecture and reduce the risk of unauthorized or unsafe changes.

Recommended controls include:

- Define clear roles and responsibilities for operators, engineers and administrators
- Apply least-privilege access principles
- Use separate accounts for operator, engineering and administrative functions
- Avoid shared user accounts
- Require authorization for PLC programming or configuration changes
- Use a formal change-management process for control logic modifications
- Document maintenance activities and engineering interventions
- Maintain an approved asset and communication inventory
- Review user access periodically
- Remove access when it is no longer required
- Provide OT-specific security awareness training
- Establish procedures for responding to abnormal process or network behavior
- Maintain tested backup and recovery procedures for PLC programs and configurations

Critical changes to the control system should be traceable to an authorized person, approved activity and documented reason.

Administrative controls do not replace technical protections, but they reduce the probability of accidental or unauthorized changes and improve accountability during incident investigation.

These controls support all identified risks by strengthening access governance, change control and operational discipline.