# PLC Programming

## Overview

The process-control logic is implemented in Structured Text using OpenPLC.

The complete tested PLC source is stored in:

`src/airport_fuel_pump_v2.st`

This document summarizes the main program structure and security-relevant design decisions.

## Main Functions

The PLC program performs:

- Process calculations
- Transfer request validation
- Transfer permissive evaluation
- START edge detection
- Batch target latching
- Runtime interlock monitoring
- Transfer simulation
- Batch completion
- Diagnostic output handling

## Capacity Calculation

Truck remaining capacity is calculated continuously:

```text id="65gtfz"
Remaining_Capacity :=
    Truck_Max_Capacity - Truck_Current_Qty;
```

Before transfer, the requested quantity is compared against both truck capacity and tank quantity.

## Transfer Permissive

The main transfer authorization logic combines the required operating conditions:

```text id="7xbbx9"
Transfer_Permitted :=
    Truck_Connected
    AND Truck_Grounded
    AND Fuel_Quality_Released
    AND E_Stop_Clear
    AND NOT Truck_Full
    AND NOT Invalid_Request
    AND NOT High_Pressure
    AND NOT Insufficient_Tank_Quantity;
```

A START command is accepted only when this condition is TRUE.

## START Edge Detection

A rising edge is generated using:

```text id="x6dg50"
Start_Pulse :=
    Start_Transfer
    AND NOT Start_Transfer_Previous;
```

This prevents a continuously held START signal from repeatedly restarting the process.

## Batch Target Latching

When START is accepted:

```text id="rbrmza"
Batch_Target_Qty := Requested_Qty;
Transferred_Qty := 0;
Transfer_Active := TRUE;
```

The active process then uses `Batch_Target_Qty` rather than the live requested quantity.

This behavior was validated during testing by changing `Requested_Qty` mid-transfer while the active batch still completed at its original target.

## Runtime Shutdown Logic

The active transfer is stopped when critical conditions are lost:

```text id="kp29d0"
IF
    NOT Transfer_Permitted
    OR Stop_Transfer
    OR Low_Pressure
    OR Tank_Empty
THEN
    Transfer_Active := FALSE;
END_IF;
```

This provides continuous protection during operation.

## Transfer Simulation

While transfer is active:

- `Transferred_Qty` increases
- `Truck_Current_Qty` increases
- `Tank_Quantity` decreases

Normal simulated process values are:

- `Flow_Rate = 120 L/min`
- `Line_Pressure ≈ 5 bar`

The final transfer increment uses the exact remaining quantity to avoid overshooting the batch target.

## Batch Completion

When the transferred quantity reaches the latched target:

```text id="jfq7zb"
Transferred_Qty >= Batch_Target_Qty
```

the PLC:

- Clears `Transfer_Active`
- Sets `Batch_Complete`
- Resets `Requested_Qty`
- Stops pump and valve operation

## Security-Relevant Logic

Several PLC design choices reduce the impact of abnormal or malicious inputs:

- Invalid requests are rejected before START
- Truck capacity is validated
- Tank quantity is validated
- Critical permissives are continuously monitored
- Fault clearing does not cause automatic restart
- Active batch target is isolated from live setpoint changes
- Abnormal conditions move the process toward a stopped state

These controls do not prevent unauthorized network access, but they provide an additional process-resilience layer when network security controls fail.

## Source Code

The full tested Structured Text implementation is available at:

`04_PLC_Programming/src/airport_fuel_pump_v2.st`