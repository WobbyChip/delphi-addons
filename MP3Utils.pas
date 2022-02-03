{
  MP3Utils.pas

  Object pascal unit with utility functions to analyze MP3 files.

  Copyright (C) 2005 Volker Siebert, Germany
  All rights reserved.

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the "Software"),
  to deal in the Software without restriction, including without limitation
  the rights to use, copy, modify, merge, publish, distribute, sublicense,
  and/or sell copies of the Software, and to permit persons to whom the
  Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  DEALINGS IN THE SOFTWARE.
}

unit MP3Utils;

interface

uses
  SysUtils, Classes;

//======================================================================
// Hilfsfunktionen
//======================================================================

function l3f_umuldiv_trunc(a, b, c: integer): integer; register;
function l3f_umuldiv_round(a, b, c: integer): integer; register;
function l3f_udiv_round(a, c: integer): integer; register;

//======================================================================
//
// Aufbau des MPEG Audio Synchronisationswort
//
// ========0======== ========1======== ========2======== ========3======== Byte
//  7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0   7 6 5 4 3 2 1 0  Bit
//
//  1 1 1 1 1 1 1 1   1 1 1 1  ~0-0    ~1-1-1-1 1-1~                       Valid
//                            X x x     x x x x X X       1-1              Compatible
//
// +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
// |1 1 1 1 1 1 1 1| |1 1 1 1| |   | | |       |   | | | |   |   | | |   |
// +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+
//                            |  |  |      |     |  | |    |   |  | |  |
//                            |  |  |      |     |  | |    |   |  | |  +-- emphasis
//                            |  |  |      |     |  | |    |   |  | +----- original
//                            |  |  |      |     |  | |    |   |  +------- copyright
//                            |  |  |      |     |  | |    |   +---------- mode extension
//                            |  |  |      |     |  | |    +-------------- mode
//                            |  |  |      |     |  | +------------------- extension
//                            |  |  |      |     |  +--------------------- padding
//                            |  |  |      |     +------------------------ frequency (0,1,2)
//                            |  |  |      +------------------------------ bitrate (1-14)
//                            |  |  +------------------------------------- no crc check
//                            |  +---------------------------------------- layer (1,2,3)
//                            +------------------------------------------- version (0,1)
//
//======================================================================

const
  // l3f.version
  L3F_MPEG_2                 = 0;
  L3F_MPEG_1                 = 1;

  // l3f.layer
  L3F_LAYER_1                = 3;
  L3F_LAYER_2                = 2;
  L3F_LAYER_3                = 1;
  L3F_LAYER_INVALID          = 0;

  // l3f.mode
  L3F_MODE_STEREO            = 0;
  L3F_MODE_JOINT_STEREO      = 1;
  L3F_MODE_DUAL_CHANNEL      = 2;
  L3F_MODE_MONO              = 3;

type
  PL3FSyncWord = ^TL3FSyncWord;
  TL3FSyncWord = packed record
    case integer of
      0: ( sw_b: array [0 .. 3] of byte; );
      1: ( sw_l: cardinal; );
  end;

function L3F_SYNC_VALID(const sw: TL3FSyncWord): boolean;
function L3F_SYNC_COMPATIBLE(const s1, s2: TL3FSyncWord): boolean;

const
  //======================================================================
  //
  // Wie die Länge des aktuellen Frames in Bytes ermittelt wird:
  //
  // Dazu benutzen wir die Werte:
  //
  //     spf  = Samples/Frame
  //            l3f_spframe[h.version][h.layer]
  //
  //     bps  = Bytes/Slot
  //            l3f_bpslot[h.layer]
  //
  //     freq = Samples/Sekunde
  //            l3f_frequency[h.version][h.frequency]
  //
  //     kbps = Byte/Sekunde
  //            125 * l3f_kbps[h.version][h.layer][h.bitrate]
  //
  // Aus der Formel:
  //
  //     spf x kbps
  //     ----------
  //        freq
  //
  // erhalten wir
  //
  //     Samples    Bytes    Sekunden    Bytes
  //     ------- x ------- x -------- = -------
  //      Frame    Sekunde    Sample     Frame
  //
  // h.padding gibt an, ob noch ein zusätzlicher Füllslot folgt, der
  // die Länge bps (Bytes/Slot) hat.
  //
  // Hier ist eine Tabelle mit den Basislängen (ohne Padding) für alle
  // möglichen Werte von h.version, h.layer, h.frequency und h.bitrate.
  //
  // V/L  F |  0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15
  // === ===+==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ====
  // 0-0 0-3|  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  //      1 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  //      2 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  //      3 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  // MPEG 2 Layer 3 ------------------------------------------------------------------------
  // 0-1  0 |   0   26   52   78  104  130  156  182  208  261  313  365  417  470  522   -1
  //      1 |   0   24   48   72   96  120  144  168  192  240  288  336  384  432  480   -1
  //      2 |   0   36   72  108  144  180  216  252  288  360  432  504  576  648  720   -1
  //      3 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  // MPEG 2 Layer 2 ------------------------------------------------------------------------
  // 0-2  0 |   0   52  104  156  208  261  313  365  417  522  626  731  835  940 1044   -1
  //      1 |   0   48   96  144  192  240  288  336  384  480  576  672  768  864  960   -1
  //      2 |   0   72  144  216  288  360  432  504  576  720  864 1008 1152 1296 1440   -1
  //      3 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  // MPEG 2 Layer 1 ------------------------------------------------------------------------
  // 0-3  0 |   0   69  104  121  139  174  208  243  278  313  348  383  417  487  557   -1
  //      1 |   0   64   96  112  128  160  192  224  256  288  320  352  384  448  512   -1
  //      2 |   0   96  144  168  192  240  288  336  384  432  480  528  576  672  768   -1
  //      3 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  // === ===+==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ====
  // 1-0  0 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  //      1 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  //      2 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  //      3 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  // MPEG 1 Layer 3 ------------------------------------------------------------------------
  // 1-1  0 |   0  104  130  156  182  208  261  313  365  417  522  626  731  835 1044   -1
  //      1 |   0   96  120  144  168  192  240  288  336  384  480  576  672  768  960   -1
  //      2 |   0  144  180  216  252  288  360  432  504  576  720  864 1008 1152 1440   -1
  //      3 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  // MPEG 1 Layer 2 ------------------------------------------------------------------------
  // 1-2  0 |   0  104  156  182  208  261  313  365  417  522  626  731  835 1044 1253   -1
  //      1 |   0   96  144  168  192  240  288  336  384  480  576  672  768  960 1152   -1
  //      2 |   0  144  216  252  288  360  432  504  576  720  864 1008 1152 1440 1728   -1
  //      3 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  // MPEG 1 Layer 1 ------------------------------------------------------------------------
  // 1-3  0 |   0   34   69  104  139  174  208  243  278  313  348  383  417  452  487   -1
  //      1 |   0   32   64   96  128  160  192  224  256  288  320  352  384  416  448   -1
  //      2 |   0   48   96  144  192  240  288  336  384  432  480  528  576  624  672   -1
  //      3 |  -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1   -1
  // === ===+==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ====
  //
  // (ANMERKUNG: Zitat von mir, 1998)
  //
  // Wie man sieht, ist der größte mögliche Frame 1728+1 Bytes groß.
  // Dies ist aber ein Extremfall für (MPEG-1 Layer 2 mit 384 kBit/s,
  // was nicht speziell optimiert werden muß.
  //
  // Die wahrscheinlichste Größe liegt bei 417+1 Bytes (MPEG 1 Layer 3,
  // 44.100 Hz) bzw. zwischen 365+1 und 522+1. Wenn jedoch die Computer
  // in Zukunft schneller werden, werden auch einige "Spezis" auf die
  // Idee kommen, mit mehr als 160 kBit/s zu komprimieren.
  //
  // Wenn wir diese Werte als Tabelle hinterlegen, benötigen wir dafür
  // 4 x 2 x 4 x 16 = 512 Werte ~= 2048 Bytes.
  //
  //======================================================================

  // Bitrate in kBit/Sekunde
  // Indiziert über [l3f.version][l3f.layer][l3f.bitrate]
  l3f_kbps: array [L3F_MPEG_2 .. L3F_MPEG_1,
                   L3F_LAYER_INVALID .. L3F_LAYER_1,
                   0 .. 15] of smallint = (
    //   0   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15
    // l3f.version 0 = MPEG 2
    ( ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ),   // 0 = invalid
      (  0,  8, 16, 24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160, -1 ),   // 1 = Layer 3
      (  0,  8, 16, 24, 32, 40, 48, 56, 64, 80, 96,112,128,144,160, -1 ),   // 2 = Layer 2
      (  0, 32, 48, 56, 64, 80, 96,112,128,144,160,176,192,224,256, -1 ) ), // 3 = Layer 1
    // l3f.version 1 = MPEG 1
    ( ( -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1 ),   // 0 = invalid
      (  0, 32, 40, 48, 56, 64, 80, 96,112,128,160,192,224,256,320, -1 ),   // 1 = Layer 3
      (  0, 32, 48, 56, 64, 80, 96,112,128,160,192,224,256,320,384, -1 ),   // 2 = Layer 2
      (  0, 32, 64, 96,128,160,192,224,256,288,320,352,384,416,448, -1 ) )  // 3 = Layer 1
  );

  // Sampling-Frequenz (Samples pro Sekunde)
  // Indiziert über [l3f.version][l3f.frequency]
  l3f_frequency: array [L3F_MPEG_2 .. L3F_MPEG_1, 0 .. 3] of integer = (
    ( 22050, 24000, 16000, -1 ), // l3f.version 0 = MPEG 2
    ( 44100, 48000, 32000, -1 )  // l3f.version 1 = MPEG 1
  );

  // Bytes pro Slot
  // Indiziert über [l3f.layer]
  l3f_bpslot: array [L3F_LAYER_INVALID .. L3F_LAYER_1] of smallint = (
    -1, 1, 1, 4
  );

  // Länge des festen Headers
  // Indiziert über [l3f.version][l3f.mode]
  l3f_hdrlen: array [L3F_MPEG_2 .. L3F_MPEG_1,
                     L3F_MODE_STEREO .. L3F_MODE_MONO] of smallint = (
    ( 17, 17, 17,  9 ),
    ( 32, 32, 32, 17 )
  );

  // Samples pro Frame
  // Indiziert über [l3f.version][l3f.layer]
  //
  // Diese Zahl ist *IMMER* ein Vielfaches von 192:
  //   384 = 2 * 192
  //   576 = 3 * 192
  //  1152 = 6 * 192
  l3f_spframe: array [L3F_MPEG_2 .. L3F_MPEG_1,
                      L3F_LAYER_INVALID .. L3F_LAYER_1] of smallint = (
    ( -1,  576, 1152, 384 ),
    ( -1, 1152, 1152, 384 )
  );

type
  TL3FHeader = record
    FileOffset: longint;            // Dateioffset
    FileSize: longint;              // Dateigröße
    SyncWord: TL3FSyncWord;         // Gefundenes Syncword
    XingHeader: longint;            // Dateioffset des Xing-Header
    Version: integer;               // MPEG Version (0=2, 1=1)
    Layer: integer;                 // MPEG Layer (0=4 .. 3=1)
    Bitrate: integer;               // Übertragungsrate (0 .. 15)
    Frequency: integer;             // Sampling-Frequenz (0 .. 3)
    Padding: integer;               // Füll-Slot (1/4 Bytes)
    Mode: integer;                  // Kanalmodus (0 .. 3, 3 = Mono)
    ModeExt: integer;               // Information für Kanalmodus
    Emphasis: integer;              // Hervorhebung ???
    NoCrc: shortint;                // CRC Prüfung (0 = ja)
    Extension: shortint;            // Erweiterung ???
    Copyright: shortint;            // Urheberrechtlich geschützt
    Original: shortint;             // Original oder verändert?
    LengthInSamples: longint;       // Länge des Frames in Samples
    LengthInBytes: longint;         // Länge des Frames in Bytes
    TotalFrames: longint;           // Gesamte Anzahl von Frames in der Datei
  end;

function  l3f_header_rate_kbps(const hdr: TL3FHeader): integer;
function  l3f_header_freq_hz(const hdr: TL3FHeader): integer;
function  l3f_header_bytes_per_slot(const hdr: TL3FHeader): integer;
procedure l3f_header_clear(var hdr: TL3FHeader);
function  l3f_header_set_syncword(var hdr: TL3FHeader; offs: longint; const sw: TL3FSyncWord): boolean;

function Layer3EstimateLengthEx(const Buffer; BufSize, TotalSize: longint; var Header: TL3FHeader): longint;
function Layer3EstimateLength(Stream: TStream; var Header: TL3FHeader): longint; overload;
function Layer3EstimateLength(const Filename: string; var Header: TL3FHeader): longint; overload;

implementation

//
//            |   a x b   |
// Berechnet  |  -------  |  für positive Zahlen a, b und c
//            +-    c    -+
//
// Register calling convention:
//      a = eax
//      b = edx
//      c = ecx

function l3f_umuldiv_trunc(a, b, c: integer): integer; register;
  assembler;
asm
  mul  edx
  div  ecx
end;

//
//            |   a x b + c / 2  |
// Berechnet  |  --------------  |  für positive Zahlen a, b und c
//            +-        c       -+
//

function l3f_umuldiv_round(a, b, c: integer): integer; register;
  assembler;
asm
  mul  edx
  push ecx
  shr  ecx, 1
  add  eax, ecx
  adc  edx, 0
  pop  ecx
  div  ecx
end;

//
//            |   a + c / 2  |
// Berechnet  |  ----------  |  für positive Zahlen a und c
//            +-      c     -+
//

function l3f_udiv_round(a, c: integer): integer; register;
  assembler;
asm
  mov  ecx, edx
  shr  edx, 1
  add  eax, edx
  rcl  edx, 1
  and  edx, 1
  div  ecx
end;

//======================================================================

function L3F_SYNC_VALID(const sw: TL3FSyncWord): boolean;
begin
  Result := (sw.sw_b[0] = $FF) and
            ((sw.sw_b[1] and $F0) = $f0) and
            ((sw.sw_b[1] and $06) <> $00) and
            ((sw.sw_b[2] and $F0) <> $F0) and
            ((sw.sw_b[2] and $0C) <> $0C);
end;

function L3F_SYNC_COMPATIBLE(const s1, s2: TL3FSyncWord): boolean;
begin
  Result := ((s1.sw_b[1] and $0E) = (s2.sw_b[1] and $0E)) and
            ((s1.sw_b[2] and $FC) = (s2.sw_b[2] and $FC)) and
            (((s1.sw_b[3] and $C0) = $C0) = ((s2.sw_b[3] and $C0) = $C0));
end;

//======================================================================

function l3f_header_rate_kbps(const hdr: TL3FHeader): integer;
begin
  Result := l3f_kbps[hdr.Version, hdr.Layer, hdr.Bitrate];
end;

function l3f_header_freq_hz(const hdr: TL3FHeader): integer;
begin
  Result := l3f_frequency[hdr.Version, hdr.Frequency];
end;

function l3f_header_bytes_per_slot(const hdr: TL3FHeader): integer;
begin
  Result := l3f_bpslot[hdr.Layer];
end;

procedure l3f_header_clear(var hdr: TL3FHeader);
begin
  FillChar(hdr, SizeOf(hdr), 0);
  hdr.FileOffset := -1;
end;

function l3f_header_set_syncword(var hdr: TL3FHeader; offs: longint; const sw: TL3FSyncWord): boolean;
var
  sb, spf, bps, freq, kbps: integer;
begin
  hdr.FileOffset := offs;
  hdr.SyncWord := sw;

  sb := sw.sw_b[1];
  hdr.Version   := (sb shr 3) and  1;
  hdr.Layer     := (sb shr 1) and  3;
  hdr.NoCrc     := (sb      ) and  1;

  sb := sw.sw_b[2];
  hdr.Bitrate   := (sb shr 4) and 15;
  hdr.Frequency := (sb shr 2) and  3;
  hdr.Padding   := (sb shr 1) and  1;
  hdr.Extension := (sb      ) and  1;

  sb := sw.sw_b[3];
  hdr.Mode      := (sb shr 6) and  3;
  hdr.ModeExt   := (sb shr 4) and  3;
  hdr.Copyright := (sb shr 3) and  1;
  hdr.Original  := (sb shr 2) and  1;
  hdr.Emphasis  := (sb      ) and  3;

  // Framelänge berechnen
  spf := l3f_spframe[hdr.Version, hdr.Layer];
  bps := l3f_bpslot[hdr.Layer];
  freq := l3f_frequency[hdr.Version][hdr.Frequency];
  kbps := 125 * l3f_kbps[hdr.Version][hdr.Layer][hdr.Bitrate];

  // Auf irgendwelche ungültigen Indizes testen
  Result := (spf > 0) and (bps > 0) and (freq > 0) and (kbps > 0);
  if Result then
  begin
    hdr.LengthInBytes := l3f_umuldiv_trunc(spf, kbps, freq) + bps * hdr.Padding;
    hdr.LengthInSamples := spf;
  end;
end;

//======================================================================

{ Schätzt die Länge eines MP3-Files
  Parameter:
    Buffer: array [0 .. BufSize - 1] of byte
    BufSize: Größe des Puffers
    TotalSize: Größe der gesamten Datei
    Header: TL3FHeader, der mit Informationen gefüllt wird.
  Rückgabewerte:
    Geschätzte Länge (Dauer) der Datei in Millisekunden.
}
function Layer3EstimateLengthEx(const Buffer; BufSize, TotalSize: longint; var Header: TL3FHeader): longint;
type
  PByteArray = ^TByteArray;
  TByteArray = packed array [0 .. MaxInt div 4] of byte;
var
  buf: PByteArray;
  fb64k, tfr, tsm: longint;
  n, n2, ff, nf, padding: integer;
  sw1, sw2: TL3FSyncWord;
  hdr1, hdr2: TL3FHeader;
begin
  l3f_header_clear(hdr1);
  padding := 0;
  ff := 0;

  buf := @Buffer;
  n := 0;
  while n + 3 < BufSize do
  begin
    sw1 := PL3FSyncWord(@buf^[n])^;
    if L3F_SYNC_VALID(sw1) then
    begin
      if l3f_header_set_syncword(hdr1, n, sw1) then
      begin
        inc(ff);
        if ff = 1 then
        begin
          // Nachsehen, ob ein Xing VBR Header vorhanden ist
          // Wenn ja, benutzen!
          n2 := n + l3f_hdrlen[hdr1.Version, hdr1.Mode] + 4;
          if (n2 + 12 < BufSize) and
             (Chr(buf^[n2 + 0]) = 'X') and
             (Chr(buf^[n2 + 1]) = 'i') and
             (Chr(buf^[n2 + 2]) = 'n') and
             (Chr(buf^[n2 + 3]) = 'g') and
             ((buf^[n2 + 7] and 1) <> 0) then
          begin
            tfr := buf^[n2 + 8];
            tfr := tfr shl 8;
            tfr := tfr or buf^[n2 + 9];
            tfr := tfr shl 8;
            tfr := tfr or buf^[n2 + 10];
            tfr := tfr shl 8;
            tfr := tfr or buf^[n2 + 11];

            hdr1.XingHeader := n2;
            hdr1.TotalFrames := tfr;

            tsm := tfr * hdr1.LengthInSamples;
            Result := l3f_umuldiv_trunc(tsm, 1000, l3f_header_freq_hz(hdr1));

            Header := hdr1;

            exit;
          end;
        end;

        padding := hdr1.Padding;

        nf := 1;
        n2 := n + hdr1.LengthInBytes;
        while n2 + 3 < BufSize do
        begin
          sw2 := PL3FSyncWord(@buf^[n2])^;
          if not L3F_SYNC_VALID(sw2) then break;
          if not L3F_SYNC_COMPATIBLE(sw1, sw2) then break;
          if not l3f_header_set_syncword(hdr2, n2, sw2) then break;

          inc(nf);
          padding := padding or hdr2.Padding;

          if nf >= 8 then
            break;

          inc(n2, hdr2.LengthInBytes);
        end;

        if nf > 2 then
          break;
      end;

      l3f_header_clear(hdr1);
    end;

    inc(n);
  end;

  if hdr1.FileOffset < 0 then
    Result := 0
  else
  begin
    hdr1.Padding := padding;

    if padding = 0 then
      fb64k := hdr1.LengthInBytes shl 16
    else
      fb64k := l3f_umuldiv_round(8192000, l3f_header_rate_kbps(hdr1) * hdr1.LengthInSamples, l3f_header_freq_hz(hdr1));

  //tfr := l3f_umuldiv_trunc(TotalSize - hdr1.FileOffset - 4, 65535, fb64k) + 2;
    tfr := l3f_umuldiv_trunc(TotalSize - hdr1.FileOffset + 2, 65536, fb64k) + 1;
    tsm := tfr * hdr1.LengthInSamples;

    hdr1.TotalFrames := tfr;

    Result := l3f_umuldiv_trunc(tsm, 1000, l3f_header_freq_hz(hdr1));
    Header := hdr1;
  end;
end;

//======================================================================

const
  ANALYZE_LENGTH = 8192;

function Layer3EstimateLength(Stream: TStream; var Header: TL3FHeader): longint;
var
  Buffer: packed array [0 .. ANALYZE_LENGTH - 1] of byte;
  Pos, BufSize, Size: longint;
begin
  Pos := Stream.Position;
  Size := Stream.Size - Pos;

  // ID3-Tag am Ende erkennen
  if Size > 128 then
  begin
    Stream.Position := Size - 128;
    Stream.ReadBuffer(Buffer, 128);
    Stream.Position := Pos;

    if (Chr(Buffer[0]) = 'T') and (Chr(Buffer[1]) = 'A') and (Chr(Buffer[2]) = 'G') then
      dec(Size, 128);
  end;

  BufSize := Size;
  if BufSize > ANALYZE_LENGTH then
    BufSize := ANALYZE_LENGTH;

  Stream.ReadBuffer(Buffer, BufSize);
  Stream.Position := Pos;

  Result := Layer3EstimateLengthEx(Buffer, BufSize, Size, Header);

  if Header.FileOffset >= 0 then
  begin
    Header.FileSize := Size - Header.FileOffset;
    inc(Header.FileOffset, Pos);
  end;
end;

//======================================================================

function Layer3EstimateLength(const Filename: string; var Header: TL3FHeader): longint;
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
  try
    Result := Layer3EstimateLength(fs, Header);
  finally
    fs.Free;
  end;
end;

end.
