# Validation and Security Testing Plan

## Objective
The purpose of this validation plan is to verify that the proposed security controls reduce the likelihood or impact of the previously demonstrated attack scenarios.

The validation process will compare the original insecure architecture with the hardened architecture.

## Validation Approach

Each previously demonstrated attack scenario will be repeated after implementing the proposed security controls.

For each test, the following will be recorded:

- Test objective
- Initial system state
- Security control being validated
- Test procedure
- Expected result
- Actual result
- Network evidence
- Process response
- Final assessment

## Validation Test Matrix

| Test ID | Related Risk | Security Control | Test Objective | Expected Result |
|---|---|---|---|---|
| V1 | R1 | Firewall / Modbus Access Control | Attempt unauthorized setpoint modification | Unauthorized host cannot modify `Requested_Qty` |
| V2 | R2 | Firewall / Modbus Access Control | Attempt unauthorized START command | Unauthorized host cannot initiate transfer |
| V3 | R3 | Network / Protocol Restriction | Attempt interlock manipulation | Unauthorized host cannot modify `Truck_Full_Sim` |
| V4 | R4 | Network / Process Data Protection | Attempt process-data manipulation | Unauthorized host cannot modify `Tank_Quantity` |
| V5 | R1-R4 | Monitoring and Detection | Generate unauthorized Modbus write attempt | Attempt is detected and logged |
| V6 | R1-R4 | PLC Logic Resilience | Test invalid or malicious process values | PLC remains in a safe and predictable state |

## Validation Success Criteria

The hardening implementation will be considered successful when:

- Unauthorized hosts cannot directly modify protected PLC registers
- Unauthorized START commands are blocked
- Critical process and interlock values cannot be modified from unapproved systems
- Unauthorized Modbus write attempts are detectable
- PLC safety logic continues to enforce process limits and permissives
- Legitimate HMI and engineering communications continue to function normally

