{B-}
unit AudioInfo;

{

  Class for manipulation with audio file information
  (contain MpegHeader, ID3Tag and other fields)

  (c) 1999,2000 Andrey V.Sorokin
  Saint-Petersburg, Russia
  anso@mail.ru
  anso@usa.net
  http://anso.da.ru
  http://anso.virtualave.net

  v. 1.1 27.02.00
   -=- (+) Xing VBR support (slightly tested. Please, send your bugreports !)

  v. 1.0 27.11.99
   -=- First release
}

interface

uses
 Classes,
 MpegFrameHdr, ID3Tags;

type

 TAudioInfo = class
   private
    fMpg : TMpegFrameHdr;
    fFirstMpegFramePos : integer;
    fXingVBR : boolean;
    fID3 : TID3v1Tag;

    fMpegDuration : integer;

    fMaxGapBeforeMpeg : integer;

    // parameters of last loaded file
    fFileSize : integer;
    fFileDate : integer;
    fFileAttr : integer;
    MpegPosition_Var : Integer;
    procedure ClearInfo;
   public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromFile (const AFileName : string);
    // Load MpegHeader and ID3Tag from file AFileName

    procedure LoadFromStream (AStream : TStream; AStreamSz : integer);
    // Load MpegHeader and ID3Tag in AStream
    // (max AStreamSz bytes from curren position)

    property Mpg : TMpegFrameHdr read fMpg;
    property ID3 : TID3v1Tag read fID3;

    property FileSize : integer read fFileSize;
    // Size of last loaded file

    property XingVBR : boolean read fXingVBR;
    // True if Xing VBR compression

    property MpegDuration : integer read fMpegDuration;
    // Sound duration (in ms) calculated from Mpg information

    property MaxGapBeforeMpeg : integer read fMaxGapBeforeMpeg write fMaxGapBeforeMpeg;
    // Max gap from file beginning to first MPEG frame.
    // If there are no Mpeg frame synch inside this gap,
    // then we assume that this is not MPEG file.
    // By default 10K. You may increase it, but too big
    // value will slow down scanning of big non-MPEG files.
    Property MpegPosition:Integer Read MpegPosition_Var Write MpegPosition_Var;
  end;


implementation

uses
 Windows, Messages, SysUtils;


{=============================================================}
{======================= TAudioInfo ==========================}

constructor TAudioInfo.Create;
 begin
  inherited;
  fMpg := TMpegFrameHdr.Create;
  fID3 := TID3v1Tag.Create;
  fMaxGapBeforeMpeg := 10 * 1024;
 end; { of constructor TAudioInfo.Create
--------------------------------------------------------------}

destructor TAudioInfo.Destroy;
 begin
  fID3.Free;
  fMpg.Free;
  inherited;
 end; { of destructor TAudioInfo.Destroy
--------------------------------------------------------------}

procedure TAudioInfo.ClearInfo;
 begin
  fMpg.Ok := false;
  fFirstMpegFramePos := -1;
  fXingVBR := false;
  fID3.Ok := false;
  fFileSize := -1;
  fFileDate := -1;
  fFileAttr := 0;
 end; { of procedure TAudioInfo.ClearInfo
--------------------------------------------------------------}

procedure TAudioInfo.LoadFromFile (const AFileName : string);
 var
  f : TStream;
 begin
  ClearInfo;
  if length (Trim (AFileName)) > 0 then begin
    f := TFileStream.Create (AFileName, fmOpenRead or fmShareDenyNone);
    try
       LoadFromStream (f, f.Size);
       fFileSize := f.Size;
      finally f.Free;
     end;
    fFileDate := FileAge (AFileName);
    fFileAttr := FileGetAttr (AFileName);
   end;
 end; { of procedure TAudioInfo.LoadFromFile
--------------------------------------------------------------}

procedure TAudioInfo.LoadFromStream (AStream : TStream; AStreamSz : integer);
 const
  BufSz = 128; // must be > MpegFrameHdrSz !!!
 var
  Buf : array [0 .. BufSz - 1] of byte;
  Sz, Pos, StartPos, Off : integer;
  XingOff, XingFrames : integer;
  MpegLen : integer;
  MpegHdr2 : TMpegFrameHdr;
 begin
  // Clear it all. If we'll fail, then all "Ok" flags will be False.
  ClearInfo;

  // Save starting position in stream (may be it <> 0)
  StartPos := AStream.Position;

  // protection against dummy
  if AStreamSz > AStream.Size - StartPos
   then AStreamSz := AStream.Size - StartPos;

  // find first MPEG frame
  Pos := 0; // position relative to StartPos
  Off := 0; // for assembling file slices
  while (Pos < fMaxGapBeforeMpeg) and (Pos < AStreamSz) do begin
    Sz := BufSz - Off;
    if Pos + Sz >= AStreamSz
     then Sz := AStreamSz - Pos;
    AStream.ReadBuffer (Buf [Off], Sz);
    fFirstMpegFramePos := fMpg.Locate (Buf, Sz + Off);
    if fFirstMpegFramePos >= 0 then begin // Urrra! Bingo !
      // convert "pos in slice" to "offset from StartPos"
      inc (fFirstMpegFramePos, Pos - Off);
      BREAK;
     end;
    inc (Pos, Sz); // update current read pos (rel to StartPos)
    Off := MpegFrameHdrSz; // after first file slice,
    // all next slices will be shifted in Buf
    // for continues processing emulation
    Move (Buf [BufSz - MpegFrameHdrSz], Buf, MpegFrameHdrSz);
    // - shift part of previous slice to Buf's beginnig
   end;

  if fMpg.Ok then begin // Valid MPEG frame found
    // Check next for be sure...
    MpegPosition_Var := fFirstMpegFramePos;
    Pos := fFirstMpegFramePos + fMpg.FrameLen;
    if Pos + MpegFrameHdrSz < AStreamSz then begin
      AStream.Position := StartPos + Pos;
      AStream.ReadBuffer (Buf, MpegFrameHdrSz);
      MpegHdr2 := TMpegFrameHdr.Create;
      try
         MpegHdr2.Load (Buf, MpegFrameHdrSz);
         fMpg.Ok := MpegHdr2.Ok;
        finally MpegHdr2.Free;
       end;
     end;
   end;

  if fMpg.Ok then begin
     // Is this Xing VBR file ?
     if (fMpg.Version = MPEG_VER_1)
      then
        if fMpg.ChannelMode <> MPEG_CHANNEL_SINGLE
         then XingOff := 32 + 4
         else XingOff := 17 + 4
      else
        if fMpg.ChannelMode <> MPEG_CHANNEL_SINGLE
         then XingOff := 17 + 4
         else XingOff := 9 + 4;
     if fFirstMpegFramePos + XingOff + 12 < AStreamSz then begin
       AStream.Position := StartPos + fFirstMpegFramePos + XingOff;
       AStream.ReadBuffer (Buf, 12);
       if (Buf [0] = Ord ('X')) and (Buf [1] = Ord ('i')) and
          (Buf [2] = Ord ('n')) and (Buf [3] = Ord ('g')) then begin
         fXingVBR := true;
         if (Buf [7] and 1) <> 0 // frames number specified
          then XingFrames := (((((Buf [8] ShL 8) + Buf [9]) ShL 8)
                 + Buf [10]) ShL 8) + Buf [11]
          else XingFrames := 0;
         if fMpg.SamplingRate > 0
          then fMpegDuration := Round ((1152 / fMpg.SamplingRate) * XingFrames) * 1000
          else fMpegDuration := 0;
        end;
      end;
     Pos := fFirstMpegFramePos + fMpg.FrameLen;
    end
   else begin // not fMpeg.Ok
     // May be this is unknown MPEG-format.
     // Reset to StartPos for ID3-tags finding.
     Pos := 0;
    end;
  AStream.Position := StartPos + Pos;


  // try to load ID3v1.1 tag
  fID3.LoadFromStream (AStream, AStreamSz - Pos);

  // calculate Duration based on MpegHdr
  if not fXingVBR then begin
    MpegLen := AStreamSz - fFirstMpegFramePos;
    if fID3.Ok
     then dec (MpegLen, ID3v1TagLen);
    if fMpg.BitRate <> MPEG_BITRATE_ERROR
     then fMpegDuration := (MpegLen * 8 div fMpg.BitRate) * 1000 { ms}
     else fMpegDuration := 0;
   end;
 end; { of procedure TAudioInfo.LoadFromStream
--------------------------------------------------------------}

end.

