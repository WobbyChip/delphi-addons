unit DDCCI;

interface

uses
  Windows, SysUtils, Classes, Registry, MultiMon, uDynamicData, Functions;

type
  MC_VCP_CODE_TYPE = (MC_MOMENTARY, MC_SET_PARAMETER);
  PMC_VCP_CODE_TYPE = ^MC_VCP_CODE_TYPE;

type
  PHYSICAL_MONITOR = packed record
    hPhysicalMonitor: HMONITOR;
    szPhysicalMonitorDescription: array[0..127] of WideChar;
  end;
  TPhysicalMonitor =  array of PHYSICAL_MONITOR;
  PPhysicalMonitor = ^TPhysicalMonitor;

type
  TMonitorInfoEx = record
    cbSize: DWORD;
    rcMonitor: TRect;
    rcWork: TRect;
    dwFlags: DWORD;
    szDevice: array[0..CCHDEVICENAME-1] of AnsiChar;
  end;

type
  TDisplayDeviceW = packed record
    cb: DWORD;
    DeviceName: array[0..31] of WideChar;
    DeviceString: array[0..127] of WideChar;
    StateFlags: DWORD;
    DeviceID: array[0..127] of WideChar;
    DeviceKey: array[0..127] of WideChar;
  end;

const
  DDCCI_POWER_ADRRESS = $D6;
  DDCCI_POWER_OFF = $05;
  DDCCI_POWER_ON = $01;

type
  TDDCCI = class
    public
      constructor Create(doUpdate: Boolean);
      destructor Destroy; override;
      function Update: TDDCCI;

      function GetMonitorCount: Integer;
      function GetIndexByDeviceID(DeviceID: String): Integer;
      function GetFriendlyName(Index: Integer): String;
      function GetDeviceName(Index: Integer): String;
      function GetDeviceString(Index: Integer): String;
      function GetDeviceID(Index: Integer): String;
      function GetDeviceKey(Index: Integer): String;
      function GetPhysicalMonitorHandle(Index: Integer): HMONITOR;

      function isSupported(DeviceID: String): Boolean;
      function PowerOn(DeviceID: String): Boolean;
      function PowerOff(DeviceID: String): Boolean;
      function PowerToggle(DeviceID: String): Boolean;
      function GetBrightness(DeviceID: String): Integer;
      function SetBrightness(DeviceID: String; Value: Integer): Boolean;
    private
      DynamicData: TDynamicData;
    end;

implementation

function GetPhysicalMonitorsFromHMONITOR(hMonitor: HMONITOR; pdwNumberOfPhysicalMonitors: DWORD; pPhysicalMonitorArray: PPhysicalMonitor): BOOL; stdcall; external 'dxva2.dll';
function GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor: HMONITOR; var pdwNumberOfPhysicalMonitors: DWORD): BOOL; stdcall; external 'dxva2.dll';
function GetVCPFeatureAndVCPFeatureReply(hMonitor: HMONITOR; bVCPCode: Byte; pvct: PMC_VCP_CODE_TYPE; var pdwCurrentValue, pdwMaximumValue: DWORD): BOOL; stdcall; external 'dxva2.dll';
function SetVCPFeature(hMonitor: HMONITOR; bVCPCode: Byte; dwNewValue: DWORD): BOOL; stdcall; external 'dxva2.dll';
function GetMonitorBrightness(hMonitor: HMONITOR; var pdwMinimumBrightness, pdwCurrentValue, pdwMaximumValue: DWORD): BOOL; stdcall; external 'dxva2.dll';
function SetMonitorBrightness(hMonitor: HMONITOR; dwNewBrightness: DWORD): BOOL; stdcall; external 'dxva2.dll';
function DestroyPhysicalMonitor(hMonitor: HMONITOR): BOOL; stdcall; external 'dxva2.dll';
function EnumDisplayDevicesW(lpDevice: PWideChar; iDevNum: DWORD; var lpDisplayDevice: TDisplayDeviceW; dwFlags: DWORD): BOOL; stdcall; external user32;


function GetMonitorFriendlyName(DeviceID: String): String;
const
  Key = '\SYSTEM\CurrentControlSet\Enum\DISPLAY\';
var
  i, j, k: Integer;
  Registry: TRegistry;
  Driver: String;
  MonitorName: String;
  EDID: array [0 .. 127] of Byte;
  subKeysNames: TStringList;
begin
  Result := Copy(DeviceID, 9, Length(DeviceID));
  Driver := Copy(Result, Pos('\', Result)+1, Length(Result));
  Result := Copy(Result, 0, Pos('\', Result)-1);

  Registry := TRegistry.Create;
  Registry.RootKey := HKEY_LOCAL_MACHINE;
  subKeysNames := TStringList.Create;

  if not Registry.OpenKeyReadOnly(Key + '\' + Result) then begin
    Registry.Destroy;
    Exit;
  end;

  Registry.GetKeyNames(subKeysNames);

  for i := 0 to subKeysNames.Count-1 do begin
    if not Registry.OpenKeyReadOnly(Key + '\' + Result + '\' + subKeysNames[i]) then Continue;
    if Registry.ReadString('Driver') <> Driver then Continue;
    if not Registry.OpenKeyReadOnly(Key + '\' + Result + '\' + subKeysNames[i] + '\' + 'Device Parameters') then Continue;
    Registry.ReadBinaryData('EDID', EDID, 128);

    for j := 0 to 3 do begin
      if (EDID[72*j] <> 0) or (EDID[73*j] <> 0) or (EDID[74*j] <> 0) or (EDID[75*j] <> $FC) or (EDID[76*j] <> 0) then Continue;
      k := 0;
      while (EDID[77*j+k] <> $A) and (k < 13) do Inc(k);
      SetString(MonitorName, PAnsiChar(@EDID[77*j]), k);
      Result := MonitorName;
      Break;
    end;
  end;
end;


function EnumMonitorsProc(MonitorHandle: HMONITOR; hDC: HDC; Rect: PRect; Data: Pointer): Boolean; stdcall;
var
  i, j: Integer;
  md: TDisplayDeviceW;
  MonitorInfo: TMonitorInfoEx;
  monitorIndex: Integer;
  szDevice, FriendlyName: String;
  pMonitorsCount: DWORD;
  pMonitors: PPhysicalMonitor;
  hPhysicalMonitor: HMONITOR;
begin
  md.cb := SizeOf(md);
  MonitorInfo.cbSize := SizeOf(MonitorInfo);
  GetMonitorInfo(MonitorHandle, @MonitorInfo);
  szDevice := MonitorInfo.szDevice;
  monitorIndex := 0;

  while EnumDisplayDevicesW(PWideChar(WideString(szDevice)), monitorIndex, md, 0) do begin
    FriendlyName := GetMonitorFriendlyName(md.DeviceID);
    TDynamicData(Data).CreateData(-1, -1, ['FriendlyName', 'DeviceName', 'DeviceString', 'DeviceID', 'DeviceKey', 'hPhysicalMonitor'], [FriendlyName, String(md.DeviceName), String(md.DeviceString), String(md.DeviceID), String(md.DeviceKey), -1]);
    Inc(monitorIndex);
  end;

  GetNumberOfPhysicalMonitorsFromHMONITOR(MonitorHandle, pMonitorsCount);
  pMonitors := AllocMem(pMonitorsCount * SizeOf(PHYSICAL_MONITOR));
  GetPhysicalMonitorsFromHMONITOR(MonitorHandle, pMonitorsCount, pMonitors);

  for i := 0 to pMonitorsCount-1 do begin
    hPhysicalMonitor := TPhysicalMonitor(pMonitors)[i].hPhysicalMonitor;
    j := TDynamicData(Data).FindIndex(0, 'hPhysicalMonitor', -1);
    TDynamicData(Data).SetValue(j, 'hPhysicalMonitor', hPhysicalMonitor);
  end;

  FreeMem(pMonitors);
  Result := True;
end;


constructor TDDCCI.Create(doUpdate: Boolean);
begin
  inherited Create;
  DynamicData := TDynamicData.Create(['FriendlyName', 'DeviceName', 'DeviceString', 'DeviceID', 'DeviceKey', 'hPhysicalMonitor']);
  if doUpdate then self.Update;
end;


destructor TDDCCI.Destroy;
var
  i: Integer;
  hPhysicalMonitor: HMONITOR;
begin
  for i := 0 to DynamicData.GetLength-1 do begin
    hPhysicalMonitor := DynamicData.GetValue(0, 'hPhysicalMonitor');
    DestroyPhysicalMonitor(hPhysicalMonitor);
  end;

  DynamicData.Destroy;
  inherited Destroy;
end;


function TDDCCI.Update: TDDCCI;
var
  i: Integer;
  hPhysicalMonitor: HMONITOR;
begin
  for i := 0 to DynamicData.GetLength-1 do begin
    hPhysicalMonitor := DynamicData.GetValue(0, 'hPhysicalMonitor');
    DestroyPhysicalMonitor(hPhysicalMonitor);
  end;

  DynamicData.SetLength(0);
  EnumDisplayMonitors(0, nil, @EnumMonitorsProc, LongInt(DynamicData));
  Result := self;
end;


function TDDCCI.GetMonitorCount: Integer;
begin
  Result := DynamicData.GetLength;
end;


function TDDCCI.GetIndexByDeviceID(DeviceID: String): Integer;
begin
  Result := DynamicData.FindIndex(0, 'DeviceID', DeviceID);
end;


function TDDCCI.GetFriendlyName(Index: Integer): String;
begin
  Result := '';
  if (Index >= DynamicData.GetLength) or (Index < 0) then Exit;
  Result := DynamicData.GetValue(Index, 'FriendlyName');
end;


function TDDCCI.GetDeviceName(Index: Integer): String;
begin
  Result := '';
  if (Index >= DynamicData.GetLength) or (Index < 0) then Exit;
  Result := DynamicData.GetValue(Index, 'DeviceName');
end;


function TDDCCI.GetDeviceString(Index: Integer): String;
begin
  Result := '';
  if (Index >= DynamicData.GetLength) or (Index < 0) then Exit;
  Result := DynamicData.GetValue(Index, 'DeviceString');
end;


function TDDCCI.GetDeviceID(Index: Integer): String;
begin
  Result := '';
  if (Index >= DynamicData.GetLength) or (Index < 0) then Exit;
  Result := DynamicData.GetValue(Index, 'DeviceID');
end;


function TDDCCI.GetDeviceKey(Index: Integer): String;
begin
  Result := '';
  if (Index >= DynamicData.GetLength) or (Index < 0) then Exit;
  Result := DynamicData.GetValue(Index, 'DeviceKey');
end;


function TDDCCI.GetPhysicalMonitorHandle(Index: Integer): HMONITOR;
begin
  Result := -1;
  if (Index >= DynamicData.GetLength) or (Index < 0) then Exit;
  Result := DynamicData.GetValue(Index, 'hPhysicalMonitor');
end;


function TDDCCI.isSupported(DeviceID: String): Boolean;
var
  i: Variant;
  j, k: DWORD;
begin
  Result := False;
  i := DynamicData.FindValue(0, 'DeviceID', DeviceID, 'hPhysicalMonitor');
  if (i = DynamicData.Null) then Exit;

  Result := GetVCPFeatureAndVCPFeatureReply(i, DDCCI_POWER_ADRRESS, nil, j, k);
end;


function TDDCCI.PowerOn(DeviceID: String): Boolean;
var
  i: Variant;
begin
  Result := False;
  i := DynamicData.FindValue(0, 'DeviceID', DeviceID, 'hPhysicalMonitor');
  if (i = DynamicData.Null) then Exit;

  Result := SetVCPFeature(i, DDCCI_POWER_ADRRESS, DDCCI_POWER_ON);
end;


function TDDCCI.PowerOff(DeviceID: String): Boolean;
var
  i: Variant;
begin
  Result := False;
  i := DynamicData.FindValue(0, 'DeviceID', DeviceID, 'hPhysicalMonitor');
  if (i = DynamicData.Null) then Exit;

  Result := SetVCPFeature(i, DDCCI_POWER_ADRRESS, DDCCI_POWER_OFF);
end;


function TDDCCI.PowerToggle(DeviceID: String): Boolean;
var
  i: Variant;
  CurrentValue, MaximumValue: DWORD;
begin
  Result := False;
  i := DynamicData.FindValue(0, 'DeviceID', DeviceID, 'hPhysicalMonitor');
  if (i = DynamicData.Null) then Exit;

  GetVCPFeatureAndVCPFeatureReply(i, DDCCI_POWER_ADRRESS, nil, CurrentValue, MaximumValue);
  Result := SetVCPFeature(i, DDCCI_POWER_ADRRESS, Q((CurrentValue <> DDCCI_POWER_ON), DDCCI_POWER_ON, DDCCI_POWER_OFF));
end;


function TDDCCI.GetBrightness(DeviceID: String): Integer;
var
  i: Variant;
  MinimumValue, MaximumValue: DWORD;
  CurrentValue: DWORD;
begin
  Result := -1;
  i := DynamicData.FindValue(0, 'DeviceID', DeviceID, 'hPhysicalMonitor');
  if (i = DynamicData.Null) then Exit;

  if not GetMonitorBrightness(i, MinimumValue, CurrentValue, MaximumValue) then Exit;
  Result := CurrentValue;
end;


function TDDCCI.SetBrightness(DeviceID: String; Value: Integer): Boolean;
var
  i: Variant;
begin
  Result := False;
  i := DynamicData.FindValue(0, 'DeviceID', DeviceID, 'hPhysicalMonitor');
  if (i = DynamicData.Null) then Exit;

  if (Value < 0) then Value := 0;
  if (Value > 100) then Value := 100;
  Result := SetMonitorBrightness(i, Value);
end;

end.
