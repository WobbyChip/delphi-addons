unit CustoBevel;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, ExtCtrls, Menus;

type
  TCustoBevel = class(TBevel)
  private
    FCanvas: TCanvas;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
  protected
    property Canvas: TCanvas read FCanvas;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Color;
  end;

implementation

constructor TCustoBevel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCanvas := TControlCanvas.Create;
  TControlCanvas(FCanvas).Control := Self;
  Shape := bsFrame;
  Color := clBlack;
end;

destructor TCustoBevel.Destroy;
begin
  FCanvas.Free;
  inherited Destroy;
end;

procedure TCustoBevel.WMPaint(var Message: TWMPaint);
begin
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := Self.Color;
  Canvas.Rectangle(0, 0, Width, Height);
end;

end.
