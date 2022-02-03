unit CustoTrayIcon;

interface

uses
  Windows, ShellAPI, Messages, Classes;

const
  WM_SBUTTONDOWN = 523;
  WM_SBUTTONUP = 524;
  WM_SBUTTONDBLCLK = 525;

type
  TNotifyIconDataW = record
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array [0..63] of WideChar;
  end;

type
  TTrayNotifyAction = procedure(Sender: TObject; Code: Integer) of object;
  TTrayNotifyEvent = procedure(Sender: TObject) of object;

type
  TTrayIcon = class(TComponent)
    private
      FHandle: THandle;
      FTrayIconData: TNotifyIconDataW;
      FInTray: Boolean;
      FAutoReadd: Boolean;
      FTitle: WideString;
      FIcon: HICON;
      FOnAction: TTrayNotifyAction;
      FOnLeftDblClick: TTrayNotifyEvent;
      FOnLeftUp: TTrayNotifyEvent;
      FOnLeftDown: TTrayNotifyEvent;
      FOnRightDblClick: TTrayNotifyEvent;
      FOnRightUp: TTrayNotifyEvent;
      FOnRightDown: TTrayNotifyEvent;
      FOnMiddleDblClick: TTrayNotifyEvent;
      FOnMiddleUp: TTrayNotifyEvent;
      FOnMiddleDown: TTrayNotifyEvent;
      FOnSideDblClick: TTrayNotifyEvent;
      FOnSideUp: TTrayNotifyEvent;
      FOnSideDown: TTrayNotifyEvent;
      FOnMouseMove: TTrayNotifyEvent;
      FOnMouseWheel: TTrayNotifyEvent;
      procedure SetTitle(const Title: WideString);
      procedure SetIcon(const hIcon: HICON);
    protected
      procedure WndProc(var Message: TMessage);
    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      procedure AddToTray;
      procedure RemoveFromTray;
      procedure Update;
      property Icon: HICON read FIcon write SetIcon;
   published
      property AutoReadd: Boolean read FAutoReadd write FAutoReadd default True;
      property Title: WideString read FTitle write SetTitle;
      property OnAction: TTrayNotifyAction read FOnAction write FOnAction;
      property OnLeftDblClick: TTrayNotifyEvent read FOnLeftDblClick write FOnLeftDblClick;
      property OnLeftUp: TTrayNotifyEvent read FOnLeftUp write FOnLeftUp;
      property OnLeftDown: TTrayNotifyEvent read FOnLeftDown write FOnLeftDown;
      property OnRightDblClick: TTrayNotifyEvent read FOnRightDblClick write FOnRightDblClick;
      property OnRightUp: TTrayNotifyEvent read FOnRightUp write FOnRightUp;
      property OnRightDown: TTrayNotifyEvent read FOnRightDown write FOnRightDown;
      property OnMiddleDblClick: TTrayNotifyEvent read FOnMiddleDblClick write FOnMiddleDblClick;
      property OnMiddleUp: TTrayNotifyEvent read FOnMiddleUp write FOnMiddleUp;
      property OnMiddleDown: TTrayNotifyEvent read FOnMiddleDown write FOnMiddleDown;
      property OnSideDblClick: TTrayNotifyEvent read FOnSideDblClick write FOnSideDblClick;
      property OnSideUp: TTrayNotifyEvent read FOnSideUp write FOnSideUp;
      property OnSideDown: TTrayNotifyEvent read FOnSideDown write FOnSideDown;
      property OnMouseMove: TTrayNotifyEvent read FOnMouseMove write FOnMouseMove;
      property OnMouseWheel: TTrayNotifyEvent read FOnMouseWheel write FOnMouseWheel;
  end;

var
  TaskbarRestart: Cardinal;

implementation

function ChangeWindowMessageFilter(msg: Cardinal; Action: Dword): BOOL; stdcall; external 'user32.dll';


constructor TTrayIcon.Create(AOwner: TComponent);
begin
  inherited;
  FHandle := AllocateHWnd(WndProc);
  FAutoReadd := True;
  FInTray := False;

  FillChar(FTrayIconData, SizeOf(FTrayIconData), 0);
  FTrayIconData.cbSize := SizeOf(FTrayIconData);
  FTrayIconData.Wnd := FHandle;
  FTrayIconData.uFlags := NIF_MESSAGE + NIF_ICON + NIF_TIP;
  FTrayIconData.uCallbackMessage := Random(65535);
end;


destructor TTrayIcon.Destroy;
begin
  Shell_NotifyIconW(NIM_DELETE, @FTrayIconData);
  if FHandle > 0 then DeallocateHWnd(FHandle);
  inherited Destroy;
end;


procedure TTrayIcon.SetTitle(const Title: WideString);
var
  len: Integer;
begin
  FTitle := Title;
  len := Length(Title);
  if len > High(FTrayIconData.szTip) then len := High(FTrayIconData.szTip);
  if len > 0 then Move(Title[1], FTrayIconData.szTip[Low(FTrayIconData.szTip)], len*SizeOf(WideChar));
  if len >= 0 then FTrayIconData.szTip[len] := #0;
  if FInTray then Update;
end;


procedure TTrayIcon.SetIcon(const hIcon: HICON);
begin
  FTrayIconData.hIcon := hIcon;
  if FInTray then Update;
end;


procedure TTrayIcon.AddToTray;
begin
  Shell_NotifyIconW(NIM_ADD, @FTrayIconData);
  FInTray := True;
end;


procedure TTrayIcon.RemoveFromTray;
begin
  Shell_NotifyIconW(NIM_DELETE, @FTrayIconData);
  FInTray := False;
end;


procedure TTrayIcon.Update;
begin
  Shell_NotifyIconW(NIM_MODIFY, @FTrayIconData);
end;


procedure TTrayIcon.WndProc(var Message: TMessage);
begin
  if (Message.Msg = FTrayIconData.uCallbackMessage) then begin
    if Assigned(FOnAction) then FOnAction(Self, Message.LParam);

    case Message.LParam of
      WM_LBUTTONDBLCLK: if Assigned(FOnLeftDblClick) then FOnLeftDblClick(Self);
      WM_LBUTTONUP: if Assigned(FOnLeftUp) then FOnLeftUp(Self); 
      WM_LBUTTONDOWN: if Assigned(FOnLeftDown) then FOnLeftDown(Self); 
      WM_RBUTTONDBLCLK: if Assigned(FOnRightDblClick) then FOnRightDblClick(Self); 
      WM_RBUTTONUP: if Assigned(FOnRightUp) then FOnRightUp(Self); 
      WM_RBUTTONDOWN: if Assigned(FOnRightDown) then FOnRightDown(Self);
      WM_MBUTTONDBLCLK: if Assigned(FOnMiddleDblClick) then FOnMiddleDblClick(Self);
      WM_MBUTTONUP: if Assigned(FOnMiddleUp) then FOnMiddleUp(Self);
      WM_MBUTTONDOWN: if Assigned(FOnMiddleDown) then FOnMiddleDown(Self);
      WM_SBUTTONDBLCLK: if Assigned(FOnSideDblClick) then FOnSideDblClick(Self);
      WM_SBUTTONUP: if Assigned(FOnSideUp) then FOnSideUp(Self);
      WM_SBUTTONDOWN: if Assigned(FOnSideDown) then FOnSideDown(Self);
      WM_MOUSEMOVE: if Assigned(FOnMouseMove) then FOnMouseMove(Self);
      WM_MOUSEWHEEL: if Assigned(FOnMouseWheel) then FOnMouseWheel(Self);
    end;
  end;

  if (Message.Msg = TaskbarRestart) and FAutoReadd then AddToTray;
  Message.Result := DefWindowProc(FHandle, Message.Msg, Message.wParam, Message.lParam);
end;


initialization
  Randomize;
  TaskbarRestart := RegisterWindowMessage('TaskbarCreated');
  ChangeWindowMessageFilter(TaskbarRestart, 1);
end.
