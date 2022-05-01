unit CustoHotKey;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, ComCtrls, Menus;

type
  TCustoHotKey = class(THotKey)
  private
    FCanvas: TCanvas;
    FBorderColor: TColor;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
  protected
    procedure Paint; virtual;
    procedure PaintWindow(DC: HDC); override;
    property Canvas: TCanvas read FCanvas;
  public
    procedure ChangeRectangleBy(x: Integer);
    procedure SetBorderColor(Color: TColor);
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Color;
    property Font;
    property Brush;
  end;

implementation

constructor TCustoHotKey.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCanvas := TControlCanvas.Create;
  TControlCanvas(FCanvas).Control := Self;
  FBorderColor := clNone;
end;


destructor TCustoHotKey.Destroy;
begin
  FCanvas.Free;
  inherited Destroy;
end;


procedure TCustoHotKey.WMPaint(var Message: TWMPaint);
begin
  ControlState := ControlState + [csCustomPaint];
  inherited;
  ControlState := ControlState - [csCustomPaint];
end;


procedure TCustoHotKey.PaintWindow(DC: HDC);
begin
  FCanvas.Lock;
  try
    FCanvas.Handle := DC;
    try
      TControlCanvas(FCanvas).UpdateTextFlags;
      Paint;
    finally
      FCanvas.Handle := 0;
    end;
  finally
    FCanvas.Unlock;
  end;
end;


procedure TCustoHotKey.Paint;
var
  CV: TCanvas;
  DC: HDC;
  Rect: TRect;
  Flags: LongInt;
  S: String;
begin
  Canvas.Font := Font;
  S := Menus.ShortCutToText(HotKey);
  if S = '' then S := 'None';
  Rect := ClientRect;
  Flags := DrawTextBiDiModeFlags(DT_SINGLELINE or DT_VCENTER);
  DrawText(Canvas.Handle, PChar(S), Length(S), Rect, Flags or DT_CALCRECT);
  Canvas.Brush.Color := Color;
  DrawText(Canvas.Handle, PChar(S), Length(S), Rect, Flags);
  if Focused then SetCaretPos(Rect.Right, Rect.Top);

  if FBorderColor <> clNone then begin
    DC := GetWindowDC(Self.Handle);
    CV := TCanvas.Create;

    try
      CV.Handle := DC;
      CV.Lock;
      CV.Brush.Style := bsClear;
      CV.Pen.Color := Self.Color;
      CV.Rectangle(1, 1, Width-1, Height-1);
      CV.Pen.Color := FBorderColor;
      CV.Rectangle(0, 0, Width, Height);
    finally
      CV.Unlock;
      CV.Free;
    end;

    RestoreDC(DC, -1);
    ReleaseDC(Handle, DC);
  end;
end;


procedure TCustoHotKey.ChangeRectangleBy(x: Integer);
begin
  SetWindowRgn(Self.Handle, CreateRectRgn(x, x, Width - x, Height - x), True);
end;

procedure TCustoHotKey.SetBorderColor(Color: TColor);
begin
  FBorderColor := Color;
  Self.Repaint;
end;

end.
