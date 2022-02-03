unit uQueryShutdown;

interface

uses
  SysUtils, Windows, Messages, Forms;

type
  TBlockShutdown = class
    public
      constructor Create;
      destructor Destroy; override;
      function CreateReason(Reason: WideString): Boolean;
      function DestroyReason: Boolean;
  end;

type
  TQueryShutdownCallback = procedure(BS: TBlockShutdown);

var
  BlockShutdown: TBlockShutdown;
  QueryShutdownCallback: TQueryShutdownCallback;
  LWndClass: TWndClass;
  WinHandle: HWND;
  ThreadID: LongWord = 0;


procedure SetQueryShutdown(Callback: TQueryShutdownCallback);

implementation

function ChangeWindowMessageFilter(msg: Cardinal; Action: Dword): BOOL; stdcall; external 'user32.dll';
function ShutdownBlockReasonCreate(hWnd: HWND; Reason: LPCWSTR): Bool; stdcall; external user32;
function ShutdownBlockReasonDestroy(hWnd: HWND): Bool; stdcall; external user32;


function WndProc(hWnd, Msg: Longint; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
begin
  //WriteLn('Message -> ' + IntToStr(Msg) + ' | lParam -> ' + IntToStr(lParam) + ' | wParam -> ' + IntToStr(wParam));

  if (Msg = WM_QUERYENDSESSION) then begin
    if Assigned(QueryShutdownCallback) then QueryShutdownCallback(BlockShutdown);
    Result := lResult(False);
    Exit;
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

  while GetMessage(Msg, 0,0,0) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;


procedure SetQueryShutdown(Callback: TQueryShutdownCallback);
begin
  if Assigned(Callback) then begin
    QueryShutdownCallback := Callback;
    if ThreadID = 0 then BlockShutdown := TBlockShutdown.Create;
    if ThreadID = 0 then ThreadID := BeginThread(nil, 0, Addr(MessageLoop), nil, 0, ThreadID);
    ChangeWindowMessageFilter(WM_QUERYENDSESSION, 1);
  end else begin
    BlockShutdown.Destroy;
    QueryShutdownCallback := nil;
    TerminateThread(ThreadID, 0);
    ThreadID := 0;
    DestroyWindow(WinHandle);
    Windows.UnregisterClass(LWndClass.lpszClassName, HInstance);
  end;
end;

constructor TBlockShutdown.Create;
begin
  inherited Create;
end;


destructor TBlockShutdown.Destroy;
begin
  inherited Destroy;
end;


function TBlockShutdown.CreateReason(Reason: WideString): Boolean;
begin
  Result := ShutdownBlockReasonCreate(WinHandle, PWideChar(Reason));
end;


function TBlockShutdown.DestroyReason: Boolean;
begin
  Result := ShutdownBlockReasonDestroy(WinHandle);
end;


initialization
  Randomize;
end.
