unit uNotify;

interface

uses
  SysUtils, Windows, Classes, Messages, Forms;

type
  TShutdownCreateReason = function(Reason: WideString): Boolean;
  TShutdownDestroyReason = function: Boolean;
  TQueryShutdownCallback = procedure(CreateReason: TShutdownCreateReason; DestroyReason: TShutdownDestroyReason);

type
  TTaskbarRestartCallback = procedure;

type
  TWindowChangeCallback = procedure(hWnd: HWND);

type
  TSessionType = (StUnknown, StConsoleConnect, StConsoleDisconnect, StRemoteConnect, StRemoteDisconnect, StLogon, StLogoff, StLock, StUnlock);
  TSessionChangeCallback = procedure(T: TSessionType);

var
  ShutdownCallbacks: TList;
  TaskbarCallbacks: TList;
  WindowCallbacks: TList;
  SessionCallbacks: TList;
  WM_TASKBARRESTART: Longint;
  WinHandle: HWND;
  ThreadID: LongWord = 0;


procedure AddShutdownCallback(Callback: TQueryShutdownCallback);
procedure RemoveShutdownCallback(Callback: TQueryShutdownCallback);
procedure AddTaskbarRestartCallback(Callback: TTaskbarRestartCallback);
procedure RemoveTaskbarRestartCallback(Callback: TTaskbarRestartCallback);
procedure AddWindowChangeCallback(Callback: TWindowChangeCallback);
procedure RemoveWindowChangeCallback(Callback: TWindowChangeCallback);
procedure AddSessionChangeCallback(Callback: TSessionChangeCallback);
procedure RemoveSessionChangeCallback(Callback: TSessionChangeCallback);

implementation

function ChangeWindowMessageFilter(msg: Cardinal; Action: Dword): BOOL; stdcall; external user32;
function ShutdownBlockReasonCreate(hWnd: HWND; Reason: LPCWSTR): BOOL; stdcall; external user32;
function ShutdownBlockReasonDestroy(hWnd: HWND): BOOL; stdcall; external user32;
function WTSRegisterSessionNotification(hWnd: HWND; dwFlags: DWORD): BOOL; stdcall; external 'wtsapi32.dll';


////////////////////////////////////
//Shutdown Notify///////////////////
////////////////////////////////////

function ShutdownCreateReason(Reason: WideString): Boolean;
begin
  Result := ShutdownBlockReasonCreate(WinHandle, PWideChar(Reason));
end;


function DestroyReason: Boolean;
begin
  Result := ShutdownBlockReasonDestroy(WinHandle);
end;


procedure AddShutdownCallback(Callback: TQueryShutdownCallback);
begin
  if not Assigned(Callback) then Exit;
  ShutdownCallbacks.Add(@Callback);
end;


procedure RemoveShutdownCallback(Callback: TQueryShutdownCallback);
begin
  if not Assigned(Callback) then Exit;
  ShutdownCallbacks.Remove(@Callback);
end;


////////////////////////////////////
//Taskbar Notify////////////////////
////////////////////////////////////


procedure AddTaskbarRestartCallback(Callback: TTaskbarRestartCallback);
begin
  if not Assigned(Callback) then Exit;
  TaskbarCallbacks.Add(@Callback);
end;


procedure RemoveTaskbarRestartCallback(Callback: TTaskbarRestartCallback);
begin
  if not Assigned(Callback) then Exit;
  TaskbarCallbacks.Remove(@Callback);
end;


////////////////////////////////////
//Window Change Notify//////////////
////////////////////////////////////


procedure AddWindowChangeCallback(Callback: TWindowChangeCallback);
begin
  if not Assigned(Callback) then Exit;
  WindowCallbacks.Add(@Callback);
end;


procedure RemoveWindowChangeCallback(Callback: TWindowChangeCallback);
begin
  if not Assigned(Callback) then Exit;
  WindowCallbacks.Remove(@Callback);
end;


////////////////////////////////////
//Session Change Notify//////////////
////////////////////////////////////


procedure AddSessionChangeCallback(Callback: TSessionChangeCallback);
begin
  if not Assigned(Callback) then Exit;
  SessionCallbacks.Add(@Callback);
end;


procedure RemoveSessionChangeCallback(Callback: TSessionChangeCallback);
begin
  if not Assigned(Callback) then Exit;
  SessionCallbacks.Remove(@Callback);
end;


////////////////////////////////////
//Handle Message Loop///////////////
////////////////////////////////////


procedure WinEventProc(hWinEventHook: THandle; event: DWORD; hwnd: HWND; idObject, idChild: Longint; idEventThread, dwmsEventTime: DWORD); stdcall;
var
  i: Integer;
begin
  if (WindowCallbacks.Count = 0) then Exit;
  for i := 0 to WindowCallbacks.Count-1 do TWindowChangeCallback(WindowCallbacks.Items[i])(hwnd);
end;


function WndProc(hWnd, Msg: Longint; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
var
  i: Integer;
  T: TSessionType;
begin
  if (Msg = WM_QUERYENDSESSION) and (ShutdownCallbacks.Count > 0) then begin
    for i := 0 to ShutdownCallbacks.Count-1 do TQueryShutdownCallback(ShutdownCallbacks.Items[i])(ShutdownCreateReason, DestroyReason);
    Result := lResult(False);
    Exit;
  end;

  if (Msg = WM_TASKBARRESTART) and (TaskbarCallbacks.Count > 0) then begin
    for i := 0 to TaskbarCallbacks.Count-1 do TTaskbarRestartCallback(TaskbarCallbacks.Items[i]);
  end;

  if (Msg = WM_WTSSESSION_CHANGE) and (SessionCallbacks.Count > 0) then begin
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

    for i := 0 to SessionCallbacks.Count-1 do TSessionChangeCallback(TaskbarCallbacks.Items[i])(T);
  end;

  Result := DefWindowProc(hWnd, Msg, wParam, lParam);
end;


procedure MessageLoop;
var
  Msg: TMsg;
  LWndClass: TWndClass;
begin
  FillChar(LWndClass, SizeOf(LWndClass), 0);
  LWndClass.hInstance := HInstance;
  LWndClass.lpszClassName := PChar(IntToStr(Random(MaxInt)) + 'Wnd');
  LWndClass.Style := CS_PARENTDC;
  LWndClass.lpfnWndProc := @WndProc;

  Windows.RegisterClass(LWndClass);
  WinHandle := CreateWindow(LWndClass.lpszClassName, PChar(Application.Title), 0,0,0,0,0,0,0, HInstance, nil);
  SetWinEventHook(EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_FOREGROUND, 0, WinEventProc, 0, 0, WINEVENT_OUTOFCONTEXT);
  WTSRegisterSessionNotification(WinHandle, 0);

  while GetMessage(Msg, 0,0,0) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;


initialization
  Randomize;
  ShutdownCallbacks := TList.Create;
  TaskbarCallbacks := TList.Create;
  WindowCallbacks := TList.Create;
  SessionCallbacks := TList.Create;

  WM_TASKBARRESTART := RegisterWindowMessage('TaskbarCreated');
  ChangeWindowMessageFilter(WM_QUERYENDSESSION, 1);
  ChangeWindowMessageFilter(WM_TASKBARRESTART, 1);
  BeginThread(nil, 0, Addr(MessageLoop), nil, 0, ThreadID);
end.
