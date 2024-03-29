unit TFlatCheckBoxUnit;

interface

{$I DFS.inc}

uses
  Windows, Messages, Classes, Graphics, Controls, Forms, ExtCtrls, FlatUtilitys;

type
  TFlatCheckBox = class(TCustomControl)
  private
    FUseAdvColors: Boolean;
    FAdvColorFocused: TAdvColors;
    FAdvColorDown: TAdvColors;
    FAdvColorBorder: TAdvColors;
    FMouseInControl: Boolean;
    MouseIsDown: Boolean;
    Focused: Boolean;
    FLayout: TCheckBoxLayout;
    FChecked: Boolean;
    FFocusedColor: TColor;
    FDownColor: TColor;
    FCheckColor: TColor;
    FBorderColor: TColor;
    FTransparent: Boolean;
    procedure SetColors (Index: Integer; Value: TColor);
    procedure SetAdvColors (Index: Integer; Value: TAdvColors);
    procedure SetUseAdvColors (Value: Boolean);
    procedure SetLayout (Value: TCheckBoxLayout);
    procedure SetChecked (Value: Boolean);
    procedure SetTransparent(const Value: Boolean);
    procedure CMEnabledChanged (var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged (var Message: TWmNoParams); message CM_TEXTCHANGED;
    procedure CMDialogChar (var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CNCommand (var Message: TWMCommand); message CN_COMMAND;
    procedure WMSetFocus (var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus (var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure CMSysColorChange (var Message: TMessage); message CM_SYSCOLORCHANGE;
    procedure CMParentColorChanged (var Message: TWMNoParams); message CM_PARENTCOLORCHANGED;
    procedure RemoveMouseTimer;
    procedure MouseTimerHandler (Sender: TObject);
    procedure CMDesignHitTest (var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure WMSize (var Message: TWMSize); message WM_SIZE;
    procedure WMMove (var Message: TWMMove); message WM_MOVE;
  protected
    procedure CalcAdvColors;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure MouseDown (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp (Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove (Shift: TShiftState; X, Y: Integer); override;
    procedure CreateWnd; override;
    procedure DrawCheckRect;
    procedure DrawCheckText;
    procedure Paint; override;
   {$IFDEF DFS_COMPILER_4_UP}
    procedure SetBiDiMode(Value: TBiDiMode); override;
   {$ENDIF}
  public
    constructor Create (AOwner: TComponent); override;
    destructor Destroy; override;
    procedure MouseEnter;
    procedure MouseLeave;
  published
    property Transparent: Boolean read FTransparent write SetTransparent default false;
    property Caption;
    property Checked: Boolean read FChecked write SetChecked default false;
    property Color default $00E1EAEB;
    property ColorFocused: TColor index 0 read FFocusedColor write SetColors default clWhite;
    property ColorDown: TColor index 1 read FDownColor write SetColors default $00C5D6D9;
    property ColorCheck: TColor index 2 read FCheckColor write SetColors default clBlack;
    property ColorBorder: TColor index 3 read FBorderColor write SetColors default $008396A0;
    property AdvColorFocused: TAdvColors index 0 read FAdvColorFocused write SetAdvColors default 10;
    property AdvColorDown: TAdvColors index 1 read FAdvColorDown write SetAdvColors default 10;
    property AdvColorBorder: TAdvColors index 2 read FAdvColorBorder write SetAdvColors default 50;
    property UseAdvColors: Boolean read FUseAdvColors write SetUseAdvColors default false;
    property Enabled;
    property Font;
    property Layout: TCheckBoxLayout read FLayout write SetLayout default checkBoxLeft;
    property ParentColor;
    property ParentFont;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
   {$IFDEF DFS_COMPILER_4_UP}
    property Action;
    property Anchors;
    property BiDiMode write SetBidiMode;
    property Constraints;
    property DragKind;
    property ParentBiDiMode;
    property OnEndDock;
    property OnStartDock;
   {$ENDIF}
  end;

var
  MouseInControl: TFlatCheckBox = nil;

implementation

var
  MouseTimer: TTimer = nil;
  ControlCounter: Integer = 0;

procedure TFlatCheckBox.CMDesignHitTest(var Message: TCMDesignHitTest);
begin
  case FLayout of
    checkboxLeft:
      if PtInRect(Rect(ClientRect.Left + 1, ClientRect.Top + 3, ClientRect.Left + 12, ClientRect.Top + 14), Point(message.XPos, message.YPos)) then
        Message.Result := 1
      else
        Message.Result := 0;
    checkboxRight:
      if PtInRect(Rect(ClientRect.Right - 12, ClientRect.Top + 3, ClientRect.Right - 1, ClientRect.Top + 14), Point(message.XPos, message.YPos)) then
        Message.Result := 1
      else
        Message.Result := 0;
  end;
end;

constructor TFlatCheckBox.Create (AOwner: TComponent);
begin
  inherited Create(AOwner);
  if MouseTimer = nil then
  begin
    MouseTimer := TTimer.Create(nil);
    MouseTimer.Enabled := False;
    MouseTimer.Interval := 100; // 10 times a second
  end;
  ParentColor := True;
  ParentFont := True;
  FFocusedColor := clWhite;
  FDownColor := $00C5D6D9;
  FCheckColor := clBlack;
  FBorderColor := $008396A0;
  FLayout := checkboxLeft;
  TabStop := True;
  FChecked := false;
  Enabled := true;
  Visible := true;
  SetBounds(0, 0, 121, 17);
  FUseAdvColors := false;
  FAdvColorFocused := 10;
  FAdvColorDown := 10;
  FAdvColorBorder := 50;
  Inc(ControlCounter);
end;

destructor TFlatCheckBox.Destroy;
begin
  RemoveMouseTimer;
  Dec(ControlCounter);
  if ControlCounter = 0 then
  begin
    MouseTimer.Free;
    MouseTimer := nil;
  end;
  inherited;
end;

procedure TFlatCheckBox.SetColors (Index: Integer; Value: TColor);
begin
  case Index of
    0: FFocusedColor := Value;
    1: FDownColor := Value;
    2: FCheckColor := Value;
    3: FBorderColor := Value;
  end;
  Invalidate;
end;

procedure TFlatCheckBox.CalcAdvColors;
begin
  if FUseAdvColors then
  begin
    FFocusedColor := CalcAdvancedColor(Color, FFocusedColor, FAdvColorFocused, lighten);
    FDownColor := CalcAdvancedColor(Color, FDownColor, FAdvColorDown, darken);
    FBorderColor := CalcAdvancedColor(Color, FBorderColor, FAdvColorBorder, darken);
  end;
end;

procedure TFlatCheckBox.SetAdvColors (Index: Integer; Value: TAdvColors);
begin
  case Index of
    0: FAdvColorFocused := Value;
    1: FAdvColorDown := Value;
    2: FAdvColorBorder := Value;
  end;
  CalcAdvColors;
  Invalidate;
end;

procedure TFlatCheckBox.SetUseAdvColors (Value: Boolean);
begin
  if Value <> FUseAdvColors then
  begin
    FUseAdvColors := Value;
    ParentColor := Value;
    CalcAdvColors;
    Invalidate;
  end;
end;

procedure TFlatCheckBox.SetLayout (Value: TCheckBoxLayout);
begin
  FLayout := Value;
  Invalidate;
end;

procedure TFlatCheckBox.SetChecked (Value: Boolean);
begin
  if FChecked <> Value then
  begin
    FChecked := Value;
    Click; //This is causing twice click event
    DrawCheckRect;
    if csDesigning in ComponentState then
      if (GetParentForm(self) <> nil) and (GetParentForm(self).Designer <> nil) then
        GetParentForm(self).Designer.Modified;
  end;
end;

procedure TFlatCheckBox.CMEnabledChanged (var Message: TMessage);
begin
  inherited;
  if not Enabled then
  begin
    FMouseInControl := False;
    MouseIsDown := False;
    RemoveMouseTimer;
  end;
  Invalidate;
end;

procedure TFlatCheckBox.CMTextChanged (var Message: TWmNoParams);
begin
  inherited;
  Invalidate;
end;

procedure TFlatCheckBox.MouseEnter;
begin
  if Enabled and not FMouseInControl then
  begin
    FMouseInControl := True;
    DrawCheckRect;
  end;
end;

procedure TFlatCheckBox.MouseLeave;
begin
  if Enabled and FMouseInControl and not MouseIsDown then
  begin
    FMouseInControl := False;
    RemoveMouseTimer;
    DrawCheckRect;
  end;
end;

procedure TFlatCheckBox.CMDialogChar (var Message: TCMDialogChar);
begin
  with Message do
    if IsAccel(Message.CharCode, Caption) and CanFocus then
    begin
      SetFocus;
      Checked := not Checked;
      Result := 1;
    end
    else
      if (CharCode = VK_SPACE) and Focused then
      begin
        Checked := not Checked;
      end
      else
        inherited;
end;

procedure TFlatCheckBox.CNCommand (var Message: TWMCommand);
begin
  if Message.NotifyCode = BN_CLICKED then Click;
end;

procedure TFlatCheckBox.WMSetFocus (var Message: TWMSetFocus);
begin
  inherited;
  if Enabled then
  begin
    Focused := True;
    DrawCheckRect;
  end;
end;

procedure TFlatCheckBox.WMKillFocus (var Message: TWMKillFocus);
begin
  inherited;
  if Enabled then
  begin
    //FMouseInControl := False;
    Focused := False;
    DrawCheckRect;
  end;
end;

procedure TFlatCheckBox.CMSysColorChange (var Message: TMessage);
begin
  if FUseAdvColors then
  begin
    ParentColor := True;
    CalcAdvColors;
  end;
  Invalidate;
end;

procedure TFlatCheckBox.CMParentColorChanged (var Message: TWMNoParams);
begin
  inherited;
  if FUseAdvColors then
  begin
    ParentColor := True;
    CalcAdvColors;
  end;
  Invalidate;
end;

procedure TFlatCheckBox.DoEnter;
begin
  inherited DoEnter;
  Focused := True;
  DrawCheckRect;
end;

procedure TFlatCheckBox.DoExit;
begin
  inherited DoExit;
  Focused := False;
  DrawCheckRect;
end;

procedure TFlatCheckBox.MouseDown (Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and Enabled then
  begin
    SetFocus;
    MouseIsDown := true;
    DrawCheckRect;
    inherited MouseDown(Button, Shift, X, Y);
  end;
end;

//Here is happening twice fire event
procedure TFlatCheckBox.MouseUp (Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and Enabled then
  begin
    MouseIsDown := false;
    if FMouseInControl then begin
      FChecked := not FChecked;
      DrawCheckRect;
      if csDesigning in ComponentState then
        if (GetParentForm(self) <> nil) and (GetParentForm(self).Designer <> nil) then
          GetParentForm(self).Designer.Modified;
    end;
    DrawCheckRect;
    inherited MouseUp(Button, Shift, X, Y);
  end;
end;

procedure TFlatCheckBox.MouseMove (Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  inherited;
  // mouse is in control ?
  P := ClientToScreen(Point(X, Y));
  if (MouseInControl <> Self) and (FindDragTarget(P, True) = Self) then
  begin
    if Assigned(MouseInControl) then
      MouseInControl.MouseLeave;
    // the application is active ?
    if (GetActiveWindow <> 0) then
    begin
      if MouseTimer.Enabled then
        MouseTimer.Enabled := False;
      MouseInControl := Self;
      MouseTimer.OnTimer := MouseTimerHandler;
      MouseTimer.Enabled := True;
      MouseEnter;
    end;
  end;
end;

procedure TFlatCheckBox.CreateWnd;
begin
  inherited CreateWnd;
  SendMessage(Handle, BM_SETCHECK, Cardinal(FChecked), 0);
end;

procedure TFlatCheckBox.DrawCheckRect;
var
  CheckboxRect: TRect;
begin
  case FLayout of
    checkboxLeft:
      CheckboxRect := Rect(ClientRect.Left + 1, ClientRect.Top + 3, ClientRect.Left + 12, ClientRect.Top + 14);
    checkboxRight:
      CheckboxRect := Rect(ClientRect.Right - 12, ClientRect.Top + 3, ClientRect.Right - 1, ClientRect.Top + 14);
  end;

  canvas.pen.style := psSolid;
  canvas.pen.width := 1;
  // Background
  if Focused or FMouseInControl then
    if not MouseIsDown then
    begin
      canvas.brush.color := FFocusedColor;
      canvas.pen.color := FFocusedColor;
    end
    else
    begin
      canvas.brush.color := FDownColor;
      canvas.brush.color := FDownColor;
    end
  else
  begin
    canvas.brush.color := Color;
    canvas.pen.color := Color;
  end;
  canvas.FillRect(CheckboxRect);
  // Tick
  if Checked then
  begin
    if Enabled then
      canvas.pen.color := FCheckColor
    else
      canvas.pen.color := clBtnShadow;
    canvas.penpos := Point(CheckboxRect.left+2, CheckboxRect.top+4);
    canvas.lineto(CheckboxRect.left+6, CheckboxRect.top+8);
    canvas.penpos := Point(CheckboxRect.left+2, CheckboxRect.top+5);
    canvas.lineto(CheckboxRect.left+5, CheckboxRect.top+8);
    canvas.penpos := Point(CheckboxRect.left+2, CheckboxRect.top+6);
    canvas.lineto(CheckboxRect.left+5, CheckboxRect.top+9);
    canvas.penpos := Point(CheckboxRect.left+8, CheckboxRect.top+2);
    canvas.lineto(CheckboxRect.left+4, CheckboxRect.top+6);
    canvas.penpos := Point(CheckboxRect.left+8, CheckboxRect.top+3);
    canvas.lineto(CheckboxRect.left+4, CheckboxRect.top+7);
    canvas.penpos := Point(CheckboxRect.left+8, CheckboxRect.top+4);
    canvas.lineto(CheckboxRect.left+5, CheckboxRect.top+7);
  end;
  // Border
  canvas.brush.color := FBorderColor;
  canvas.FrameRect(CheckboxRect);
end;

procedure TFlatCheckBox.DrawCheckText;
var
  TextBounds: TRect;
  Format: UINT;
begin
  Format := DT_WORDBREAK;
  case FLayout of
    checkboxLeft:
    begin
      TextBounds := Rect(ClientRect.Left + 16, ClientRect.Top + 1, ClientRect.Right - 1, ClientRect.Bottom - 1);
      Format := Format or DT_LEFT;
    end;
    checkboxRight:
    begin
      TextBounds := Rect(ClientRect.Left + 1, ClientRect.Top + 1, ClientRect.Right - 16, ClientRect.Bottom - 1);
      Format := Format or DT_RIGHT;
    end;
  end;

  with Canvas do
  begin
    Brush.Style := bsClear;
    Font := Self.Font;
    if not Enabled then
    begin
      OffsetRect(TextBounds, 1, 1);
      Font.Color := clBtnHighlight;
      DrawText(Handle, PChar(Caption), Length(Caption), TextBounds, Format);
      OffsetRect(TextBounds, -1, -1);
      Font.Color := clBtnShadow;
      DrawText(Handle, PChar(Caption), Length(Caption), TextBounds, Format);
    end
    else
      DrawText(Handle, PChar(Caption), Length(Caption), TextBounds, Format);
  end;
end;

procedure TFlatCheckBox.Paint;
begin
  if FTransparent then
    DrawParentImage(Self, Self.Canvas);
  DrawCheckRect;
  DrawCheckText;
end;

procedure TFlatCheckBox.MouseTimerHandler (Sender: TObject);
var
  P: TPoint;
begin
  GetCursorPos (P);
  if FindDragTarget(P, True) <> Self then
    MouseLeave;
end;

procedure TFlatCheckBox.RemoveMouseTimer;
begin
  if MouseInControl = Self then
  begin
    MouseTimer.Enabled := False;
    MouseInControl := nil;
  end;
end;

procedure TFlatCheckBox.SetTransparent(const Value: Boolean);
begin
  FTransparent := Value;
  Invalidate;
end;

procedure TFlatCheckBox.WMMove(var Message: TWMMove);
begin
  inherited;
  if FTransparent then
    Invalidate;
end;

procedure TFlatCheckBox.WMSize(var Message: TWMSize);
begin
  inherited;
  if FTransparent then
    Invalidate;
end;

{$IFDEF DFS_COMPILER_4_UP}
procedure TFlatCheckBox.SetBiDiMode(Value: TBiDiMode);
begin
  inherited;
  if BidiMode = bdRightToLeft then
    Layout := checkboxRight
  else
    Layout := checkboxLeft;
end;
{$ENDIF}

end.
