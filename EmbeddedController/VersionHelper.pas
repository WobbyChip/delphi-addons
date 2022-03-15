unit VersionHelper;

interface

uses
  Windows;

const
  VER_SERVICEPACKMAJOR = $0000010;
  VER_MAJORVERSION = $0000002;
  VER_MINORVERSION = $0000001;
  VER_GREATER_EQUAL = 3;

type
  OSVersionInfoEX = record
    dwOSVersionInfoSize: DWORD;
    dwMajorVersion: DWORD;
    dwMinorVersion: DWORD;
    dwBuildNumber: DWORD;
    dwPlatformID: DWORD;
    szCSDVersion: array[0..127] of Char;
    wServicePackMajor: Word;
    wServicePackMinor: Word;
    wSuiteMask: Word;
    wProductType: Byte;
    wReserved: Byte;
  end;

function IsWindowsVersionOrGreater(wMajorVersion, wMinorVersion, wServicePackMajor: Word): Bool; stdcall;

implementation

function VerifyVersionInfo(var LPOSVERSIONINFOEX : OSVERSIONINFOEX; dwTypeMask: DWORD;dwlConditionMask: int64): BOOL; stdcall; external 'kernel32.dll' name 'VerifyVersionInfoA';
function VerSetConditionMask(dwlConditionMask: int64;dwTypeBitMask: DWORD; dwConditionMask: Byte): int64; stdcall; external 'kernel32.dll';

function IsWindowsVersionOrGreater;
var
  osvi: OSVersionInfoEX;
  mask: Int64;
begin
  FillChar(osvi, SizeOf(osvi), 0);
  osvi.dwOSVersionInfoSize := SizeOf(osvi);
  FillChar(mask, 8, 0);
  mask := VerSetConditionMask(mask, VER_MAJORVERSION, VER_GREATER_EQUAL);
  mask := VerSetConditionMask(mask, VER_MINORVERSION, VER_GREATER_EQUAL);
  mask := VerSetConditionMask(mask, VER_SERVICEPACKMAJOR, VER_GREATER_EQUAL);
  osvi.dwMajorVersion := wMajorVersion;
  osvi.dwMinorVersion := wMinorVersion;
  osvi.wServicePackMajor := wServicePackMajor;
  Result := VerifyVersionInfo(osvi, VER_MAJORVERSION or VER_MINORVERSION or VER_SERVICEPACKMAJOR, mask) <> False;
end;

end. 
