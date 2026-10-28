# Risk Assessment

## Scope
This assessment covers the demonstrated attack scenarios against the Aviation Fuel Farm OT Security Demonstration Lab.

## Rating Method
Likelihood and Impact are rated on a 1-5 scale.

- 1 = Very Low
- 2 = Low
- 3 = Medium
- 4 = High
- 5 = Very High

Risk Score = Likelihood x Impact

## Risk Register

| ID | Scenario | Likelihood | Impact | Risk Score | Rating |
|---|---|---:|---:|---:|---|
| R1 | Unauthorized Setpoint Manipulation | 4 | 3 | 12 | High |
| R2 | Unauthorized START Command | 4 | 4 | 16 | High |
| R3 | Runtime Interlock Manipulation | 4 | 3 | 12 | High |
| R4 | Sensor / Process Data Integrity Manipulation | 4 | 4 | 16 | High |

## R1 - Unauthorized Setpoint Manipulation

**Likelihood: 4/5**

The attack requires network access to the OT environment, but once access is obtained, the Modbus/TCP holding register can be modified without authentication or authorization.

**Impact: 3/5**

The attacker can alter an operator setpoint and compromise process data integrity. However, changing the requested quantity alone does not immediately start the transfer, and the PLC continues to enforce process permissives and safety checks.

**Risk Score: 12/25 - High**

The combination of weak protocol-level protection and direct write access creates a significant integrity risk, although existing PLC logic limits the immediate physical impact.

## R2 - Unauthorized START Command

**Likelihood: 4/5**

The attack requires network access to the OT environment. Once access is obtained, the START register can be modified directly over Modbus/TCP without authentication or authorization.

**Impact: 4/5**

The attacker can initiate an actual process operation and cause the transfer sequence to start. This directly affects the physical process and therefore represents a higher impact than simple setpoint manipulation.

The PLC still enforces configured permissives and safety conditions, which limits the attacker's ability to start the process under unsafe conditions.

**Risk Score: 16/25 - High**

Unauthorized access to a control command creates a significant process-control risk because a network-level attacker can initiate physical process activity without using the legitimate operator interface.

## R3 - Runtime Interlock Manipulation

**Likelihood: 4/5**

The attack requires network access to the OT environment. Once access is obtained, the attacker can modify the interlock-related holding register directly over Modbus/TCP without authentication or authorization.

**Impact: 3/5**

Manipulating the `Truck_Full` condition during an active transfer causes the PLC to remove the transfer permissive and stop the process.

This creates an operational availability impact and can interrupt normal fuel transfer operations. However, the PLC responds safely by shutting down the process rather than continuing under a perceived unsafe condition.

**Risk Score: 12/25 - High**

Unauthorized modification of interlock data can disrupt process availability and cause unintended shutdowns. The impact is significant, but existing fail-safe PLC logic limits the potential for direct hazardous process behavior.


## R4 - Sensor / Process Data Integrity Manipulation

**Likelihood: 4/5**

The attack requires network access to the OT environment. Once access is obtained, the process measurement register can be modified directly over Modbus/TCP without authentication or authorization.

**Impact: 4/5**

Manipulating `Tank_Quantity` changes the process information used by the PLC control logic.

In the demonstrated scenario, forcing the tank quantity to `0` caused the PLC to detect an empty-tank condition and stop the active transfer.

The immediate response was fail-safe, but compromise of trusted process measurements can cause the controller to make incorrect decisions based on falsified process data.

**Risk Score: 16/25 - High**

Loss of process data integrity represents a significant OT risk because the control system depends on trustworthy field and process information.

Even when the PLC logic is correctly designed, compromised input data can still produce unintended process behavior.

## Residual Risk Assessment

The residual risk assessment estimates the remaining risk after the proposed security controls are implemented.

| Risk ID | Initial Likelihood | Initial Impact | Initial Score | Residual Likelihood | Residual Impact | Residual Score | Residual Rating |
|---|---:|---:|---:|---:|---:|---:|---|
| R1 | 4 | 3 | 12 | 2 | 3 | 6 | Medium |
| R2 | 4 | 4 | 16 | 2 | 3 | 6 | Medium |
| R3 | 4 | 3 | 12 | 2 | 2 | 4 | Low |
| R4 | 4 | 4 | 16 | 2 | 3 | 6 | Medium |

### Residual Risk Rationale

**R1 - Unauthorized Setpoint Manipulation**

Network segmentation, firewall restrictions and Modbus/TCP access controls significantly reduce the likelihood that an unauthorized host can reach and modify the setpoint register.

The impact remains moderate because a successful unauthorized write could still affect process configuration, although PLC validation limits the potential consequence.

---

**R2 - Unauthorized START Command**

Restricting access to the PLC and limiting Modbus write permissions reduces the likelihood of unauthorized process initiation.

The residual impact is reduced because PLC permissives and interlocks continue to restrict unsafe process startup.

---

**R3 - Runtime Interlock Manipulation**

Network and protocol access controls reduce the likelihood of unauthorized interlock manipulation.

The residual impact is relatively low because the PLC responds to the manipulated condition by entering a safe shutdown state and requires a new START command before operation can resume.

---

**R4 - Sensor / Process Data Integrity Manipulation**

Network segmentation, access restrictions, monitoring and process validation reduce the likelihood of unauthorized manipulation of process measurements.

The remaining impact is still significant because the PLC depends on trusted process data for control decisions. Additional validation, redundancy or independent measurement verification may be required for critical process variables.