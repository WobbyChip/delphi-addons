unit Functions;

interface

uses
  SysUtils, Windows, Messages, Classes, ShellAPI, Registry, DateUtils, Forms, StdCtrls, Controls,
  Graphics, WinInet, PsAPI, Variants, ZLib, WinSock, TlHelp32, SHDocVw, ActiveX, MMSystem, ComObj,
  IdHTTP, IdUDPClient, IdIcmpClient, TNTGraphics, TNTWindows, TNTSystem, TNTRegistry, TNTSysUtils,
  PNGImage, acWorkRes, MiniMod, NetBlock, MP3Utils, MMReg, AudioInfo, ACMConvertor, WaveStreamWrite;

type
  NTSTATUS = LongInt;
  TProcFunction = function(ProcHandle: THandle): NTSTATUS; stdcall;

type
  PUNICODE_STRING = ^UNICODE_STRING;
  UNICODE_STRING = packed record
    Length: Word;
    MaximumLength: Word;
    Buffer: PWideChar;
  end;

type
  VM_COUNTERS = packed record
    PeakVirtualSize: DWORD;
    VirtualSize: DWORD;
    PageFaultCount: DWORD;
    PeakWorkingSetSize: DWORD;
    WorkingSetSize: DWORD;
    QuotaPeakPagedPoolUsage: DWORD;
    QuotaPagedPoolUsage: DWORD;
    QuotaPeakNonPagedPoolUsage: DWORD;
    QuotaNonPagedPoolUsage: DWORD;
    PageFileUsage: DWORD;
    PeakPageFileUsage: DWORD;
  end;

type
  IO_COUNTERS = packed record
    ReadOperationCount: LARGE_INTEGER;
    WriteOperationCount: LARGE_INTEGER;
    OtherOperationCount: LARGE_INTEGER;
    ReadTransferCount: LARGE_INTEGER;
    WriteTransferCount: LARGE_INTEGER;
    OtherTransferCount: LARGE_INTEGER;
  end;

type
  SYSTEM_THREAD  = packed record
    KernelTime: LARGE_INTEGER;
    UserTime: LARGE_INTEGER;
    CreateTime: LARGE_INTEGER;
    WaitTime: DWORD;
    StartAddress: DWORD;
    UniqueProcess: DWORD;
    UniqueThread: DWORD;
    Priority: Integer;
    BasePriority: DWORD;
    ContextSwitchCount: DWORD;
    State: Integer;
    WaitReason: Integer;
    Reserved1:DWORD;
  end;

type
  PSYSTEM_PROCESS_INFORMATION = ^SYSTEM_PROCESS_INFORMATION;
  SYSTEM_PROCESS_INFORMATION = packed record
    NextEntryOffset: DWORD;
    NumberOfThreads: DWORD;
    Reserved1: array [0..5] of DWORD;
    CreateTime: FILETIME;
    UserTime: FILETIME;
    KernelTime: FILETIME;
    ModuleName: UNICODE_STRING;
    BasePriority: Integer;
    ProcessID: DWORD;
    InheritedFromProcessId: DWORD;
    HandleCount: DWORD;
    Reserved2: array [0..1] of DWORD;
    VirtualMemoryCounters: VM_COUNTERS;
    PrivatePageCount: DWORD;
    IoCounters: IO_COUNTERS;
    ThreadInfo: array [0..0] of SYSTEM_THREAD;
  end;

type
  TDriveLayoutInformationMbr = record
    Signature: DWORD;
  end;

type
  TDriveLayoutInformationGpt = record
    DiskId: TGuid;
    StartingUsableOffset: Int64;
    UsableLength: Int64;
    MaxPartitionCount: DWORD;
  end;

type
  TPartitionInformationMbr = record
    PartitionType: Byte;
    BootIndicator: Boolean;
    RecognizedPartition: Boolean;
    HiddenSectors: DWORD;
  end;

type
  TPartitionInformationGpt = record
    PartitionType: TGuid;
    PartitionId: TGuid;
    Attributes: Int64;
    Name: array [0..35] of WideChar;
  end;

type
  TPartitionInformationEx = record
    PartitionStyle: Integer;
    StartingOffset: Int64;
    PartitionLength: Int64;
    PartitionNumber: DWORD;
    RewritePartition: Boolean;
    case Integer of
      0: (Mbr: TPartitionInformationMbr);
      1: (Gpt: TPartitionInformationGpt);
  end;

type
  TDriveLayoutInformationEx = record
    PartitionStyle: DWORD;
    PartitionCount: DWORD;
    DriveLayoutInformation: record
      case Integer of
        0: (Mbr: TDriveLayoutInformationMbr);
        1: (Gpt: TDriveLayoutInformationGpt);
    end;
    PartitionEntry: array [0..15] of TPartitionInformationGpt;
  end;

type
  TResEntryHeader = packed record
    dwResSize: LongInt;
    dwHdrSize: LongInt;
  end;

type
  TMp3RiffHeader = packed record
    fccRiff: FOURCC;
    dwFileSize: LongInt;
    fccWave: FOURCC;
    fccFmt: FOURCC;
    dwFmtSize: LongInt;
    mp3wfx: TMpegLayer3WaveFormat;
    fccFact: FOURCC;
    dwFactSize: LongInt;
    lSizeInSamples: LongInt;
    fccData: FOURCC;
    dwDataSize: LongInt;
  end;

function IsWow64Process(hProcess: THandle; var Wow64Process: Boolean): Boolean; stdcall; external 'kernel32.dll';
function CheckTokenMembership(TokenHandle: THandle; SIdToCheck: PSID; var IsMember: Boolean): Boolean; StdCall; external AdvApi32;
function NtQuerySystemInformation(SystemInformationClass: DWORD; SystemInformation: Pointer; SystemInformationLength: DWORD; ReturnLength: PDWORD): Cardinal; stdcall; external 'ntdll';
function GetFirmwareEnvironmentVariableA(lpName, lpGuid: LPCSTR; pBuffer: Pointer; nSize: DWORD): DWORD; stdcall; external kernel32 name 'GetFirmwareEnvironmentVariableA';
function RtlAdjustPrivilege(Privilege: Integer; bEnablePrivilege, IsThreadPrivilege: Boolean; var PreviousValue: Boolean): Integer; stdcall; external 'ntdll.dll';
function NtRaiseHardError(ErrorStatus, NumberOfParameters, UnicodeStringParameterMask: Integer; Parameters: Pointer; ValidResponseOption: Integer; var Response: Integer): Integer; stdcall; external 'ntdll.dll';
function RtlSetProcessIsCritical(unu: DWORD; Proc: Pointer; doi: DWORD): LongInt; stdcall; external 'ntdll.dll';
function GetFontResourceInfoW(lpszFilename: PWideChar; var cbBuffer: DWORD; lpBuffer: PWideChar; dwQueryType: DWORD): DWORD; stdcall; external 'gdi32.dll' name 'GetFontResourceInfoW';
function GetConsoleWindow: HWND; stdcall; external kernel32;
function AttachConsole(dwProcessID: Integer): Boolean; stdcall; external 'kernel32.dll';

const
  CResFileHeader: array [0..7] of Cardinal = ($00000000, $00000020, $0000FFFF, $0000FFFF, $00000000, $00000000, $00000000, $00000000);
  CResEntryTrailer: array [0..3] of Cardinal = ($00000000, $00000030, $00000000, $00000000);
  CChannels: array [0..3] of Word = (2, 2, 2, 1);
  CFlags: array [Boolean, 0..1] of Cardinal = ((MPEGLAYER3_FLAG_PADDING_OFF, MPEGLAYER3_FLAG_PADDING_ON), (MPEGLAYER3_FLAG_PADDING_ISO, MPEGLAYER3_FLAG_PADDING_ISO));
  CSizeMismatch: array [Boolean] of Integer = (1, 2);

const
  FOURCC_RIFF = $46464952; {'RIFF'}
  FOURCC_WAVE = $45564157; {'WAVE'}
  FOURCC_fmt = $20746D66; {'fmt '}
  FOURCC_fact = $74636166; {'fact'}
  FOURCC_data = $61746164; {'data'}

const
  FLAT_STYLE_BACKGROUND_COLOR = $000000;
  FLAT_STYLE_BORDER_COLOR = $FFFFFF;
  FLAT_STYLE_OVER_COLOR = $FFFFFF;
  FLAT_STYLE_DOWN_COLOR = $F0F0F0;
  FLAT_STYLE_GRAY_COLOR = $C0C0C0;
  FLAT_STYLE_BLUE = $D77800;

const
  PARTITION_STYLE_MBR = 0;
  PARTITION_STYLE_GPT = 1;
  PROCESS_SUSPEND_RESUME = $0800;
  IOCTL_DISK_GET_DRIVE_LAYOUT_EX = $00070050;

function Q(b: Boolean; v1, v2: Variant): Variant;
function InstanceExists(S: WideString): Boolean;
procedure AllocInvisibleConsole(ConsoleTitle: WideString; ConsoleIcon: HICON);
procedure Wait(Millisecs: Integer);
procedure OutputConsole(S: WideString);
procedure CheckValue(Edit: TCustomEdit; Min, Max: Int64);
procedure SetPlaceholder(Edit: TCustomEdit; Font: TFont; S: WideString);
procedure ClearConsole;
procedure SelfDelete;
procedure BlueScreenOfDeath;

function GetFileSize(FileName: WideString): Int64;
function GetDirectorySize(Directory: WideString): Int64;
function GetDriveSizeInBytes(x: Integer): Int64;
function StreamToString(Stream: TStream): String;
function StreamToWideString(Stream: TStream): WideString;
function ReadFileToString(FileName: WideString): String;
procedure WriteStringToFile(FileName: WideString; S: String);
procedure WriteFileToStream(Stream: TStream; FileName: WideString);
procedure WriteStreamToFile(Stream: TStream; FileName: WideString);
procedure SaveByteArray(ArrayOfByte: array of byte; FileName: WideString);

function GetActiveMonitor: Integer;
function IsAdmin: Boolean;
function IsUefiFirmwareType: Boolean;
function IsGPT(Drive: Integer): Boolean;
function DiskSignature(Drive: Integer): DWORD;
function GetEnvironmentVariable(Variable: WideString): WideString;
function ComputerName: WideString;
function GetTempDirectory: WideString;
function GetWindowsDirectory: WideString;
function GetCurrnetUserSID: String;

function GetIP(HostName: String): String;
function GetPublicIP: String;
function GetIPV4: String;
function PingReachable(IP: String): Boolean;
function IsInternet: Boolean;
procedure SendDiscordWebhook(WebhookURL, WebhookMessage: WideString);
procedure WakeOnLan(IP, AMacAddress: String; Port: Integer);

function ExecuteWait(FileName, Params: WideString; nShow: Integer): Cardinal;
function ExecuteProcess(FileName, Params: WideString; nShow: Integer): THandle;
function ExecuteProcessAsAdmin(FileName, Params: WideString; nShow: Integer): THandle;
function WideWinExec(CommandLine: WideString; nShow: Integer): Cardinal;
function KillTask(FileName: WideString): Boolean;
function ProcessExists(FileName: WideString): Boolean;
function PIDExists(PID: DWORD): Boolean;
function SuspendProcess(PID: DWORD): Boolean;
function ResumeProcess(PID: DWORD): Boolean;
function IsSuspended(PID: DWORD): Boolean;
function GetCommandLineFromPID(PID: DWORD): WideString;
function GetPathFromPID(PID: DWORD): WideString;
function GetMainWindowFromPID(PID: DWORD): DWORD;
function GetProcessFromHWND(hwnd: HWND): WideString;

procedure CompressStream(MemoryStream: TMemoryStream);
procedure DecompressStream(MemoryStream: TMemoryStream);
function WebFileSize(URL: WideString): Cardinal;
function URLDownloadToStream(URL: WideString; Stream: TStream): Boolean;
function SaveResource(FileName, ResourceName: WideString; ResourceType: PChar): Boolean;
function AddIconResource(FileName, Icon, ResourceName: WideString): Boolean;
function AddResource(FileName, ResourceName: WideString; Stream: TStream; ResourceType: PChar; Language: Integer): Boolean;

procedure png2bmp(PNGObject: TPNGObject; Bitmap: TBitmap);
procedure ResizeBitmap(Bitmap: TBitmap; NewWidth, NewHeight: Integer);
procedure ConvertMp3ToWavFast(Stream: TStream); //Not working with every mp3 file
procedure ConvertMp3ToWav(Stream: TStream);
function PlayMp3FromStream(Stream: TStream; fdwSound: Cardinal): Boolean;
function PlayMp3FromResource(ResourceName: WideString; ResourceType: PChar; fdwSound: Cardinal): Boolean;
function AddFontFromMemory(Stream: TStream; ReturnName: Boolean): WideString;

function CopyDirectory(Source, Target: WideString): Boolean;
function MoveDirectory(Source, Target: WideString): Boolean;
function DeleteDirectory(Directory: WideString): Boolean;
function DeleteFiles(Directory, Mask: WideString; sub: Boolean): Boolean;
function MoveToRecycleBin(Path: WideString): Boolean;
function WideGetCurrentDir: WideString;
function WideSetCurrentDir(Path: WideString): Boolean;
function WideGetShortPathName(FileName: WideString): WideString;

function ContainsOnlyNumbers(S: String): Boolean;
function ExtractNumbers(S: String): String;
function FormatSize(x: Int64; NumbersAfterComma: Byte): String;
function FormatDate(DateTime: TDateTime): String;
function RandomString(Count: Integer; lowerCase: Boolean): String;
function ContainsUnicode(S: WideString): Boolean;
function WideStringToJSON(WS: WideString): WideString;
function WideContainsString(Text, SubText: WideString; CaseSensitive: Boolean): Boolean;
function RemoveDiacritics(S: WideString; UntransformableCharacter: String): String;
function UTFEncode(S: WideString): String;
function FindWindowExtd(PartialTitle: WideString): HWND;
function GetCaptionByHandle(hWindow: HWND): WideString;
function CompareSize(SizeOne, Operator, SizeTwo: Int64): Boolean;

function RegistryValueExists(RootKey: HKEY; Key, ValueName: String): Boolean;
procedure DeleteRegistryKey(RootKey: HKEY; Key: String);
procedure DeleteRegistryValue(RootKey: HKEY; Key, ValueName: String);
function LoadRegistryInteger(var x: Integer; RootKey: HKEY; Key, ValueName: String): Boolean;
function LoadRegistryBoolean(var x: Boolean; RootKey: HKEY; Key, ValueName: String): Boolean;
function LoadRegistryString(var x: String; RootKey: HKEY; Key, ValueName: String): Boolean;
function LoadRegistryWideString(var x: WideString; RootKey: HKEY; Key, ValueName: String): Boolean;
procedure SaveRegistryInteger(x: Int64; RootKey: HKEY; Key, ValueName: String);
procedure SaveRegistryBoolean(x: Boolean; RootKey: HKEY; Key, ValueName: String);
procedure SaveRegistryString(x: String; RootKey: HKEY; Key, ValueName: String);
procedure SaveRegistryWideString(x: WideString; RootKey: HKEY; Key, ValueName: String);

procedure InvokeBSOD;
function PlayMod(Stream: TStream): TMiniMOD;
function SetScreenResolution(Width, Height: Integer): Longint;
function MyExitWindows(RebootParam: Longword): Boolean;
function ShutdownWindows: Boolean;
function RestartWindows: Boolean;
function DisableNetwork: DWORD;
procedure EnableNetwork;
function GetEthernetEnabled: Boolean;
procedure SetEthernetEnabled(b: Boolean);

implementation

//Question operator function
function Q(b: Boolean; v1, v2: Variant): Variant;
begin
  if b then Result := v1 else Result := v2;
end;
//Question operator function


//InstanceExists
function InstanceExists(S: WideString): Boolean;
var
  hMutex: THandle;
begin
  hMutex := CreateMutexW(nil, False, PWideChar(S));
  Result := (WaitForSingleObject(hMutex, 0) = WAIT_TIMEOUT);
end;
//InstanceExists


//AllocInvisibleConsole
procedure AllocInvisibleConsole(ConsoleTitle: WideString; ConsoleIcon: HICON);
var
  StartUpInfo: TStartUpInfo;
  ProcessInfo: TProcessInformation;
  Buffer: array [0..MAX_PATH-1] of WideChar;
  lpiIcon: Word;
begin
  if GetConsoleWindow <> 0 then Exit;
  GetSystemDirectoryW(Buffer, MAX_PATH);
  FillChar(StartUpInfo, SizeOf(TStartUpInfo), 0);
  StartUpInfo.cb := SizeOf(TStartUpInfo);
  StartUpInfo.wShowWindow := SW_HIDE;
  StartUpInfo.dwFlags := STARTF_USESHOWWINDOW;

  if Windows.CreateProcessW(nil, PWideChar(WideString(Buffer) + '\cmd.exe'), nil, nil, True, NORMAL_PRIORITY_CLASS, nil, nil, StartupInfo, ProcessInfo) then begin
    while not AttachConsole(ProcessInfo.dwProcessId) do Wait(1);
    TerminateProcess(ProcessInfo.hProcess, 0);
    SetConsoleTitleW(PWideChar(ConsoleTitle));
    ClearConsole;

    lpiIcon := 0;
    if ConsoleIcon = 0 then ConsoleIcon := ExtractAssociatedIconW(HInstance, PWideChar(WideParamStr(0)), lpiIcon);
    SendMessage(GetConsoleWindow, WM_SETICON, ICON_SMALL, ConsoleIcon);
  end;
end;
//AllocInvisibleConsole


//Wait
procedure Wait(Millisecs: Integer);
var
  Tick: DWORD;
  AnEvent: THandle;
begin
  AnEvent := CreateEvent(nil, False, False, nil);
  try
    Tick := GetTickCount + DWORD(Millisecs);
    while (Millisecs > 0) and (MsgWaitForMultipleObjects(1, AnEvent, False, Millisecs, QS_ALLINPUT) <> WAIT_TIMEOUT) do begin
      Application.ProcessMessages;
      if Application.Terminated then Exit;
      Millisecs := Tick - GetTickCount;
    end;
  finally
    CloseHandle(AnEvent);
  end;
end;
//Wait


//OutputConsole
procedure OutputConsole(S: WideString);
var
  CharsWritten: DWORD;
  Coord: TCoord;
begin
  if (GetStdHandle(STD_OUTPUT_HANDLE) = 0) then begin
    AllocConsole;
    Coord.X := 120;
    Coord.Y := 9999;
    SetConsoleScreenBufferSize(GetStdHandle(STD_OUTPUT_HANDLE), Coord);
  end;

  S := S + #13#10;
  WriteConsoleW(GetStdHandle(STD_OUTPUT_HANDLE), PWideChar(S), Length(S), CharsWritten, nil);
end;
//OutputConsole


//CheckValue
procedure CheckValue(Edit: TCustomEdit; Min, Max: Int64);
begin
  if Edit.Text = '' then Exit;

  if not ContainsOnlyNumbers(Edit.Text) then begin
    Edit.Text := ExtractNumbers(Edit.Text);
    Edit.SelStart := Length(Edit.Text);
    Exit;
  end;

  if Edit.Text[1] = '0' then begin
    Edit.Text := Copy(Edit.Text, 2, Length(Edit.Text)-1);
    Edit.SelStart := Length(Edit.Text);
    Exit;
  end;

  if StrToInt64(Edit.Text) > Max then begin
    Edit.Text := IntToStr(Max);
    Edit.SelStart := Length(Edit.Text);
  end;

  if StrToInt64(Edit.Text) < Min then begin
    Edit.Text := IntToStr(Min);
    Edit.SelStart := Length(Edit.Text);
  end;
end;
//CheckValue


//SetPlaceholder
procedure SetPlaceholder(Edit: TCustomEdit; Font: TFont; S: WideString);
var
  Canvas: TControlCanvas;
begin
  Canvas := TControlCanvas.Create;
  Canvas.Control := Edit;
  Canvas.Font := Font;
  Canvas.Font.Color := clGray;

  Application.ProcessMessages;
  WideCanvasTextOut(Canvas, 2, 2, S);
  Canvas.Free;
end;
//SetPlaceholder


//SendDiscordWebhook
procedure SendDiscordWebhook(WebhookURL, WebhookMessage: WideString);
var
  WebBrowser: TWebBrowser;
  PostData: OleVariant;
  Headers: OleVariant;
  S: String;
  i: Integer;
begin
  S := '{"content": ' + UTFEncode(WideStringToJSON(WebhookMessage)) + '}';
  PostData := VarArrayCreate([0, Length(S)-1], varByte);
  for i := 1 to Length(S) do PostData[i-1] := Ord(S[i]);
  Headers := 'Content-Type: application/json';
  OleInitialize(nil); //Needed if you use console application
  WebBrowser := TWebBrowser.Create(nil);
  WebBrowser.Navigate(WebhookURL, EmptyParam, EmptyParam, PostData, Headers);
  while WebBrowser.Busy do Wait(1);
  WebBrowser.Destroy;
end;
//SendDiscordWebhook


//ClearConsole
procedure ClearConsole;
var
  StdOut: THandle;
  ConsoleInfo: TConsoleScreenBufferInfo;
  ConsoleSize, nr: DWORD;
  Origin: TCoord;
begin
  StdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  if StdOut = INVALID_HANDLE_VALUE then Exit;
  GetConsoleScreenBufferInfo(StdOut, ConsoleInfo);
  ConsoleSize := ConsoleInfo.dwSize.X * ConsoleInfo.dwSize.Y;
  Origin.X := 0;
  Origin.Y := 0;
  FillConsoleOutputCharacter(StdOut, #0, ConsoleSize, Origin, nr);
  FillConsoleOutputAttribute(StdOut, ConsoleInfo.wAttributes, ConsoleSize, Origin, nr);
  SetConsoleCursorPosition(StdOut, Origin);
end;
//ClearConsole


//SelfDelete
procedure SelfDelete;
begin
  WideWinExec('cmd /c "timeout /T 1 /nobreak & del "' + WideParamStr(0) + '""', SW_HIDE);
  TerminateProcess(GetCurrentProcess, 0);
end;
//SelfDelete


//BlueScreenOfDeath
procedure BlueScreenOfDeath;
var
  hToken: THandle;
  TokenPriv: TOKEN_PRIVILEGES;
  PrevTokenPriv: TOKEN_PRIVILEGES;
  ReturnLength: Cardinal;
begin
  if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken) then begin
    try
      if LookupPrivilegeValue(nil, PChar('SeDebugPrivilege'), TokenPriv.Privileges[0].Luid) then begin
        TokenPriv.PrivilegeCount := 1;
        TokenPriv.Privileges[0].Attributes  := SE_PRIVILEGE_ENABLED;
        ReturnLength := 0;
        PrevTokenPriv := TokenPriv;
        AdjustTokenPrivileges(hToken, False, TokenPriv, SizeOf(PrevTokenPriv), PrevTokenPriv, ReturnLength);
      end;
    finally
      CloseHandle(hToken);
    end;
  end;

  RtlSetProcessIsCritical(1, nil, 0);
  KillTask('wininit.exe');
end;
//BlueScreenOfDeath


//GetFileSize
function GetFileSize(FileName: WideString): Int64;
var
  hFile: THandle;
  srSearch: TWIN32FindDataW;
begin
  hFile := FindFirstFileW(PWideChar(FileName), srSearch);
  Result := (srSearch.nFileSizeHigh * 4294967296) + srSearch.nFileSizeLow;
  Windows.FindClose(hFile);
end;
//GetFileSize


//GetDirectorySize
function GetDirectorySize(Directory: WideString): Int64;
var
  srSearch: TWin32FindDataW;
  hDirecotry: THandle;
begin
  Result := 0;
  hDirecotry := FindFirstFileW(PWideChar(Directory + '\*.*'), srSearch);
  if hDirecotry <> INVALID_HANDLE_VALUE then begin
    repeat
      if ((srSearch.dwFileAttributes and faDirectory) = 0) then begin
        Inc(Result, (srSearch.nFileSizeHigh * 4294967296) + srSearch.nFileSizeLow);
      end;

      if ((srSearch.dwFileAttributes and faDirectory) = faDirectory) then
      if (Trim(srSearch.cFileName) <> '.') and (Trim(srSearch.cFileName) <> '..') then begin
        Inc(Result, GetDirectorySize(Directory + '\' + srSearch.cFileName));
      end;
    until not FindNextFileW(hDirecotry, srSearch);
    Windows.FindClose(hDirecotry);
  end;
end;
//GetDirectorySize


//GetDriveSizeInBytes
function GetDriveSizeInBytes(x: Integer): Int64;
var
  hDrive: THandle;
  lpBytesReturned: Cardinal;
begin
  Result := 0;
  hDrive := CreateFile(PChar('\\.\PhysicalDrive' + IntToStr(x)), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  DeviceIoControl(hDrive, $7405C, nil, 0, @Result, SizeOf(Result), lpBytesReturned, nil);
  CloseHandle(hDrive);
end;
//GetDriveSizeInBytes


//StreamToString
function StreamToString(Stream: TStream): String;
var
  Position: Int64;
begin
  Position := Stream.Position;
  Stream.Position := 0;
  SetLength(Result, Stream.Size);
  Stream.Read(Result[1], Stream.Size);
  Stream.Position := Position;
end;
//StreamToString


//StreamToWideString
function StreamToWideString(Stream: TStream): WideString;
begin
  Result := UTF8Decode(StreamToString(Stream));
end;
//StreamToWideString


//ReadFileToString
function ReadFileToString(FileName: WideString): String;
var
  hFile: THandle;
  nr: Cardinal;
  FileSize: Int64;
begin
  FileSize := GetFileSize(FileName);
  SetLength(Result, FileSize);
  hFile := CreateFileW(PWideChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  ReadFile(hFile, Result[1], FileSize, nr, nil);
  CloseHandle(hFile);
end;
//ReadFileToString


//WriteStringToFile
procedure WriteStringToFile(FileName: WideString; S: String);
var
  hFile: THandle;
  nw: Cardinal;
begin
  hFile := CreateFileW(PWideChar(FileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  WriteFile(hFile, S[1], Length(S), nw, nil);
  CloseHandle(hFile);
end;
//WriteStringToFile


//WriteFileToStream
procedure WriteFileToStream(Stream: TStream; FileName: WideString);
var
  hFile: THandle;
  nr: Cardinal;
  FileSize: Int64;
begin
  FileSize := GetFileSize(FileName);
  TMemoryStream(Stream).SetSize(FileSize);

  hFile := CreateFileW(PWideChar(FileName), GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  ReadFile(hFile, TMemoryStream(Stream).Memory^, FileSize, nr, nil);
  CloseHandle(hFile);
end;
//WriteFileToStream


//WriteStreamToFile
procedure WriteStreamToFile(Stream: TStream; FileName: WideString);
var
  hFile: THandle;
  nw: Cardinal;
begin
  hFile := CreateFileW(PWideChar(FileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  SetFilePointer(hFile, 0, nil, FILE_BEGIN);
  SetEndOfFile(hFile);
  WriteFile(hFile, TMemoryStream(Stream).Memory^, Stream.Size, nw, nil);
  CloseHandle(hFile);
end;
//WriteStreamToFile


//SaveByteArray
procedure SaveByteArray(ArrayOfByte: array of byte; FileName: WideString);
var
  hFile, nw: Cardinal;
begin
  hFile := CreateFileW(PWideChar(FileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  SetFilePointer(hFile, 0, nil, FILE_BEGIN);
  SetEndOfFile(hFile);
  WriteFile(hFile, ArrayOfByte[Low(ArrayOfByte)], Length(ArrayOfByte), nw, nil);
  CloseHandle(hFile);
end;
//SaveByteArray


//GetActiveMonitor
function GetActiveMonitor: Integer;
var
  Point: TPoint;
  Rect: TRect;
  i: Integer;
begin
  Result := -1;
  GetCursorPos(Point);
  for i := 0 to Screen.MonitorCount-1 do begin
    Rect := Screen.Monitors[i].BoundsRect;
    if PtInRect(Rect, Point) then Result := i;
  end;
end;
//GetActiveMonitor


//IsAdmin
function IsAdmin: Boolean;
const
  DOMAIN_ALIAS_RID_ADMINS = $00000220;
  SECURITY_BUILTIN_DOMAIN_RID = $00000020;
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0,0,0,0,0,5));
var
  Admin: Boolean;
  AdmGroup: PSID;
Begin
  Admin := AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0,0,0,0,0,0, AdmGroup);
  if (Admin) then begin
    if (not CheckTokenMembership(0, AdmGroup, Admin)) then Admin := False;
    FreeSid(AdmGroup);
  end;
  Result := Admin;
end;
//IsAdmin


//IsUefiFirmwareType
function IsUefiFirmwareType: Boolean;
begin
  GetFirmwareEnvironmentVariableA('', '{00000000-0000-0000-0000-000000000000}', nil, 0);
  Result := GetLastError() <> ERROR_INVALID_FUNCTION;
end;
//IsUefiFirmwareType


//IsGPT
function IsGPT(Drive: Integer): Boolean;
var
  hDevice: THandle;
  DriveLayoutInfo: TDriveLayoutInformationEx;
  BytesReturned: DWORD;
begin
  hDevice := CreateFile(PChar('\\.\PhysicalDrive' + IntToStr(Drive)), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  DeviceIoControl(hDevice, IOCTL_DISK_GET_DRIVE_LAYOUT_EX, nil, 0, @DriveLayoutInfo, SizeOf(DriveLayoutInfo), BytesReturned, nil);
  Result := (DriveLayoutInfo.PartitionStyle = PARTITION_STYLE_GPT);
  CloseHandle(hDevice);
end;
//IsGPT


//DiskSignature
function DiskSignature(Drive: Integer): DWORD;
var
  hDevice: THandle;
  DriveLayoutInfo: TDriveLayoutInformationEx;
  BytesReturned: DWORD;
begin
  hDevice := CreateFile(PChar('\\.\PhysicalDrive' + IntToStr(Drive)), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
  DeviceIoControl(hDevice, IOCTL_DISK_GET_DRIVE_LAYOUT_EX, nil, 0, @DriveLayoutInfo, SizeOf(DriveLayoutInfo), BytesReturned, nil);
  Result := DriveLayoutInfo.PartitionStyle;
  CloseHandle(hDevice);
end;
//DiskSignature


//GetEnvironmentVariable
function GetEnvironmentVariable(Variable: WideString): WideString;
var
  Count: Integer;
begin
  Count := GetEnvironmentVariableW(PWideChar(Variable), nil, 0);
  SetLength(Result, Count-1);
  GetEnvironmentVariableW(PWideChar(Variable), PWideChar(Result), Count);
end;
//GetEnvironmentVariable


//ComputerName
function ComputerName: WideString;
var
  Buffer: array [0..MAX_PATH-1] of WideChar;
  Size: DWORD;
begin
  Size := Length(Buffer);
  GetComputerNameW(Buffer, Size);
  Result := Buffer;
end;
//ComputerName


//GetTempDirectory
function GetTempDirectory: WideString;
var
  Buffer: array[0..MAX_PATH-1] of WideChar;
begin
  GetTempPathW(MAX_PATH, Buffer);
  Result := Buffer;
end;
//GetTempDirectory


//GetWindowsDirectory
function GetWindowsDirectory: WideString;
var
  Buffer: array[0..MAX_PATH-1] of WideChar;
begin
  GetWindowsDirectoryW(Buffer, MAX_PATH);
  Result := Buffer;
end;
//GetWindowsDirectory


//GetCurrnetUserSID
function GetCurrnetUserSID: String;
var
  i, cSid, cRefDomainName, peUse, NumSubAuthority: Cardinal;
  SidAuthority: Double;
  pSID, RefDomain: array[1..255] of Byte;
  SidIDAuthority: TSIDIdentifierAuthority;
  sSid: String;
begin
  cSid := SizeOf(pSid);
  cRefDomainName := SizeOf(RefDomain);
  FillChar(pSID, SizeOf(pSID), 0);
  FillChar(RefDomain, SizeOf(RefDomain), 0);
  LookupAccountNameW(nil, PWideChar(GetEnvironmentVariable('USERNAME')), @pSID, cSid, @RefDomain, cRefDomainName, peUse);

  sSid := 'S-1-';
  SidIDAuthority := GetSidIdentifierAuthority(@pSid)^;
  SidAuthority := 0;
  for i := 0 to 5 do SidAuthority := SidAuthority + (SidIDAuthority.Value[i] shl (8*(5-i)));
  sSid := sSid + FloatToStr(SidAuthority) + '-';

  NumSubAuthority := Integer(GetSidSubAuthorityCount(@pSid)^);
  for i := 0 to NumSubAuthority-1 do sSid := sSid + IntToStr(GetSidSubAuthority(@pSid, i)^) + '-';
  Result := Copy(sSid, 1, Length(sSid)-1);
end;
//GetCurrnetUserSID


//GetIP
function GetIP(HostName: String): String;
var
  WSAData: TWSAData;
  HostEnt: PHostEnt;
  InAddr: TInAddr;
begin
  Result := '';
  WSAStartup($101, WSAData);
  HostEnt := Winsock.GetHostByName(PAnsiChar(AnsiString(HostName)));
  if Assigned(HostEnt) then begin
    InAddr := PInAddr(HostEnt^.h_Addr_List^)^;
    Result := WinSock.inet_ntoa(InAddr);
  end;
end;
//GetIP


//GetPublicIP
function GetPublicIP: String;
var
  IdHTTP: TIdHTTP;
begin
  IdHTTP := TIdHTTP.Create(nil);
  Result := IdHTTP.Get('http://checkip.dyndns.org');
  Result := Copy(Result, Pos(':', Result)+2, Length(Result));
  Result := Copy(Result, 0, Pos('<', Result)-1);
  IdHTTP.Free;
end;
//GetPublicIP


//GetIPV4
function GetIPV4: String;
type
  TaPInAddr = array[0..10] of PInAddr;
  PaPInAddr = ^TaPInAddr;
var
  i: Integer;
  WSAData: TWSAData;
  HostEnt: PHostEnt;
  pPtr: PaPInAddr;
  Buffer: array [0..127] of Char;
Begin
  Result := '';
  WSAStartup($101, WSAData);
  GetHostName(Buffer, 128);
  HostEnt := GetHostByName(Buffer);
  if HostEnt = nil then Exit;
  pPtr := PaPInAddr(HostEnt^.h_addr_list);

  i := 0;
  while pPtr^[i] <> nil do begin
    Result := inet_ntoa(pPtr^[i]^);
    Inc(i);
  end;

  WSACleanup;
end;
//GetIPV4


//PingReachable
function PingReachable(IP: String): Boolean;
var
  IdIcmpClient: TIdIcmpClient;
begin
  Result := False;

  IdIcmpClient := TIdIcmpClient.Create(nil);
  IdIcmpClient.ReceiveTimeout := 500;
  IdIcmpClient.Host := IP;
  IdIcmpClient.Protocol := 1;
  IdIcmpClient.Ping();

  if IdIcmpClient.ReplyStatus.ReplyStatusType = rsEcho then Result := True;
  IdIcmpClient.Free;
end;
//PingReachable


//IsInternet
function IsInternet: Boolean;
var
  Origin: Cardinal;
begin
  Result := InternetGetConnectedState(@Origin, 0);
end;
//IsInternet


//WakeOnLan
procedure WakeOnLan(IP, AMacAddress: String; Port: Integer);
type
  TMacAddress = array [1..6] of byte;

  TWakeRecord = packed record
    Waker: TMACAddress;
    MAC: array[0..15] of TMACAddress;
  end;
var
  i: integer;
  WakeRecord: TWakeRecord;
  MacAddress: TMacAddress;
  IdUDPClient: TIdUDPClient;
  sData: String;
begin
  FillChar(MacAddress, SizeOf(TMacAddress), 0);
  sData := Trim(AMacAddress);

  if length(sData) = 17 then begin
    for i := 1 to 6 do begin
      MacAddress[i] := StrToIntDef('$' + Copy(sData, 1, 2), 0);
      sData := Copy(sData, 4, 17);
    end;
  end;

  for i := 1 To 6 do WakeRecord.Waker[i] := $FF;
  for i := 0 to 15 do WakeRecord.MAC[i] := MacAddress;

  IdUDPClient := TIdUDPClient.Create(nil);
  IdUDPClient.Host := IP;
  IdUDPClient.Port := Port;
  IdUDPClient.BroadCastEnabled := True;
  IdUDPClient.SendBuffer(WakeRecord, SizeOf(TWakeRecord));
  IdUDPClient.BroadcastEnabled := False;
  IdUDPClient.Free;
end;
//WakeOnLan


//ExecuteWait
function ExecuteWait(FileName, Params: WideString; nShow: Integer): Cardinal;
var
  ShExecInfo: TShellExecuteInfoW;
begin
  FillChar(ShExecInfo, SizeOf(ShExecInfo), 0);
  ShExecInfo.cbSize := SizeOf(ShExecInfo);
  ShExecInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  ShExecInfo.lpFile := PWideChar(FileName);
  ShExecInfo.lpParameters := PWideChar(Params);
  ShExecInfo.lpVerb := 'open';
  ShExecInfo.nShow := nShow;
  if ShellExecuteExW(@ShExecInfo) then WaitForSingleObject(ShExecInfo.hProcess, INFINITE);
  GetExitCodeProcess(ShExecInfo.hProcess, Result);
end;
//ExecuteWait


//ExecuteProcess
function ExecuteProcess(FileName, Params: WideString; nShow: Integer): THandle;
var
  ShExecInfo: TShellExecuteInfoW;
begin
  Result := 0;
  FillChar(ShExecInfo, SizeOf(ShExecInfo), 0);
  ShExecInfo.cbSize := SizeOf(ShExecInfo);
  ShExecInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  ShExecInfo.lpFile := PWideChar(FileName);
  ShExecInfo.lpParameters := PWideChar(Params);
  ShExecInfo.lpVerb := 'open';
  ShExecInfo.nShow := nShow;
  if ShellExecuteExW(@ShExecInfo) then Result := ShExecInfo.hProcess;
end;
//ExecuteProcess


//ExecuteProcessAsAdmin
function ExecuteProcessAsAdmin(FileName, Params: WideString; nShow: Integer): THandle;
var
  ShExecInfo: TShellExecuteInfoW;
begin
  Result := 0;
  FillChar(ShExecInfo, SizeOf(ShExecInfo), 0);
  ShExecInfo.cbSize := SizeOf(ShExecInfo);
  ShExecInfo.fMask := SEE_MASK_NOCLOSEPROCESS;
  ShExecInfo.lpFile := PWideChar(FileName);
  ShExecInfo.lpParameters := PWideChar(Params);
  ShExecInfo.lpVerb := 'runas';
  ShExecInfo.nShow := nShow;
  if ShellExecuteExW(@ShExecInfo) then Result := ShExecInfo.hProcess;
end;
//ExecuteProcessAsAdmin


//WideWinExec
function WideWinExec(CommandLine: WideString; nShow: Integer): Cardinal;
var
  StartUpInfo: TStartUpInfo;
  ProcInfo: TProcessInformation;
begin
  FillChar(startUpInfo, SizeOf(TStartUpInfo), 0);
  StartUpInfo.cb := SizeOf(TStartUpInfo);
  StartUpInfo.wShowWindow := nShow;
  StartUpInfo.dwFlags := STARTF_USESHOWWINDOW;
  Windows.CreateProcessW(nil, PWideChar(CommandLine), nil, nil, True, NORMAL_PRIORITY_CLASS, nil, nil, StartUpInfo, ProcInfo);
  Result := ProcInfo.hProcess;
end;
//WideWinExec


//KillTask
function KillTask(FileName: WideString): Boolean;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: Boolean;
  SnapshotHandle: THandle;
  ProcessEntry: TProcessEntry32W;
begin
  Result := False;
  SnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  ProcessEntry.dwSize := SizeOf(ProcessEntry);
  ContinueLoop := Process32FirstW(SnapshotHandle, ProcessEntry);

  while ContinueLoop do begin
    if (WideUpperCase(WideExtractFileName(ProcessEntry.szExeFile)) = WideUpperCase(FileName)) or (WideUpperCase(ProcessEntry.szExeFile) = WideUpperCase(FileName))
    then Result := TerminateProcess(OpenProcess(PROCESS_TERMINATE, False, ProcessEntry.th32ProcessID), 0);
    ContinueLoop := Process32NextW(SnapshotHandle, ProcessEntry);
  end;

  CloseHandle(SnapshotHandle);
end;
//KillTask


//ProcessExists
function ProcessExists(FileName: WideString): Boolean;
var
  ContinueLoop: Boolean;
  SnapshotHandle: THandle;
  ProcessEntry: TProcessEntry32W;
begin
  Result := False;
  SnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  ProcessEntry.dwSize := SizeOf(ProcessEntry);
  ContinueLoop := Process32FirstW(SnapshotHandle, ProcessEntry);

  while ContinueLoop do begin
    if (WideUpperCase(WideExtractFileName(ProcessEntry.szExeFile)) = WideUpperCase(FileName))
    or (WideUpperCase(ProcessEntry.szExeFile) = WideUpperCase(FileName)) then Result := True;
    ContinueLoop := Process32NextW(SnapshotHandle, ProcessEntry);
  end;

  CloseHandle(SnapshotHandle);
end;
//ProcessExists


//PIDExists
function PIDExists(PID: DWORD): Boolean;
var
  ContinueLoop: Boolean;
  SnapshotHandle: THandle;
  ProcessEntry: TProcessEntry32;
begin
  Result := False;
  SnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  ProcessEntry.dwSize := SizeOf(ProcessEntry);
  ContinueLoop := Process32First(SnapshotHandle, ProcessEntry);

  while ContinueLoop do begin
    if ProcessEntry.th32ProcessID = PID then Result := True;
    ContinueLoop := Process32Next(SnapshotHandle, ProcessEntry);
  end;

  CloseHandle(SnapshotHandle);
end;
//PIDExists


//SuspendProcess
function SuspendProcess(PID: DWORD): Boolean;
var
  LibHandle, ProcHandle: THandle;
  NtSuspendProcess: TProcFunction;
begin
  Result := False;
  LibHandle := SafeLoadLibrary('ntdll.dll');
  if LibHandle = 0 then Exit;

  @NtSuspendProcess := GetProcAddress(LibHandle, 'NtSuspendProcess');
  if @NtSuspendProcess = nil then Exit;

  ProcHandle := OpenProcess(PROCESS_SUSPEND_RESUME, False, PID);
  if ProcHandle = 0 then Exit;

  Result := NtSuspendProcess(ProcHandle) = 0;
  CloseHandle(ProcHandle);
  FreeLibrary(LibHandle);
end;
//SuspendProcess


//ResumeProcess
function ResumeProcess(PID: DWORD): Boolean;
var
  LibHandle, ProcHandle: THandle;
  NtResumeProcess: TProcFunction;
begin
  Result := False;
  LibHandle := SafeLoadLibrary('ntdll.dll');
  if LibHandle = 0 then Exit;

  @NtResumeProcess := GetProcAddress(LibHandle, 'NtResumeProcess');
  if @NtResumeProcess = nil then Exit;

  ProcHandle := OpenProcess(PROCESS_SUSPEND_RESUME, False, PID);
  if ProcHandle = 0 then Exit;

  Result := NtResumeProcess(ProcHandle) = 0;
  CloseHandle(ProcHandle);
  FreeLibrary(LibHandle);
end;
//ResumeProcess


//IsSuspended
function IsSuspended(PID: DWORD): Boolean;
var
  SPI: PSYSTEM_PROCESS_INFORMATION;
  hProcess: THandle;
  Size: DWORD;
  i: Integer;
begin
  Result := True;
  hProcess := OpenProcess(PROCESS_ALL_ACCESS, False, PID);

  if hProcess <= 0 then begin
    Result := False;
    Exit;
  end;

  NtQuerySystemInformation(5, nil, 0, @Size);
  GetMem(SPI, Size);
  NtQuerySystemInformation(5, SPI, Size, @Size);

  repeat
    if SPI^.ProcessID = PID then begin
      for i := 0 to SPI^.NumberOfThreads-1 do begin
        if SPI^.ThreadInfo[i].WaitReason <> 5 then Result := False;
      end;
      Break;
    end;
    SPI := Pointer(DWORD(SPI) + SPI^.NextEntryOffset);
  until SPI^.NextEntryOffset = 0;
end;
//IsSuspended


//GetCommandLineFromPID
function GetCommandLineFromPID(PID: DWORD): WideString;
var
  FSWbemLocator: OleVariant;
  FWMIService: OleVariant;
  FWbemObjectSet: OleVariant;
begin;
  Result := '';

  try
    FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    FWMIService := FSWbemLocator.ConnectServer('localhost', 'root\CIMV2', '', '');
    FWbemObjectSet := FWMIService.Get(Format('Win32_Process.Handle="%d"', [PID]));
    Result := VarToWideStr(FWbemObjectSet.CommandLine);
  except
  end;
end;
//GetCommandLineFromPID


//GetPathFromPID
function GetPathFromPID(PID: DWORD): WideString;
var
  hProcess: THandle;
  ProcessPath: array[0..MAX_PATH-1] of WideChar;
begin
  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PID);
  if hProcess = 0 then Exit;

  GetModuleFileNameExW(hProcess, 0, ProcessPath, MAX_PATH);
  Result := ProcessPath;
  CloseHandle(hProcess)
end;
//GetPathFromPID


//GetMainWindowFromPID
function GetMainWindowFromPID(PID: DWORD): DWORD;
type
  PEnumInfo = ^TEnumInfo;
  TEnumInfo = record
    ProcessID: DWORD;
    HWND: THandle;
  end;
function EnumWindowsProc(Wnd: DWORD; var EI: TEnumInfo): Bool; stdcall;
var
  PID: DWORD;
begin
  GetWindowThreadProcessID(Wnd, @PID);
  Result := (PID <> EI.ProcessID) or (not IsWindowVisible(WND)) or (not IsWindowEnabled(WND));
  if not Result then EI.HWND := WND;
end;
var
  EI: TEnumInfo;
begin
  EI.ProcessID := PID;
  EI.HWND := 0;
  EnumWindows(@EnumWindowsProc, Integer(@EI));
  Result := EI.HWND;
end;
//GetMainWindowFromPID


//GetProcessFromHWND
function GetProcessFromHWND(hwnd: HWND): WideString;
var
  pid: DWORD;
  hProcess: THandle;
  Path: array[0..4095] of WideChar;
begin
  Result := '';
  GetWindowThreadProcessId(hwnd, pid);
  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, pid);

  if (hProcess = 0) then Exit;
  if GetModuleFileNameExW(hProcess, 0, @Path[0], Length(Path)) <> 0 then Result := WideExtractFileName(Path);
  CloseHandle(hProcess);
end;
//GetProcessFromHWND


//CompressStream
procedure CompressStream(MemoryStream: TMemoryStream);
var
  InBuf, OutBuf: Pointer;
  InBytes, OutBytes: Integer;
begin
  InBuf := nil;
  OutBuf := nil;
  try
    MemoryStream.Position := 0;
    GetMem(InBuf, MemoryStream.Size);
    InBytes := MemoryStream.Read(InBuf^, MemoryStream.Size);
    CompressBuf(InBuf, InBytes, OutBuf, OutBytes);
    MemoryStream.Position := 0;
    MemoryStream.SetSize(OutBytes);
    MemoryStream.Write(OutBuf^, OutBytes);
  finally
    MemoryStream.Position := 0;
    if InBuf <> nil then FreeMem(InBuf);
    if OutBuf <> nil then FreeMem(OutBuf);
  end;
end;
//CompressStream


//DecompressStream
procedure DecompressStream(MemoryStream: TMemoryStream);
var
  InBuf, OutBuf: Pointer;
  InBytes, OutBytes: Integer;
begin
  InBuf := nil;
  OutBuf := nil;
  try
    MemoryStream.Position := 0;
    GetMem(InBuf, MemoryStream.Size);
    InBytes := MemoryStream.Read(InBuf^, MemoryStream.Size);
    DecompressBuf(InBuf, InBytes, 0, OutBuf, OutBytes);
    MemoryStream.Position := 0;
    MemoryStream.SetSize(OutBytes);
    MemoryStream.Write(OutBuf^, OutBytes);
  finally
    MemoryStream.Position := 0;
    if InBuf <> nil then FreeMem(InBuf);
    if OutBuf <> nil then FreeMem(OutBuf);
  end;
end;
//DecompressStream


//WebFileSize
function WebFileSize(URL: WideString): Cardinal;
var
  hSession, hURL: HInternet;
  Len, Index, Origin: Cardinal;
begin
  Result := Cardinal(-1);
  if not InternetGetConnectedState(@Origin, 0) then Exit;

  Index := 0;
  Len := SizeOf(Result);

  hSession := InternetOpenW(PWideChar(WideParamStr(0)), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hSession = nil then Exit;
  hURL := InternetOpenUrlW(hSession, PWideChar(URL), nil, 0, INTERNET_FLAG_NO_CACHE_WRITE, 0);
  if hURL = nil then Exit;
  HttpQueryInfo(hURL, HTTP_QUERY_CONTENT_LENGTH or HTTP_QUERY_FLAG_NUMBER, @Result, Len, Index);
  InternetCloseHandle(hSession);
end;
//WebFileSize


//URLDownloadToStream
function URLDownloadToStream(URL: WideString; Stream: TStream): Boolean;
const
  BufferSize = 1024*10*10;
var
  hSession, hURL: HInternet;
  Buffer: array[1..BufferSize] of Byte;
  Origin: Cardinal;
  BufferLen: DWORD;
begin
  Result := False;
  BufferLen := 0;
  Stream.Position := 0;

  if not InternetGetConnectedState(@Origin, 0) then Exit;
  hSession := InternetOpenW(PWideChar(WideParamStr(0)), INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  hURL := InternetOpenUrlW(hSession, PWideChar(URL), nil, 0, INTERNET_FLAG_NO_CACHE_WRITE, 0);

  try
    repeat
      InternetReadFile(hURL, @Buffer, SizeOf(Buffer), BufferLen);
      Stream.Write(Buffer, BufferLen);
      Application.ProcessMessages;
    until BufferLen = 0;
  except
    InternetCloseHandle(hURL);
  end;

  Stream.Position := 0;
  InternetCloseHandle(hSession);
  Result := True;
end;
//URLDownloadToStream


//SaveResource
function SaveResource(FileName, ResourceName: WideString; ResourceType: PChar): Boolean;
var
  hFile, nw: Cardinal;
  hResource, hGlobal: THandle;
begin
  hResource := FindResourceW(HInstance, PWideChar(ResourceName), PWideChar(ResourceType));
  hGlobal := LoadResource(HInstance, hResource);
  Result := (hResource <> 0) and (hGlobal <> 0);
  if not Result then Exit;

  hFile := CreateFileW(PWideChar(FileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  SetFilePointer(hFile, 0, nil, FILE_BEGIN);
  SetEndOfFile(hFile);
  WriteFile(hFile, LockResource(hGlobal)^, SizeOfResource(HInstance, hResource), nw, nil);
  CloseHandle(hFile);
end;
//SaveResource


//AddIconResource
function AddIconResource(FileName, Icon, ResourceName: WideString): Boolean;
var
  hFile: DWORD;
begin
  Result := False;
  hFile := BeginUpdateResourceW(PWideChar(FileName), False);

  if hFile <> 0 then begin
    Result := LoadIconGroupResourceW(hFile, PWideChar(ResourceName), 0, PWideChar(Icon));
    EndUpdateResourceW(hFile, False);
  end;
end;
//AddIconResource


//AddResource
function AddResource(FileName, ResourceName: WideString; Stream: TStream; ResourceType: PChar; Language: Integer): Boolean;
var
  hFile: Cardinal;
  Buffer: Pointer;
begin
  Result := False;
  GetMem(Buffer, Stream.Size);
  Stream.Position := 0;
  Stream.ReadBuffer(Buffer^, Stream.Size);
  hFile := Windows.BeginUpdateResourceW(PWideChar(FileName), False);

  if hFile <> 0 then begin
    Result := Windows.UpdateResourceW(hFile, PWideChar(ResourceType), PWideChar(ResourceName), Language, Buffer, Stream.Size);
    Windows.EndUpdateResourceW(hFile, False);
  end;

  FreeMem(Buffer, Stream.Size);
end;
//AddResource


//png2bmp
procedure png2bmp(PNGObject: TPNGObject; Bitmap: TBitmap);
begin
  if not Assigned(Bitmap) then Bitmap := TBitmap.Create;
  Bitmap.Width := PNGObject.Width;
  Bitmap.Height := PNGObject.Height;
  Bitmap.Canvas.Brush.Color := clBlack;
  Bitmap.Canvas.FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));
  PNGObject.Draw(Bitmap.Canvas, Bitmap.Canvas.ClipRect);
end;
//png2bmp


//ResizeBitmap
procedure ResizeBitmap(Bitmap: TBitmap; NewWidth, NewHeight: Integer);
var
  NewBitmap: TBitmap;
begin
  NewBitmap := TBitmap.Create;
  try
    NewBitmap.Width := NewWidth;
    NewBitmap.Height := NewHeight;
    NewBitmap.Canvas.StretchDraw(Rect(0, 0, NewWidth, NewHeight), Bitmap);
    Bitmap.Width := NewWidth;
    Bitmap.Height := NewHeight;
    Bitmap.Canvas.Draw(0, 0, NewBitmap);
  finally
    NewBitmap.Free;
  end;
end;
//ResizeBitmap


//ConvertMp3ToWavFast
procedure ConvertMp3ToWavFast(Stream: TStream);
var
  L3FHeader: TL3FHeader;
  Mp3RiffHeader: TMp3RiffHeader;
  Buffer: Pointer;
begin
  Stream.Position := 0;

  //Get info
  Layer3EstimateLength(Stream, L3FHeader);
  Mp3RiffHeader.fccRiff := FOURCC_RIFF;
  Mp3RiffHeader.dwFileSize := L3FHeader.FileSize + SizeOf(TMp3RiffHeader);
  Mp3RiffHeader.fccWave := FOURCC_WAVE;
  Mp3RiffHeader.fccFmt := FOURCC_fmt;
  Mp3RiffHeader.dwFmtSize := SizeOf(TMpegLayer3WaveFormat);
  Mp3RiffHeader.mp3wfx.wfx.wFormatTag := WAVE_FORMAT_MPEGLAYER3;
  Mp3RiffHeader.mp3wfx.wfx.nChannels := CChannels[L3FHeader.Mode];
  Mp3RiffHeader.mp3wfx.wfx.nSamplesPerSec := l3f_header_freq_hz(L3FHeader);
  Mp3RiffHeader.mp3wfx.wfx.nAvgBytesPerSec := 125 * l3f_header_rate_kbps(L3FHeader);
  Mp3RiffHeader.mp3wfx.wfx.nBlockAlign := 1;
  Mp3RiffHeader.mp3wfx.wfx.wBitsPerSample := 0;
  Mp3RiffHeader.mp3wfx.wfx.cbSize := MPEGLAYER3_WFX_EXTRA_BYTES;
  Mp3RiffHeader.mp3wfx.wID := MPEGLAYER3_ID_MPEG;
  Mp3RiffHeader.mp3wfx.fdwFlags := CFlags[L3FHeader.XingHeader > 0, L3FHeader.Padding];
  Mp3RiffHeader.mp3wfx.nBlockSize := L3FHeader.LengthInBytes;
  Mp3RiffHeader.mp3wfx.nFramesPerBlock := 1;
  Mp3RiffHeader.mp3wfx.nCodecDelay := 1105;
  Mp3RiffHeader.fccFact := FOURCC_fact;
  Mp3RiffHeader.dwFactSize := 4;
  Mp3RiffHeader.lSizeInSamples := (L3FHeader.TotalFrames - CSizeMismatch[L3FHeader.XingHeader > 0]) * L3FHeader.LengthInSamples - Mp3RiffHeader.mp3wfx.nCodecDelay;
  Mp3RiffHeader.fccData := FOURCC_data;
  Mp3RiffHeader.dwDataSize := L3FHeader.FileSize;

  //Copy file data to buffer
  GetMem(Buffer, L3FHeader.FileSize);
  Stream.Position := L3FHeader.FileOffset;
  Stream.ReadBuffer(Buffer^, L3FHeader.FileSize);

  //Write header to stream
  Stream.Position := 0;
  Stream.WriteBuffer(Mp3RiffHeader, SizeOf(Mp3RiffHeader));

  //Copy file data from buffer
  Stream.WriteBuffer(Buffer^, L3FHeader.FileSize);
  FreeMem(Buffer);
end;
//ConvertMp3ToWavFast


//ConvertMp3ToWav
procedure ConvertMp3ToWav(Stream: TStream);
var
  AudioInfo: TAudioInfo;
  ACMWaveFormat1, ACMWaveFormat2: TACMWaveFormat;
  ACMWaveFormat: TACMWaveFormat;
  MpegLayer3WaveFormat: TMpegLayer3WaveFormat absolute ACMWaveFormat;
  ACMConvertor: TACMConvertor;
  WaveStreamWrite: TWaveStreamWrite;
begin
  Stream.Position := 0;

  AudioInfo := TAudioInfo.Create;
  AudioInfo.LoadFromStream(Stream, Stream.Size);

  ACMConvertor := TACMConvertor.Create(nil);
  ACMConvertor.InputBufferSize := Stream.Size;
  Stream.Seek(AudioInfo.MpegPosition, soFromBeginning);

  ZeroMemory(@ACMWaveFormat1, SizeOf(ACMWaveFormat1));
  ZeroMemory(@ACMWaveFormat2, SizeOf(ACMWaveFormat2));
  ZeroMemory(@MpegLayer3WaveFormat, SizeOf(MpegLayer3WaveFormat));

  ACMWaveFormat := ACMWaveFormat1;
  MpegLayer3WaveFormat.wfx.wFormatTag := 85;

  case AudioInfo.Mpg.ChannelMode of
    0: begin MpegLayer3WaveFormat.wfx.nChannels := 2; MpegLayer3WaveFormat.fdwFlags := 2; end;
    1: begin MpegLayer3WaveFormat.wfx.nChannels := 2; MpegLayer3WaveFormat.fdwFlags := 4; end;
    2: begin MpegLayer3WaveFormat.wfx.nChannels := 2; MpegLayer3WaveFormat.fdwFlags := 2; end;
    3: begin MpegLayer3WaveFormat.wfx.nChannels := 1; MpegLayer3WaveFormat.fdwFlags := 4; end;
  end;

  MpegLayer3WaveFormat.wfx.nSamplesPerSec := AudioInfo.Mpg.SamplingRate;
  MpegLayer3WaveFormat.wfx.nAvgBytesPerSec := AudioInfo.Mpg.BitRate div 8;
  MpegLayer3WaveFormat.wfx.nBlockAlign := 1;
  MpegLayer3WaveFormat.wfx.wBitsPerSample := 0;
  MpegLayer3WaveFormat.wfx.cbSize := 12;
  MpegLayer3WaveFormat.wID := 1;
  MpegLayer3WaveFormat.nBlockSize := AudioInfo.Mpg.FrameLen;

  MpegLayer3WaveFormat.nFramesPerBlock := 1;
  MpegLayer3WaveFormat.nCodecDelay := 0;
  CopyMemory(@ACMWaveFormat1, @ACMWaveFormat, Sizeof(TMpegLayer3WaveFormat));

  ACMWaveFormat2 := ACMConvertor.SuggestFormat(ACMWaveFormat1);
  ACMConvertor.FormatIn := ACMWaveFormat1;
  ACMConvertor.FormatOut := ACMWaveFormat2;
  ACMConvertor.OpenStream;
  ZeroMemory(ACMConvertor.BufferIn, ACMConvertor.InputBufferSize);

  Stream.Position := 0;
  Stream.Read(ACMConvertor.BufferIn^, Stream.Size);
  ACMConvertor.Convert;

  WaveStreamWrite := TWaveStreamWrite.Create(nil);
  WaveStreamWrite.FMTchunk.WaveFMT.WaveFormat := ACMWaveFormat2.Format;
  WaveStreamWrite.Initialize(Stream);
  WaveStreamWrite.AddData(ACMConvertor.BufferOut^, ACMConvertor.FStreamHeader_P.cbDstLengthUsed, Stream);

  WaveStreamWrite.Destroy;
  ACMConvertor.Destroy;
end;
//ConvertMp3ToWav


//PlayMp3FromStream
function PlayMp3FromStream(Stream: TStream; fdwSound: Cardinal): Boolean;
begin
  try
    ConvertMp3ToWav(Stream);
  except
    Result := False;
    Exit;
  end;

  Result := PlaySound(TMemoryStream(Stream).Memory, 0, SND_MEMORY or fdwSound);
end;
//PlayMp3FromStream


//PlayMp3FromResource
function PlayMp3FromResource(ResourceName: WideString; ResourceType: PChar; fdwSound: Cardinal): Boolean;
var
  MemoryStream: TMemoryStream;
  hResource, hGlobal: THandle;
begin
  hResource := FindResourceW(HInstance, PWideChar(ResourceName), PWideChar(ResourceType));
  hGlobal := LoadResource(HInstance, hResource);
  Result := (hResource <> 0) and (hGlobal <> 0);
  if not Result then Exit;

  MemoryStream := TMemoryStream.Create;
  MemoryStream.WriteBuffer(LockResource(hGlobal)^, SizeOfResource(HInstance, hResource));
  Result := PlayMp3FromStream(MemoryStream, fdwSound);
end;
//PlayMp3FromResource


//AddFontFromMemory
function AddFontFromMemory(Stream: TStream; ReturnName: Boolean): WideString;
const
  QFR_DESCRIPTION = 1;
var
  Count, cbBuffer: DWORD;
  lpBuffer: array[0..MAX_PATH-1] of WideChar;
  FileName: WideString;
begin
  if ReturnName then begin
    cbBuffer := SizeOf(lpBuffer);
    FileName := GetTempDirectory + RandomString(32, True);
    WriteStreamToFile(Stream, FileName);

    AddFontResourceW(PWideChar(FileName));
    GetFontResourceInfoW(PWideChar(FileName), cbBuffer, lpBuffer, QFR_DESCRIPTION);
    RemoveFontResourceW(PWideChar(FileName));

    DeleteFileW(PWideChar(FileName));
    Result := lpBuffer;
  end else Result := '';

  AddFontMemResourceEx(TMemoryStream(Stream).Memory, Stream.Size, nil, @Count);
end;
//AddFontFromMemory


//CopyDirectory
function CopyDirectory(Source, Target: WideString): Boolean;
var
  ShFileOp: TSHFileOpStructW;
begin
  FillChar(ShFileOp, SizeOf(ShFileOp), 0);
  ShFileOp.wFunc := FO_COPY;
  ShFileOp.pFrom := PWideChar(Source + #0);
  ShFileOp.pTo := PWideChar(Target + #0);
  ShFileOp.fFlags := FOF_FILESONLY or FOF_SILENT or FOF_NOERRORUI or FOF_NOCONFIRMATION;
  Result := (SHFileOperationW(ShFileOp) = 0);
end;
//CopyDirectory


//MoveDirectory
function MoveDirectory(Source, Target: WideString): Boolean;
var
  ShFileOp: TSHFileOpStructW;
begin
  FillChar(ShFileOp, SizeOf(ShFileOp), 0);
  ShFileOp.wFunc := FO_MOVE;
  ShFileOp.pFrom := PWideChar(Source + #0);
  ShFileOp.pTo := PWideChar(Target + #0);
  ShFileOp.fFlags := FOF_FILESONLY or FOF_SILENT or FOF_NOERRORUI or FOF_NOCONFIRMATION;
  Result := (SHFileOperationW(ShFileOp) = 0);
end;
//MoveDirectory


//DeleteDirectory
function DeleteDirectory(Directory: WideString): Boolean;
var
  ShFileOp: TSHFileOpStructW;
begin
  FillChar(ShFileOp, SizeOf(ShFileOp), 0);
  ShFileOp.wFunc := FO_DELETE;
  ShFileOp.pFrom := PWideChar(Directory + #0);
  ShFileOp.fFlags := FOF_SILENT or FOF_NOERRORUI or FOF_NOCONFIRMATION;
  Result := (SHFileOperationW(ShFileOp) = 0);
end;
//DeleteDirectory


//DeleteFiles
function DeleteFiles(Directory, Mask: WideString; sub: Boolean): Boolean;
var
  ShFileOp: TSHFileOpStructW;
begin
  FillChar(ShFileOp, SizeOf(ShFileOp), 0);
  ShFileOp.wFunc := FO_DELETE;
  ShFileOp.pFrom := PWideChar(Directory + '\' + Mask + #0);
  if not sub then ShFileOp.fFlags := ShFileOp.fFlags or FOF_FILESONLY;
  ShFileOp.fFlags := ShFileOp.fFlags or FOF_NOCONFIRMATION;
  Result := (SHFileOperationW(ShFileOp) = 0);
end;
//DeleteFiles


//MoveToRecycleBin
function MoveToRecycleBin(Path: WideString): Boolean;
var
  ShFileOp: TSHFileOpStructW;
begin
  FillChar(ShFileOp, SizeOf(ShFileOp), 0);
  ShFileOp.wFunc := FO_DELETE;
  ShFileOp.pFrom := PWideChar(Path + #0);
  ShFileOp.fFlags := FOF_ALLOWUNDO or FOF_SILENT or FOF_NOERRORUI or FOF_NOCONFIRMATION;
  Result := (SHFileOperationW(ShFileOp) = 0);
end;
//MoveToRecycleBin


//WideGetCurrentDir
function WideGetCurrentDir: WideString;
var
  Len: DWORD;
begin
  Len := GetCurrentDirectoryW(0, PWideChar(Result));
  SetLength(Result, Len);
  GetCurrentDirectoryW(Len, PWideChar(Result));
  Result := PWideChar(Result);
end;
//WideGetCurrentDir


//WideSetCurrentDir
function WideSetCurrentDir(Path: WideString): Boolean;
begin
  Result := SetCurrentDirectoryW(PWideChar(Path));
end;
//WideSetCurrentDir


//WideGetShortPathName
function WideGetShortPathName(FileName: WideString): WideString;
var
  Len: Integer;
begin
  Len := GetShortPathNameW(PWideChar(FileName), nil, 0);
  SetLength(Result, Len);
  GetShortPathNameW(PWideChar(FileName), PWideChar(Result), Len);
end;
//WideGetShortPathName


//ContainsOnlyNumbers
function ContainsOnlyNumbers(S: String): Boolean;
var
  i: Integer;
begin
  Result := True;
  for i := 1 to Length(S) do begin
    if not (S[i] in ['0'..'9']) then begin
      Result := False;
      Break;
    end;
  end;
end;
//ContainsOnlyNumbers


//ExtractNumbers
function ExtractNumbers(S: String): String;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do if S[i] in ['0'..'9'] then Result := Result + S[i];
end;
//ExtractNumbers


//RandomString
function RandomString(Count: Integer; lowerCase: Boolean): String;
const
  S = '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Count do Result := Result + S[Random(Length(S))+1];
  if lowerCase then Result := AnsiLowerCase(Result);
end;
//RandomString


//ContainsUnicode
function ContainsUnicode(S: WideString): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to Length(S) do if Ord(S[i]) > 128 then begin
    Result := True;
    Exit;
  end;
end;
//ContainsUnicode


//WideStringToJSON
function WideStringToJSON(WS: WideString): WideString;
var
  i: Integer;
begin
  for i := 1 to Length(WS) do begin
    case WS[i] of
      '/', '\', '"': Result := Result + '\' + WS[i];
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
    else if Ord(WS[i]) < 32
      then Result := Result + '\u' + IntToHex(Ord(WS[i]), 4)
      else Result := Result + WS[i];
    end;
  end;

  Result := '"' + Result + '"';
end;
//WideStringToJSON


//WideContainsString
function WideContainsString(Text, SubText: WideString; CaseSensitive: Boolean): Boolean;
begin
  if not CaseSensitive then Text := WideUpperCase(Text);
  if not CaseSensitive then SubText := WideUpperCase(SubText);
  Result := Pos(Text, SubText) > 0;
end;
//WideContainsString


//RemoveDiacritics
function RemoveDiacritics(S: WideString; UntransformableCharacter: String): String;
const
  CodePage = 20127;
begin
  SetLength(Result, WideCharToMultiByte(CodePage, 0, PWideChar(S), Length(S), nil, 0, nil, nil));
  WideCharToMultiByte(CodePage, 0, PWideChar(S), Length(S), PAnsiChar(Result), Length(Result), nil, nil);
  Result := StringReplace(Result, '?', UntransformableCharacter, [rfReplaceAll, rfIgnoreCase]);
end;
//RemoveDiacritics


//UTFEncode
function UTFEncode(S: WideString): String;
var
  InputLength, OutputLength: Integer;
begin
  InputLength := Length(S);
  OutputLength := WideCharToMultiByte(CP_UTF8, 0, PWideChar(S), InputLength, nil, 0, nil, nil);
  SetLength(Result, OutputLength);
  WideCharToMultiByte(CP_UTF8, 0, PWideChar(S), InputLength, PAnsiChar(Result), OutputLength, nil, nil);
end;
//UTFEncode


//FindWindowExtd
function FindWindowExtd(PartialTitle: WideString): HWND;
var
  hWindow: HWND;
  Len: Integer;
  Temp: array [0..MAX_PATH-1] of WideChar;
  Title: WideString;
begin
  Result := 0;
  hWindow := FindWindowW(nil, nil);
  PartialTitle := WideUpperCase(PartialTitle);

  while hWindow <> 0 do begin
    Len := GetWindowTextW(hWindow, Temp, MAX_PATH);
    Title := WideUpperCase(Copy(Temp, 1, Len));

    if Pos(PartialTitle, Title) <> 0 then begin
      Result := hWindow;
      Break;
    end;

    hWindow := GetWindow(hWindow, GW_HWNDNEXT);
  end;
end;
//FindWindowExtd


//GetCaptionByHandle
function GetCaptionByHandle(hWindow: HWND): WideString;
var
  Len: Integer;
  Temp: array [0..MAX_PATH-1] of WideChar;
begin
  Len := GetWindowTextW(hWindow, Temp, MAX_PATH);
  Result := Copy(Temp, 1, Len);
end;
//GetCaptionByHandle


//CompareSize
function CompareSize(SizeOne, Operator, SizeTwo: Int64): Boolean;
const
  ALWAYS_TRUE = 0;
  GREATER_THAN = 1;
  LESS_THAN = 2;
  EQUALS = 3;
begin
  Result := False;

  case Operator of
    GREATER_THAN: if SizeOne > SizeTwo then Result := True;
    LESS_THAN: if SizeOne < SizeTwo then Result := True;
    EQUALS: if SizeOne = SizeTwo then Result := True;
    ALWAYS_TRUE: Result := True;
  end;
end;
//CompareSize


//FormatSize
function FormatSize(x: Int64; NumbersAfterComma: Byte): String;
begin
  Result := Format('%d Bytes', [x]);
  if x >= (1024) then Result := Format('%.' + IntToStr(NumbersAfterComma) + 'f KB', [x/1024]);
  if x >= (1024*1024) then Result := Format('%.' + IntToStr(NumbersAfterComma) + 'f MB', [x/(1024*1024)]);
  if x >= (1024*1024*1024) then Result := Format('%.' + IntToStr(NumbersAfterComma) + 'f GB', [x/(1024*1024*1024)]);
end;
//FormatSize


//FormatDate
function FormatDate(DateTime: TDateTime): String;
var
  SecondsDifference: Int64;
begin
  SecondsDifference := SecondsBetween(DateTime, Now);

  if (SecondsDifference >= 0) and (SecondsDifference < 60) then begin
    Result := 'A few sec';
    Exit;
  end;

  Result := '1 Min';
  if (SecondsDifference >= 60*2) and (SecondsDifference < 60*60) then begin
    Result := IntToStr(Round(SecondsDifference/60)) + ' Mins';
    Exit;
  end;

  if (SecondsDifference < 60*60) then Exit;

  Result := '1 Hour';
  if (SecondsDifference >= 60*60*2) and (SecondsDifference < 60*60*24) then begin
    Result := IntToStr(Round(SecondsDifference/60/60)) + ' Hours';
    Exit;
  end;

  if (SecondsDifference < 60*60*24) then Exit;

  Result := '1 Day';
  if (SecondsDifference >= 60*60*24*2) then begin
    Result := IntToStr(Round(SecondsDifference/60/60/24)) + ' Days';
    Exit;
  end;
end;
//FormatDate


//RegistryValueExists
function RegistryValueExists(RootKey: HKEY; Key, ValueName: String): Boolean;
var
  Registry: TRegistry;
begin
  Registry := Tregistry.Create;
  Registry.RootKey := RootKey;
  Registry.OpenKey(Key, True);
  Result := Registry.ValueExists(ValueName);
  Registry.CloseKey;
  Registry.Free;
end;
//RegistryValueExists


//DeleteRegistryKey
procedure DeleteRegistryKey(RootKey: HKEY; Key: String);
var
  Registry: TRegistry;
begin
  Registry := Tregistry.Create;
  Registry.RootKey := RootKey;
  Registry.DeleteKey(Key);
  Registry.CloseKey;
  Registry.Free;
end;
//DeleteRegistryKey


//DeleteRegistryValue
procedure DeleteRegistryValue(RootKey: HKEY; Key, ValueName: String);
var
  Registry: TRegistry;
begin
  Registry := Tregistry.Create;
  Registry.RootKey := RootKey;
  Registry.OpenKey(Key, True);
  Registry.DeleteValue(ValueName);
  Registry.CloseKey;
  Registry.Free;
end;
//DeleteRegistryValue


//LoadRegistryInteger
function LoadRegistryInteger(var x: Integer; RootKey: HKEY; Key, ValueName: String): Boolean;
var
  Registry: TRegistry;
begin
  Result := False;
  Registry := TRegistry.Create;
  Registry.RootKey := RootKey;
  Registry.OpenKey(Key, True);

  if Registry.ValueExists(ValueName) then begin
    x := Registry.ReadInteger(ValueName);
    Result := True;
  end;

  Registry.Free;
end;
//LoadRegistryInteger


//LoadRegistryBoolean
function LoadRegistryBoolean(var x: Boolean; RootKey: HKEY; Key, ValueName: String): Boolean;
var
  Registry: TRegistry;
begin
  Result := False;
  Registry := TRegistry.Create;
  Registry.RootKey := RootKey;
  Registry.OpenKey(Key, True);

  if Registry.ValueExists(ValueName) then begin
    x := Registry.ReadBool(ValueName);
    Result := True;
  end;

  Registry.Free;
end;
//LoadRegistryBoolean


//LoadRegistryString
function LoadRegistryString(var x: String; RootKey: HKEY; Key, ValueName: String): Boolean;
var
  Registry: TRegistry;
begin
  Result := False;
  Registry := TRegistry.Create;
  Registry.RootKey := RootKey;
  Registry.OpenKey(Key, True);

  if Registry.ValueExists(ValueName) then begin
    x := Registry.ReadString(ValueName);
    Result := True;
  end;

  Registry.Free;
end;
//LoadRegistryString


//LoadRegistryWideString
function LoadRegistryWideString(var x: WideString; RootKey: HKEY; Key, ValueName: String): Boolean;
var
  Registry: TTNTRegistry;
begin
  Result := False;
  Registry := TTNTRegistry.Create;
  Registry.RootKey := RootKey;
  Registry.OpenKey(Key, True);

  if Registry.ValueExists(ValueName) then begin
    x := Registry.ReadString(ValueName);
    Result := True;
  end;

  Registry.Free;
end;
//LoadRegistryWideString


//SaveRegistryInteger
procedure SaveRegistryInteger(x: Int64; RootKey: HKEY; Key, ValueName: String);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  Registry.RootKey := RootKey;
  Registry.OpenKey(Key, True);
  Registry.WriteInteger(ValueName, x);
  Registry.Free;
end;
//SaveRegistryInteger


//SaveRegistryBoolean
procedure SaveRegistryBoolean(x: Boolean; RootKey: HKEY; Key, ValueName: String);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  Registry.RootKey := RootKey;
  Registry.OpenKey(Key, True);
  Registry.WriteBool(ValueName, x);
  Registry.Free;
end;
//SaveRegistryBoolean


//SaveRegistryString
procedure SaveRegistryString(x: String; RootKey: HKEY; Key, ValueName: String);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create;
  Registry.RootKey := RootKey;
  Registry.OpenKey(Key, True);
  Registry.WriteString(ValueName, x);
  Registry.Free;
end;
//SaveRegistryString


//SaveRegistryWideString
procedure SaveRegistryWideString(x: WideString; RootKey: HKEY; Key, ValueName: String);
var
  Registry: TTNTRegistry;
begin
  Registry := TTNTRegistry.Create;
  Registry.RootKey := RootKey;
  Registry.OpenKey(Key, True);
  Registry.WriteString(ValueName, x);
  Registry.Free;
end;
//SaveRegistryWideString


//InvokeBSOD
procedure InvokeBSOD;
var
  outBoolean: Boolean;
  outInteger: Integer;
begin
  RtlAdjustPrivilege(19, True, False, outBoolean);
  NtRaiseHardError(WPARAM($c0000022), 0, 0, nil, 6, outInteger);
end;
//InvokeBSOD


//PlayMod
function PlayMod(Stream: TStream): TMiniMOD;
var
  ArrayOfByte: array of byte;
begin
  SetLength(ArrayOfByte, Stream.Size);
  Stream.Position := 0;
  Stream.Read(ArrayOfByte[0], Stream.Size);
  Stream.Position := 0;

  Result := TMiniMOD.Create(44100, True, True);
  Result.Load(ArrayOfByte, Length(ArrayOfByte));
  Result.Play;
end;
//PlayMod


//SetScreenResolution
function SetScreenResolution(Width, Height: Integer): Longint;
var
  DeviceMode: TDeviceMode;
begin
  DeviceMode.dmSize := SizeOf(TDeviceMode); 
  DeviceMode.dmPelsWidth := Width; 
  DeviceMode.dmPelsHeight := Height; 
  DeviceMode.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;  
  Result := ChangeDisplaySettings(DeviceMode, CDS_UPDATEREGISTRY); 
end;
//SetScreenResolution


//MyExitWindows
function MyExitWindows(RebootParam: Longword): Boolean;
var
  TTokenHd: THandle;
  TTokenPvg, rTTokenPvg: TTokenPrivileges;
  cbtpPrevious: DWORD;
  pcbtpPreviousRequired: DWORD;
  tpResult: Boolean;
const
  SE_SHUTDOWN_NAME = 'SeShutdownPrivilege';
begin
  if Win32Platform = VER_PLATFORM_WIN32_NT then begin
    tpResult := OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, TTokenHd);
    if tpResult then begin
      tpResult := LookupPrivilegeValue(nil, SE_SHUTDOWN_NAME, TTokenPvg.Privileges[0].Luid);
      TTokenPvg.PrivilegeCount := 1;
      TTokenPvg.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
      cbtpPrevious := SizeOf(rTTokenPvg);
      pcbtpPreviousRequired := 0;
      if tpResult then Windows.AdjustTokenPrivileges(TTokenHd, False, TTokenPvg, cbtpPrevious, rTTokenPvg, pcbtpPreviousRequired);
    end;
  end;

  Result := ExitWindowsEx(RebootParam, 0);
end;
//MyExitWindows


//ShutdownWindows
function ShutdownWindows: Boolean;
begin
  Result := MyExitWindows(EWX_POWEROFF or EWX_FORCE);
end;
//ShutdownWindows


//RestartWindows
function RestartWindows: Boolean;
begin
  Result := MyExitWindows(EWX_REBOOT or EWX_FORCE);
end;
//RestartWindows


//DisableNetwork
function DisableNetwork: DWORD;
var
  NetBlockInfo: TNetBlockInfo;
begin
  Result := 0;
  if not IsAdmin then Exit;
  NetBlockInfo.dwBlockMode := NB_BLOCK_INTERNET;
  NetBlockInfo.dwResolution := 20;
  Result := SetNetBlock(@NetBlockInfo);
end;
//DisableNetwork


//EnableNetwork
procedure EnableNetwork;
begin
  StopNetBlock;
end;
//EnableNetwork


//getEthernetEnabled
function GetEthernetEnabled: Boolean;
const
  wbemFlagForwardOnly = $00000020;
var
  FSWbemLocator: OleVariant;
  FWMIService: OleVariant;
  FWbemObjectSet: OleVariant;
  FWbemObject: OleVariant;
  EnumVariant: IEnumVariant;
  iValue: LongWord;
begin;
  Result := False;
  FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
  FWMIService := FSWbemLocator.ConnectServer('localhost', 'root\CIMV2', '', '');
  FWbemObjectSet := FWMIService.ExecQuery('SELECT * FROM Win32_NetworkAdapter where GUID<>null and NetConnectionID="Ethernet" and NetEnabled=true', 'WQL', wbemFlagForwardOnly);
  EnumVariant := IUnknown(FWbemObjectSet._NewEnum) as IEnumVariant;

  while EnumVariant.Next(1, FWbemObject, iValue) = 0 do begin
    Result := FWbemObject.NetEnabled;
    FWbemObject := Unassigned;
    Break;
  end;
end;
//getEthernetEnabled


//setEthernetEnabled
procedure SetEthernetEnabled(b: Boolean);
const
  wbemFlagForwardOnly = $00000020;
var
  FSWbemLocator: OleVariant;
  FWMIService: OleVariant;
  FWbemObjectSet: OleVariant;
  FWbemObject: OleVariant;
  EnumVariant: IEnumVariant;
  iValue: LongWord;
begin;
  FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
  FWMIService := FSWbemLocator.ConnectServer('localhost', 'root\CIMV2', '', '');
  FWbemObjectSet := FWMIService.ExecQuery('SELECT * FROM Win32_NetworkAdapter where GUID<>null and NetConnectionID="Ethernet"', 'WQL', wbemFlagForwardOnly);
  EnumVariant := IUnknown(FWbemObjectSet._NewEnum) as IEnumVariant;

  while EnumVariant.Next(1, FWbemObject, iValue) = 0 do begin
    if b then FWbemObject.Enable() else FWbemObject.Disable();
    FWbemObject := Unassigned;
    Break;
  end;
end;
//setEthernetEnabled

initialization
  Randomize;
end.
