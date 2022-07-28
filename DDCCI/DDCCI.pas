unit DDCCI;

interface

uses
  Windows, Classes, Registry, MultiMon, uDynamicData, Functions;

type
  MC_VCP_CODE_TYPE = (MC_MOMENTARY, MC_SET_PARAMETER);
  PMC_VCP_CODE_TYPE = ^MC_VCP_CODE_TYPE;

type
  _PHYSICAL_MONITOR = packed record
    hPhysicalMonitor: HMONITOR;
    szPhysicalMonitorDescription: array[0..127] of WideChar;
  end;
  TPhysicalMonitor = _PHYSICAL_MONITOR;

type
  TDisplayDevice = packed record
    cb: DWORD;
    DeviceName: array[0..31] of AnsiChar;
    DeviceString: array[0..127] of AnsiChar;
    StateFlags: DWORD;
    DeviceID: array[0..127] of AnsiChar;
    DeviceKey: array[0..127] of AnsiChar;
  end;

const
  DDCCI_POWER_ADRRESS = $D6;
  DDCCI_POWER_OFF = $05;
  DDCCI_POWER_ON = $01;

type
  TDDCCI = class
    public
      DynamicData: TDynamicData;
      constructor Create(doUpdate: Boolean);
      destructor Destroy; override;
      procedure Update;

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
    private

    end;

implementation

function SetVCPFeature(hMonitor: HMONITOR; bVCPCode: Byte; dwNewValue: DWORD): BOOL; stdcall; external 'dxva2.dll';
function GetVCPFeatureAndVCPFeatureReply(hMonitor: HMONITOR; bVCPCode: Byte; pvct: PMC_VCP_CODE_TYPE; var pdwCurrentValue, pdwMaximumValue: DWORD): BOOL; stdcall; external 'dxva2.dll';
function GetPhysicalMonitorsFromHMONITOR(hMonitor: HMONITOR; pdwNumberOfPhysicalMonitors: DWORD; var pPhysicalMonitorArray: array of TPhysicalMonitor): BOOL; stdcall; external 'dxva2.dll';
function GetNumberOfPhysicalMonitorsFromHMONITOR(hMonitor: HMONITOR; var pdwNumberOfPhysicalMonitors: DWORD): BOOL; stdcall; external 'dxva2.dll';
function DestroyPhysicalMonitor(hMonitor: HMONITOR): BOOL; stdcall; external 'dxva2.dll';
function EnumDisplayDevicesA(Unused: Pointer; iDevNum: DWORD; var lpDisplayDevice: TDisplayDevice; dwFlags: DWORD): BOOL; stdcall; external user32;


function EnumMonitorsProc(hmon: HMONITOR; dc: HDC; Rect: PRect; Data: Pointer): Boolean; stdcall;
begin
  TList(Data).Add(Pointer(hmon));
  Result := True;
end;


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


constructor TDDCCI.Create(doUpdate: Boolean);
begin
  inherited Create;
  DynamicData := TDynamicData.Create(['FriendlyName', 'DeviceName', 'DeviceString', 'DeviceID', 'DeviceKey']);
  if doUpdate then self.Update;
end;


destructor TDDCCI.Destroy;
begin
  DynamicData.Destroy;
  inherited Destroy;
end;


procedure TDDCCI.Update;
var
  dd, md: TDisplayDevice;
  deviceIndex, monitorIndex: Integer;
  FriendlyName: String;
begin
  DynamicData.SetLength(0);
  dd.cb := SizeOf(dd);
  md.cb := SizeOf(md);
  deviceIndex := 0;

  while EnumDisplayDevicesA(nil, deviceIndex, dd, 0) do begin
    monitorIndex := 0;

    while EnumDisplayDevicesA(@dd.deviceName, monitorIndex, md, 0) do begin
      FriendlyName := GetMonitorFriendlyName(md.DeviceID);
      DynamicData.CreateData(-1, -1, ['FriendlyName', 'DeviceName', 'DeviceString', 'DeviceID', 'DeviceKey'], [FriendlyName, String(md.DeviceName), String(md.DeviceString), String(md.DeviceID), String(md.DeviceKey)]);
      Inc(monitorIndex);
    end;

    Inc(deviceIndex);
  end;
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
var
  i, j, k: Integer;
  DisplayMonitors: TList;
  MonitorHandle: HMONITOR;
  PhysicalMonitorsCount: DWORD;
  PhysicalMonitors: array of TPhysicalMonitor;
begin
  Result := -1;
  if (Index >= DynamicData.GetLength) or (Index < 0) then Exit;
  DisplayMonitors := TList.Create;
  EnumDisplayMonitors(0, nil, @EnumMonitorsProc, LongInt(DisplayMonitors));
  k := 0;

  for i := 0 to DisplayMonitors.Count-1 do begin
    MonitorHandle := HMONITOR(DisplayMonitors.Items[i]);
    GetNumberOfPhysicalMonitorsFromHMONITOR(MonitorHandle, PhysicalMonitorsCount);
    SetLength(PhysicalMonitors, PhysicalMonitorsCount);
    GetPhysicalMonitorsFromHMONITOR(MonitorHandle, PhysicalMonitorsCount, PhysicalMonitors);

    for j := 0 to PhysicalMonitorsCount-1 do begin
      if (k = Index) then begin
        Result := PhysicalMonitors[j].hPhysicalMonitor;
        DisplayMonitors.Destroy;
        Exit;
      end;

      Inc(k);
      DestroyPhysicalMonitor(PhysicalMonitors[j].hPhysicalMonitor);
    end;
  end;

  DisplayMonitors.Destroy;
end;


function TDDCCI.isSupported(DeviceID: String): Boolean;
var
  i: Integer;
  j, k: DWORD;
begin
  Result := False;
  i := DynamicData.FindIndex(0, 'DeviceID', DeviceID);
  if (i < 0) then Exit;
  i := GetPhysicalMonitorHandle(i);
  if (i < 0) then Exit;

  Result := GetVCPFeatureAndVCPFeatureReply(i, DDCCI_POWER_ADRRESS, nil, j, k);
  DestroyPhysicalMonitor(i);
end;


function TDDCCI.PowerOn(DeviceID: String): Boolean;
var
  i: Integer;
begin
  Result := False;
  i := DynamicData.FindIndex(0, 'DeviceID', DeviceID);
  if (i < 0) then Exit;
  i := GetPhysicalMonitorHandle(i);
  if (i < 0) then Exit;

  Result := SetVCPFeature(i, DDCCI_POWER_ADRRESS, DDCCI_POWER_ON);
  DestroyPhysicalMonitor(i);
end;


function TDDCCI.PowerOff(DeviceID: String): Boolean;
var
  i: Integer;
begin
  Result := False;
  i := DynamicData.FindIndex(0, 'DeviceID', DeviceID);
  if (i < 0) then Exit;
  i := GetPhysicalMonitorHandle(i);
  if (i < 0) then Exit;

  Result := SetVCPFeature(i, DDCCI_POWER_ADRRESS, DDCCI_POWER_OFF);
  DestroyPhysicalMonitor(i);
end;


function TDDCCI.PowerToggle(DeviceID: String): Boolean;
var
  i: Integer;
  CurrentValue, MaximumValue: DWORD;
begin
  Result := False;
  i := DynamicData.FindIndex(0, 'DeviceID', DeviceID);
  if (i < 0) then Exit;
  i := GetPhysicalMonitorHandle(i);
  if (i < 0) then Exit;

  GetVCPFeatureAndVCPFeatureReply(i, DDCCI_POWER_ADRRESS, nil, CurrentValue, MaximumValue);
  Result := SetVCPFeature(i, DDCCI_POWER_ADRRESS, Q((CurrentValue <> DDCCI_POWER_ON), DDCCI_POWER_ON, DDCCI_POWER_OFF));
  DestroyPhysicalMonitor(i);
end;

end.
