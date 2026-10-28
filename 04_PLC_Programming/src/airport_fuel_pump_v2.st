PROGRAM program0
  VAR
    Tank_Level AT %MW0 : INT;	(*% - reserved for future process simulation *)
    Tank_Quantity AT %MW1 : INT;	(*liters*)
    Truck_Current_Qty AT %MW2 : INT;	(*liters*)
    Truck_Max_Capacity AT %MW3 : INT;	(*liters*)
    Requested_Qty AT %MW4 : INT;	(*liters*)
    Remaining_Capacity AT %MW5 : INT;  (*liters*)
    Line_Pressure AT %MW6 : INT;	(*bar*)
    Flow_Rate AT %MW7 : INT;	(*L/min*)
    Fuel_Temperature AT %MW8 : INT;	(*deg C - reserved for future process simulation*)
    Transferred_Qty AT %MW9 : INT;  (*liters*)
    Truck_Connected_Sim AT %MW10 : INT;          (* 0 = FALSE, 1 = TRUE *)
    Truck_Grounded_Sim AT %MW11 : INT;           (* 0 = FALSE, 1 = TRUE *)
    Fuel_Quality_Released_Sim AT %MW12 : INT;    (* 0 = FALSE, 1 = TRUE *)
    E_Stop_Clear_Sim AT %MW13 : INT;             (* 0 = FALSE, 1 = TRUE *)
    Truck_Full_Sim AT %MW14 : INT;               (* 0 = FALSE, 1 = TRUE *)
    Start_Transfer_Sim AT %MW15 : INT;   (* 0 = FALSE, 1 = TRUE *)
    Stop_Transfer_Sim AT %MW16 : INT;    (* 0 = FALSE, 1 = TRUE *)
  END_VAR

  VAR
    Start_Transfer AT %IX0.0 : BOOL;
    Stop_Transfer AT %IX0.1 : BOOL;
    Truck_Connected AT %IX0.2 : BOOL;
    Truck_Grounded AT %IX0.3 : BOOL;
    Fuel_Quality_Released AT %IX0.4 : BOOL;
    E_Stop_Clear AT %IX0.5 : BOOL;
    Truck_Full AT %IX0.6 : BOOL;
    

  END_VAR

  VAR
    Transfer_Pump AT %QX0.0 : BOOL;
    Outlet_Valve AT %QX0.1 : BOOL;
    Alarm AT %QX0.2 : BOOL;
  END_VAR
 
  VAR
    Diag_Invalid_Request AT %QX0.3 : BOOL;
    Diag_Transfer_Permitted AT %QX0.4 : BOOL;
    Diag_Transfer_Active AT %QX0.5 : BOOL;
    Diag_Insufficient_Tank_Quantity AT %QX0.6 : BOOL;
    Diag_Batch_Complete AT %QX0.7 : BOOL;
  END_VAR
  
  VAR
    High_Pressure : BOOL := FALSE;
    Low_Pressure : BOOL := FALSE;
    LowPressure_Timer : TON;
    Transfer_Scan_Count : INT := 0;
    Invalid_Request : BOOL := FALSE;
    Transfer_Permitted  : BOOL := FALSE;
    Insufficient_Tank_Quantity : BOOL := FALSE;
    Batch_Target_Qty : INT := 0;
    Remaining_To_Transfer : INT :=0;
    Transfer_Active : BOOL := FALSE;
    Start_Transfer_Previous : BOOL := FALSE;
    Start_Pulse : BOOL := FALSE;
    Batch_Complete : BOOL := FALSE;
    Tank_Empty : BOOL := FALSE;
    
    
    
  END_VAR
  
  (*=====================================*)
  (*  1. INPUT / SIMULATION MAPPING      *)
  (*=====================================*)
  
  
  Truck_Connected := Truck_Connected_Sim = 1;
  Truck_Grounded := Truck_Grounded_Sim = 1;
  Fuel_Quality_Released := Fuel_Quality_Released_Sim = 1;
  E_Stop_Clear := E_Stop_Clear_Sim = 1;
  Truck_Full := Truck_Full_Sim = 1;
  
  Start_Transfer := Start_Transfer_Sim = 1;
  Stop_Transfer := Stop_Transfer_Sim = 1; 
   
   
   
  

  
  (*=====================================*)
  (*   2. BASIC CALCULATIONS             *)
  (*=====================================*)
  
  Remaining_Capacity := Truck_Max_Capacity - Truck_Current_Qty;
  
  IF Transfer_Active THEN
    Remaining_To_Transfer := Batch_Target_Qty - Transferred_Qty;
  ELSE
    Remaining_To_Transfer := Requested_Qty;
  END_IF;

  
  (*=====================================*)
  (*   3. REQUEST / PROCESS CONDITIONS   *)
  (*=====================================*)

  IF Transfer_Active THEN
  
    Invalid_Request := Remaining_To_Transfer > Remaining_Capacity;
  
  ELSE
  
    Invalid_Request := 
    (Requested_Qty <= 0)
    OR
    (Remaining_To_Transfer > Remaining_Capacity);
  
  END_IF;
  
  
  High_Pressure := Line_Pressure > 8;
  
  Tank_Empty := Tank_Quantity <= 0;
    
  Insufficient_Tank_Quantity := Remaining_To_Transfer > Tank_Quantity;

   (*=====================================*)
   (*  4. TRANSFER PERMISSIVE             *)
   (*=====================================*)


  Transfer_Permitted :=
    Truck_Connected
    AND Truck_Grounded
    AND Fuel_Quality_Released
    AND E_Stop_Clear
    AND NOT Truck_Full
    AND NOT Invalid_Request
    AND NOT High_Pressure
    AND NOT Insufficient_Tank_Quantity;
    
    
  (*=====================================*)
  
  (*   5. RUNNING CONDITION MONITORING   *)
  (*=====================================*)

  LowPressure_Timer(
   	IN:= Transfer_Active,
   	PT := T#6s
   );
   
   Low_Pressure := FALSE;
   
   IF LowPressure_Timer.Q AND Line_Pressure <1 THEN
     Low_Pressure := TRUE;
   END_IF;
   
   
  (*=====================================*)
  (*       6. ALARM SUMMARY              *)
  (*=====================================*)
   
   Alarm :=
     Invalid_Request
     OR Insufficient_Tank_Quantity
     OR High_Pressure
     OR Low_Pressure
     OR Truck_Full
     OR Tank_Empty
     OR NOT E_Stop_Clear;
   
  (*=====================================*)
  (*      7. COMMAND / STATE LOGIC       *)
  (*=====================================*)
   
   Start_Pulse := Start_Transfer AND NOT Start_Transfer_Previous;
   Start_Transfer_Previous := Start_Transfer;
    
   IF Start_Pulse AND Transfer_Permitted THEN
        Batch_Target_Qty := Requested_Qty;
        Transferred_Qty := 0;
   	Transfer_Active := TRUE;
   	Batch_Complete := FALSE;
   END_IF;
   
   IF (NOT Transfer_Permitted)
    OR Stop_Transfer 
    OR Low_Pressure
    OR Tank_Empty THEN
    
   	Transfer_Active := FALSE;
   
   END_IF;
   
   
   
   IF Transfer_Active THEN
     Transfer_Scan_Count := Transfer_Scan_Count +1;
   ELSE
    Transfer_Scan_Count := 0;
   END_IF;
   
   IF Transfer_Scan_Count >= 10 THEN
   
     IF Remaining_to_Transfer >=2 THEN
       Transferred_Qty := Transferred_Qty +2;
       Truck_Current_Qty := Truck_Current_Qty + 2;
       Tank_Quantity := Tank_Quantity - 2;
     ELSE
       Transferred_Qty := Transferred_Qty + Remaining_To_Transfer;
       Truck_Current_Qty := Truck_Current_Qty + Remaining_To_Transfer;
       Tank_Quantity := Tank_Quantity - Remaining_To_Transfer;
     END_IF;
     
     Transfer_Scan_Count := 0;
   END_IF;
   
   IF Transfer_Active AND Transferred_Qty >= Batch_Target_Qty THEN
     Transfer_Active := FALSE;
     Batch_Complete := TRUE;
     Requested_Qty := 0;
   END_IF;
   
   
   (*=====================================*)
   (*  8. PROCESS SIMULATION / OUTPUTS    *)
   (*=====================================*)
   
   
   Transfer_Pump := Transfer_Active;
   Outlet_Valve := Transfer_Active;
   
   IF Transfer_Pump AND Outlet_Valve THEN
     Line_Pressure := 5;
   ELSE
     Line_Pressure := 0;
   END_IF;
   
   IF Transfer_Pump AND Outlet_Valve THEN
     Flow_Rate := 120;
   ELSE
     Flow_Rate := 0;
   END_IF;
   
   (*=====================================*)
   (*   9. DIAGNOSTICS                    *)
   (*=====================================*)
   
   Diag_Invalid_Request := Invalid_Request;
   Diag_Transfer_Permitted := Transfer_Permitted;
   Diag_Transfer_Active := Transfer_Active;
   Diag_Insufficient_Tank_Quantity := Insufficient_Tank_Quantity;
   Diag_Batch_Complete := Batch_Complete;
  
END_PROGRAM

CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#100ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : program0;
  END_RESOURCE

END_CONFIGURATION

