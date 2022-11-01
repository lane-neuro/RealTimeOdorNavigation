# RealTimeOdorNavigation
Mouse Olfaction - Real Time Navigational Analysis - Tariq et al. (UW: Gire Lab; Neurobiology)

# Class Hierarchy

## (root) RealTimeOdorNavigation/

### RealTimeOdorNavigation.m
RealTimeOdorNavigation.m: BASE_CLASS
	- Trial[] (Trial)
	
### Trial.m
Trial.m -> (ETHAcc_File, Camera_File)
	- Name
	- SubjectID
	- Frame[] (Frame)
	- Arena (Arena)

## ./Hardware/

### Accelerometer.m

Accelerometer.m -> (Acc_Frame_Data)
	- X
	- Y
	- Z
	
### ETH_Sensor.m

ETH_Sensor.m -> (ETH_Frame_Data)
	- Voltage
	
### Camera.m
	
Camera.m -> (Camera_Frame_Data)
	- Nose (Coords)
	- LeftEar (Coords)
	- RightEar (Coords)
	- Neck (Coords)
	- Body (Coords)
	- Tailbase (Coords)
	- Port (Coords)

## ./Odor-Arena/

### Arena.m

Arena.m -> (Arena_Data)
	- TopLeft (Coords)
	- TopRight (Coords)
	- BottomLeft (Coords)
	- BottomRight (Coords)
	- Port (Coords)
	
### CameraFrame.m

CameraFrame.m -> (Index, ETH_Data, Acc_Data, Camera_Data)
	- Index
	- Ethanol Sensor[] (ETH_Sensor)
	- Accelerometer[] (Accelerometer)
	- Camera (Camera)

### Coords.m

Coords.m -> (X, Y, Likelihood)
	- X
	- Y
	- Optional Property: Likelihood

