unit uCoolerBoost;

interface

uses
  EmbeddedController;

type
  TModeType = (modeAuto, modeBasic, modeAdvanced);

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

  //0 - Address; 1 - ON; 2 - OFF
  //EC_WEBCAM: array[0..2] of Integer = ($2E, $4B, $49);
  //EC_CB: array[0..2] of Integer = ($98, $80, $00);
  //0 - Address; 1 - Speed Address; 2 - Auto; 3 - Basic; 4 - Advanced;
  //EC_FANS: array[0..4] of Integer = (EC_FANS_ADRRESS, EC_FANS_SPEED_ADRRESS, AUTO_MODE, BASIC_MODE, ADVANCED_MODE);

var
  EC: TEmbeddedController;

function GetBasicValue: Integer;
function GetMode: TModeType;
function isECLoaded: Boolean;
function isCoolerBoostEnabled: Boolean;
function isWebcamEnabled: Boolean;
procedure SetBasicMode(Value: Integer);
procedure SetMode(mode: TModeType);
procedure SetCoolerBoostEnabled(bool: Boolean);
procedure SetWebcamEnabled(bool: Boolean);
procedure ToggleCoolerBoost;
procedure ToggleWebcam;

implementation

function GetBasicValue: Integer;
var
  bResult: Byte;
begin
  while not EC.readByte(EC_FANS_SPEED_ADRRESS, bResult) or (bResult = 255) do;
  if bResult >= 128 then Result := 128 - bResult else Result := bResult;
end;


function GetMode: TModeType;
var
  bResult: Byte;
begin
  while not EC.readByte(EC_FANS_SPEED_ADRRESS, bResult) or (bResult = 255) do;

  case bResult of
    EC_FANS_MODE_AUTO: Result := modeAuto;
    EC_FANS_MODE_BASIC: Result := modeBasic;
    EC_FANS_MODE_ADVANCED: Result := modeAdvanced;
  end;
end;


function isECLoaded: Boolean;
begin
  Result := EC.driverFileExist and EC.driverLoaded;
end;


function isCoolerBoostEnabled: Boolean;
var
  bResult: Byte;
begin
  while not EC.readByte(EC_CB_ADDRESS, bResult) or (bResult = 255) do;
  Result := (bResult >= EC_CB_ON);
end;


function isWebcamEnabled: Boolean;
var
  bResult: Byte;
begin
  while not EC.readByte(EC_WEBCAM_ADDRESS, bResult) do;
  Result := (bResult = EC_WEBCAM_ON);
end;


procedure SetBasicMode(Value: Integer);
begin
  if (Value < -15) or (Value > 15) then Exit;
  if (Value <= 0) then Value := 128 + Abs(Value);
  SetMode(modeBasic);
  while EC.readByte(EC_FANS_SPEED_ADRRESS) <> Value do EC.writeByte(EC_FANS_SPEED_ADRRESS, Value);
end;


procedure SetMode(mode: TModeType);
begin
  case mode of
    modeAuto: while EC.readByte(EC_FANS_ADRRESS) <> EC_FANS_MODE_AUTO do EC.writeByte(EC_FANS_ADRRESS, EC_FANS_MODE_AUTO);
    modeBasic: while EC.readByte(EC_FANS_ADRRESS) <> EC_FANS_MODE_BASIC do EC.writeByte(EC_FANS_ADRRESS, EC_FANS_MODE_BASIC);
    modeAdvanced: while EC.readByte(EC_FANS_ADRRESS) <> EC_FANS_MODE_ADVANCED do EC.writeByte(EC_FANS_ADRRESS, EC_FANS_MODE_ADVANCED);
  end;
end;


procedure SetCoolerBoostEnabled(bool: Boolean);
var
  bResult: Byte;
begin
  if bool then begin
    while (EC.readByte(EC_CB_ADDRESS) <> EC_CB_ON) do EC.writeByte(EC_CB_ADDRESS, EC_CB_ON)
  end else begin
    while (EC.readByte(EC_CB_ADDRESS) <> EC_CB_OFF) do EC.writeByte(EC_CB_ADDRESS, EC_CB_OFF);
  end;
end;


procedure SetWebcamEnabled(bool: Boolean);
begin
  if bool then begin
    while (EC.readByte(EC_WEBCAM_ADDRESS) <> EC_WEBCAM_ON) do EC.writeByte(EC_WEBCAM_ADDRESS, EC_WEBCAM_ON);
  end else begin
    while (EC.readByte(EC_WEBCAM_ADDRESS) <> EC_WEBCAM_OFF) do EC.writeByte(EC_WEBCAM_ADDRESS, EC_WEBCAM_OFF);
  end;
end;


procedure ToggleCoolerBoost;
begin
  SetCoolerBoostEnabled(not isCoolerBoostEnabled);
end;


procedure ToggleWebcam;
begin
  SetWebcamEnabled(not isWebcamEnabled);
end;


initialization
  EC := TEmbeddedController.Create;
  EC.retry := 5;
end.
