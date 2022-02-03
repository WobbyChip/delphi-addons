{ DiskUtils (copyleft) 2006
  Deefaze - www.delphifr.com [f0xi]

  version of 2006/01/13 refacted in 2008, april

  CODA CODA NO REFACTORING !
}
unit DiskUtils;

interface

uses SysUtils, math, classes, Windows;

{ Disk number : 0=current, 1=A, 2=B, 3=C etc}
type
  TDiskNumberMask = byte;

{ Disk letter : A..Z }
type
  TDiskLetterMask = char;

{ Symbols }
type
  TSymbolString  = string[8];
  TSymbolsArray  = array[0..4] of TSymbolString;

const
  ArSymbOctets : TSymbolsArray = ('Octets','Ko',   'Mo',   'Go',   'To');
  ArSymbBytes  : TSymbolsArray = ('Bytes', 'KB',   'MB',   'GB',   'TB');
  ArSymbBits   : TSymbolsArray = ('bits',  'Kb',   'Mb',   'Gb',   'Tb');
  ArSymbOcPSec : TSymbolsArray = ('Ops',   'KOps', 'MOps', 'GOps', 'TOps');
  ArSymbByPSec : TSymbolsArray = ('Bps',   'KBps', 'MBps', 'GBps', 'TBps');
  ArSymbBiPSec : TSymbolsArray = ('bps',   'Kbps', 'Mbps', 'Gbps', 'Tbps');

{ Normes }
type
  TDivNormeArray = array[0..3] of int64;

const
  ArOldNorme   : TDivNormeArray = (1024, 1048576, 1073741824, 1099511627776);
  ArNewNorme   : TDivNormeArray = (1000, 1000000, 1000000000, 1000000000000);

{ --- }
type
  TSizeFormat = (dsByte,dsKilo,dsMega,dsGiga,dsTera);
  TSizeResult = (dsTotal,dsFree,dsUsed);

{ TDisk }
type
  TDisk = class(TObject)                                                                                                                                                                               { original code by : f0xi - www.delphifr.com (copyleft) 2006}
  private
    fDiskExist  : boolean;
    fDiskNumber : TDiskNumberMask;
    fDiskLetter : TDiskLetterMask;
    fVolumeName : string;
    fFileSystem : string;
    fDriveType  : cardinal;
    fDriveTypeStr : string;
    fDriveSerial  : integer;
    fDriveSerialStr : string;
    fSizeFree   : int64;
    fSizeTotal  : int64;
    fSizeUsed   : int64;
    fPercentFree: single;
    fPercentUsed: single;
    procedure SetDiskNumber(const val : TDiskNumberMask);
    procedure SetDiskLetter(const val : TDiskLetterMask);
  public
    procedure GetInfos;
  public
    constructor Create; reintroduce; overload;
    constructor Create(const DiskLetter: TDiskLetterMask); reintroduce; overload;
    constructor Create(const DiskNumber: TDiskNumberMask); reintroduce; overload;
  public
    property DiskExist   : boolean read fDiskExist default false;
    property DiskNumber  : TDiskNumberMask read fDiskNumber write SetDiskNumber;
    property DiskLetter  : TDiskLetterMask read fDiskLetter write SetDiskLetter;
  public
    property VolumeName  : string read fVolumeName;
    property FileSystem  : string read fFileSystem;
    property DriveType   : cardinal read fDriveType;
    property DriveTypeStr: string read fDriveTypeStr;
    property DriveSerial : integer read fDriveSerial;
    property DriveSerialStr : string read fDriveSerialStr;
    property SizeFree    : int64 read fSizeFree;
    property SizeTotal   : int64 read fSizeTotal;
    property SizeUsed    : int64 read fSizeUsed;
    property PercentFree : single read fPercentFree;
    property PercentUsed : single read fPercentUsed;
  end;


{ LoadSymbolsArray
  Charge un tableau de symboles dans les variables globales
}
procedure LoadSymbolsArray(const SA: TSymbolsArray);

{ LoadDivNormeArray
  Charge un tableau des diviseurs normalisés dans les variables globales
}
procedure LoadDivNormeArray(const DVN: TDivNormeArray);

{ GetDiskSize
  Retourne la taille d'une unité de stockage
}
function GetDiskSize(const dn: TDiskNumberMask; const sf: TSizeFormat=dsByte;
                     const sr: TSizeResult=dsTotal) : currency;

{ GetDiskSizeStr
  retourne la taille d'une unité de stockage sous forme de chaine
}
function GetDiskSizeStr(const dn: TDiskNumberMask; const sf: TSizeFormat=dsByte;
                        const sr: TSizeResult=dsTotal; const dcm: byte=3): string;

{ DivSizeTo
  Renvois une capacité selon le format désiré (Tera, Giga, Mega, Kilo)
}
function DivSizeTo(const SZ: Int64; const sf: TSizeFormat=dsByte): currency; overload;
function DivSizeTo(const SZ: currency; const sf: TSizeFormat=dsByte): currency; overload;

{ BytesToBits
  Multiplie SZ par 8 et renvois le resultat
}
function BytesToBits(const SZ : int64) : int64;

{ BitsToBytes
  Divise SZ par 8 et renvois le resultat
}
function BitsToBytes(const SZ: int64) : currency;

{ DiskNumberToLetter
  Renvois la lettre correspondante au numero de l'unité de stockage
}
function DiskNumberToLetter(const DN: TDiskNumberMask) : TDiskLetterMask;

{ DiskLetterToNumber
  Renvois le numero correspondant a la lettre de l'unité de strockage
}
function DiskLetterToNumber(const DL: TDiskLetterMask) : TDiskNumberMask;

{ GetFilesFrom
  Renvois les fichiers contenus dans un dossier dans la liste
  <!> attention <!>
   - peu etre long a executer, en fonction des performances de vos disques
   - n'est pas sub-recursive (ne scan pas les repertoires contenus dans le dossier
}
procedure GetFilesFrom(Strings: TStrings; const path: string; const extention: string = '*.*');

{ GetDiskName
  Renvois le nom de l'unité de stockage
}
function GetDiskName(const DL : TDiskLetterMask) : String;

{ GetDiskFileSystem
  Renvois le systeme de fichier utilisé sur l'unité de stockage
}
function GetDiskFileSystem(const DL : TDiskLetterMask) : string;

{ GetDiskType
  Renvois le type de l'unité de stockage (disque dur, cdrom etc)
}
function GetDiskType(const DL : TDiskLetterMask) : cardinal;

{ GetDiskTypeX
  Alternative a GetDiskType pour un retour identique
}
function GetDiskTypeX(const DL : TDiskLetterMask) : integer;
function DiskTypeToStr(const DT : cardinal) : string;

{ GetDiskSerial
  Renvois le numero de serie de l'unité de stockage
}
function GetDiskSerial(const DL : TDiskLetterMask) : integer;

{ DiskSerialToStr
  Convertis le numero de serie de l'unité de stockage sous forme de chaine
}
function DiskSerialToStr(const DS : integer) : string;

{ ValueToPercent
  Calcul le pourcentage d'une valeur par rapport a son maximum et minimum
}
function ValueToPercent(const P,Max : single;const Min : single = 0) : single;

{ Variables globales }
var
   KiloValue : integer = 1024;
   MegaValue : integer = 1048576;
   GigaValue : integer = 1073741824;
   TeraValue : int64   = 1099511627776;

   SizeBaseSymbol  : TSymbolString = 'Octets';
   SizeKiloSymbol  : TSymbolString = 'Ko';
   SizeMegaSymbol  : TSymbolString = 'Mo';
   SizeGigaSymbol  : TSymbolString = 'Go';
   SizeTeraSymbol  : TSymbolString = 'To';

implementation

function ValueToPercent(const P,Max : single;const Min : single = 0) : single;
begin
  result := 0;
  if (P = 0) or ((Max = 0) and (Min = 0)) then
    exit;
  result := P / ((Max+Min)*0.01);
end;

procedure LoadSymbolsArray(const SA : TSymbolsArray);
begin
   SizeBaseSymbol  := SA[0];
   SizeKiloSymbol  := SA[1];
   SizeMegaSymbol  := SA[2];
   SizeGigaSymbol  := SA[3];
   SizeTeraSymbol  := SA[4];
end;

procedure LoadDivNormeArray(const DVN : TDivNormeArray);
begin
   KiloValue := DVN[0];
   MegaValue := DVN[1];
   GigaValue := DVN[2];
   TeraValue := DVN[3];
end;

function GetDiskSize(const dn : TDiskNumberMask; const sf : TSizeFormat = dsByte; const sr : TSizeResult = dsTotal) : currency;
begin
  if DiskSize(dn) = -1 then
  begin
    result := -1;
    exit;
  end
  else
    result := 0;

  case sr of
    dsTotal : result := DiskSize(dn);
    dsFree  : result := DiskFree(dn);
    dsUsed  : result := DiskSize(dn)-DiskFree(dn);
  end;

  case sf of
    dsByte : result := result;
    dsKilo : result := result/KiloValue;
    dsMega : result := result/MegaValue;
    dsGiga : result := result/GigaValue;
    dsTera : result := result/TeraValue;
  end;
end;

function GetDiskSizeStr( const dn : TDiskNumberMask; const sf : TSizeFormat = dsByte; const sr : TSizeResult = dsTotal;
                         const dcm : byte = 3) : string;
begin
  if DiskSize(dn) = -1 then
  begin
    result := '';
    exit;
  end;

  case sf of
    dsByte : result := format('%.0n '+SizeBaseSymbol,[     GetDiskSize(dn,sf,sr)]);
    dsKilo : result := format('%.*n '+SizeKiloSymbol,[dcm, GetDiskSize(dn,sf,sr)]);
    dsMega : result := format('%.*n '+SizeMegaSymbol,[dcm, GetDiskSize(dn,sf,sr)]);
    dsGiga : result := format('%.*n '+SizeGigaSymbol,[dcm, GetDiskSize(dn,sf,sr)]);
    dsTera : result := format('%.*n '+SizeTeraSymbol,[dcm, GetDiskSize(dn,sf,sr)]);
  end;
end;

function DivSizeTo(const SZ : Int64; const sf : TSizeFormat = dsByte) : currency; overload;
begin
  result := 0;
  case sf of
    dsByte : result := SZ;
    dsKilo : result := SZ/KiloValue;
    dsMega : result := SZ/MegaValue;
    dsGiga : result := SZ/GigaValue;
    dsTera : result := SZ/TeraValue;
  end;
end;

function DivSizeTo(const SZ : currency; const sf : TSizeFormat = dsByte) : currency; overload;
begin
  result := 0;
  case sf of
    dsByte : result := SZ;
    dsKilo : result := SZ/KiloValue;
    dsMega : result := SZ/MegaValue;
    dsGiga : result := SZ/GigaValue;
    dsTera : result := SZ/TeraValue;
  end;
end;

function BytesToBits(const SZ : int64) : int64;
begin
  result := SZ*8;
end;

function BitsToBytes(const SZ : int64) : currency;
begin
  result := SZ/8;
end;

function DiskNumberToLetter(const DN : TDiskNumberMask) : TDiskLetterMask;
begin
  if inrange(DN,1,26) then
    result := char(DN+64)
  else
    result := #0;
end;

function DiskLetterToNumber(const DL : TDiskLetterMask) : TDiskNumberMask;
begin
  Result := Byte(DL);
  case Result of
    65..90 : Result := Result - 64;
    97..122: Result := Result - 95;
    else
      Result := 0;
  end;
end;

procedure GetFilesFrom(Strings : TStrings; const path : string; const extention : string = '*.*');
var TSR : TSearchRec;
begin
  if not DirectoryExists(Path) then
    exit;
  Strings.BeginUpdate;
  try
    if SysUtils.FindFirst(path+extention, faAnyFile, TSR) = 0 then
    repeat
      Strings.Add(TSR.Name);
    until SysUtils.FindNext(TSR) <> 0;
  finally
    SysUtils.FindClose(TSR);
    Strings.EndUpdate;
  end;
end;

function GetDiskName(const DL : TDiskLetterMask) : String;
var
  FLSys, VName : array[0..255] of Char;
  SerNM, MaxFN, CType : DWORD;
begin
  GetVolumeInformation(PChar(DL+':\'), VName, SizeOf(VName), @SerNM, MaxFN, CType, FLSys, sizeOf(FLSys));
  Result := string(VName);
end;

function GetDiskFileSystem(const DL : TDiskLetterMask) : string;
var
  FLSys, VName : array[0..255] of Char;
  SerNM, MaxFN, CType : DWORD;
begin
  GetVolumeInformation(PChar(DL+':\'), VName, SizeOf(VName), @SerNM, MaxFN, CType, FLSys, sizeOf(FLSys));
  Result := string(FLSys);
end;

function GetDiskType(const DL : TDiskLetterMask) : cardinal;
begin
  result := GetDriveType(PChar(DL+':\'));
end;

function GetDiskTypeX(const DL : TDiskLetterMask) : integer;
var
  FLSys, VName : array[0..255] of Char;
  SerNM, MaxFN, CType : DWORD;
begin
  GetVolumeInformation(PChar(DL+':\'), VName, SizeOf(VName), @SerNM, MaxFN, CType, FLSys, sizeOf(FLSys));
  Result := integer(CType);
end;

function DiskTypeToStr(const DT : cardinal) : string;
begin
  case DT of
    0 : result := 'Unknow';
    1 : result := 'Local drive';
    2 : result := 'Removable drive';
    3 : result := 'Local drive';
    4 : result := 'Network drive';
    5 : result := 'CD/DVD rom';
    6 : result := 'RAM disk';
    else
      result := IntToStr(DT);
  end;
end;

function GetDiskSerial(const DL : TDiskLetterMask) : integer;
var
  FLSys, VName : array[0..255] of Char;
  SerNM, MaxFN, CType : DWORD;
begin
  GetVolumeInformation(PChar(DL+':\'), VName, SizeOf(VName), @SerNM, MaxFN, CType, FLSys, sizeOf(FLSys));
  Result := integer(SerNM);
end;

function DiskSerialToStr(const DS : integer) : string;
var pR : PChar;
    pB : ^Byte;
    N  : integer;
const
    BTC : array[0..15] of char = '0123456789ABCDEF';
begin
   SetLength(Result, 9);
   pR := PChar(Result);
   pB := @DS;
   inc(pB,3);
   for N := 0 to 3 do
   begin
     pR[0] := BTC[pB^ shr 4];
     pR[1] := BTC[pB^ and $F];
     dec(pB);
     if N = 1 then
     begin
       pR[2] := '-';
       inc(pR,3);
     end
     else
       inc(pR,2);
   end;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TDisk.Create;
begin
  SetDiskNumber(0);
end;

constructor TDisk.Create(const DiskLetter: TDiskLetterMask);
begin
  SetDiskLetter(DiskLetter);
end;

constructor TDisk.Create(const DiskNumber: TDiskNumberMask);
begin
  SetDiskNumber(DiskNumber);
end;

procedure TDisk.SetDiskNumber(const val : TDiskNumberMask);
begin
  if fDiskNumber <> val then
  begin
    fDiskNumber := val;
    fDiskLetter := DiskNumberToLetter(val);
    GetInfos;
  end;
end;

procedure TDisk.SetDiskLetter(const val: TDiskLetterMask);
begin
  if fDiskLetter <> val then
  begin
    fDiskLetter := val;
    fDiskNumber := DiskLetterToNumber(val);
    GetInfos;
  end;
end;

procedure TDisk.GetInfos;
begin
  if DiskSize(fDiskNumber) = -1 then
  begin
    fDiskExist    := false;
    fSizeTotal    := 0;
    fSizeFree     := 0;
    fSizeUsed     := 0;
    fVolumeName   := '';
    fFileSystem   := '';
    fDriveType    := 0;
    fDriveTypeStr := '0';
    fPercentFree  := 0;
    fPercentUsed  := 0;
    fDriveSerial  := 0;
    fDriveSerialStr := '0000-0000';
  end
  else
  begin
    fDiskExist      := true;
    fSizeTotal      := round(GetDiskSize(fDiskNumber,dsByte,dsTotal));
    fSizeFree       := round(GetDiskSize(fDiskNumber,dsByte,dsFree));
    fSizeUsed       := round(GetDiskSize(fDiskNumber,dsByte,dsUsed));
    fVolumeName     := GetDiskName(fDiskLetter);
    fFileSystem     := GetDiskFileSystem(fDiskLetter);
    fDriveType      := GetDiskType(fDiskLetter);
    fDriveTypeStr   := DiskTypeToStr(fDriveType);
    fPercentFree    := ValueToPercent(fSizeFree,fSizeTotal);
    fPercentUsed    := ValueToPercent(fSizeUsed,fSizeTotal);
    fDriveSerial    := GetDiskSerial(fDiskLetter);
    fDriveSerialStr := DiskSerialToStr(fDriveSerial);
  end;
end;

{ That all folk! (^_^)
}

end.
