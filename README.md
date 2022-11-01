# RealTimeOdorNavigation
Mouse Olfaction - Real Time Navigational Analysis - Tariq et al. (UW: Gire Lab; Neurobiology)

# Class Hierarchy

## (root) RealTimeOdorNavigation/

### ./RealTimeOdorNavigation
RealTimeOdorNavigation.m: BASE_CLASS
	- Trial[] (Trial)
	
### ./Trial
Trial.m -> (ETHAcc_File, Camera_File)
	- Name
	- SubjectID
	- Frame[] (Frame)
	- Arena (Arena)

## ./Hardware/

### Accelerometer

Accelerometer.m -> (Acc_Frame_Data)
	- X
	- Y
	- Z
	
### ETH_Sensor

ETH_Sensor.m -> (ETH_Frame_Data)
	- Voltage
	
### Camera
	
Camera.m -> (Camera_Frame_Data)
	- Nose (Coords)
	- LeftEar (Coords)
	- RightEar (Coords)
	- Neck (Coords)
	- Body (Coords)
	- Tailbase (Coords)
	- Port (Coords)

## ./Odor-Arena/

### Arena

Arena.m -> (Arena_Data)
	- TopLeft (Coords)
	- TopRight (Coords)
	- BottomLeft (Coords)
	- BottomRight (Coords)
	- Port (Coords)
	
### CameraFrame

CameraFrame.m -> (Index, ETH_Data, Acc_Data, Camera_Data)
	- Index
	- Ethanol Sensor[] (ETH_Sensor)
	- Accelerometer[] (Accelerometer)
	- Camera (Camera)

### Coords

Coords.m -> (X, Y, Likelihood)
	- X
	- Y
	- Optional Property: Likelihood

