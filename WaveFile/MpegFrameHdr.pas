{$B-}
unit MpegFrameHdr;

{

  Class for manipulation with frame headers of
  MPEG version 1, 2, 2.5 Layer I, II, III

  (c) 1999,2000 Andrey V.Sorokin
  Saint-Petersburg, Russia
  anso@mail.ru
  anso@usa.net
  http://anso.da.ru
  http://anso.virtualave.net

  v. 1.0 27.11.99
   -=- First release
}


interface


const
 MpegFrameHdrSz = 4;

 MPEG_VER_ERROR = 0;
 MPEG_VER_1 = 1;
 MPEG_VER_2 = 2;
 MPEG_VER_2_5 = 3;

 MpegVerStr : array [0 .. 3] of string [3] = (
  '?!!', '1.0', '2.0', '2.5');

 MPEG_LAYER_ERROR = 0;
 MPEG_LAYER_I = 1;
 MPEG_LAYER_II = 2;
 MPEG_LAYER_III = 3;

 MpegLayerStr : array [0 .. 3] of string [3] = (
  '?!!', 'I', 'II', 'III');

 MPEG_BITRATE_ERROR = -1;
 MPEG_SAMPLINGRATE_ERROR = -1;

 MPEG_CHANNEL_STEREO = 0;
 MPEG_CHANNEL_JOINTSTEREO = 1;
 MPEG_CHANNEL_DUAL = 2;
 MPEG_CHANNEL_SINGLE = 3;

 MpegChannelStr : array [0 .. 3] of string = (
  'Stereo', 'Joint Stereo', 'Dual', 'Mono');

 MPEG_EMPHASIS_NONE = 0;
 MPEG_EMPHASIS_50_15 = 1;
 MPEG_EMPHASIS_ERROR = 2;
 MPEG_EMPHASIS_CCIT_J_17 = 3;

 MpegEmphasisStr : array [0 .. 3] of string = (
  'None', '50/15 ms', '?!!', 'CCIT J.17');

type

 TMpegFrameHdr = class

   private
    fHdrBuf : array [0 .. MPegFrameHdrSz - 1] of byte;

    // some precalculated fieds for optimization
    // (calculated in Load and Locate)
    fOk : boolean;
    fVersion : integer;
    fKBitRate : integer;
    fSamplingRate : integer;
    fFrameLen : integer;

    // calculating fields "on the fly" from fHdrBuf
    function GetOk : boolean;
    function GetSync : boolean;
    function GetVersion : integer;
    function GetVersionStr : string;
    function GetLayer : integer;
    function GetLayerStr : string;
    function GetCRCExists : boolean;
    function GetKBitRate : integer;
    function GetBitRate : integer;
    function GetSamplingRate : integer;
    function GetPadding : boolean;
    function GetPaddingLen : integer;
    function GetChannelMode : integer;
    function GetChannelModeStr : string;
    function GetChannelModeExt : integer;
    function GetChannelModeExtStr : string;
    function GetCopyright : boolean;
    function GetOriginal : boolean;
    function GetEmphasis : integer;
    function GetEmphasisStr : string;
    function GetFrameLen : integer;

   public

    constructor Create;
    // Simple set Ok to False

    function Load (const ABuf; ABufSz : integer) : boolean;
    // Initialize class fieds with values from
    // mpeg-header AHeader (MPegFrameHdrBufSz bytes)
    // Return true if all fields is Ok.

    function Locate (const ABuf; ABufSz : integer) : integer;
    // Search Mpeg header in ABuf buffer of ABufSz length.
    // If success then call Load and return index of first
    // header byte in APos (0 - index of first byte of ABuf)
    // otherwise return -1

    property Ok : boolean read fOk write fOk;
    // True, if all fealds of header is valid
    // Writeable only for reinitialization purpose.

    property Sync : boolean read GetSync;
    // True, if there is valid sinc bits in header

    property Version : integer read fVersion;
    // MPEG_VER_* value

    property VersionStr : string read GetVersionStr;
    // Version as string ('1.0', '2.0', '2.5', '?!!')

    property Layer : integer read GetLayer;
    // MPEG_LAYER_* value

    property LayerStr : string read GetLayerStr;
    // Layer as string ('I', 'II', 'III', '?!!')

    property CRCExists : boolean read GetCRCExists;
    // True if there is CRC

    property KBitRate : integer read fKBitRate;
    // BitRate in Bits/1000/sec

    property BitRate : integer read GetBitRate;
    // BitRate in Bits/sec

    property SamplingRate : integer read fSamplingRate;
    // Sampling frequency, Hz

    property Padding : boolean read GetPadding;
    // True if there is padding slot in the frame

    property PaddingLen : integer read GetPaddingLen;
    // Length of padding, bytes (zero if no padding)

    property ChannelMode : integer read GetChannelMode;
    // MPEG_CHANNEL_*

    property ChannelModeStr : string read GetChannelModeStr;
    // ChannelMode as english strings (from MpegChannelStr)

    property ChannelModeExt : integer read GetChannelModeExt;
    // Channel mode extension (only for joint stereo)

    property ChannelModeExtStr : string read GetChannelModeExtStr;
    // Channel mode extention as english string

    property Copyright : boolean read GetCopyright;
    // True if copyright

    property Original : boolean read GetOriginal;
    // True if original media

    property Emphasis : integer read GetEmphasis;
    // MPEG_EMPHASIS_*

    property EmphasisStr : string read GetEmphasisStr;
    // Emphasis as english string

    property FrameLen : integer read fFrameLen;
    // length of the frame (bytes)
  end;


implementation


constructor TMpegFrameHdr.Create;
 begin
  inherited;
  fOk := False;
  FillChar (fHdrBuf, SizeOf (fHdrBuf), 0);
 end; { of constructor TMpegFrameHdr.Create
--------------------------------------------------------------}

function TMpegFrameHdr.Load (const ABuf; ABufSz : integer) : boolean;
 begin
  if ABufSz >= MPegFrameHdrSz then begin
     Move (ABuf, fHdrBuf, MPegFrameHdrSz);
     // optimization - precalculate some fields
     fVersion := GetVersion;
     fKBitRate := GetKBitRate; // depends on Version & Layer !!
     fSamplingRate := GetSamplingRate; // depends on Version !!
     fFrameLen := GetFrameLen; // depends on Layer, KBitRate, SamplingRate & Padding !!
     fOk := GetOk; // Depends on nearly all fields
     Result := Ok;
    end
   else Result := False;
 end; { of function TMpegFrameHdr.Load
--------------------------------------------------------------}

function TMpegFrameHdr.Locate (const ABuf; ABufSz : integer) : integer;
 var
  p : PChar;
 begin
  Result := 0;
  p := @ABuf;
  while Result <= (ABufSz - MPegFrameHdrSz) do
   if (p^ = #$FF) and ((ord ((p + 1)^) and $E0) = $E0)
      and Load (p^, ABufSz - Result)
    then EXIT
    else begin
      inc (p);
      inc (Result);
     end;
  Result := -1;
 end; { of function TMpegFrameHdr.Locate
--------------------------------------------------------------}

function TMpegFrameHdr.GetOk : boolean;
 begin
  Result := Sync and (Version <> MPEG_VER_ERROR)
    and (Layer <> MPEG_LAYER_ERROR)
    and (KBitRate <> MPEG_BITRATE_ERROR)
    and (SamplingRate <> MPEG_SAMPLINGRATE_ERROR);
 end; { of function TMpegFrameHdr.GetOk
--------------------------------------------------------------}

function TMpegFrameHdr.GetSync : boolean;
 begin
  Result := (fHdrBuf [0] = $FF) and ((fHdrBuf [1] and $E0) = $E0);
 end; { of function TMpegFrameHdr.GetSync
--------------------------------------------------------------}

function TMpegFrameHdr.GetVersion : integer;
 begin
  case (fHdrBuf [1] ShR 3) and 3 of
    0: Result := MPEG_VER_2_5;
    2: Result := MPEG_VER_2;
    3: Result := MPEG_VER_1;
    else Result := MPEG_VER_ERROR;
   end;
 end; { of function TMpegFrameHdr.GetVersion
--------------------------------------------------------------}

function TMpegFrameHdr.GetVersionStr : string;
 begin
  Result := MpegVerStr [Version];
 end; { of function TMpegFrameHdr.GetVersionStr
--------------------------------------------------------------}

function TMpegFrameHdr.GetLayer : integer;
 begin
  Result := (4 - (fHdrBuf [1] ShR 1) and 3) and 3;
 end; { of function TMpegFrameHdr.GetLayer
--------------------------------------------------------------}

function TMpegFrameHdr.GetLayerStr : string;
 begin
  Result := MpegLayerStr [Layer];
 end; { of function TMpegFrameHdr.GetLayerStr
--------------------------------------------------------------}

function TMpegFrameHdr.GetCRCExists : boolean;
 begin
  Result := (fHdrBuf [1] and 1) = 0;
 end; { of function TMpegFrameHdr.GetCRCExists
--------------------------------------------------------------}

function TMpegFrameHdr.GetKBitRate : integer;
 const
  MpegKBitRate : array [1 .. 3, 1 .. 3, 0 .. 15] of integer = (
  (//MPEG 1
   (0, 32, 64, 96,128,160,192,224,256,288,320,352,384,416,448,MPEG_BITRATE_ERROR), //Layer I
   (0, 32, 48, 56, 64, 80, 96,112,128,160,192,224,256,320,384,MPEG_BITRATE_ERROR), //Layer II
   (0, 32, 40, 48, 56, 64, 80, 96,112,128,160,192,224,256,320,MPEG_BITRATE_ERROR)  //Layer III
  ),
  (//MPEG 2
   (0, 32, 48, 56, 64, 80, 96,112,128,144,160,176,192,224,256,MPEG_BITRATE_ERROR), //Layer I)
   (0,  8, 16, 24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160,MPEG_BITRATE_ERROR), //Layer II
   (0,  8, 16, 24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160,MPEG_BITRATE_ERROR)  //Layer III
  ),
  (//MPEG 2.5
   (0, 32, 48, 56, 64, 80, 96,112,128,144,160,176,192,224,256,MPEG_BITRATE_ERROR), //Layer I)
   (0,  8, 16, 24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160,MPEG_BITRATE_ERROR), //Layer II
   (0,  8, 16, 24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160,MPEG_BITRATE_ERROR)  //Layer III
  ));
 begin
  if (Version <> MPEG_VER_ERROR) and (Layer <> MPEG_LAYER_ERROR)
   then Result := MpegKBitRate [Version, Layer, (fHdrBuf [2] ShR 4) and $F]
   else Result := MPEG_BITRATE_ERROR
 end; { of function TMpegFrameHdr.GetKBitRate
--------------------------------------------------------------}

function TMpegFrameHdr.GetBitRate : integer;
 begin
  Result := KBitRate * 1000;
 end; { of function TMpegFrameHdr.GetBitRate
--------------------------------------------------------------}

function TMpegFrameHdr.GetSamplingRate : integer;
 const
  MpegSamplingRate : array [1 .. 3, 0 .. 3] of integer = (
    (44100, 48000, 32000, MPEG_SAMPLINGRATE_ERROR), //MPEG 1
    (22050, 24000, 16000, MPEG_SAMPLINGRATE_ERROR), //MPEG 2
    (32000, 16000,  8000, MPEG_SAMPLINGRATE_ERROR)  //MPEG 2.5
   );
 begin
  if Version <> MPEG_VER_ERROR
   then Result := MpegSamplingRate [Version, (fHdrBuf [2] ShR 2) and 3]
   else Result := MPEG_SAMPLINGRATE_ERROR;
 end; { of function TMpegFrameHdr.GetSamplingRate
--------------------------------------------------------------}

function TMpegFrameHdr.GetPadding : boolean;
 begin
  Result := ((fHdrBuf [2] ShR 1) and 1) = 1;
 end; { of function TMpegFrameHdr.GetPadding
--------------------------------------------------------------}

function TMpegFrameHdr.GetPaddingLen : integer;
 begin
  if Padding
   then
     if Layer = MPEG_LAYER_I
      then Result := 4
      else Result := 1
   else Result := 0;
 end; { of function TMpegFrameHdr.GetPaddingLen
--------------------------------------------------------------}

function TMpegFrameHdr.GetChannelMode : integer;
 begin
  Result := (fHdrBuf [3] ShR 6) and 3;
 end; { of function TMpegFrameHdr.GetChannelMode
--------------------------------------------------------------}

function TMpegFrameHdr.GetChannelModeStr : string;
 begin
  Result := MpegChannelStr [ChannelMode];
 end; { of function TMpegFrameHdr.GetChannelModeStr
--------------------------------------------------------------}

function TMpegFrameHdr.GetChannelModeExt : integer;
 begin
  Result := (fHdrBuf [3] ShR 4) and 3;
 end; { of function TMpegFrameHdr.GetChannelModeExt
--------------------------------------------------------------}

function TMpegFrameHdr.GetChannelModeExtStr : string;
 const
  MpegChannelExtStr : array [0 .. 1, 0 .. 3] of string = (
   ('Bands 4-31', 'Bands 8-31', 'Bands 12-31', 'Bands 16-31'),
   ('', 'Intensity', 'MS', 'MS/Intensity'));
 begin
  if ChannelMode = MPEG_CHANNEL_JOINTSTEREO
   then
     if Layer = MPEG_LAYER_III
      then Result := MpegChannelExtStr [1, ChannelModeExt]
      else Result := MpegChannelExtStr [0, ChannelModeExt]
   else Result := '';
 end; { of function TMpegFrameHdr.GetChannelModeExtStr
--------------------------------------------------------------}

function TMpegFrameHdr.GetCopyright : boolean;
 begin
  Result := ((fHdrBuf [3] ShR 3) and 1) = 1;
 end; { of function TMpegFrameHdr.GetCopyright
--------------------------------------------------------------}

function TMpegFrameHdr.GetOriginal : boolean;
 begin
  Result := ((fHdrBuf [3] ShR 2) and 1) = 1;
 end; { of function TMpegFrameHdr.GetOriginal
--------------------------------------------------------------}

function TMpegFrameHdr.GetEmphasis : integer;
 begin
  Result := fHdrBuf [3] and 3;
 end; { of function TMpegFrameHdr.GetEmphasis
--------------------------------------------------------------}

function TMpegFrameHdr.GetEmphasisStr : string;
 begin
  Result := MpegEmphasisStr [Emphasis];
 end; { of function TMpegFrameHdr.GetEmphasisStr
--------------------------------------------------------------}

function TMpegFrameHdr.GetFrameLen : integer;
{  384 samples/frame for Layer I
  1152 samples/frame for Layer II and Layer III
  8 bits Mpeg 1, 16 bits Mpeg 2 & 2.5}
 begin
  if SamplingRate > 0
   then
     if Version = MPEG_VER_1
      then
        if Layer = MPEG_LAYER_I
         then Result := Trunc ((48 * BitRate) / SamplingRate) + PaddingLen
         else Result := Trunc ((144 * BitRate) / SamplingRate) + PaddingLen
      else
        if Layer = MPEG_LAYER_I
         then Result := Trunc ((24 * BitRate) / SamplingRate) + PaddingLen
         else Result := Trunc ((72 * BitRate) / SamplingRate) + PaddingLen
   else Result := 0;
 end; { of function TMpegFrameHdr.GetFrameLen
--------------------------------------------------------------}

end.

