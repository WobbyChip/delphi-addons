unit uWMI;

interface

uses
  ActiveX, Variants, WbemScripting_TLB;

function GetWMI(wmiHost, wmiRoot, wmiClass, wmiProperty: String; Index: Integer): OleVariant;
procedure SetWMI(wmiHost, wmiRoot, wmiClass, wmiProperty: String; Index: Integer; Value: OleVariant);

implementation

function GetWMI(wmiHost, wmiRoot, wmiClass, wmiProperty: String; Index: Integer): OleVariant;
var
  WbemLocator: TSWbemLocator;
  WbemServices: ISWbemServices;
  WbemObjectSet: ISWbemObjectSet;
  WbemObject: ISWbemObject;
  WbemProperty: ISWbemProperty;
  Enum: IEnumVariant;
  colItem: OleVariant;
  iValue, i: Cardinal;
begin
  WbemLocator := TSWbemLocator.Create(nil);
  WbemServices := WbemLocator.ConnectServer(wmiHost, wmiRoot, '', '', '', '', 0, nil);
  WbemObjectSet := WbemServices.ExecQuery('SELECT * FROM ' + wmiClass, 'WQL', wbemFlagReturnImmediately and wbemFlagForwardOnly, nil);
  Enum := (WbemObjectSet._NewEnum) as IEnumVariant;

  for i := 0 to Index do begin
    if Enum.Next(1, colItem, iValue) = S_OK then begin
      WbemObject := IUnknown(colItem) as ISWBemObject;
      colItem := Unassigned;
      WbemProperty := WbemObject.Properties_.Item(wmiProperty, 0);
      Result := WbemProperty.Get_Value;
    end;
  end;

  Enum := nil;
  WbemProperty := nil;
  WbemObject := nil;
  WbemObjectSet := nil;
  WbemServices := nil;
  WbemLocator.Destroy;
end;

procedure SetWMI(wmiHost, wmiRoot, wmiClass, wmiProperty: String; Index: Integer; Value: OleVariant);
var
  WbemLocator: TSWbemLocator;
  WbemServices: ISWbemServices;
  WbemObjectSet: ISWbemObjectSet;
  WbemObject: ISWbemObject;
  WbemProperty: ISWbemProperty;
  Enum: IEnumVariant;
  colItem: OleVariant;
  iValue, i: Cardinal;
begin
  WbemLocator := TSWbemLocator.Create(nil);
  WbemServices := WbemLocator.ConnectServer(wmiHost, wmiRoot, '', '', '', '', 0, nil);
  WbemObjectSet := WbemServices.ExecQuery('SELECT * FROM ' + wmiClass, 'WQL', wbemFlagReturnImmediately and wbemFlagForwardOnly, nil);
  Enum := (WbemObjectSet._NewEnum) as IEnumVariant;

  for i := 0 to Index do begin
    if Enum.Next(1, colItem, iValue) = S_OK then begin
      WbemObject := IUnknown(colItem) as ISWBemObject;
      colItem := Unassigned;
      WbemProperty := WbemObject.Properties_.Item(wmiProperty, 0);
    end;
  end;

  WbemProperty.Set_Value(Value);
  WbemObject.Put_(0, WbemProperty);

  Enum := nil;
  WbemProperty := nil;
  WbemObject := nil;
  WbemObjectSet := nil;
  WbemServices := nil;
  WbemLocator.Destroy;
end;

end.