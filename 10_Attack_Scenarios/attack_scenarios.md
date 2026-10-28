# Attack Scenarios

## Scenario 1 — Unauthorized Setpoint Manipulation

**Target:** Requested_Qty  
**Protocol:** Modbus/TCP  
**Function Code:** FC6 — Write Single Register  
**Source Host:** Kali Linux — 192.168.56.102  
**Target PLC:** OpenPLC — 192.168.56.101:502  

### Initial State
The PLC and HMI were operating normally.
The Requested_Qty value was valid and writable through Modbus/TCP.

### Attacker Action
The Kali host modified the Requested_Qty register without authentication.

### Network Observation
Wireshark showed a Modbus/TCP FC6 — Write Single Register request.

Because mbpoll uses 1-based register references while the Modbus PDU uses 0-based addressing:
- mbpoll reference: 1029
- Wireshark reference number: 1028

### Result
The Requested_Qty value changed to 75, and the HMI displayed the modified value.

### Security Finding
A host with network access to Modbus/TCP port 502 was able to modify process control data without authentication.

### Security Impact
This demonstrates loss of process data integrity and unauthorized modification of an operator setpoint.

Example command:

```bash
mbpoll -m tcp -a 1 -r 1029 -t 4:int16 192.168.56.101 75
```

## Scenario 2 — Unauthorized START Command

**Target:** `Start_Transfer_Sim`  
**Protocol:** Modbus/TCP  
**Function Code:** FC6 — Write Single Register  
**Source Host:** Kali Linux — `192.168.56.102`  
**Target PLC:** OpenPLC — `192.168.56.101:502`

### Initial State
The fuel transfer system was idle and the required transfer permissives were satisfied.

A valid `Requested_Qty` had already been configured.

### Attacker Action
The Kali host generated a START command by writing a `0 → 1` transition to the `Start_Transfer_Sim` holding register.

### Network Observation
Wireshark captured two Modbus/TCP FC6 — Write Single Register requests.

For the START register:
- mbpoll reference: 1040
- Wireshark reference number: 1039
The first request wrote:
Reference Number: 1039
Register Value: 0

The second request wrote:
Reference Number: 1039
Register Value: 1

The PLC returned an FC6 response echoing the register address and value, confirming that the writes were accepted.

No authentication or authorization exchange occurred before the control command was processed.

### PLC / Process Response
The 0 → 1 transition generated the START edge expected by the PLC logic.

The PLC activated the transfer sequence.

Observed HMI changes included:
- Line Pressure → approximately 5 bar
- Flow Rate → 120 L/min
- Tank Quantity decreased
- Truck Quantity increased
- Transferred Quantity increased

### Result
A host with network access to the PLC was able to initiate the fuel transfer process remotely using an unauthenticated Modbus write.

### Security Finding
Modbus/TCP control registers were directly writable by another host on the OT network without authentication.

Network access to TCP port 502 was sufficient to issue a valid process command.
Security Impact
This demonstrates unauthorized control of the physical process.

A compromised or unauthorized host with access to the OT network could initiate process operations without using the legitimate HMI or operator workflow.

### Safety Observation
The PLC still enforced its configured permissives before allowing the transfer to start.

Therefore, unauthorized network access enabled command injection, while the PLC control logic provided a limited layer of process protection.
Example commands:

```bash
mbpoll -m tcp -a 1 -r 1040 -t 4:int16 192.168.56.101 0
mbpoll -m tcp -a 1 -r 1040 -t 4:int16 192.168.56.101 1
```

## Scenario 3 — Runtime Interlock Manipulation

**Target:** `Truck_Full_Sim`  
**Protocol:** Modbus/TCP  
**Function Code:** FC6 — Write Single Register  
**Source Host:** Kali Linux — `192.168.56.102`  
**Target PLC:** OpenPLC — `192.168.56.101:502`

### Initial State
A fuel transfer was already active.

The process was operating normally with:

- Line Pressure ≈ `5 bar`
- Flow Rate = `120 L/min`
- Transferred Quantity increasing
- Truck_Full condition = `FALSE`

### Attacker Action
The Kali host modified the `Truck_Full_Sim` holding register during an active transfer.

### Network Observation
Wireshark captured a Modbus/TCP FC6 — Write Single Register request.

For the Truck_Full_Sim register:
- mbpoll reference: 1039
- Modbus/Wireshark reference number: 1038
- Written value: 1
The PLC returned an FC6 response echoing the register address and value, confirming that the write was accepted.

No authentication or authorization exchange occurred before the register modification.

### PLC / Process Response
The PLC interpreted the modified input as a valid Truck_Full condition.

The transfer permissive was removed and the active transfer was stopped.

Observed HMI changes included:
- Flow Rate → 0
- Line Pressure → 0
- Transferred Quantity stopped increasing
- Tank Quantity stopped decreasing
- Truck Quantity stopped increasing

### Result
A host with access to the OT network was able to interrupt an active fuel transfer by modifying a field-condition register.

### Security Finding
Process interlock data could be modified remotely through unauthenticated Modbus/TCP writes.

The PLC correctly trusted the received process input and executed the configured safety shutdown.

### Security Impact
This demonstrates a process availability and data-integrity risk.

An attacker may not need direct control of START/STOP commands to disrupt operations. Manipulating a trusted field condition can indirectly force the PLC to stop the process.

### Safety Observation
After Truck_Full_Sim was restored to 0, the transfer did not restart automatically.

A new START command was required.

This demonstrates the safety principle:

Fault clear does not equal automatic restart.

The PLC logic reduced the risk of an unexpected process restart after an interlock trip.
Example command:

```bash
mbpoll -m tcp -a 1 -r 1039 -t 4:int16 192.168.56.101 1
```

## Scenario 4 — Sensor / Process Data Integrity Manipulation

**Target:** `Tank_Quantity`  
**Protocol:** Modbus/TCP  
**Function Code:** FC6 — Write Single Register  
**Source Host:** Kali Linux — `192.168.56.102`  
**Target PLC:** OpenPLC — `192.168.56.101:502`

### Initial State
A fuel transfer was active and operating normally.

The storage tank contained sufficient fuel and the transfer process was running with:

- Line Pressure ≈ `5 bar`
- Flow Rate = `120 L/min`
- Transferred Quantity increasing
- Tank Quantity decreasing normally

### Attacker Action
The Kali host modified the `Tank_Quantity` holding register during the active transfer.

### Network Observation
Wireshark captured a Modbus/TCP FC6 — Write Single Register request.

For the Tank_Quantity register:
- mbpoll reference: 1026
- Modbus/Wireshark reference number: 1025
- Written value: 0
The PLC returned an FC6 response echoing the address and value, confirming that the write was accepted.

No authentication or authorization exchange occurred before the process value was modified.

### PLC/Process Response
The PLC interpreted the modified Tank_Quantity value as a real process condition.

The control logic detected an empty-tank condition and stopped the active transfer.

Observed HMI changes included:
- Tank Quantity → 0
- Flow Rate → 0
- Line Pressure → 0
- Transferred Quantity stopped increasing
- Tank and truck quantities stopped changing

### Result
A host with network access to the PLC was able to manipulate process measurement data and trigger a real control response.

### Security Finding
The integrity of process data was not protected against unauthorized Modbus/TCP writes.

The PLC correctly executed its safety logic based on the information it received, but the trusted process value itself had been falsified.

###Security Impact
This demonstrates a process data integrity and availability risk.

An attacker does not necessarily need to issue direct START or STOP commands. Manipulating a trusted process value can cause the PLC to make an incorrect control decision.

### Engineering/ Security Lesson
Correct control logic can still produce an undesirable physical outcome when its input data is compromised.

Protecting OT systems therefore requires controls that preserve the integrity of both:
- control commands
- sensor and process data



Example command:

```bash
mbpoll -m tcp -a 1 -r 1026 -t 4:int16 192.168.56.101 0
```