# Modbus Memory Map

## Overview

OpenPLC exposes the main process variables and simulation controls through Modbus/TCP holding registers.

The lab uses:

`TCP/502`

`mbpoll` uses 1-based register references, while the Modbus PDU shown in Wireshark uses 0-based addressing.

Example:

`mbpoll 1029 -> Modbus PDU address 1028`

## Process Registers

| PLC Variable | PLC Address | mbpoll Reference | Purpose |
|---|---|---:|---|
| `Tank_Level` | `%MW0` | 1025 | Reserved tank level value |
| `Tank_Quantity` | `%MW1` | 1026 | Available fuel quantity |
| `Truck_Current_Qty` | `%MW2` | 1027 | Current truck fuel quantity |
| `Truck_Max_Capacity` | `%MW3` | 1028 | Maximum truck capacity |
| `Requested_Qty` | `%MW4` | 1029 | Operator-requested transfer quantity |
| `Remaining_Capacity` | `%MW5` | 1030 | Calculated truck remaining capacity |
| `Line_Pressure` | `%MW6` | 1031 | Simulated transfer-line pressure |
| `Flow_Rate` | `%MW7` | 1032 | Simulated fuel flow rate |
| `Fuel_Temperature` | `%MW8` | 1033 | Reserved fuel temperature |
| `Transferred_Qty` | `%MW9` | 1034 | Quantity transferred during active batch |

## Simulation and Command Registers

| PLC Variable | PLC Address | mbpoll Reference | Purpose |
|---|---|---:|---|
| `Truck_Connected_Sim` | `%MW10` | 1035 | Simulated truck connection |
| `Truck_Grounded_Sim` | `%MW11` | 1036 | Simulated grounding condition |
| `Fuel_Quality_Released_Sim` | `%MW12` | 1037 | Simulated fuel quality release |
| `E_Stop_Clear_Sim` | `%MW13` | 1038 | Emergency-stop clear condition |
| `Truck_Full_Sim` | `%MW14` | 1039 | Simulated truck-full condition |
| `Start_Transfer_Sim` | `%MW15` | 1040 | START command |
| `Stop_Transfer_Sim` | `%MW16` | 1041 | STOP command |

## Common Modbus Operations

Read holding register:

```bash
mbpoll -m tcp -a 1 -r 1026 -c 1 -t 4:int16 192.168.56.101
```

Write holding register:

```bash
mbpoll -m tcp -a 1 -r 1029 -t 4:int16 192.168.56.101 100
```

The main function codes observed during testing were:

- `FC3` - Read Holding Registers
- `FC6` - Write Single Register

## Security Relevance

Several security scenarios relied on direct writes to these registers.

Examples:

- `Requested_Qty` -> unauthorized setpoint manipulation
- `Start_Transfer_Sim` -> unauthorized process start
- `Truck_Full_Sim` -> runtime interlock manipulation
- `Tank_Quantity` -> process-data integrity manipulation

The memory map therefore provides the link between Modbus network traffic and actual PLC/process behavior.