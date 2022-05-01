unit uWindowChange;

interface

uses
  SysUtils, Windows, Messages, Forms;

type
  TWindowChangeCallback = procedure(hwnd: HWND);

var
  WindowChangeCallback: TWindowChangeCallback;
  hhook: Cardinal;
  LWndClass: TWndClass;
  WinHandle: HWND;
  ThreadID: LongWord = 0;


procedure SetWindowChange(Callback: TWindowChangeCallback);

implementation


procedure WinEventProc(hWinEventHook: THandle; event: DWORD; hwnd: HWND; idObject, idChild: Longint; idEventThread, dwmsEventTime: DWORD); stdcall;
begin
 if Assigned(WindowChangeCallback) then WindowChangeCallback(hwnd);
end;


function WndProc(hWnd, Msg: Longint; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
begin
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
  hhook := SetWinEventHook(EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_FOREGROUND, 0, WinEventProc, 0, 0, WINEVENT_OUTOFCONTEXT);

  while GetMessage(Msg, 0,0,0) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;


procedure SetWindowChange(Callback: TWindowChangeCallback);
begin
  if Assigned(Callback) then begin
    WindowChangeCallback := Callback;
    if ThreadID = 0 then ThreadID := BeginThread(nil, 0, Addr(MessageLoop), nil, 0, ThreadID);
  end else begin
    WindowChangeCallback := nil;
    UnhookWinEvent(hhook);
    TerminateThread(ThreadID, 0);
    ThreadID := 0;
    DestroyWindow(WinHandle);
    Windows.UnregisterClass(LWndClass.lpszClassName, HInstance);
  end;
end;


initialization
  Randomize;
end.
