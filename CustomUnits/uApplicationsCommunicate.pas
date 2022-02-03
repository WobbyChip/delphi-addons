unit uApplicationsCommunicate;

interface

uses
  SysUtils, Windows, Classes, Messages;

type
  TProcedure = procedure;

type
  PCallback = ^TCallback;
  TCallback = record
    Group: Integer;
    Msg: Integer;
    Callback: TProcedure;
  end;

var
  Callbacks: TList;
  WinHandle: HWND = 0;
  id: LongWord = 0;
  LWndClass: TWndClass;


procedure SetMessageCallback(Group: String; Msg: Integer; Proc: TProcedure);
procedure RemoveMessageCallback(Group: String; Msg: Integer);
procedure SendMessage(Group: String; Msg: Integer);

implementation

procedure SendMessage(Group: String; Msg: Integer);
var
  lpdw: Cardinal;
begin
  SendMessageTimeout(HWND_BROADCAST, RegisterWindowMessage(PChar(Group)), WinHandle, Msg, SMTO_NORMAL, 100, lpdw);
end;


procedure RunCallback(Group, Msg: Integer);
var
  i: Integer;
  Callback: PCallback;
begin
  for i := 0 to Callbacks.Count-1 do begin
    Callback := Callbacks.Items[i];
    if (Callback.Group = Group) and (Callback.Msg = Msg) and Assigned(Callback.Callback) then Callback.Callback;
  end;
end;


procedure SetMessageCallback(Group: String; Msg: Integer; Proc: TProcedure);
var
  Callback: PCallback;
begin
  Callback := New(PCallback);
  Callback^.Group := RegisterWindowMessage(PChar(Group));
  Callback^.Msg := Msg;
  Callback^.Callback := Proc;
  Callbacks.Add(Callback);
end;


procedure RemoveMessageCallback(Group: String; Msg: Integer);
var
  i, g: Integer;
  Callback: PCallback;
begin
  g := RegisterWindowMessage(PChar(Group));

  for i := 0 to Callbacks.Count-1 do begin
    Callback := Callbacks.Items[0];
    if (Callback.Group = g) and (Callback.Msg = Msg) then Callbacks.Delete(i);
  end;
end;


function WindowProc(hWnd, Msg: Longint; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
begin
  if wParam <> WinHandle then RunCallback(Msg, lParam);
  Result := DefWindowProc(hWnd, Msg, wParam, lParam);
end;


procedure MessageLoop;
var
  Msg: TMsg;
begin
  id := Random(MaxInt);

  FillChar(LWndClass, SizeOf(LWndClass), 0);
  LWndClass.hInstance := HInstance;
  LWndClass.lpszClassName := PChar(IntToStr(id) + 'Wnd');
  LWndClass.Style := CS_PARENTDC;
  LWndClass.lpfnWndProc := @WindowProc;

  Windows.RegisterClass(LWndClass);
  WinHandle := CreateWindow(LWndClass.lpszClassName, PChar(IntToStr(id)), 0,0,0,0,0,0,0, HInstance, nil);

  while GetMessage(Msg, 0,0,0) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;


initialization
  Randomize;
  Callbacks := TList.Create;
  BeginThread(nil, 0, Addr(MessageLoop), nil, 0, id);
  while WinHandle = 0 do Sleep(1);
end.
