unit uTaskbarRestart;

interface

uses
  SysUtils, Windows;

type
  TCallback = procedure;

var
  Callback: TCallback;
  TaskbarRestart: Cardinal;
  LWndClass: TWndClass;
  WinHandle: HWND;
  ThreadID: LongWord = 0;

procedure SetTaskbarRestart(Proc: TCallback);

implementation

function ChangeWindowMessageFilter(msg: Cardinal; Action: Dword): BOOL; stdcall; external 'user32.dll';


function WndProc(hWnd, Msg: Longint; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
begin
  if (Msg = TaskbarRestart) and Assigned(Callback) then Callback;
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
  WinHandle := CreateWindow(LWndClass.lpszClassName, nil, 0,0,0,0,0,0,0, HInstance, nil);

  while GetMessage(Msg, 0,0,0) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;


procedure SetTaskbarRestart(Proc: TCallback);
begin
  if Assigned(Proc) then begin
    Callback := Proc;
    TaskbarRestart := RegisterWindowMessage('TaskbarCreated');
    if ThreadID = 0 then ThreadID := BeginThread(nil, 0, Addr(MessageLoop), nil, 0, ThreadID);
    ChangeWindowMessageFilter(TaskbarRestart, 1);
  end else begin
    Callback := nil;
    TerminateThread(ThreadID, 0);
    ThreadID := 0;
    DestroyWindow(WinHandle);
    Windows.UnregisterClass(LWndClass.lpszClassName, HInstance);
  end;
end;


initialization
  Randomize;
end.
