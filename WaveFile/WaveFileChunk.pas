unit WaveFileChunk;

interface
uses
  Classes,MMSystem,SysUtils,Windows,xmldom, XMLIntf, msxmldom, XMLDoc,Math,WaveFile;

type
  TchunkRecord = Packed Record
    Name:Packed Array [0..3] of Char;
    Size:DWORD;
  end;
  TRIFFchunk = class;
  TBWFchunk = class;
  TFMTchunk = class;
  TDATAchunk = class;

  TWaveFMT = Class
    Private
      WaveFMTchunk:PWaveFormatEx;
      Function GetwFormatTag:Word;
      Function GetnChannels:Word;
      Function GetnSamplesPerSec:DWORD;
      Function GetnAvgBytesPerSec:DWORD;
      Function GetnBlockAlign:Word;
      Function GetwBitsPerSample:Word;
      Function GetcbSize:Word;
      Procedure SetwFormatTag(Value:Word);
      Procedure SetnChannels(Value:Word);
      Procedure SetnSamplesPerSec(Value:DWORD);
      Procedure SetnAvgBytesPerSec(Value:DWORD);
      Procedure SetnBlockAlign(Value:Word);
      Procedure SetwBitsPerSample(Value:Word);
      Procedure SetcbSize(Value:Word);
      Function GetWaveFormat:TWaveFormatEx;
      Procedure SetWaveFormat(Value:TWaveFormatEx);
    Public
      Property WaveFormat:TWaveFormatEx Read GetWaveFormat Write SetWaveFormat;
      Property wFormatTag: Word Read GetwFormatTag Write SetwFormatTag;
      Property nChannels: Word Read GetnChannels Write SetnChannels;
      Property nSamplesPerSec: DWORD Read GetnSamplesPerSec Write SetnSamplesPerSec;
      Property nAvgBytesPerSec: DWORD Read GetnAvgBytesPerSec Write SetnAvgBytesPerSec;
      Property nBlockAlign: Word Read GetnBlockAlign Write SetnBlockAlign;
      Property wBitsPerSample: Word Read GetwBitsPerSample Write SetwBitsPerSample;
      Property cbSize: Word Read GetcbSize Write SetcbSize;
      Constructor Create(WaveFMTchunk:PWaveFormatEx);

  end;
  Tchunk = Class
    Private
      chunkRecord:TchunkRecord;

    Protected
      Function GetName:String;Virtual;
      Function GetSize:DWORD;Virtual;
      Function GetData(Index:Int64):Byte;Virtual;Abstract;
      Procedure SetName(Value:String);Virtual;
      Procedure SetSize(Value:DWORD);Virtual;
      Procedure SetData(Index:Int64;Value:Byte);Virtual;Abstract;
      Procedure Finalize;Virtual;Abstract;
      Property Data[Index:Int64]:Byte Read GetData Write SetData;

    Public
      Property Name:String Read GetName;
      Property Size:DWORD Read GetSize;
      Constructor Create;Virtual;
      Destructor Destroy;Override;
      Function TotalSize:Int64;Virtual;abstract;
      Procedure Write(Stream: TStream; Index, Size: Int64); Virtual;
  end;

  TRIFFchunk = class(Tchunk)
    Private
      BWFchunk_Var:TBWFchunk;
      FMTchunk_Var:TFMTchunk;
      DATAchunk_Var:TDATAchunk;
    Public
      Constructor Create(BWFchunk:TBWFchunk;FMTchunk:TFMTchunk;DATAchunk:TDATAchunk);OverLoad;
      Procedure Write(Stream: TStream; Index, Size: Int64);Override;
      Procedure Finalize;
      Function TotalSize:Int64;Override;
  end;

  TBWFchunk = class(Tchunk)
    Private
      WaveBWFchunk:TWaveBWFchunk;
      WaveBWF_Var:TWaveBWF;
      CodingHistory:String;
      Active_Var:Boolean;
    Public
      Property WaveBWF:TWaveBWF Read WaveBWF_Var;
      Constructor Create;OverLoad;OverRide;
      Destructor Destroy;OverRide;
      Procedure Write(Stream: TStream; Index, Size: Int64);Override;
      Procedure Finalize;
      Function TotalSize:Int64;Override;
      Property Active:Boolean Read Active_Var Write Active_Var;
  end;

  TFMTchunk = class(Tchunk)
    Private
      WaveFMTchunk:TWaveFormatEx;
      WaveFMT_Var:TWaveFMT;
    Public
      //Procedure SetSize(Value:DWORD);Virtual;
      Property WaveFMT:TWaveFMT Read WaveFMT_Var;
      Constructor Create;Overload;OverRide;
      Destructor Destroy;OverRide;
      Procedure Write(Stream: TStream; Index, Size: Int64);Override;
      Function TotalSize:Int64;Override;
  end;

  TDATAchunk = class(Tchunk)
    Private
      FMTchunk:TFMTchunk;
    Public
    Procedure SetSize(Value:DWORD);Override;
    Procedure Write(Stream: TStream; Index, Size: Int64);Override;
    Procedure WriteData(var Buffer; Stream: TStream; Index, Size: Int64); Virtual;
    Constructor Create(FMTchunk:TFMTchunk);OverLoad;
    Function TotalSize:Int64;Override;
  end;

implementation

Constructor Tchunk.Create;
begin
  Inherited;
  chunkRecord.Name[0] := ' ';
  chunkRecord.Name[1] := ' ';
  chunkRecord.Name[2] := ' ';
  chunkRecord.Name[3] := ' ';
  chunkRecord.Size := 0;
end;

Destructor Tchunk.Destroy;
begin
  Inherited;
end;

Function Tchunk.GetName:String;
begin
  Setlength(Result,4);
  Result[1] := chunkRecord.Name[0];
  Result[2] := chunkRecord.Name[1];
  Result[3] := chunkRecord.Name[2];
  Result[4] := chunkRecord.Name[3];
end;

Function Tchunk.GetSize:DWORD;
begin
  Result := chunkRecord.Size;
end;


Procedure Tchunk.SetName(Value:String);
begin

  if Length(Value) <= 4 then
  begin
    case Length(Value) of
      0:
      begin
        chunkRecord.Name[0] := ' ';
        chunkRecord.Name[1] := ' ';
        chunkRecord.Name[2] := ' ';
        chunkRecord.Name[3] := ' ';
      end;
      1:
      begin
        chunkRecord.Name[0] := Value[1];
        chunkRecord.Name[1] := ' ';
        chunkRecord.Name[2] := ' ';
        chunkRecord.Name[3] := ' ';
      end;
      2:
      begin
        chunkRecord.Name[0] := Value[1];
        chunkRecord.Name[1] := Value[2];
        chunkRecord.Name[2] := ' ';
        chunkRecord.Name[3] := ' ';
      end;
      3:
      begin
        chunkRecord.Name[0] := Value[1];
        chunkRecord.Name[1] := Value[2];
        chunkRecord.Name[2] := Value[3];
        chunkRecord.Name[3] := ' ';
      end;
      4:
      begin
        chunkRecord.Name[0] := Value[1];
        chunkRecord.Name[1] := Value[2];
        chunkRecord.Name[2] := Value[3];
        chunkRecord.Name[3] := Value[4];
      end;
    end;
  end;
end;

Procedure Tchunk.SetSize(Value:DWORD);
begin
  chunkRecord.Size := Value;
end;

Procedure Tchunk.Write(Stream: TStream; Index, Size: Int64);
begin
  if Stream <> NIL then
  begin
    Stream.Seek(Index,soBeginning);
    Stream.Write(chunkRecord,Sizeof(TchunkRecord));
  end;
end;

Constructor TRIFFchunk.Create(BWFchunk:TBWFchunk;FMTchunk:TFMTchunk;DATAchunk:TDATAchunk);
begin
  Inherited Create;
  Self.SetName('RIFF');
  Self.BWFchunk_Var := BWFchunk;
  Self.FMTchunk_Var := FMTchunk;
  Self.DATAchunk_Var := DATAchunk;
end;

Procedure TRIFFchunk.Write(Stream: TStream; Index, Size: Int64);
var
  WAVEName: Packed Array[0..3] of char;
begin
  if Stream <> NIL then
  begin
    Self.Finalize;
    Inherited;
    WAVEName[0]:='W';
    WAVEName[1]:='A';
    WAVEName[2]:='V';
    WAVEName[3]:='E';
    Stream.Write(WAVEName, Sizeof(WAVEName));
  end;

end;

Procedure TRIFFchunk.Finalize;
begin
  Self.SetSize(4);
  if (Self.BWFchunk_Var <> NIL) then
  begin
    Self.SetSize(Self.Size+BWFchunk_Var.Size+8);
  end;
  if (Self.FMTchunk_Var <> NIL) then
  begin
    Self.SetSize(Self.Size+FMTchunk_Var.Size+8);
  end;
  if (Self.DATAchunk_Var <> NIL) then
  begin
    Self.SetSize(Self.Size+DATAchunk_Var.Size+8);
  end;
end;

Constructor TBWFchunk.Create;
begin
  Inherited;
  Self.SetName('bext');
  CodingHistory := '';
  Self.WaveBWF_Var := TWaveBWF.Create(@Self.WaveBWFchunk,CodingHistory);
  Self.SetSize(sizeof(TWaveBWFchunk));
  Active_Var := True;
end;

Destructor TBWFchunk.Destroy;
begin
  Self.WaveBWF_Var.Destroy;
  Inherited;
end;

Procedure TBWFchunk.Write(Stream: TStream; Index, Size: Int64);
var
  ZeroByte:Byte;
begin
  ZeroByte := 0;
  if Stream <> NIL then
  begin
    Self.Finalize;
    Inherited;
    Stream.Write(Self.WaveBWFchunk,Sizeof(Self.WaveBWFchunk));
    if CodingHistory <> '' then
    begin
      Stream.Write(CodingHistory[1],Length(CodingHistory));
      Stream.Write(ZeroByte,1);
    end;
  end;
end;

Procedure TBWFchunk.Finalize;
begin
  if CodingHistory <> '' then
    Self.SetSize(Self.Size+Length(Self.CodingHistory)+1)
  else
    Self.SetSize(Self.Size)
end;

Constructor TFMTchunk.Create;
begin
  Inherited;
  self.SetName('fmt');
  WaveFMT_Var := TWaveFMT.Create(@WaveFMTchunk);
  Self.SetSize(Sizeof(WaveFMTchunk));
end;

Destructor TFMTchunk.Destroy;
begin
  WaveFMT_Var.Destroy;
  Inherited;
end;

Procedure TFMTchunk.Write(Stream: TStream; Index, Size: Int64);
begin
  if Stream <> NIL then
  begin
    Inherited;
    Stream.Write(Self.WaveFMTchunk,Sizeof(Self.WaveFMTchunk));
  end;
end;

Constructor TDATAchunk.Create(FMTchunk:TFMTchunk);
begin
  Inherited Create;
  self.SetName('data');
  Self.FMTchunk := FMTchunk;
end;

Procedure TDATAchunk.SetSize(Value:DWORD);
begin
  Inherited;
end;

Procedure TDATAchunk.Write(Stream: TStream; Index, Size: Int64);
begin
  Inherited;
end;

Procedure TDATAchunk.WriteData(var Buffer; Stream: TStream; Index, Size: Int64);
begin
  if Stream <> NIL then
  begin
    Stream.Seek(Index, soBeginning);
    Stream.Write(Buffer, Size);
  end;
end;


Constructor TWaveFMT.Create(WaveFMTchunk:PWaveFormatEx);
begin
  Inherited Create;
  Self.WaveFMTchunk := WaveFMTchunk;
end;

Function TWaveFMT.GetwFormatTag:Word;
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Result := Self.WaveFMTchunk.wFormatTag;
  end;
end;

Function TWaveFMT.GetnChannels:Word;
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Result := Self.WaveFMTchunk.nChannels;
  end;
end;

Function TWaveFMT.GetnSamplesPerSec:DWORD;
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Result := Self.WaveFMTchunk.nSamplesPerSec;
  end;
end;

Function TWaveFMT.GetnAvgBytesPerSec:DWORD;
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Result := Self.WaveFMTchunk.nAvgBytesPerSec;
  end;
end;

Function TWaveFMT.GetnBlockAlign:Word;
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Result := Self.WaveFMTchunk.nBlockAlign;
  end;
end;

Function TWaveFMT.GetwBitsPerSample:Word;
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Result := Self.WaveFMTchunk.wBitsPerSample;
  end;
end;

Function TWaveFMT.GetcbSize:Word;
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Result := Self.WaveFMTchunk.cbSize;
  end;
end;

Procedure TWaveFMT.SetwFormatTag(Value:Word);
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Self.WaveFMTchunk.wFormatTag := Value;
  end;
end;

Procedure TWaveFMT.SetnChannels(Value:Word);
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Self.WaveFMTchunk.nChannels := Value;
  end;
end;

Procedure TWaveFMT.SetnSamplesPerSec(Value:DWORD);
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Self.WaveFMTchunk.nSamplesPerSec := Value;
  end;
end;

Procedure TWaveFMT.SetnAvgBytesPerSec(Value:DWORD);
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Self.WaveFMTchunk.nAvgBytesPerSec := Value;
  end;
end;

Procedure TWaveFMT.SetnBlockAlign(Value:Word);
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Self.WaveFMTchunk.nBlockAlign := Value;
  end;
end;

Procedure TWaveFMT.SetwBitsPerSample(Value:Word);
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Self.WaveFMTchunk.wBitsPerSample := Value;
  end;
end;

Procedure TWaveFMT.SetcbSize(Value:Word);
begin
  if Self.WaveFMTchunk <> NIL then
  begin
    Self.WaveFMTchunk.cbSize := Value;
  end;
end;

Function TWaveFMT.GetWaveFormat:TWaveFormatEx;
begin
  Result.wFormatTag := Self.wFormatTag;
  Result.nChannels := Self.nChannels;
  Result.nSamplesPerSec := Self.nSamplesPerSec;
  Result.nAvgBytesPerSec := Self.nAvgBytesPerSec;
  Result.nBlockAlign := Self.nBlockAlign;
  Result.wBitsPerSample := Self.wBitsPerSample;
  Result.cbSize := 0;

end;

Procedure TWaveFMT.SetWaveFormat(Value:TWaveFormatEx);
begin
  Self.wFormatTag := Value.wFormatTag;
  Self.nChannels := Value.nChannels;
  Self.nSamplesPerSec := Value.nSamplesPerSec;
  Self.nAvgBytesPerSec := Value.nAvgBytesPerSec;
  Self.nBlockAlign := Value.nBlockAlign;
  Self.wBitsPerSample := Value.wBitsPerSample;
end;

Function TRIFFchunk.TotalSize:Int64;
begin
  Result := 12;
end;

Function TBWFchunk.TotalSize:Int64;
begin
  if Active_Var then
  begin
    Result := Self.Size + 8;
  end
  else
  begin
    Result := 0;
  end;
end;

Function TFMTchunk.TotalSize:Int64;
begin
  Result := Self.Size + 8;
end;

Function TDATAchunk.TotalSize:Int64;
begin
  Result := Self.Size + 8;
end;

end.
