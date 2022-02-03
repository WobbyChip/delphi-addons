unit uMouseHook;

interface

uses
  SysUtils, Windows, Classes, Messages;

const
  WM_SBUTTONDOWN = 523;
  WM_SBUTTONUP = 524;

type
  TMouseCallback = function(wParam: Integer): Integer;

type
  TMouseHookFilters = record
    BlockMouseMove: Boolean;
    BlockLeftButton: Boolean;
    BlockRightButton: Boolean;
    BlockMiddleButton: Boolean;
    BlockSideButton: Boolean;
    BlockWheel: Boolean;
    AllowBlockedCallback: Boolean;
  end;

var
  MouseCallback: TMouseCallback;
  Filters: TMouseHookFilters;
  hMouseHook: HHOOK = 0;


function StartMouseHook(Proc: TMouseCallback): Boolean;
function StopMouseHook: Boolean;

procedure BlockMouseMove(block: Boolean);
procedure BlockLeftButton(block: Boolean);
procedure BlockRightButton(block: Boolean);
procedure BlockMiddleButton(block: Boolean);
procedure BlockSideButton(block: Boolean);
procedure BlockWheel(block: Boolean);
procedure AllowBlockedCallback(allow: Boolean);

implementation

function MouseProc(Code: Integer; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
begin
  Result := 0;

  case wParam of
    WM_MOUSEMOVE: if Filters.BlockMouseMove then Result := -1;
    WM_LBUTTONDOWN: if Filters.BlockLeftButton then Result := -1;
    WM_LBUTTONUP: if Filters.BlockLeftButton then Result := -1;
    WM_RBUTTONDOWN: if Filters.BlockRightButton then Result := -1;
    WM_RBUTTONUP: if Filters.BlockRightButton then Result := -1;
    WM_MBUTTONDOWN: if Filters.BlockMiddleButton then Result := -1;
    WM_MBUTTONUP: if Filters.BlockMiddleButton then Result := -1;
    WM_SBUTTONDOWN: if Filters.BlockSideButton then Result := -1;
    WM_SBUTTONUP: if Filters.BlockSideButton then Result := -1;
    WM_MOUSEWHEEL: if Filters.BlockWheel then Result := -1;
  end;

  if Assigned(MouseCallback) and ((Result <> -1) or Filters.AllowBlockedCallback) then Result := MouseCallback(wParam);
  if (Result <> -1) then Result := CallNextHookEx(hMouseHook, Code, wParam, lParam);
end;


function StartMouseHook(Proc: TMouseCallback): Boolean;
const
  WH_MOUSE_LL = 14;
begin
  MouseCallback := Proc;
  if hMouseHook = 0 then hMouseHook := SetWindowsHookEx(WH_MOUSE_LL, @MouseProc, HInstance, 0);
  Result := (hMouseHook <> 0);
end;


function StopMouseHook: Boolean;
begin
  MouseCallback := nil;
  if (hMouseHook <> 0) and UnhookWindowsHookEx(hMouseHook) then hMouseHook := 0;
  Result := (hMouseHook = 0);
end;


procedure BlockMouseMove(block: Boolean);
begin
  Filters.BlockMouseMove := block;
end;


procedure BlockLeftButton(block: Boolean);
begin
  Filters.BlockLeftButton := block;
end;


procedure BlockRightButton(block: Boolean);
begin
  Filters.BlockRightButton := block;
end;


procedure BlockMiddleButton(block: Boolean);
begin
  Filters.BlockMiddleButton := block;
end;


procedure BlockSideButton(block: Boolean);
begin
  Filters.BlockSideButton := block;
end;


procedure BlockWheel(block: Boolean);
begin
  Filters.BlockWheel := block;
end;


procedure AllowBlockedCallback(allow: Boolean);
begin
  Filters.AllowBlockedCallback := allow;
end;


initialization
  Filters.BlockMouseMove := False;
  Filters.BlockLeftButton := False;
  Filters.BlockRightButton := False;
  Filters.BlockMiddleButton := False;
  Filters.BlockSideButton := False;
  Filters.BlockWheel := False;
  Filters.AllowBlockedCallback := True;
end.
