unit uSessionChange;

interface

uses
  SysUtils, Windows, Messages, Forms;

type
  TSessionType = (StUnknown, StConsoleConnect, StConsoleDisconnect, StRemoteConnect,
                  StRemoteDisconnect, StLogon, StLogoff, StLock, StUnlock);

type
  TSessionChangeCallback = procedure(T: TSessionType);

var
  SessionChangeCallback: TSessionChangeCallback;
  LWndClass: TWndClass;
  WinHandle: HWND;
  ThreadID: LongWord = 0;


procedure SetSessionChange(Callback: TSessionChangeCallback);

implementation


function RegisterSessionNotification(Wnd: HWND; dwFlags: DWORD): Boolean;
type
  TWTSRegisterSessionNotification = function(Wnd: HWND; dwFlags: DWORD): BOOL; stdcall;
var
  hWTSapi32dll: THandle;
  WTSRegisterSessionNotification: TWTSRegisterSessionNotification;
begin
  Result := False;
  hWTSAPI32DLL := LoadLibrary('wtsapi32.dll');
  if (hWTSAPI32DLL > 0) then begin
    try
      @WTSRegisterSessionNotification := GetProcAddress(hWTSAPI32DLL, 'WTSRegisterSessionNotification');
      if Assigned(WTSRegisterSessionNotification) then begin
        Result:= WTSRegisterSessionNotification(Wnd, dwFlags);
      end;
    finally
      if hWTSAPI32DLL > 0 then FreeLibrary(hWTSAPI32DLL);
    end;
  end;
end;


function WndProc(hWnd, Msg: Longint; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
var
  T: TSessionType;
begin
  //WriteLn('Message -> ' + IntToStr(Msg) + ' | lParam -> ' + IntToStr(lParam) + ' | wParam -> ' + IntToStr(wParam));

  if (Msg = WM_WTSSESSION_CHANGE) then begin
    case WPARAM of
      WTS_CONSOLE_CONNECT: T := StConsoleConnect;
      WTS_CONSOLE_DISCONNECT: T := StConsoleDisconnect;
      WTS_REMOTE_CONNECT: T := StRemoteConnect;
      WTS_REMOTE_DISCONNECT: T := StRemoteDisconnect;
      WTS_SESSION_LOGON: T := StLogon;
      WTS_SESSION_LOGOFF: T := StLogoff;
      WTS_SESSION_LOCK: T := StLock;
      WTS_SESSION_UNLOCK: T := StUnlock;
    else
      T := StUnknown;
    end;

    if Assigned(SessionChangeCallback) then SessionChangeCallback(T);
  end;

  Result := DefWindowProc(hWnd, Msg, wParam, lParam);
end;


procedure MessageLoop;
var
  Msg: TMsg;
begin
  FillChar(LWndClass, SizeOf(LWndClass), 0);
  LWndClass.hInstance := HInstance;
  LWndClass.lpszClassName := PChar(IntToStr(Random(MaxInt)) + 'Wnd');
  LWndClass.Style := CS_PARENTDC;
  LWndClass.lpfnWndProc := @WndProc;

  Windows.RegisterClass(LWndClass);
  WinHandle := CreateWindow(LWndClass.lpszClassName, PChar(Application.Title), 0,0,0,0,0,0,0, HInstance, nil);
  RegisterSessionNotification(WinHandle, 0);

  while GetMessage(Msg, 0,0,0) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;


procedure SetSessionChange(Callback: TSessionChangeCallback);
begin
  if Assigned(Callback) then begin
    SessionChangeCallback := Callback;
    if ThreadID = 0 then ThreadID := BeginThread(nil, 0, Addr(MessageLoop), nil, 0, ThreadID);
  end else begin
    SessionChangeCallback := nil;
    TerminateThread(ThreadID, 0);
    ThreadID := 0;
    DestroyWindow(WinHandle);
    Windows.UnregisterClass(LWndClass.lpszClassName, HInstance);
  end;
end;


initialization
  Randomize;
end.
