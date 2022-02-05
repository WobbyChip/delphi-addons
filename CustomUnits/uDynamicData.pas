unit uDynamicData;

interface

uses
  Windows, Classes, Dialogs, Variants, TypInfo, Registry, MMSystem, uKBDynamic, Functions;

const
  varArrayOfByte = 8209;
  varArrayOfInt = 8195;
  varArrayOfFloat = 8197;
  varArrayOfString = 8200;

type
  TArrayOfByte = array of Byte;
  TArrayOfInt = array of Integer;
  TArrayOfFloat = array of Double;
  TArrayOfString = array of WideString;

type
  TDynamicValue_ = record
    Name: WideString;
    DataType: Integer;

    DataInt: Int64;
    DataFloat: Double;
    DataString: WideString;

    ArrayOfByte: TArrayOfByte;
    ArrayOfInt: TArrayOfInt;
    ArrayOfFloat: TArrayOfFloat;
    ArrayOfString: TArrayOfString;
  end;

  TDynamicList_ = array of array of TDynamicValue_;

type
  TDynamicData = class
    public
      doCompress: Boolean;
      doRemoveUnsued: Boolean;
      lOptions: TKBDynamicOptions;
      DynamicValues: array of WideString;
      DynamicData: TDynamicList_;

      constructor Create(doCompress, doRemoveUnsued: Boolean; DynamicValues: array of WideString);
      destructor Destroy; override;
      function Load(ROOT_KEY: DWORD; KEY, Value: String; onFailDelete: Boolean): Boolean; overload;
      function Load(FileName: WideString; onFailDelete: Boolean): Boolean; overload;
      procedure Save(ROOT_KEY: DWORD; KEY, Value: String); overload;
      procedure Save(FileName: WideString); overload;
      function GetLength: Integer;

      function GetValue(Index: Integer; Name: WideString): Variant;
      procedure SetValue(Index: Integer; Name: WideString; Value: Variant);
      procedure ClearValue(Index, SubIndex: Integer);
      procedure DeleteValue(Index: Integer; Name: WideString);

      procedure SetValueArray(Index: Integer; Name: WideString; ArrayOfByte: TArrayOfByte); overload;
      procedure SetValueArray(Index: Integer; Name: WideString; ArrayOfInt: TArrayOfInt); overload;
      procedure SetValueArray(Index: Integer; Name: WideString; ArrayOfFloat: TArrayOfFloat); overload;
      procedure SetValueArray(Index: Integer; Name: WideString; ArrayOfString: TArrayOfString); overload;

      function GetValueArrayByte(Index: Integer; Name: WideString): TArrayOfByte;
      function GetValueArrayInt(Index: Integer; Name: WideString): TArrayOfInt;
      function GetValueArrayFloat(Index: Integer; Name: WideString): TArrayOfFloat;
      function GetValueArrayString(Index: Integer; Name: WideString): TArrayOfString;

      function CreateData(Index: Integer): Integer;
      procedure DeleteData(Index: Integer);
      procedure ResetData;
    private
      procedure RemoveUnused(Index: Integer);
      procedure RemoveUnusedAtIndex(idx1, idx2: Integer);
  end;

implementation

constructor TDynamicData.Create(doCompress, doRemoveUnsued: Boolean; DynamicValues: array of WideString);
var
  i: Integer;
begin
  inherited Create;
  self.doCompress := doCompress;
  self.doRemoveUnsued := doRemoveUnsued;
  SetLength(self.DynamicValues, Length(DynamicValues));

  lOptions := [
    kdoAnsiStringCodePage

    {$IFDEF KBDYNAMIC_DEFAULT_UTF8}
    ,kdoUTF16ToUTF8
    {$ENDIF}

    {$IFDEF KBDYNAMIC_DEFAULT_CPUARCH}
    ,kdoCPUArchCompatibility
    {$ENDIF}
  ];

  for i := 0 to Length(DynamicValues)-1 do begin
    self.DynamicValues[i] := DynamicValues[i];
  end;
end;


destructor TDynamicData.Destroy;
begin
  ZeroMemory(@self.DynamicData, SizeOf(self.DynamicData));
  SetLength(self.DynamicData, 0);
  inherited Destroy;
end;


procedure TDynamicData.RemoveUnusedAtIndex(idx1, idx2: Integer);
var
  i, ArrayLength: Integer;
begin
  ArrayLength := Length(self.DynamicData[idx1]);

  if idx2 = ArrayLength-1 then begin
    SetLength(self.DynamicData[idx1], ArrayLength-1);
    Exit;
  end;

  for i := idx2 to Length(self.DynamicData[idx1])-2 do begin
    self.DynamicData[idx1][idx2] := self.DynamicData[idx1][idx2+1];
  end;

  SetLength(self.DynamicData[idx1], ArrayLength-1);
end;

procedure TDynamicData.RemoveUnused(Index: Integer);
var
  j, l: Integer;
  S: WideString;
  b: Boolean;
begin
  for j := 0 to Length(self.DynamicData[Index])-1 do begin
    S := self.DynamicData[Index][j].Name;
    b := False;

    for l := 0 to Length(self.DynamicValues)-1 do begin
      b := (S = self.DynamicValues[l]);
      if b then Break;
    end;

    if not b then begin
      RemoveUnusedAtIndex(Index, j);
      RemoveUnused(Index);
      Exit;
    end;
  end;
end;


function TDynamicData.Load(ROOT_KEY: DWORD; KEY, Value: String; onFailDelete: Boolean): Boolean;
var
  MemoryStream: TMemoryStream;
  Registry: TRegistry;
  i: Integer;
begin
  Result := True;
  Registry := TRegistry.Create;
  Registry.RootKey := ROOT_KEY;
  Registry.OpenKey(KEY, True);

  if Registry.ValueExists(Value) then begin
    MemoryStream := TMemoryStream.Create;
    MemoryStream.SetSize(Registry.GetDataSize(Value));
    Registry.ReadBinaryData(Value, MemoryStream.Memory^, MemoryStream.Size);

    try
      if doCompress then DecompressStream(MemoryStream);
      TKBDynamic.ReadFrom(MemoryStream, self.DynamicData, TypeInfo(TDynamicList_), 1);
      MemoryStream.Free;
    except
      Result := False;
      PlaySound('SystemExclamation', 0, SND_ASYNC);
      ShowMessage('There was an error loading data.');
      ZeroMemory(@self.DynamicData, SizeOf(self.DynamicData));
      SetLength(self.DynamicData, 0);
      if onFailDelete then Registry.DeleteValue(Value);
    end;
  end;

  Registry.Free;

  //Clear non used values
  if doRemoveUnsued then begin
    for i := 0 to Length(self.DynamicData)-1 do begin
      RemoveUnused(i);
    end;
  end;
end;


function TDynamicData.Load(FileName: WideString; onFailDelete: Boolean): Boolean;
var
  MemoryStream: TMemoryStream;
  i: Integer;
begin
  Result := True;
  MemoryStream := TMemoryStream.Create;
  WriteFileToStream(MemoryStream, FileName);

  if MemoryStream.Size > 0 then begin
    try
      if doCompress then DecompressStream(MemoryStream);
      TKBDynamic.ReadFrom(MemoryStream, self.DynamicData, TypeInfo(TDynamicList_), 1);
    except
      Result := False;
      PlaySound('SystemExclamation', 0, SND_ASYNC);
      ShowMessage('There was an error loading data.');
      ZeroMemory(@self.DynamicData, SizeOf(self.DynamicData));
      SetLength(self.DynamicData, 0);
      if onFailDelete then DeleteFileW(PWideChar(FileName));
    end;
  end;

  MemoryStream.Free;

  //Clear non used values
  if doRemoveUnsued then begin
    for i := 0 to Length(self.DynamicData)-1 do begin
      RemoveUnused(i);
    end;
  end;
end;


procedure TDynamicData.Save(ROOT_KEY: DWORD; KEY, Value: String);
var
  MemoryStream: TMemoryStream;
  lOptions: TKBDynamicOptions;
  Registry: TRegistry;
begin
  MemoryStream := TMemoryStream.Create;
  TKBDynamic.WriteTo(MemoryStream, self.DynamicData, TypeInfo(TDynamicList_), 1, lOptions);
  if doCompress then CompressStream(MemoryStream);

  Registry := TRegistry.Create;
  Registry.RootKey := ROOT_KEY;
  Registry.OpenKey(KEY, True);
  Registry.WriteBinaryData(Value, MemoryStream.Memory^, MemoryStream.Size);
  Registry.Free;

  MemoryStream.Free;
end;


procedure TDynamicData.Save(FileName: WideString);
var
  MemoryStream: TMemoryStream;
begin
  MemoryStream := TMemoryStream.Create;
  TKBDynamic.WriteTo(MemoryStream, self.DynamicData, TypeInfo(TDynamicList_), 1, lOptions);
  if doCompress then CompressStream(MemoryStream);
  WriteStreamToFile(MemoryStream, FileName);
  MemoryStream.Free;
end;


function TDynamicData.GetLength: Integer;
begin
  Result := Length(self.DynamicData);
end;


function TDynamicData.GetValue(Index: Integer; Name: WideString): Variant;
var
  i: Integer;
begin
  Result := Null;
  if Index >= Length(self.DynamicData) then Exit;

  for i := 0 to Length(self.DynamicData[Index])-1 do begin
    if self.DynamicData[Index][i].Name = Name then begin
      case self.DynamicData[Index][i].DataType and VarTypeMask of
        varSmallInt: Result := SmallInt(self.DynamicData[Index][i].DataInt);
        varInteger: Result := Integer(self.DynamicData[Index][i].DataInt);
        varBoolean: Result := Boolean(self.DynamicData[Index][i].DataInt);
        varByte: Result := Byte(self.DynamicData[Index][i].DataInt);
        varWord: Result := Word(self.DynamicData[Index][i].DataInt);
        varLongWord: Result := LongWord(self.DynamicData[Index][i].DataInt);
        varShortInt: Result := ShortInt(self.DynamicData[Index][i].DataInt);
        varInt64: Result := Int64(self.DynamicData[Index][i].DataInt);

        varSingle: Result := self.DynamicData[Index][i].DataFloat;
        varDouble: Result := self.DynamicData[Index][i].DataFloat;
        varDate: Result := TDateTime(self.DynamicData[Index][i].DataFloat);
        varCurrency: Result := self.DynamicData[Index][i].DataFloat;

        varOleStr: Result := WideString(self.DynamicData[Index][i].DataString);
        varString: Result := String(self.DynamicData[Index][i].DataString);
      end;

      Break;
    end;
  end;
end;


procedure TDynamicData.SetValue(Index: Integer; Name: WideString; Value: Variant);
var
  i, l: Integer;
begin
  if Index >= Length(self.DynamicData) then Exit;
  l := Length(self.DynamicData[Index]);

  for i := 0 to l do begin
    if i = l then SetLength(self.DynamicData[Index], i+1);
    if (i < l) and (self.DynamicData[Index][i].Name = Name) then Break;
  end;

  if i >= l then i := i-1;
  self.DynamicData[Index][i].Name := Name;
  ClearValue(Index, i);
  self.DynamicData[Index][i].DataType := VarType(Value);

  case VarType(Value) and VarTypeMask of
    varSmallInt: self.DynamicData[Index][i].DataInt := Value;
    varInteger: self.DynamicData[Index][i].DataInt := Value;
    varBoolean: self.DynamicData[Index][i].DataInt := Value;
    varByte: self.DynamicData[Index][i].DataInt := Value;
    varWord: self.DynamicData[Index][i].DataInt := Value;
    varLongWord: self.DynamicData[Index][i].DataInt := Value;
    varShortInt: self.DynamicData[Index][i].DataInt := Value;
    varInt64: self.DynamicData[Index][i].DataInt := Value;

    varSingle: self.DynamicData[Index][i].DataFloat := Value;
    varDouble: self.DynamicData[Index][i].DataFloat := Value;
    varDate: self.DynamicData[Index][i].DataFloat := Value;
    varCurrency: self.DynamicData[Index][i].DataFloat := Value;

    varOleStr: self.DynamicData[Index][i].DataString := Value;
    varString: self.DynamicData[Index][i].DataString := Value;
  end;
end;


procedure TDynamicData.SetValueArray(Index: Integer; Name: WideString; ArrayOfByte: TArrayOfByte);
var
  i, l: Integer;
begin
  if Index >= Length(self.DynamicData) then Exit;
  l := Length(self.DynamicData[Index]);

  for i := 0 to l do begin
    if i = l then SetLength(self.DynamicData[Index], i+1);
    if (i < l) and (self.DynamicData[Index][i].Name = Name) then Break;
  end;

  if i >= l then i := i-1;
  self.DynamicData[Index][i].Name := Name;
  ClearValue(Index, i);
  self.DynamicData[Index][i].DataType := 0;
  self.DynamicData[Index][i].ArrayOfByte := ArrayOfByte;
end;


procedure TDynamicData.SetValueArray(Index: Integer; Name: WideString; ArrayOfInt: TArrayOfInt);
var
  i, l: Integer;
begin
  if Index >= Length(self.DynamicData) then Exit;
  l := Length(self.DynamicData[Index]);

  for i := 0 to l do begin
    if i = l then SetLength(self.DynamicData[Index], i+1);
    if (i < l) and (self.DynamicData[Index][i].Name = Name) then Break;
  end;

  if i >= l then i := i-1;
  self.DynamicData[Index][i].Name := Name;
  ClearValue(Index, i);
  self.DynamicData[Index][i].DataType := 0;
  self.DynamicData[Index][i].ArrayOfInt := ArrayOfInt;
end;


procedure TDynamicData.SetValueArray(Index: Integer; Name: WideString; ArrayOfFloat: TArrayOfFloat);
var
  i, l: Integer;
begin
  if Index >= Length(self.DynamicData) then Exit;
  l := Length(self.DynamicData[Index]);

  for i := 0 to l do begin
    if i = l then SetLength(self.DynamicData[Index], i+1);
    if (i < l) and (self.DynamicData[Index][i].Name = Name) then Break;
  end;

  if i >= l then i := i-1;
  self.DynamicData[Index][i].Name := Name;
  ClearValue(Index, i);
  self.DynamicData[Index][i].DataType := 0;
  self.DynamicData[Index][i].ArrayOfFloat := ArrayOfFloat;
end;


procedure TDynamicData.SetValueArray(Index: Integer; Name: WideString; ArrayOfString: TArrayOfString);
var
  i, l: Integer;
begin
  if Index >= Length(self.DynamicData) then Exit;
  l := Length(self.DynamicData[Index]);

  for i := 0 to l do begin
    if i = l then SetLength(self.DynamicData[Index], i+1);
    if (i < l) and (self.DynamicData[Index][i].Name = Name) then Break;
  end;

  if i >= l then i := i-1;
  self.DynamicData[Index][i].Name := Name;
  ClearValue(Index, i);
  self.DynamicData[Index][i].DataType := 0;
  self.DynamicData[Index][i].ArrayOfString := ArrayOfString;
end;


function TDynamicData.GetValueArrayByte(Index: Integer; Name: WideString): TArrayOfByte;
var
  i: Integer;
begin
  Result := nil;
  if Index >= Length(self.DynamicData) then Exit;

  for i := 0 to Length(self.DynamicData[Index])-1 do begin
    if self.DynamicData[Index][i].Name = Name then begin
      Result := self.DynamicData[Index][i].ArrayOfByte;
      Break;
    end;
  end;
end;


function TDynamicData.GetValueArrayInt(Index: Integer; Name: WideString): TArrayOfInt;
var
  i: Integer;
begin
  Result := nil;
  if Index >= Length(self.DynamicData) then Exit;

  for i := 0 to Length(self.DynamicData[Index])-1 do begin
    if self.DynamicData[Index][i].Name = Name then begin
      Result := self.DynamicData[Index][i].ArrayOfInt;
      Break;
    end;
  end;
end;


function TDynamicData.GetValueArrayFloat(Index: Integer; Name: WideString): TArrayOfFloat;
var
  i: Integer;
begin
  Result := nil;
  if Index >= Length(self.DynamicData) then Exit;

  for i := 0 to Length(self.DynamicData[Index])-1 do begin
    if self.DynamicData[Index][i].Name = Name then begin
      Result := self.DynamicData[Index][i].ArrayOfFloat;
      Break;
    end;
  end;
end;


function TDynamicData.GetValueArrayString(Index: Integer; Name: WideString): TArrayOfString;
var
  i: Integer;
begin
  Result := nil;
  if Index >= Length(self.DynamicData) then Exit;

  for i := 0 to Length(self.DynamicData[Index])-1 do begin
    if self.DynamicData[Index][i].Name = Name then begin
      Result := self.DynamicData[Index][i].ArrayOfString;
      Break;
    end;
  end;
end;


procedure TDynamicData.ClearValue(Index, SubIndex: Integer);
begin
  self.DynamicData[Index][SubIndex].DataType := 0;

  self.DynamicData[Index][SubIndex].DataInt := 0;
  self.DynamicData[Index][SubIndex].DataFloat := 0;
  self.DynamicData[Index][SubIndex].DataString := '';

  SetLength(self.DynamicData[Index][SubIndex].ArrayOfByte, 0);
  SetLength(self.DynamicData[Index][SubIndex].ArrayOfInt, 0);
  SetLength(self.DynamicData[Index][SubIndex].ArrayOfFloat, 0);
  SetLength(self.DynamicData[Index][SubIndex].ArrayOfString, 0);
end;


procedure TDynamicData.DeleteValue(Index: Integer; Name: WideString);
var
  i: Integer;
begin
  if Index >= Length(self.DynamicData) then Exit;

  for i := 0 to Length(self.DynamicData[Index])-1 do begin
    if self.DynamicData[Index][i].Name = Name then begin
      ClearValue(Index, i);
      RemoveUnusedAtIndex(Index, i);
    end;
  end;
end;


function TDynamicData.CreateData(Index: Integer): Integer;
var
  i: Integer;
begin
  SetLength(self.DynamicData, Length(self.DynamicData)+1);

  if (Index = -1) then begin
    Result := Length(self.DynamicData)-1;
    Exit;
  end;

  for i := Length(self.DynamicData)-1 downto Index+1 do begin
    self.DynamicData[i] := self.DynamicData[i-1];
  end;

  Result := Index;
  SetLength(self.DynamicData[Index], 0);
end;


procedure TDynamicData.DeleteData(Index: Integer);
var
  i: Integer;
begin
  if (Index = Length(self.DynamicData)-1) then begin
    SetLength(self.DynamicData, Length(self.DynamicData)-1);
    Exit;
  end;

  for i := Index to Length(self.DynamicData)-2 do begin
    self.DynamicData[i] := self.DynamicData[i+1];
  end;

  SetLength(self.DynamicData, Length(self.DynamicData)-1);
end;


procedure TDynamicData.ResetData;
begin
  SetLength(self.DynamicData, 0);
end;


end.