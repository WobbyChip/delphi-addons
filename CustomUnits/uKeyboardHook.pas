unit uKeyboardHook;

interface

uses
  Windows;

const
  LLKHF_BUTTONUP = 128;

type
  TKeyboardCallback = function(vkCode, scanCode, flags: DWORD): Integer;
  TAsciiCallback = function(Chr: Char): Integer;

type
  PKBDLLHOOKSTRUCT = ^TKBDLLHOOKSTRUCT;
  TKBDLLHOOKSTRUCT = packed record
    vkCode: DWORD;
    scanCode: DWORD;
    flags: DWORD;
    time: DWORD;
    dwExtraInfo: DWORD;
  end;

var
  KeyboardCallback: TKeyboardCallback;
  AsciiCallback: TAsciiCallback;
  KeyboardDisabled: Boolean = False;
  hKeyboardHook: HHOOK = 0;


function StartKeyboardHook: Boolean;
function StopKeyboardHook: Boolean;
procedure SetKeyboardCallback(Proc: TKeyboardCallback);
procedure SetAsciiCallback(Proc: TAsciiCallback);
procedure DisableKeyboard(bool: Boolean);

implementation

function KeyboardProc(Msg: Integer; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
var
  pkbhs: PKBDLLHOOKSTRUCT;
  KeyState: TKeyBoardState;
  ArrayOfChar: array[0..1] of Char;
  i: Integer;
begin
  pkbhs := PKBDLLHOOKSTRUCT(lParam);
  if KeyboardDisabled then Result := -1 else Result := 0;

  if Assigned(AsciiCallback) and (pkbhs.flags = 0) then begin
    for i := 0 to Length(KeyState)-1 do KeyState[i] := GetKeyState(i);
    i := ToAscii(pkbhs.vkCode, pkbhs.scanCode, KeyState, ArrayOfChar, pkbhs.flags);
  end else i := 0;

  if Assigned(KeyboardCallback) and (not KeyboardDisabled) then Result := KeyboardCallback(pkbhs.vkCode, pkbhs.scanCode, pkbhs.flags);
  if Assigned(AsciiCallback) and (not KeyboardDisabled) and (i > 0) then Result := AsciiCallback(ArrayOfChar[0]);
  if (Result <> -1) then Result := CallNextHookEx(hKeyboardHook, Msg, wParam, lParam);
end;


function StartKeyboardHook: Boolean;
const
  WH_KEYBOARD_LL = 13;
begin
  if hKeyboardHook = 0 then hKeyboardHook := SetWindowsHookEx(WH_KEYBOARD_LL, @KeyboardProc, HInstance, 0);
  Result := (hKeyboardHook <> 0);
end;


function StopKeyboardHook: Boolean;
begin
  KeyboardCallback := nil;
  AsciiCallback := nil;

  if (hKeyboardHook <> 0) and UnhookWindowsHookEx(hKeyboardHook) then hKeyboardHook := 0;
  Result := (hKeyboardHook = 0);
end;


procedure SetKeyboardCallback(Proc: TKeyboardCallback);
begin
  KeyboardCallback := Proc;
end;


procedure SetAsciiCallback(Proc: TAsciiCallback);
begin
  AsciiCallback := Proc;
end;


procedure DisableKeyboard(bool: Boolean);
begin
  KeyboardDisabled := bool;
end;

end.