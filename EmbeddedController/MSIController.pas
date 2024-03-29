unit MSIController;

interface

uses
  Windows, EmbeddedController;

const
  EC_LOADED_RETRY = 20;
  EC_WEBCAM_ADDRESS = $2E;
  EC_WEBCAM_ON = $4B;
  EC_WEBCAM_OFF = $49;
  EC_CB_ADDRESS = $98;
  EC_CB_ON = $80;
  EC_CB_OFF = $00;
  EC_FANS_ADRRESS = $F4;
  EC_FANS_SPEED_ADRRESS = $F5;
  EC_FANS_MODE_AUTO = $0C;
  EC_FANS_MODE_BASIC = $4C;
  EC_FANS_MODE_ADVANCED = $8C;
  EC_GPU_TEMP_ADRRESS = $80;
  EC_CPU_TEMP_ADRRESS = $68;

type
  TModeType = (modeAuto, modeBasic, modeAdvanced);

type
  TMSIController = class
    protected
       EC: TEmbeddedController;
       hasEC: Boolean;
    public
      constructor Create;
      destructor Destroy; override;

      function GetGPUTemp: Byte;
      function GetCPUTemp: Byte;
      function GetBasicValue: Integer;
      function GetFanMode: TModeType;
      function isECLoaded(bEC: Boolean): Boolean;
      function isCoolerBoostEnabled: Boolean;
      function isWebcamEnabled: Boolean;
      procedure SetBasicMode(Value: Integer);
      procedure SetFanMode(mode: TModeType);
      procedure SetCoolerBoostEnabled(bool: Boolean);
      procedure SetWebcamEnabled(bool: Boolean);
      procedure ToggleCoolerBoost;
      procedure ToggleWebcam;
    end;

implementation

constructor TMSIController.Create;
var
  i, j, k: Integer;
  bDummy: Byte;
begin
  inherited Create;
  EC := TEmbeddedController.Create;
  EC.retry := 5;
  hasEC := False;
  j := 0; k := 0;

  for i := 1 to EC_LOADED_RETRY do begin
    hasEC := EC.readByte(0, bDummy);
    if hasEC then Break else Sleep(1);
  end;

  if (not hasEC) then Exit;

  for i := 1 to EC_LOADED_RETRY do begin
    if (self.GetCPUTemp > 0) then Inc(j) else Inc(k);
    Sleep(1);
  end;

  hasEC := (j > k);
end;


destructor TMSIController.Destroy;
begin
  EC.Destroy;
  inherited Destroy;
end;


function TMSIController.GetGPUTemp: Byte;
begin
  Result := 255;
  if (not self.isECLoaded(True)) then begin Result := 0; Exit; end;
  while (not EC.readByte(EC_GPU_TEMP_ADRRESS, Result)) or (Result = 255) do;
end;


function TMSIController.GetCPUTemp: Byte;
begin
  Result := 255;
  if (not self.isECLoaded(True)) then begin Result := 0; Exit; end;
  while (not EC.readByte(EC_CPU_TEMP_ADRRESS, Result)) or (Result = 255) do;
end;


function TMSIController.GetBasicValue: Integer;
var
  bResult: Byte;
begin
  Result := 128;
  if (not self.isECLoaded(True)) then Exit;
  while (not EC.readByte(EC_FANS_SPEED_ADRRESS, bResult)) or (bResult = 255) do;
  if bResult >= 128 then Result := 128 - bResult else Result := bResult;
end;


function TMSIController.GetFanMode: TModeType;
var
  bResult: Byte;
begin
  Result := modeAuto;
  if (not self.isECLoaded(True)) then Exit;
  while (not EC.readByte(EC_FANS_ADRRESS, bResult)) or (bResult = 255) do;

  case bResult of
    EC_FANS_MODE_AUTO: Result := modeAuto;
    EC_FANS_MODE_BASIC: Result := modeBasic;
    EC_FANS_MODE_ADVANCED: Result := modeAdvanced;
  end;
end;


function TMSIController.isECLoaded(bEC: Boolean): Boolean;
begin
  Result := ((not bEC) or hasEC) and EC.driverFileExist and EC.driverLoaded;
end;


function TMSIController.isCoolerBoostEnabled: Boolean;
var
  bResult: Byte;
begin
  if (not self.isECLoaded(True)) then begin Result := False; Exit; end;
  while (not EC.readByte(EC_CB_ADDRESS, bResult)) or (bResult = 255) do;
  Result := (bResult >= EC_CB_ON);
end;


function TMSIController.isWebcamEnabled: Boolean;
var
  bResult: Byte;
begin
  if (not self.isECLoaded(True)) then begin Result := False; Exit; end;
  while not EC.readByte(EC_WEBCAM_ADDRESS, bResult) do;
  Result := (bResult = EC_WEBCAM_ON);
end;


procedure TMSIController.SetBasicMode(Value: Integer);
begin
  if (not self.isECLoaded(True)) then Exit;
  if (Value < -15) or (Value > 15) then Exit;
  if (Value <= 0) then Value := 128 + Abs(Value);
  SetFanMode(modeBasic);
  while EC.readByte(EC_FANS_SPEED_ADRRESS) <> Value do EC.writeByte(EC_FANS_SPEED_ADRRESS, Value);
end;


procedure TMSIController.SetFanMode(mode: TModeType);
begin
  if (not self.isECLoaded(True)) then Exit;

  case mode of
    modeAuto: while EC.readByte(EC_FANS_ADRRESS) <> EC_FANS_MODE_AUTO do EC.writeByte(EC_FANS_ADRRESS, EC_FANS_MODE_AUTO);
    modeBasic: while EC.readByte(EC_FANS_ADRRESS) <> EC_FANS_MODE_BASIC do EC.writeByte(EC_FANS_ADRRESS, EC_FANS_MODE_BASIC);
    modeAdvanced: while EC.readByte(EC_FANS_ADRRESS) <> EC_FANS_MODE_ADVANCED do EC.writeByte(EC_FANS_ADRRESS, EC_FANS_MODE_ADVANCED);
  end;
end;


procedure TMSIController.SetCoolerBoostEnabled(bool: Boolean);
begin
  if (not self.isECLoaded(True)) then Exit;

  if bool then begin
    while (EC.readByte(EC_CB_ADDRESS) <> EC_CB_ON) do EC.writeByte(EC_CB_ADDRESS, EC_CB_ON)
  end else begin
    while (EC.readByte(EC_CB_ADDRESS) <> EC_CB_OFF) do EC.writeByte(EC_CB_ADDRESS, EC_CB_OFF);
  end;
end;


procedure TMSIController.SetWebcamEnabled(bool: Boolean);
begin
  if (not self.isECLoaded(True)) then Exit;

  if bool then begin
    while (EC.readByte(EC_WEBCAM_ADDRESS) <> EC_WEBCAM_ON) do EC.writeByte(EC_WEBCAM_ADDRESS, EC_WEBCAM_ON);
  end else begin
    while (EC.readByte(EC_WEBCAM_ADDRESS) <> EC_WEBCAM_OFF) do EC.writeByte(EC_WEBCAM_ADDRESS, EC_WEBCAM_OFF);
  end;
end;


procedure TMSIController.ToggleCoolerBoost;
begin
  SetCoolerBoostEnabled(not isCoolerBoostEnabled);
end;


procedure TMSIController.ToggleWebcam;
begin
  SetWebcamEnabled(not isWebcamEnabled);
end;

end.
