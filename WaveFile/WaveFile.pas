unit WaveFile;

(*
  This unit designed by SAAT team in 2008.
  Description:
    This unit designed to handle loading and reading wave file.
    This Class suport Virtual MarkIn and MarkOut.
    In this class all methods for reading , GetSize , Seek, Reset and EOF
    are Working dynamicaly. means changing MarkIn and MarkOut while Reading Data
    do not effect on anything.
    MarkIn and MarkOut Set in Three Method:
    1-AssignMark_Size:
      This method load MarkIn and MarkOut in Size mode means that start MarkIn
      and Stop MarkOut in Size will pass
      Example:
        DataSize=10,000
        MarkIn=1,000
        MarkOut=2,000
        GetSize=DataSize - ((MarkIn + MarkOut)

    2-AssignMark_Percent:
      This Method load MarkIn and MarkOut in Percent Mode
      Attention:
        Parameter of this method div by 1000 for more functionality
        Example:
          DataSize=10,000
          MarkIn=10,000
          MarkOut=20,000
          GetSize=DataSize - (((MarkIn + MarkOut) * DataSize) div 100,000

    3-AssignMark_mSec:
      This method load MarkIn And MarkOut in m_Sec mode
      Example:
        DataSize=10,000
        MarkIn=10,000
        MarkOut=20,000
        GetSize=DataSize - (((MarkIn + MarkOut) * DataSize) div FileDuration

    Other metods:

    1-LoadFile:
      Only check if valid file and load file format.
    2-GetSize:
      Return virtual size.
    3-Seek:
      Go to virtual Index.
    4-Reset:
      Reset vitual Index.

    Properties:

    1-FileInfo:
      Return wave file format Information .
      Load data after LoadFile method.
    2-EOF:
      Set when Index be end of File
*)

interface

uses
  Classes,MMSystem,SysUtils,Windows,xmldom, XMLIntf, msxmldom, XMLDoc,Math;

type
  TWaveFile_Read = Class;
  TWaveBWFchunk = packed Record
    Description : Packed Array [0..255] of Char;
    Originator  : Packed Array [0..31] of Char;
    OriginatorReference : Packed Array [0..31] of Char;
    OriginationDate : Packed Array [0..9] of Char;
    OriginationTime : Packed Array [0..7] of Char;
    TimeReferenceLow : DWORD;
    TimeReferenceHigh : DWORD;
    Version : WORD;
    UMID : Packed Array [0..63] of Byte;
    Reserved : Packed Array [0..189] of Byte;
    //CodingHistory : Packed Array[0..37] of Byte;
  end;

  TPWaveBWFchunk=^TWaveBWFchunk;
  TWaveBWF = Class
    Private
      CoddingHistory: ^String;
      WaveBWFchunk:TPWaveBWFchunk;
      Function GetDescription:String;
      Function GetOriginator:String;
      Function GetOriginatorReference:String;
      Function GetOriginationDate:String;
      Function GetOriginationTime:String;
      Function GetTimeReferenceLow:DWORD;
      Function GetTimeReferenceHigh:DWORD;
      Function GetVersion:WORD;
      Function GetUMID(Index:Byte):Byte;
      Function GetReserved(Index:Byte):Byte;
      //Function GetCodingHistory(Index:Int64):Byte;
      Function GetCodingHistory:String;
      Procedure SetDescription(Value:String);
      Procedure SetOriginator(Value:String);
      Procedure SetOriginatorReference(Value:String);
      Procedure SetOriginationDate(Value:String);
      Procedure SetOriginationTime(Value:String);
      Procedure SetTimeReferenceLow(Value:DWORD);
      Procedure SetTimeReferenceHigh(Value:DWORD);
      Procedure SetVersion(Value:WORD);
      Procedure SetUMID(Index:Byte;Value:Byte);
      Procedure SetReserved(Index:Byte;Value:Byte);
      //Procedure SetCodingHistory(Index:Int64;Value:Byte);
      Procedure SetCodingHistory(Value:String);
    Public
      Procedure Assign(WaveBWF:TWaveBWF);
      Property Description:String Read GetDescription Write SetDescription;
      Property Originator:String Read GetOriginator Write SetOriginator;
      Property OriginatorReference:String Read GetOriginatorReference Write SetOriginatorReference;

      Property OriginationDate:String Read GetOriginationDate Write SetOriginationDate;
      Property OriginationTime:String Read GetOriginationTime Write SetOriginationTime;
      Property TimeReferenceLow:DWORD Read GetTimeReferenceLow Write SetTimeReferenceLow;
      Property TimeReferenceHigh:DWORD Read GetTimeReferenceHigh Write SetTimeReferenceHigh;
      Property Version:WORD Read GetVersion Write SetVersion;
      Property UMID[Index:Byte]:Byte Read GetUMID Write SetUMID;
      Property Reserved[Index:Byte]:Byte Read GetReserved Write SetReserved;
      Property CodingHistory:String Read GetCodingHistory Write SetCodingHistory;//[Index:Int64]:Byte Read GetCodingHistory Write SetCodingHistory;
      Constructor Create(WaveBWFchunk:TPWaveBWFchunk;Var CoddingHistory:String);
  end;
  TWaveXMLRecord = Record
    ghari_Var:String;
 	  NoeMianBarname_Var:String;
  	Mozoo_Var:String;
	  NoeManba_Var:String;
  	onvan_Var:String;
	  AddreseArchive_Var:String;
  	Moddat_Var:String;
	  GhabeliatePakhsh_Var:String;
  	Tozih_Var:String;
	  ID_Var:String;
  end;
  TPWaveXMLRecord = ^TWaveXMLRecord;
  TWaveXML=class
    Private
      WaveXMLRecord:TPWaveXMLRecord;
      Function Getghari:String;
      Function GetNoeMianBarname:String;
      Function GetMozoo:String;
      Function GetNoeManba:String;
      Function Getonvan:String;
      Function GetAddreseArchive:String;
      Function GetModdat:String;
      Function GetGhabeliatePakhsh:String;
      Function GetTozih:String;
      Function GetID:String;


      Procedure Setghari(Value:String);
      Procedure SetNoeMianBarname(Value:String);
      Procedure SetMozoo(Value:String);
      Procedure SetNoeManba(Value:String);
      Procedure Setonvan(Value:String);
      Procedure SetAddreseArchive(Value:String);
      Procedure SetModdat(Value:String);
      Procedure SetGhabeliatePakhsh(Value:String);
      Procedure SetTozih(Value:String);
      Procedure SetID(Value:String);

    Public
        Procedure Assign(WaveXML:TWaveXML);
  	    Property ghari:String read Getghari Write Setghari;
    	  Property NoeMianBarname:String Read GetNoeMianBarname Write SetNoeMianBarname;
  	    Property Mozoo:String Read GetMozoo Write SetMozoo;
	      Property NoeManba:String Read GetNoeManba Write SetNoeManba;
    	  Property onvan:String Read Getonvan Write Setonvan;
	      Property AddreseArchive:String Read GetAddreseArchive Write SetAddreseArchive;
  	    Property Moddat:String Read GetModdat Write SetModdat;
	      Property GhabeliatePakhsh:String Read GetGhabeliatePakhsh Write SetGhabeliatePakhsh;
    	  Property Tozih:String Read GetTozih Write SetTozih;
	      Property ID:String Read GetID Write SetID;
        Constructor Create(WaveXMLRecord:TPWaveXMLRecord);
  end;

  TWaveFileFormat = class(TObject)
    Private
      WaveFile:TWaveFile_Read;
      wFormatTag_Var: Word;
      nChannels_Var: Word;
      nSamplesPerSec_Var: DWORD;
      nAvgBytesPerSec_Var: DWORD;
      nBlockAlign_Var: Word;
      wBitsPerSample_Var: Word;
      Size_Var:Int64;
      Duration_Var:Int64;
      WaveBWF_Var:TWaveBWF;
      WaveXML_Var:TWaveXML;
      Function GetSize:Int64;
      Function GetDuration:Int64;
    Public
      Property wFormatTag: Word Read wFormatTag_Var Write wFormatTag_Var;
      Property nChannels: Word Read nChannels_Var Write nChannels_Var;
      Property nSamplesPerSec: DWORD Read nSamplesPerSec_Var Write nSamplesPerSec_Var;
      Property nAvgBytesPerSec: DWORD Read nAvgBytesPerSec_Var Write nAvgBytesPerSec_Var;
      Property nBlockAlign: Word Read nBlockAlign_Var Write nBlockAlign_Var;
      Property wBitsPerSample: Word Read wBitsPerSample_Var Write wBitsPerSample_Var;
      Property Size:Int64 Read GetSize Write Size_Var;
      Property Duration:Int64 Read GetDuration Write Duration_Var;
      Property WaveBWF:TWaveBWF Read WaveBWF_Var Write WaveBWF_Var;
      Property WaveXML:TWaveXML Read WaveXML_Var Write WaveXML_Var;
      Constructor Create(WaveBWFchunk:TPWaveBWFchunk;WaveXMLRecord:TPWaveXMLRecord;Var CoddingHistory:String;WaveFile:TWaveFile_Read);
      Destructor Destroy;


  end;

  TMarkStyle = (Size_S,Percent_S,mSec_S,None_S);
  TWaveFile_Read = Class(TComponent)
    Private
      BWF_Var:String;
      BWF_Exists_Var:Boolean;
      CoddingHistory: String;
      XMLDocument_Var: TXMLDocument;
      WaveBWFchunk:TWaveBWFchunk;
      WaveXMLRecord:TWaveXMLRecord;
      EOF_Var:Boolean;
      IsValid_Var:Boolean;
      FileInfo_Var:TWaveFileFormat;
      FileDuration:Int64;
      DataSize:Int64;
      MarkIn_S,MarkOut_S:Int64;
      MarkIn_P,MarkOut_P:Int64;
      MarkIn_m,MarkOut_m:Int64;
      MarkStyle_Var:TMarkStyle;
      Index_Var:Int64;
      Data_Index:Int64;
      FileName:String;
      Function GetFileInfo:TWaveFileFormat;
      Function ItemValid(WaveFileName : string):Boolean;
      Procedure AssignMark_Size(MarkIn,MarkOut:Int64);
      Procedure AssignMark_Percent(MarkIn,MarkOut:Int64);
      Procedure AssignMark_mSec(MarkIn,MarkOut:Int64);
      Function GetPosition:Int64;
      Function GetXML:String;
      Function GetXMLExists:Boolean;
      Function GetBWF:String;
      Function GetBWFExists:Boolean;
      Function GetMarkIn:Int64;
      Function GetMarkOut:Int64;
    Public
      Format:Byte;
      Procedure AssignMark(MarkStyle:TMarkStyle;MarkIn,MarkOut:Int64);Overload;
      Procedure AssignMark(MarkIn,MarkOut:Int64);Overload;
      Property MarkIn:Int64 Read GetMarkIn;
      Property MarkOut:Int64 Read GetMarkOut;
      Property MarkStyle:TMarkStyle Read MarkStyle_Var Write MarkStyle_Var;
      Function LoadFile(FileName:String):Boolean;
      Property FileInfo:TWaveFileFormat Read GetFileInfo;
      Function GetSize:Int64;
      Function Read(var Buffer;var Size:Int64):Boolean;
      Function Seek(Index:Int64):Boolean;
      Procedure Reset;
      Property EOF:Boolean Read EOF_Var;
      Property Position:Int64 Read GetPosition;
      Property XML:String Read GetXML;
      Property XMLExists:Boolean Read GetXMLExists;
      Property BWF:String Read GetBWF;
      Property BWFExists:Boolean Read GetBWFExists;
      Constructor Create(AOwner:TComponent);Override;
      Destructor Destroy;
  end;

implementation

Constructor TWaveFile_Read.Create(AOwner:TComponent);
begin
  inherited Create(AOwner);
  MarkStyle_Var := None_S;
  Index_Var := 0;
  Self.DataSize := 0;
  Data_Index := 0;
  EOF_Var := False;
  FileInfo_Var := TWaveFileFormat.Create(@WaveBWFchunk,@WaveXMLRecord,CoddingHistory,Self);
  XMLDocument_Var := TXMLDocument.Create(AOwner);
  XMLDocument_Var.DOMVendor :=  DOMVendors.Vendors[0];
  BWF_Exists_Var := False;
end;

Destructor TWaveFile_Read.Destroy;
begin
  FileInfo_Var.Destroy;
  XMLDocument_Var.Destroy;
  inherited;
end;

Function TWaveFile_Read.LoadFile(FileName:String):Boolean;
begin
  if ItemValid(FileName) then
  begin
    if FileExists(Copy(FileName,1,length(FileName)-3)+'XML') then
    begin
      Self.Reset;
      XMLDocument_Var.Active := False;
      XMLDocument_Var.FileName := Copy(FileName,1,length(FileName)-3)+'XML';
      XMLDocument_Var.Active := True;
      
      if (XMLDocument_Var.DocumentElement <> NIL) and(XMLDocument_Var.DocumentElement.ChildNodes.Count >=1) then
      begin
        WaveXMLRecord.ghari_Var := XMLDocument_Var.DocumentElement.ChildNodes[0].NodeValue;
      end;
      if (XMLDocument_Var.DocumentElement <> NIL) and(XMLDocument_Var.DocumentElement.ChildNodes.Count >=2) then
      begin
        WaveXMLRecord.NoeMianBarname_Var := XMLDocument_Var.DocumentElement.ChildNodes[1].NodeValue;
      end;
      if (XMLDocument_Var.DocumentElement <> NIL) and(XMLDocument_Var.DocumentElement.ChildNodes.Count >=3) then
      begin
        WaveXMLRecord.Mozoo_Var := XMLDocument_Var.DocumentElement.ChildNodes[2].NodeValue;
      end;
      if (XMLDocument_Var.DocumentElement <> NIL) and(XMLDocument_Var.DocumentElement.ChildNodes.Count >=4) then
      begin
        WaveXMLRecord.NoeManba_Var := XMLDocument_Var.DocumentElement.ChildNodes[3].NodeValue;
      end;
      if (XMLDocument_Var.DocumentElement <> NIL) and(XMLDocument_Var.DocumentElement.ChildNodes.Count >=5) then
      begin
        WaveXMLRecord.onvan_Var := XMLDocument_Var.DocumentElement.ChildNodes[4].NodeValue;
      end;
      if (XMLDocument_Var.DocumentElement <> NIL) and(XMLDocument_Var.DocumentElement.ChildNodes.Count >=6) then
      begin
        WaveXMLRecord.AddreseArchive_Var := XMLDocument_Var.DocumentElement.ChildNodes[5].NodeValue;
      end;
      if (XMLDocument_Var.DocumentElement <> NIL) and(XMLDocument_Var.DocumentElement.ChildNodes.Count >=7) then
      begin
        WaveXMLRecord.Moddat_Var := XMLDocument_Var.DocumentElement.ChildNodes[6].NodeValue;
      end;
      if (XMLDocument_Var.DocumentElement <> NIL) and(XMLDocument_Var.DocumentElement.ChildNodes.Count >=8) then
      begin
        WaveXMLRecord.GhabeliatePakhsh_Var := XMLDocument_Var.DocumentElement.ChildNodes[7].NodeValue;
      end;
      if (XMLDocument_Var.DocumentElement <> NIL) and(XMLDocument_Var.DocumentElement.ChildNodes.Count >=9) then
      begin
        WaveXMLRecord.Tozih_Var := XMLDocument_Var.DocumentElement.ChildNodes[8].NodeValue;
      end;
      if (XMLDocument_Var.DocumentElement <> NIL) and(XMLDocument_Var.DocumentElement.ChildNodes.Count >=10) then
      begin
        WaveXMLRecord.ID_Var := XMLDocument_Var.DocumentElement.ChildNodes[9].NodeValue;
      end;
      XMLDocument_Var.Active := False;
    end;
    Result := True;
    IsValid_Var := Result;
    Self.FileName := FileName;
  end
  else
  begin
    Result := False;
    IsValid_Var := Result;
  end;

end;

Procedure TWaveFile_Read.AssignMark_Size(MarkIn,MarkOut:Int64);
begin
  if (MarkIn <> 0) and (MarkOut <> 0) then
  begin
    MarkStyle_Var := Size_S;
    MarkIn_S := MarkIn;
    MarkOut_S := MarkOut;
  end
  else
  begin
    MarkStyle_Var := None_S;
  end;
end;

Procedure TWaveFile_Read.AssignMark_Percent(MarkIn,MarkOut:Int64);
begin
  if (MarkIn <> 0) and (MarkOut <> 0) then
  begin
    if(MarkIn+MarkOut) < 100000 then
    begin
      MarkStyle_Var := Percent_S;
      MarkIn_P := MarkIn;
      MarkOut_P := MarkOut;
    end
    else
    begin
      raise Exception.Create('MarkIn+MarkOut is bigger than 100000');
    end;
  end
  else
  begin
    MarkStyle_Var := None_S;
  end;
end;

Procedure TWaveFile_Read.AssignMark_mSec(MarkIn,MarkOut:Int64);
begin
  if (MarkIn <> 0) and (MarkOut <> 0) then
  begin
    MarkStyle_Var := mSec_S;
    MarkIn_m := MarkIn;
    MarkOut_m := MarkOut;
  end
  else
  begin
    MarkStyle_Var := None_S;
  end;
end;

Function TWaveFile_Read.GetFileInfo:TWaveFileFormat;
begin
  if IsValid_Var then
  begin
    Result := FileInfo_Var;
  end
  else
  begin
    raise Exception.Create('Invalid Wave File');
  end
end;

Function TWaveFile_Read.ItemValid(WaveFileName : string):Boolean;
var i:Byte;
    f        : TFileStream;
    TempStr  : String;
    FileSize : int64;
    RIFF_OK  : Boolean;
    PCM__OK  : Boolean;
    Data_Ok  : Boolean;
    fmt__Ok  : Boolean;
    bext_OK  : Boolean;
    BitLen   : Integer;
    ByteRate : Integer;
    SampleRate:Integer;
    ChannelNum:Integer;
    FormatTag:DWORD;
    chunkSize: int64;
    Data_Size : int64;
    ReadedSize: int64;
    inputTime : TDateTime;
    BWFSize:Int64;
    counter:Integer;
    WaveBWFchunk1:TWaveBWFchunk;
    arr:packed array [1.. 1000] of char absolute WaveBWFchunk1;
begin
  BWF_Exists_Var := False;
  Result:=False;
  FileSize:=0;
  RIFF_OK:=False;
  PCM__OK:=False;
  Data_Ok:=False;
  fmt__Ok:=False;
  BWFSize := 0;
//InputTime:=now;   00250_00315.wav
  //if (copy(WaveFileName,1,2) <> '\\') or ServerConnected then
  if FileExists(WaveFileName) then
  begin
    TempStr:='';
    f:=TFileStream.Create(WaveFileName,fmShareDenyNone);
    if f.size < (36+8) then begin f.Free; exit; end; //RIFF_chunk_Size=8; fmt_chunk_Size=24; other_chunk_atleast=8
    SetLength(TempStr,20);
    f.Read(TempStr[1],20); ReadedSize:=20;
    RIFF_OK:=(copy(TempStr,1,4) = 'RIFF');
    i:=8; while i>=5 do begin FileSize:=FileSize * 256 + ord(TempStr[i]); i:=i-1; end; FileSize := FileSize + 8;


    TempStr:=copy(TempStr,13,8);
    While not(fmt__Ok and Data_Ok) do
    begin
      chunkSize:=((ord(TempStr[8])*256 + ord(TempStr[7]))*256 + ord(TempStr[6]))*256 + ord(TempStr[5]);
      if copy(TempStr,1,4) = 'fmt ' then
      begin
        SetLength(TempStr,chunkSize);
        f.Read(TempStr[1],chunkSize); ReadedSize:=ReadedSize + chunkSize ;
        FormatTag :=( ord(TempStr[02])*256 + ord(TempStr[01]));
        ChannelNum:=( ord(TempStr[04])*256 + ord(TempStr[03]));
        SampleRate:=((ord(TempStr[08])*256 + ord(TempStr[07]))*256 + ord(TempStr[06]))*256 + ord(TempStr[05]);
        ByteRate  :=((ord(TempStr[12])*256 + ord(TempStr[11]))*256 + ord(TempStr[10]))*256 + ord(TempStr[09]);
        BitLen    :=( ord(TempStr[16])*256 + ord(TempStr[15]));
        fmt__Ok   :=true;
        PCM__OK:=(FormatTag = 1);
      end else
      if copy(TempStr,1,4) = 'bext' then
      begin
        BWF_Exists_Var := True;
        bext_OK := True;
        BWFSize := chunkSize;
        SetLength(TempStr,chunkSize);
        f.Read(TempStr[1],chunkSize); ReadedSize:=ReadedSize + chunkSize ;
        Self.BWF_Var := TempStr;
        if sizeof(WaveBWFchunk)>chunkSize then
          Zeromemory(@WaveBWFchunk,sizeof(WaveBWFchunk));
        CopyMemory(@WaveBWFchunk,@TempStr[1],min(sizeof(WaveBWFchunk),chunkSize));
        if chunkSize>sizeof(WaveBWFchunk) then
        begin
          //SetLength(CoddingHistory,chunkSize-sizeof(WaveBWFchunk));
          CoddingHistory:=Copy(TempStr,Length(TempStr)-(chunkSize-sizeof(WaveBWFchunk))+1,chunkSize-sizeof(WaveBWFchunk));
        end;
      end else
      if copy(TempStr,1,4) = 'data' then
      begin
        Data_Ok  :=True;
        Data_Size:=chunkSize;
        if f.Size < (ReadedSize + chunkSize) then begin f.Free; exit; end;
        Data_Index := ReadedSize {+ 8};
        f.Seek(chunkSize,soFromCurrent); ReadedSize:=ReadedSize + chunkSize;
      end else
      begin
        if f.Size < (ReadedSize + chunkSize) then begin f.Free; exit; end;
        f.Seek(chunkSize,soFromCurrent); ReadedSize:=ReadedSize + chunkSize;
      end;
      if not(fmt__Ok and Data_Ok) then
      begin
        SetLength(TempStr,8);
        if f.Size < (ReadedSize + 8) then begin f.Free; exit; end;
        f.Read(TempStr[1],8); ReadedSize:=ReadedSize + 8;
      end;
    end;
    if ByteRate > 0 then
    begin
      FileDuration:=(Data_Size * 1000) div ByteRate;
    end
    else
    begin
      FileDuration := 0;
    end;

    Result:=(FileSize = f.Size) and PCM__OK and RIFF_OK ;
    {
    case Format of
      0 : Result:=Result and (BitLen = 16) and  (SampleRate = 44100);
      1 : Result:=Result and (BitLen = 16) and  (SampleRate = 48000);
      2 : Result:=Result and (BitLen = 24) and ((SampleRate = 48000) or (SampleRate = 96000));
     else Result:=false;
    end;
    }
    f.Free;
  End;
  if Result then
  begin
    FileInfo_Var.wFormatTag := FormatTag;
    FileInfo_Var.nChannels := ChannelNum;
    FileInfo_Var.nSamplesPerSec := SampleRate;
    FileInfo_Var.wBitsPerSample := BitLen;
    FileInfo_Var.nBlockAlign := ((FileInfo_Var.wBitsPerSample DIV 8) * FileInfo_Var.nChannels);
    FileInfo_Var.nAvgBytesPerSec := (FileInfo_Var.nSamplesPerSec * FileInfo_Var.nBlockAlign);
    //FileInfo_Var.cbSize := 0;
    Self.DataSize := Data_Size;
    FileInfo_Var.Size := Self.DataSize;
    FileInfo_Var.Duration := FileDuration;
    if (FileInfo_Var.wBitsPerSample = 0) or (FileInfo_Var.nChannels = 0) or
       (FileInfo_Var.nSamplesPerSec = 0) or (FileInfo_Var.nBlockAlign = 0) or
       (FileInfo_Var.nBlockAlign = 0) or (FileInfo_Var.nAvgBytesPerSec = 0) then
       begin
        Result := False;
       end;
  end;
end;

Function TWaveFile_Read.GetSize:Int64;
begin
  if IsValid_Var then
  begin
    Result := 0;
    case MarkStyle_Var of
      Size_S:
      begin
        if(FileInfo_Var.nBlockAlign > 0)and ((MarkIn_S Div FileInfo_Var.nBlockAlign)=0)and
          ((MarkOut_S Div FileInfo_Var.nBlockAlign)=0)and((MarkIn_S+MarkOut_S)<=Self.DataSize) then
        begin
          Result := Self.DataSize - (MarkIn_S+MarkOut_S);         
        end;
      end;
      Percent_S:
      begin
        if (MarkIn_P+MarkOut_P)<=100000 then
        begin
          //Result := (Self.DataSize - ((MarkIn_P+MarkOut_P) * Self.DataSize)) div 100000;
          Result := Self.DataSize -((((MarkIn_P * Self.DataSize) div 100000) div FileInfo_Var.nBlockAlign)* FileInfo_Var.nBlockAlign)-
                    ((((MarkOut_P * Self.DataSize) div 100000) div FileInfo_Var.nBlockAlign)* FileInfo_Var.nBlockAlign);
        end;
      end;
      mSec_S:
      begin
        if (MarkIn_m+MarkOut_m)<=FileDuration then
        begin
        (*
          Result := ((Self.DataSize - ((MarkIn_m+MarkOut_m) * Self.DataSize) div FileDuration) div FileInfo_Var.nBlockAlign)
                    * FileInfo_Var.nBlockAlign ;
        *)
          if (FileDuration <> 0) then
          begin
            Result := Self.DataSize - (((MarkIn_m * Self.DataSize) div FileDuration) div FileInfo_Var.nBlockAlign)* FileInfo_Var.nBlockAlign-
                      (((MarkOut_m * Self.DataSize) div FileDuration) div FileInfo_Var.nBlockAlign)* FileInfo_Var.nBlockAlign;
          end
          else
          begin
            Result := 0;
          end
        end;
      end;
      None_S:
      begin
        Result := Self.DataSize;
      end;
    end;
  end
  else
  begin
    raise Exception.Create('Invalid Wave File');
  end;
end;

Function TWaveFile_Read.Read(var Buffer;var Size:Int64):Boolean;
var
  FileStream:TFileStream;
  RealIndex:Int64;
  EndRealIndex:Int64;
begin
  if (FileExists(FileName))and(IsValid_Var) then
  begin
    RealIndex := Index_Var;
    EndRealIndex := Index_Var;//Self.DataSize;
    Result := True;
    FileStream := TFileStream.Create(FileName,fmShareDenyNone);
    case MarkStyle_Var of
      Size_S:
      begin
        if(FileInfo_Var.nBlockAlign > 0)and ((MarkIn_S mod FileInfo_Var.nBlockAlign)=0)and
          ((MarkOut_S mod FileInfo_Var.nBlockAlign)=0)and((MarkIn_S+MarkOut_S)<=Self.DataSize) then
        begin

          RealIndex := Index_Var + MarkIn_S;
          EndRealIndex := Self.DataSize - MarkOut_S;
        end;
      end;
      Percent_S:
      begin
        if (MarkIn_P+MarkOut_P)<=100000 then
        begin
          if ((((MarkIn_P) * Self.DataSize) div 100000) mod FileInfo_Var.nBlockAlign )=0 then
          begin
            RealIndex := Index_Var + ((MarkIn_P) * Self.DataSize) div 100000;
          end
          else
          begin
            RealIndex := Index_Var + (((MarkIn_P) * Self.DataSize) div 100000 )-
            ((((MarkIn_P) * Self.DataSize) div 100000) mod FileInfo_Var.nBlockAlign );
          end;

          if ((((MarkOut_P) * Self.DataSize) div 100000) mod FileInfo_Var.nBlockAlign )=0 then
          begin
            EndRealIndex :=Self.DataSize - (((MarkOut_P) * Self.DataSize) div 100000);
          end
          else
          begin
            EndRealIndex :=Self.DataSize - (((MarkOut_P) * Self.DataSize) div 100000)-
            ((((MarkOut_P) * Self.DataSize) div 100000) mod FileInfo_Var.nBlockAlign);
          end;
        end;
      end;
      mSec_S:
      begin
        if (MarkIn_m+MarkOut_m)<=FileDuration then
        begin
          if ((((MarkIn_m) * Self.DataSize) div FileDuration) mod FileInfo_Var.nBlockAlign) = 0 then
          begin
            RealIndex :=Index_Var + ((MarkIn_m) * Self.DataSize) div FileDuration;
          end
          else
          begin
            RealIndex :=Index_Var + (((MarkIn_m) * Self.DataSize) div FileDuration)-
            ((((MarkIn_m) * Self.DataSize) div FileDuration) mod FileInfo_Var.nBlockAlign);
          end;
          if ((((MarkOut_m) * Self.DataSize) div FileDuration) mod FileInfo_Var.nBlockAlign) = 0 then
          begin
            EndRealIndex := Self.DataSize - (((MarkOut_m) * Self.DataSize) div FileDuration);
          end
          else
          begin
            EndRealIndex := Self.DataSize - (((MarkOut_m) * Self.DataSize) div FileDuration)-
            ((((MarkOut_m) * Self.DataSize) div FileDuration) mod FileInfo_Var.nBlockAlign);
          end;
        end;
      end;
      None_S:
      begin
        RealIndex := Index_Var;
        EndRealIndex := Self.DataSize;
      end;
    end;
    if (RealIndex) < DataSize then
    begin
      if(EndRealIndex-RealIndex)<Size then
      begin
        ZeroMemory(@Buffer,Size);
        Size := EndRealIndex-RealIndex;
        if Size < 0 then
        begin
          Size := 0;
        end;
        if RealIndex < Index_Var then
        begin
          RealIndex := Index_Var;
        end;
      end;
      if Size <> 0 then
      begin
        FileStream.Seek(RealIndex+Data_Index,soBeginning);
        FileStream.Read(Buffer,Size);
      end;

      FileStream.Free;
      Index_Var := Index_Var + Size;
      EOF_Var :=(Size = 0)or(Index_Var >= GetSize);
    end;
  end
  else
  begin
    Result := False;
    raise Exception.Create('Invalid Wave File');
  end;
end;

Function TWaveFile_Read.Seek(Index:Int64):Boolean;
begin
  if Index < 0 then
  begin
    Exit;
  end;
  if (Index < GetSize) and (IsValid_Var) then
  begin
    Index_Var := Index;
  end
  else
  begin
    if not (Index < GetSize) and (IsValid_Var) then
    begin
      Index := GetSize - 1;
    end;
  end;
   EOF_Var :=(Index_Var >= GetSize);
end;

Procedure TWaveFile_Read.Reset;
begin
  Self.Seek(0);
end;


Function TWaveFile_Read.GetPosition:Int64;
begin
  case MarkStyle_Var of
    Size_S:
    begin
      Result:= Self.Index_Var;
    end;
    Percent_S:
    begin
      Result:= (Self.Index_Var * 100000) div Self.DataSize;
    end;
    mSec_S:
    begin
      Result:= (Self.Index_Var * FileDuration) div Self.DataSize;
    end;
    None_S:
    begin
      Result:= Self.Index_Var;
    end;
  end;
  EOF_Var :=(Index_Var >= GetSize);
end;

Procedure TWaveFile_Read.AssignMark(MarkStyle:TMarkStyle;MarkIn,MarkOut:Int64);
begin
  case MarkStyle of
    Size_S:
    begin
      AssignMark_Size(MarkIn,MarkOut);
    end;
    Percent_S:
    begin
      AssignMark_Percent(MarkIn,MarkOut);
    end;
    mSec_S:
    begin
      AssignMark_mSec(MarkIn,MarkOut);
    end;
  end;
end;

Function TWaveFile_Read.GetXML:String;
var
  FileStream:TFileStream;
begin
  if IsValid_Var then
  begin
    if FileExists(Copy(FileName,1,length(FileName)-3)+'XML') then
    begin
      FileStream:=TFileStream.Create(Copy(FileName,1,length(FileName)-3)+'XML',fmShareDenyNone);
      SetLength(Result,FileStream.Size);
      FileStream.Read(Result[1],FileStream.Size);
      FileStream.Free;
    end;
  end
  else
  begin
    raise Exception.Create('Invalid XML File');
  end;
end;

Function TWaveFile_Read.GetXMLExists:Boolean;
begin
  Result := FileExists(Copy(FileName,1,length(FileName)-3)+'XML');
end;

Function TWaveFile_Read.GetBWF:String;
begin
  Result := Self.BWF_Var;
end;

Function TWaveFile_Read.GetBWFExists:Boolean;
begin
  Result := Self.IsValid_Var and Self.BWF_Exists_Var;
end;

Constructor TWaveFileFormat.Create(WaveBWFchunk:TPWaveBWFchunk;WaveXMLRecord:TPWaveXMLRecord;Var CoddingHistory:String;WaveFile:TWaveFile_Read);
begin
  Inherited Create;
  wFormatTag_Var:=0;
  nChannels_Var:=0;
  nSamplesPerSec_Var:=0;
  nAvgBytesPerSec_Var:=0;
  nBlockAlign_Var:=0;
  wBitsPerSample_Var:=0;
  Size_Var:=0;
  Duration_Var:=0;
  WaveBWF_Var := TWaveBWF.Create(WaveBWFchunk,CoddingHistory);
  WaveXML_Var := TWaveXML.Create(WaveXMLRecord);
  Self.WaveFile := WaveFile;
end;

Destructor TWaveFileFormat.Destroy;
begin
  WaveBWF_Var.Destroy;
  WaveXML_Var.Destroy;
  inherited;
end;

Constructor TWaveBWF.Create(WaveBWFchunk:TPWaveBWFchunk;Var CoddingHistory:String);
begin
  Inherited Create;
  Self.WaveBWFchunk := WaveBWFchunk;
  Self.CoddingHistory := @ CoddingHistory;
end;

Function TWaveBWF.GetDescription:String;
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Result := strpas(Self.WaveBWFchunk.Description);
  end
  else
  begin
  end;
end;

Procedure TWaveBWF.Assign(WaveBWF:TWaveBWF);
begin
  if WaveBWF <> Nil then
  begin
    Self.WaveBWFchunk^ := WaveBWF.WaveBWFchunk^;
    Self.CodingHistory := WaveBWF.CodingHistory;
  end;
end;

Function TWaveBWF.GetOriginator:String;
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Result := strpas(Self.WaveBWFchunk.Originator);
  end
  else
  begin
  end;
end;

Function TWaveBWF.GetOriginatorReference:String;
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Result := strpas(Self.WaveBWFchunk.OriginatorReference);
  end
  else
  begin
  end;
end;

Function TWaveBWF.GetOriginationDate:String;
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Result := strpas(Self.WaveBWFchunk.OriginationDate);
  end
  else
  begin
  end;
end;

Function TWaveBWF.GetOriginationTime:String;
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Result := strpas(Self.WaveBWFchunk.OriginationTime);
  end
  else
  begin
  end;
end;

Function TWaveBWF.GetTimeReferenceLow:DWORD;
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Result := Self.WaveBWFchunk.TimeReferenceLow;
  end
  else
  begin
  end;
end;

Function TWaveBWF.GetTimeReferenceHigh:DWORD;
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Result := Self.WaveBWFchunk.TimeReferenceHigh;
  end
  else
  begin
  end;
end;

Function TWaveBWF.GetVersion:WORD;
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Result := Self.WaveBWFchunk.Version;
  end
  else
  begin
  end;
end;

Function TWaveBWF.GetUMID(Index:Byte):Byte;
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    if Index < 64 then
    begin
      Result := Self.WaveBWFchunk.UMID[Index];
    end;
  end
  else
  begin
  end;
end;

Function TWaveBWF.GetReserved(Index:Byte):Byte;
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    if Index < 190 then
    begin
      Result := Self.WaveBWFchunk.Reserved[Index];
    end;
  end
  else
  begin
  end;
end;

//Function TWaveBWF.GetCodingHistory(Index:Int64):Byte;
Function TWaveBWF.GetCodingHistory:String;
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    //if Index < 38 then
    begin
      Result := CoddingHistory^;//Self.WaveBWFchunk.CodingHistory[Index];
    end;
  end
  else
  begin
  end;
end;

Procedure TWaveBWF.SetDescription(Value:String);
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    StrPCopy(Self.WaveBWFchunk.Description,Value);
    //Result := strpas(Self.WaveBWFchunk.Description);
  end
  else
  begin
  end;
end;

Procedure TWaveBWF.SetOriginator(Value:String);
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    StrPCopy(Self.WaveBWFchunk.Originator,Value);
    //Result := strpas(Self.WaveBWFchunk.Description);
  end
  else
  begin
  end;
end;


Procedure TWaveBWF.SetOriginatorReference(Value:String);
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    StrPCopy(Self.WaveBWFchunk.OriginatorReference,Value);
    //Result := strpas(Self.WaveBWFchunk.Description);
  end
  else
  begin
  end;
end;

Procedure TWaveBWF.SetOriginationDate(Value:String);
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    StrPCopy(Self.WaveBWFchunk.OriginationDate,Value);
    //Result := strpas(Self.WaveBWFchunk.Description);
  end
  else
  begin
  end;
end;

Procedure TWaveBWF.SetOriginationTime(Value:String);
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    StrPCopy(Self.WaveBWFchunk.OriginationTime,Value);
    //Result := strpas(Self.WaveBWFchunk.Description);
  end
  else
  begin
  end;
end;

Procedure TWaveBWF.SetTimeReferenceLow(Value:DWORD);
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Self.WaveBWFchunk.TimeReferenceLow := Value;
    //Result := strpas(Self.WaveBWFchunk.Description);
  end
  else
  begin
  end;
end;

Procedure TWaveBWF.SetTimeReferenceHigh(Value:DWORD);
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Self.WaveBWFchunk.TimeReferenceHigh := Value;
    //Result := strpas(Self.WaveBWFchunk.Description);
  end
  else
  begin
  end;
end;

Procedure TWaveBWF.SetVersion(Value:WORD);
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Self.WaveBWFchunk.Version := Value;
    //Result := strpas(Self.WaveBWFchunk.Description);
  end
  else
  begin
  end;
end;

Procedure TWaveBWF.SetUMID(Index:Byte;Value:Byte);
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Self.WaveBWFchunk.UMID[Index] := Value;
    //Result := strpas(Self.WaveBWFchunk.Description);
  end
  else
  begin
  end;
end;

Procedure TWaveBWF.SetReserved(Index:Byte;Value:Byte);
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    Self.WaveBWFchunk.Reserved[Index] := Value;
    //Result := strpas(Self.WaveBWFchunk.Description);
  end
  else
  begin
  end;
end;

//Procedure TWaveBWF.SetCodingHistory(Index:Int64;Value:Byte);
Procedure TWaveBWF.SetCodingHistory(Value:String);
begin
  if Self.WaveBWFchunk <> NIL then
  begin
    //Self.WaveBWFchunk.CodingHistory[Index] := Value;
    //Result := strpas(Self.WaveBWFchunk.Description);
    CoddingHistory^ := Value;
  end
  else
  begin
  end;
end;


Constructor TWaveXML.Create(WaveXMLRecord:TPWaveXMLRecord);
begin
  Inherited Create;
  Self.WaveXMLRecord := WaveXMLRecord;
end;

Function TWaveXML.Getghari:String;
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Result:=Self.WaveXMLRecord.ghari_Var;
  end
  else
  begin
  end;
end;

Function TWaveXML.GetNoeMianBarname:String;
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Result:=Self.WaveXMLRecord.NoeMianBarname_Var;
  end
  else
  begin
  end;
end;

Function TWaveXML.GetMozoo:String;
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Result:=Self.WaveXMLRecord.Mozoo_Var;
  end
  else
  begin
  end;
end;

Function TWaveXML.GetNoeManba:String;
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Result:=Self.WaveXMLRecord.NoeManba_Var;
  end
  else
  begin
  end;
end;

Function TWaveXML.Getonvan:String;
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Result:=Self.WaveXMLRecord.onvan_Var;
  end
  else
  begin
  end;
end;

Function TWaveXML.GetAddreseArchive:String;
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Result:=Self.WaveXMLRecord.AddreseArchive_Var;
  end
  else
  begin
  end;
end;

Function TWaveXML.GetModdat:String;
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Result:=Self.WaveXMLRecord.Moddat_Var;
  end
  else
  begin
  end;
end;

Function TWaveXML.GetGhabeliatePakhsh:String;
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Result:=Self.WaveXMLRecord.GhabeliatePakhsh_Var;
  end
  else
  begin
  end;
end;

Function TWaveXML.GetTozih:String;
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Result:=Self.WaveXMLRecord.Tozih_Var;
  end
  else
  begin
  end;
end;

Function TWaveXML.GetID:String;
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Result:=Self.WaveXMLRecord.ID_Var;
  end
  else
  begin
  end;
end;


Procedure TWaveXML.Setghari(Value:String);
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Self.WaveXMLRecord.ghari_Var:=Value;
  end
  else
  begin
  end;
end;

Procedure TWaveXML.SetNoeMianBarname(Value:String);
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Self.WaveXMLRecord.NoeMianBarname_Var:=Value;
  end
  else
  begin
  end;
end;

Procedure TWaveXML.SetMozoo(Value:String);
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Self.WaveXMLRecord.Mozoo_Var:=Value;
  end
  else
  begin
  end;
end;

Procedure TWaveXML.SetNoeManba(Value:String);
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Self.WaveXMLRecord.NoeManba_Var:=Value;
  end
  else
  begin
  end;
end;

Procedure TWaveXML.Setonvan(Value:String);
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Self.WaveXMLRecord.onvan_Var:=Value;
  end
  else
  begin
  end;
end;

Procedure TWaveXML.SetAddreseArchive(Value:String);
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Self.WaveXMLRecord.AddreseArchive_Var:=Value;
  end
  else
  begin
  end;
end;

Procedure TWaveXML.SetModdat(Value:String);
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Self.WaveXMLRecord.Moddat_Var:=Value;
  end
  else
  begin
  end;
end;

Procedure TWaveXML.SetGhabeliatePakhsh(Value:String);
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Self.WaveXMLRecord.GhabeliatePakhsh_Var:=Value;
  end
  else
  begin
  end;
end;

Procedure TWaveXML.SetTozih(Value:String);
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Self.WaveXMLRecord.Tozih_Var:=Value;
  end
  else
  begin
  end;
end;

Procedure TWaveXML.SetID(Value:String);
begin
  if Self.WaveXMLRecord <> Nil then
  begin
    Self.WaveXMLRecord.ID_Var:=Value;
  end
  else
  begin
  end;
end;

Function TWaveFile_Read.GetMarkIn:Int64;
begin
  case MarkStyle_Var of
    Size_S:
    begin
      Result := Self.MarkIn_S;
    end;
    Percent_S:
    begin
      Result := Self.MarkIn_P;
    end;
    mSec_S:
    begin
      Result := Self.MarkIn_m;
    end;
    None_S:
    begin
      Result := 0;
    end;
  end;
end;

Function TWaveFile_Read.GetMarkOut:Int64;
begin
  case MarkStyle_Var of
    Size_S:
    begin
      Result := Self.MarkOut_S;
    end;
    Percent_S:
    begin
      Result := Self.MarkOut_P;
    end;
    mSec_S:
    begin
      Result := Self.MarkOut_m;
    end;
    None_S:
    begin
      Result := 0;
    end;
  end;
end;

Procedure TWaveFile_Read.AssignMark(MarkIn,MarkOut:Int64);
begin
  if(Self.MarkStyle = Size_S) or (Self.MarkStyle = Percent_S) or
    (Self.MarkStyle = mSec_S) then
    Self.AssignMark(Self.MarkStyle,MarkIn,MarkOut);
end;


Function TWaveFileFormat.GetSize:Int64;
begin
  if WaveFile <> Nil then
  begin
    Result := WaveFile.GetSize;
  end;
end;

Function TWaveFileFormat.GetDuration:Int64;
begin
  if (WaveFile <> Nil) and (Self.nAvgBytesPerSec_Var <> 0) then
  begin
    Result := (WaveFile.GetSize*1000) div Self.nAvgBytesPerSec_Var;
  end;
end;

Procedure TWaveXML.Assign(WaveXML:TWaveXML);
begin
  if WaveXML <> NIL then
  begin
    Self.WaveXMLRecord^ := WaveXML.WaveXMLRecord^; 
  end;
end;

end.
