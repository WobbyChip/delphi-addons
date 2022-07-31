unit uQueryShutdown;

interface

uses
  SysUtils, Windows, Classes, Messages, Forms;

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
  PQueryShutdownCallback = ^TQueryShutdownCallback;

var
  BlockShutdown: TBlockShutdown;
  ShutdownCallbacks: TList;
  WinHandle: HWND;
  ThreadID: LongWord = 0;


procedure AddShutdownCallback(Callback: TQueryShutdownCallback);
procedure RemoveShutdownCallback(Callback: TQueryShutdownCallback);

implementation

function ChangeWindowMessageFilter(msg: Cardinal; Action: Dword): BOOL; stdcall; external user32;
function ShutdownBlockReasonCreate(hWnd: HWND; Reason: LPCWSTR): BOOL; stdcall; external user32;
function ShutdownBlockReasonDestroy(hWnd: HWND): BOOL; stdcall; external user32;


function WndProc(hWnd, Msg: Longint; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
var
  i: Integer;
begin
  if (Msg = WM_QUERYENDSESSION) and (ShutdownCallbacks.Count > 0) then begin
    for i := 0 to ShutdownCallbacks.Count-1 do TQueryShutdownCallback(ShutdownCallbacks.Items[i])(BlockShutdown);
    Result := lResult(False);
    Exit;
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

  while GetMessage(Msg, 0,0,0) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;


procedure AddShutdownCallback(Callback: TQueryShutdownCallback);
begin
  ShutdownCallbacks.Add(@Callback);
end;


procedure RemoveShutdownCallback(Callback: TQueryShutdownCallback);
begin
  ShutdownCallbacks.Remove(@Callback);
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
  ShutdownCallbacks := TList.Create;
  BlockShutdown := TBlockShutdown.Create;
  BeginThread(nil, 0, Addr(MessageLoop), nil, 0, ThreadID);
  ChangeWindowMessageFilter(WM_QUERYENDSESSION, 1);
end.
