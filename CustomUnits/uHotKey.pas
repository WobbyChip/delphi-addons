unit uHotKey;

interface

uses
  SysUtils, Windows, Classes, Variants, Messages;

const
  hkExclusions = [144, 111, 45, 40, 39, 38, 37, 36, 35, 34, 33];

type
  TProcedure = procedure(Key, ShortCut: Integer; CustomValue: Variant);

type
  PCallback = ^TCallback;
  TCallback = record
    Key: Integer;
    ShortCut: Integer;
    CustomValue: Variant;
    Callback: TProcedure;
  end;

var
  Callbacks: TList;
  WinHandle: HWND;
  LWndClass: TWndClass;

function ShortCutToKey(ShortCut: TShortCut): Integer;
function ShortCutToModifiers(ShortCut: TShortCut): Integer;
function ModifiersKeyToShortCut(fsModifiers, vk: Cardinal): TShortCut;

function SetShortCut(Proc: TProcedure; ShortCut: TShortCut): Integer; overload;
function SetShortCut(Proc: TProcedure; ShortCut: TShortCut; CustomValue: Variant): Integer; overload;
function ChangeShortCut(Key: Integer; ShortCut: TShortCut): Boolean;
function ShortCutToHotKey(ShortCut: Integer): Integer;

function SetHotKey(Proc: TProcedure; fsModifiers, vk: Cardinal): Integer; overload;
function SetHotKey(Proc: TProcedure; fsModifiers, vk: Cardinal; CustomValue: Variant): Integer; overload;
function ChangeHotKey(Key: Integer; fsModifiers, vk: Cardinal): Boolean;
function ChangeCallback(Key: Integer; Proc: TProcedure): Boolean;
function RemoveHotKey(Key: Integer): Boolean;
function DisableHotKey(Key: Integer): Boolean;
function EnableHotKey(Key: Integer): Boolean;


implementation

function ShortCutToKey(ShortCut: TShortCut): Integer;
begin
  Result := ShortCut and not (scShift + scCtrl + scAlt);
end;


function ShortCutToModifiers(ShortCut: TShortCut): Integer;
begin
  Result := 0;
  if ShortCut and scCtrl <> 0 then Result := Result or MOD_CONTROL;
  if ShortCut and scShift <> 0 then Result := Result or MOD_SHIFT;
  if ShortCut and scAlt <> 0 then Result := Result or MOD_ALT;
end;


function ModifiersKeyToShortCut(fsModifiers, vk: Cardinal): TShortCut;
begin
  Result := 0;
  if vk = 0 then Exit else Result := vk;
  if fsModifiers and MOD_CONTROL <> 0 then Inc(Result, scCtrl);
  if fsModifiers and MOD_SHIFT <> 0 then Inc(Result, scShift);
  if fsModifiers and MOD_ALT <> 0 then Inc(Result, scAlt);
end;


procedure RunCallback(Key: Integer);
var
  i: Integer;
  Callback: PCallback;
begin
  for i := 0 to Callbacks.Count-1 do begin
    Callback := Callbacks.Items[i];
    if (Callback.Key = Key) and Assigned(Callback.Callback) then Callback.Callback(Key, Callback.ShortCut, Callback.CustomValue);
  end;
end;


function SetShortCut(Proc: TProcedure; ShortCut: TShortCut): Integer;
begin
  Result := SetShortCut(Proc, ShortCut, Null);
end;


function SetShortCut(Proc: TProcedure; ShortCut: TShortCut; CustomValue: Variant): Integer;
begin
  Result := SetHotKey(Proc, ShortCutToModifiers(ShortCut), ShortCutToKey(ShortCut), CustomValue);
end;


function SetHotKey(Proc: TProcedure; fsModifiers, vk: Cardinal): Integer;
begin
  Result := SetHotKey(Proc, fsModifiers, vk, Null);
end;


function SetHotKey(Proc: TProcedure; fsModifiers, vk: Cardinal; CustomValue: Variant): Integer;
var
  Callback: PCallback;
begin
  Callback := New(PCallback);
  Callback^.Key := Random(MaxInt);
  Callback^.ShortCut := ModifiersKeyToShortCut(fsModifiers, vk);
  Callback^.CustomValue := CustomValue;
  Callback^.Callback := Proc;
  Callbacks.Add(Callback);

  RegisterHotKey(WinHandle, Callback^.Key, fsModifiers, vk);
  Result := Callback^.Key;
end;


function ChangeCallback(Key: Integer; Proc: TProcedure): Boolean;
var
  i: Integer;
begin
  Result := False;

  for i := 0 to Callbacks.Count-1 do begin
    if PCallback(Callbacks.Items[i]).Key = Key then begin
      PCallback(Callbacks.Items[i]).Callback := Proc;
      Result := True;
      Break;
    end;
  end;
end;


function ChangeShortCut(Key: Integer; ShortCut: TShortCut): Boolean;
begin
  Result := ChangeHotKey(Key, ShortCutToModifiers(ShortCut), ShortCutToKey(ShortCut));
end;


function ShortCutToHotKey(ShortCut: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;

  for i := 0 to Callbacks.Count-1 do begin
    if PCallback(Callbacks.Items[i]).ShortCut = ShortCut then begin
      Result := PCallback(Callbacks.Items[i]).Key;
      Break;
    end;
  end;
end;


function ChangeHotKey(Key: Integer; fsModifiers, vk: Cardinal): Boolean;
var
  i: Integer;
begin
  Result := False;

  for i := 0 to Callbacks.Count-1 do begin
    if PCallback(Callbacks.Items[i]).Key = Key then begin
      UnregisterHotKey(WinHandle, Key);
      RegisterHotKey(WinHandle, Key, fsModifiers, vk);
      PCallback(Callbacks.Items[i]).ShortCut := ModifiersKeyToShortCut(fsModifiers, vk);
      Result := True;
      Break;
    end;
  end;
end;


function RemoveHotKey(Key: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;

  for i := 0 to Callbacks.Count-1 do begin
    if PCallback(Callbacks.Items[i]).Key = Key then begin
      UnregisterHotKey(WinHandle, Key);
      Callbacks.Delete(i);
      Result := True;
      Break;
    end;
  end;
end;


function DisableHotKey(Key: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;

  for i := 0 to Callbacks.Count-1 do begin
    if PCallback(Callbacks.Items[i]).Key = Key then begin
      Result := UnregisterHotKey(WinHandle, Key);
      Break;
    end;
  end;
end;


function EnableHotKey(Key: Integer): Boolean;
var
  i: Integer;
  Callback: PCallback;
begin
  Result := False;

  for i := 0 to Callbacks.Count-1 do begin
    Callback := Callbacks.Items[i];
    if Callback.Key = Key then begin
      Result := RegisterHotKey(WinHandle, Key, ShortCutToModifiers(Callback.ShortCut), ShortCutToKey(Callback.ShortCut));
      Break;
    end;
  end;
end;


function WndProc(hWnd, Msg: Longint; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
begin
  if Msg = WM_HOTKEY then RunCallback(wParam);
  Result := DefWindowProc(hWnd, Msg, wParam, lParam);
end;


initialization
  Randomize;
  Callbacks := TList.Create;

  FillChar(LWndClass, SizeOf(LWndClass), 0);
  LWndClass.hInstance := HInstance;
  LWndClass.lpszClassName := PChar(IntToStr(Random(MaxInt)) + 'Wnd');
  LWndClass.Style := CS_PARENTDC;
  LWndClass.lpfnWndProc := @WndProc;

  Windows.RegisterClass(LWndClass);
  WinHandle := CreateWindow(LWndClass.lpszClassName, nil, 0,0,0,0,0,0,0, HInstance, nil);
end.
