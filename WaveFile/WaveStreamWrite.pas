unit WaveStreamWrite;

interface

uses
  Classes, WaveFile, WaveFileChunk;

type
  TWaveStreamWrite = class
    private
      FRIFFchunk: TRIFFchunk;
      FBWFchunk: TBWFchunk;
      FFMTchunk: TFMTchunk;
      FDATAchunk: TDATAchunk;
      FDataSize: Int64;
    public
      property BWFchunk :TBWFchunk Read FBWFchunk;
      property FMTchunk: TFMTchunk Read FFMTchunk;
      procedure AddData(var Buffer; Size: Int64; Stream: TStream);
      procedure WriteData(var Buffer; Index, Size: Int64; Stream: TStream);
      procedure Initialize(Stream: TStream);
      property DataSize: Int64 read FDataSize;
      constructor Create(AOwner: TComponent); virtual;
      destructor Destroy; override;
  end;

implementation

constructor TWaveStreamWrite.Create(AOwner:TComponent);
begin
  Inherited Create;
  FFMTchunk := TFMTchunk.Create;
  FBWFchunk := TBWFchunk.Create;
  FDATAchunk := TDATAchunk.Create(FFMTchunk);
  FRIFFchunk := TRIFFchunk.Create(FBWFchunk, FFMTchunk, FDATAchunk);
  FDataSize := 0;
end;


destructor TWaveStreamWrite.Destroy;
begin
  FFMTchunk.Destroy;
  FBWFchunk.Destroy;
  FDATAchunk.Destroy;
  FRIFFchunk.Destroy;
  Inherited;
end;


procedure TWaveStreamWrite.AddData(var Buffer; Size:Int64; Stream: TStream);
begin
  FDATAchunk.SetSize(Size + FDataSize);

  FRIFFchunk.Write(Stream, 0, 0);
  FDATAchunk.Write(Stream, 12 + FBWFchunk.Size + 8 + FFMTchunk.Size + 8, 0);
  FDATAchunk.WriteData(Buffer, Stream, 12 + FBWFchunk.Size + 8 + FFMTchunk.Size + 16 + FDataSize, Size);

  FDataSize := FDataSize + Size;
end;


procedure TWaveStreamWrite.WriteData(var Buffer; Index, Size: Int64; Stream: TStream);
begin
  if (Index + Size) > FDataSize then begin
    FDATAchunk.SetSize(Index + Size);
  end;

  FRIFFchunk.Write(Stream, 0, 0);
  FDATAchunk.Write(Stream, 12 + FBWFchunk.Size + 8 + FFMTchunk.Size + 8, 0);
  FDATAchunk.WriteData(Buffer, Stream, 12 + FBWFchunk.Size + 8 + FFMTchunk.Size + 16 + Index, Size);

  FDataSize := FDataSize + Size;
end;


procedure TWaveStreamWrite.Initialize(Stream: TStream);
begin
  Stream.Position := 0;

  FBWFchunk.Finalize;
  FRIFFchunk.Write(Stream, 0, 0);

  if FBWFchunk.Active then begin
    FBWFchunk.Write(Stream, FRIFFchunk.TotalSize, 0);
  end;

  FFMTchunk.Write(Stream, FRIFFchunk.TotalSize + FBWFchunk.TotalSize, 0);
  FDATAchunk.Write(Stream, FRIFFchunk.TotalSize + FBWFchunk.TotalSize + FFMTchunk.TotalSize, 0);
end;

end.
