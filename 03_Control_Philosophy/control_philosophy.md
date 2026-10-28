# Control Philosophy

## Objective

The PLC controls the transfer of aviation fuel from a storage tank to a refueling truck.

The process is allowed to run only when the required operating conditions are valid. If a critical condition is lost during transfer, the PLC moves the process to a stopped state.

## Transfer Permissives

A transfer is permitted only when:

- Truck is connected
- Truck is grounded
- Fuel quality is released
- Emergency stop is clear
- Truck is not full
- Requested quantity is valid
- Truck has sufficient remaining capacity
- Tank has sufficient fuel
- No high-pressure condition exists

The START command alone cannot activate the process unless these conditions are satisfied.

## Request Validation

Before starting a batch, the PLC validates the requested transfer quantity.

The request is rejected when:

- `Requested_Qty <= 0`
- Requested quantity exceeds truck remaining capacity
- Requested quantity exceeds available tank quantity

This prevents invalid or physically impossible transfer requests.

## Start and Batch Logic

The PLC uses a `0 -> 1` START transition to initiate a transfer.

When a valid START is received:

- `Requested_Qty` is copied into `Batch_Target_Qty`
- `Transferred_Qty` is reset
- Transfer becomes active

The batch target is therefore latched at START.

Changes to the live `Requested_Qty` during an active transfer do not change the current batch target.

## Runtime Protection

While transfer is active, the PLC continuously monitors process conditions.

The transfer is stopped if:

- A required permissive is lost
- STOP is commanded
- Low-pressure trip occurs
- Tank becomes empty

High pressure also removes the transfer permissive.

## Normal Process State

During active transfer:

- Transfer pump = ON
- Outlet valve = OPEN
- Line pressure ≈ `5 bar`
- Flow rate = `120 L/min`
- Tank quantity decreases
- Truck quantity increases
- Transferred quantity increases

When transfer is inactive:

- Pump = OFF
- Valve = CLOSED
- Pressure = `0`
- Flow = `0`

## No Automatic Restart

After a trip or permissive loss, clearing the abnormal condition does not automatically restart the process.

A new START command is required.

This prevents unexpected equipment operation after a fault.

## Batch Completion

When:

`Transferred_Qty >= Batch_Target_Qty`

the PLC:

- Stops the transfer
- Marks the batch complete
- Resets the requested quantity
- Returns pressure and flow to zero

## Control Design Principles

The PLC logic follows four main principles:

1. Validate commands before execution
2. Continuously monitor critical conditions
3. Fail toward a stopped state
4. Require deliberate operator action after abnormal shutdown

These principles provide predictable process behavior and limit the impact of both operational faults and malicious input manipulation.