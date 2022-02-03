unit CustoRegister;

interface

uses
  Classes;

procedure Register;

implementation

uses
  CustoBevel, CustoHotKey, CustoTrayIcon;

procedure Register;
begin
  RegisterComponents('CustomComponenets', [TCustoHotKey]);
  RegisterComponents('CustomComponenets', [TCustoBevel]);
  RegisterComponents('CustomComponenets', [TTrayIcon]);
end;

end.
