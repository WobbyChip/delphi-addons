unit MSIController;

interface

uses
  EmbeddedController;

const
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

type
  TModeType = (modeAuto, modeBasic, modeAdvanced);

type
  TMSIController = class
    protected
      EC: TEmbeddedController;
    public
      constructor Create;
      destructor Destroy; override;

      function GetBasicValue: Integer;
      function GetFanMode: TModeType;
      function isECLoaded: Boolean;
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
begin
  inherited Create;
  EC := TEmbeddedController.Create;
  EC.retry := 5;
end;


destructor TMSIController.Destroy;
begin
  EC.Destroy;
  inherited Destroy;
end;


function TMSIController.GetBasicValue: Integer;
var
  bResult: Byte;
begin
  while not EC.readByte(EC_FANS_SPEED_ADRRESS, bResult) or (bResult = 255) do;
  if bResult >= 128 then Result := 128 - bResult else Result := bResult;
end;


function TMSIController.GetFanMode: TModeType;
var
  bResult: Byte;
begin
  Result := modeAuto;
  while not EC.readByte(EC_FANS_ADRRESS, bResult) or (bResult = 255) do;

  case bResult of
    EC_FANS_MODE_AUTO: Result := modeAuto;
    EC_FANS_MODE_BASIC: Result := modeBasic;
    EC_FANS_MODE_ADVANCED: Result := modeAdvanced;
  end;
end;


function TMSIController.isECLoaded: Boolean;
begin
  Result := EC.driverFileExist and EC.driverLoaded;
end;


function TMSIController.isCoolerBoostEnabled: Boolean;
var
  bResult: Byte;
begin
  while not EC.readByte(EC_CB_ADDRESS, bResult) or (bResult = 255) do;
  Result := (bResult >= EC_CB_ON);
end;


function TMSIController.isWebcamEnabled: Boolean;
var
  bResult: Byte;
begin
  while not EC.readByte(EC_WEBCAM_ADDRESS, bResult) do;
  Result := (bResult = EC_WEBCAM_ON);
end;


procedure TMSIController.SetBasicMode(Value: Integer);
begin
  if (Value < -15) or (Value > 15) then Exit;
  if (Value <= 0) then Value := 128 + Abs(Value);
  SetFanMode(modeBasic);
  while EC.readByte(EC_FANS_SPEED_ADRRESS) <> Value do EC.writeByte(EC_FANS_SPEED_ADRRESS, Value);
end;


procedure TMSIController.SetFanMode(mode: TModeType);
begin
  case mode of
    modeAuto: while EC.readByte(EC_FANS_ADRRESS) <> EC_FANS_MODE_AUTO do EC.writeByte(EC_FANS_ADRRESS, EC_FANS_MODE_AUTO);
    modeBasic: while EC.readByte(EC_FANS_ADRRESS) <> EC_FANS_MODE_BASIC do EC.writeByte(EC_FANS_ADRRESS, EC_FANS_MODE_BASIC);
    modeAdvanced: while EC.readByte(EC_FANS_ADRRESS) <> EC_FANS_MODE_ADVANCED do EC.writeByte(EC_FANS_ADRRESS, EC_FANS_MODE_ADVANCED);
  end;
end;


procedure TMSIController.SetCoolerBoostEnabled(bool: Boolean);
begin
  if bool then begin
    while (EC.readByte(EC_CB_ADDRESS) <> EC_CB_ON) do EC.writeByte(EC_CB_ADDRESS, EC_CB_ON)
  end else begin
    while (EC.readByte(EC_CB_ADDRESS) <> EC_CB_OFF) do EC.writeByte(EC_CB_ADDRESS, EC_CB_OFF);
  end;
end;


procedure TMSIController.SetWebcamEnabled(bool: Boolean);
begin
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
