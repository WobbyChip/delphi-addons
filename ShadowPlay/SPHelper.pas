unit SPHelper;

interface

uses
  Windows, ShellApi, SysUtils, Classes, Forms, ActiveX;

procedure Wait(Millisecs: Integer);
function Q(b: Boolean; v1, v2: Variant): Variant;
function ReadIntPtr(p: Pointer): Pointer;
function AllocCoTaskMem(Size: Cardinal): Pointer;
function FromVirtual(Keys: array of Integer): TShortCut;
function GetModifierKey(vk: Cardinal): Cardinal;
procedure SimulateHotkey(ShortCut: TShortCut);
function DeleteDirectory(Directory: WideString): Boolean;

implementation

procedure Wait(Millisecs: Integer);
var
  Tick: DWORD;
  AnEvent: THandle;
begin
  AnEvent := CreateEvent(nil, False, False, nil);
  try
    Tick := GetTickCount + DWORD(Millisecs);
    while (Millisecs > 0) and (MsgWaitForMultipleObjects(1, AnEvent, False, Millisecs, QS_ALLINPUT) <> WAIT_TIMEOUT) do begin
      Application.ProcessMessages;
      if Application.Terminated then Exit;
      Millisecs := Tick - GetTickCount;
    end;
  finally
    CloseHandle(AnEvent);
  end;
end;


function Q(b: Boolean; v1, v2: Variant): Variant;
begin
  if b then Result := v1 else Result := v2;
end;


function AllocCoTaskMem(Size: Cardinal): Pointer;
begin
  Result := CoTaskMemAlloc(Size);
end;


function ReadIntPtr(p: Pointer): Pointer;
begin
  Result := Pointer(PInteger(p)^);
end;


function FromVirtual(Keys: array of Integer): TShortCut;
var
  i: Integer;
  fsModifiers, v: Cardinal;
begin
  Result := 0;
  fsModifiers := 0;

  for i := 0 to Length(Keys)-1 do begin
    v := getModifierKey(Keys[i]);
    if (v <> 0) then fsModifiers := (fsModifiers or v) else if (Keys[i] <> 0) then Result := Keys[i];
  end;

  if Result = 0 then Exit;
  if fsModifiers and MOD_CONTROL <> 0 then Inc(Result, scCtrl);
  if fsModifiers and MOD_SHIFT <> 0 then Inc(Result, scShift);
  if fsModifiers and MOD_ALT <> 0 then Inc(Result, scAlt);
end;


function GetModifierKey(vk: Cardinal): Cardinal;
begin
  Result := 0;
  if vk = 16 then Result := MOD_SHIFT;
  if vk = 17 then Result := MOD_CONTROL;
  if vk = 18 then Result := MOD_ALT;
end;


procedure SimulateHotkey(ShortCut: TShortCut);
var
  Key, i: Cardinal;
  Keys: array[0..3] of Integer;
begin
  Key := ShortCut and not (scShift + scCtrl + scAlt);
  Keys[0] := Key;

  if ShortCut and scCtrl <> 0 then Keys[1] := VK_CONTROL;
  if ShortCut and scShift <> 0 then Keys[2] := VK_SHIFT;
  if ShortCut and scAlt <> 0 then Keys[3] := VK_MENU;

  for i := 0 to Length(Keys)-1 do begin
    Keybd_Event(Keys[i], 0, 0, 0);
  end;

  for i := 0 to Length(Keys)-1 do begin
    Keybd_Event(Keys[i], 0, 2, 0);
  end;
end;


function DeleteDirectory(Directory: WideString): Boolean;
var
  ShFileOp: TSHFileOpStructW;
begin
  FillChar(ShFileOp, SizeOf(ShFileOp), 0);
  ShFileOp.wFunc := FO_DELETE;
  ShFileOp.pFrom := PWideChar(Directory + #0);
  ShFileOp.fFlags := FOF_SILENT or FOF_NOERRORUI or FOF_NOCONFIRMATION;
  Result := (SHFileOperationW(ShFileOp) = 0);
end;

end.
