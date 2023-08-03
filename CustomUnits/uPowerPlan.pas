unit uPowerPlan;

interface

uses
  Windows, SysUtils, uDynamicData, Functions;

const
  ACCESS_SCHEME = 16;

type
  TPowerPlan = class
    public
      constructor Create;
      destructor Destroy; override;
      function Update: TPowerPlan;

      function GetSchemesCount: Integer;
      function GetIndexByGUID(GUID: String): Integer;
      function GetGUID(Index: Integer): String;
      function GetFriendlyName(Index: Integer): WideString;
      function GetActiveScheme: String;
      function SetActiveScheme(GUID: String): Boolean;
    private
      DynamicData: TDynamicData;
    end;

implementation

function PowerEnumerate(RootPowerKey: HKEY; SchemeGuid: PGUID; SubGroupOfPowerSettingsGuid: PGUID; AccessFlags: DWORD; Index: ULONG; Buffer: Pointer; var BufferSize: DWORD): DWORD; stdcall; external 'powrprof.dll';
function PowerReadFriendlyName(RootPowerKey: HKEY; SchemeGuid: PGUID; SubGroupOfPowerSettingsGuid: PGUID; PowerSettingGuid: PGUID; Buffer: Pointer; var BufferSize: DWORD): DWORD; stdcall; external 'powrprof.dll';
function PowerGetActiveScheme(RootPowerKey: HKEY; ActivePolicyGuid: PGUID): DWORD; stdcall; external 'powrprof.dll';
function PowerSetActiveScheme(RootPowerKey: HKEY; ActivePolicyGuid: PGUID): DWORD; stdcall; external 'powrprof.dll';


constructor TPowerPlan.Create;
begin
  inherited Create;
  DynamicData := TDynamicData.Create(['FriendlyName', 'GUID']);
  self.Update;
end;


destructor TPowerPlan.Destroy;
begin
  DynamicData.Destroy;
  inherited Destroy;
end;


function TPowerPlan.Update: TPowerPlan;
var
  SchemeGuid: TGUID;
  BufferSize: DWORD;
  Index: Cardinal;
  BufferName: array of WideChar;
begin
  Result := self;
  DynamicData.ClearAllData;
  BufferSize := SizeOf(TGUID);
  Index := 0;

  while (PowerEnumerate(0, nil, nil, ACCESS_SCHEME, Index, @SchemeGuid, BufferSize) = 0) do begin
    Inc(Index);
    if (PowerReadFriendlyName(0, @SchemeGuid, nil, nil, nil, BufferSize) <> 0) then Continue;
    SetLength(BufferName, BufferSize);
    if (PowerReadFriendlyName(0, @SchemeGuid, nil, nil, @BufferName[0], BufferSize) <> 0) then Continue;
    self.DynamicData.CreateData(-1, -1, ['FriendlyName', 'GUID'], [WideString(BufferName), GUIDToString(SchemeGuid)])
  end;
end;


function TPowerPlan.GetSchemesCount: Integer;
begin
  Result := DynamicData.GetLength;
end;


function TPowerPlan.GetIndexByGUID(GUID: String): Integer;
begin
  Result := DynamicData.FindIndex(0, 'GUID', GUID);
end;


function TPowerPlan.GetGUID(Index: Integer): String;
begin
  Result := '';
  if (Index >= DynamicData.GetLength) or (Index < 0) then Exit;
  Result := DynamicData.GetValue(Index, 'GUID');
end;


function TPowerPlan.GetFriendlyName(Index: Integer): WideString;
begin
  Result := '';
  if (Index >= DynamicData.GetLength) or (Index < 0) then Exit;
  Result := DynamicData.GetValue(Index, 'FriendlyName');
end;


function TPowerPlan.GetActiveScheme: String;
var
  SchemeGuid: PGUID;
begin
  Result := '';
  if (PowerGetActiveScheme(0, @SchemeGuid) <> 0) then Exit;
  Result := GUIDToString(TGUID(SchemeGuid^));
end;


function TPowerPlan.SetActiveScheme(GUID: String): Boolean;
var
  SchemeGuid: TGUID;
begin
  SchemeGuid := StringToGUID(GUID);
  Result := (PowerSetActiveScheme(0, @SchemeGuid) = 0);
end;

end.
