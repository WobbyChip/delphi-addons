unit uWTSSessions;

interface

uses
  Windows, SysUtils;

type
  WTS_INFO_CLASS = (
    WTSInitialProgram,
    WTSApplicationName,
    WTSWorkingDirectory,
    WTSOEMId,
    WTSSessionId,
    WTSUserName,
    WTSWinStationName,
    WTSDomainName,
    WTSConnectState,
    WTSClientBuildNumber,
    WTSClientName,
    WTSClientDirectory,
    WTSClientProductId,
    WTSClientHardwareId,
    WTSClientAddress,
    WTSClientDisplay,
    WTSClientProtocolType,
    WTSIdleTime,
    WTSLogonTime,
    WTSIncomingBytes,
    WTSOutgoingBytes,
    WTSIncomingFrames,
    WTSOutgoingFrames,
    WTSClientInfo,
    WTSSessionInfo,
    WTSSessionInfoEx,
    WTSConfigInfo,
    WTSValidationInfo,
    WTSSessionAddressV4,
    WTSIsRemoteSession
  );

  WTS_CONNECTSTATE_CLASS = (
    WTSActive,
    WTSConnected,
    WTSConnectQuery,
    WTSShadow,
    WTSDisconnected,
    WTSIdle,
    WTSListen,
    WTSReset,
    WTSDown,
    WTSInit
  );

  PWTS_SESSION_INFO = ^WTS_SESSION_INFO;
  WTS_SESSION_INFO = record
    SessionId: DWORD;
    pWinStationName: LPTSTR;
    State: WTS_CONNECTSTATE_CLASS;
  end;

const
  WTS_CURRENT_SERVER_HANDLE = 0;
  WTS_CURRENT_SESSION = DWORD(-1);

function WTSEnumerateSessionsW(hServer: THandle; Reserved: DWORD; Version: DWORD; var ppSessionInfo: PWTS_SESSION_INFO; var pCount: DWORD): BOOL; stdcall; external 'Wtsapi32.dll' name 'WTSEnumerateSessionsW';
function WTSQuerySessionInformationW(hServer: THandle; SessionId: DWORD; WTSInfoClass: WTS_INFO_CLASS; var ppBuffer: Pointer; var pBytesReturned: DWORD): BOOL; stdcall; external 'Wtsapi32.dll' name 'WTSQuerySessionInformationW';
procedure WTSFreeMemory(pMemory: Pointer); stdcall; external 'Wtsapi32.dll';
function WTSDisconnectSession(hServer: THandle; SessionId: DWORD; bWait: BOOL): BOOL; stdcall; external 'Wtsapi32.dll' name 'WTSDisconnectSession';
function WTSConnectSessionW(LogonId: DWORD; TargetLogonId: DWORD; pPassword: LPWSTR; bWait: BOOL): BOOL; stdcall; external 'Wtsapi32.dll' name 'WTSConnectSessionW';
function WTSGetActiveConsoleSessionId: DWORD; stdcall; external kernel32 name 'WTSGetActiveConsoleSessionId';

function WTFindSessionId(UserName: WideString): Integer;
function WTSWitchUser(UserName, Password: WideString): Boolean;
function WTGetUserState(UserName: WideString): WTS_CONNECTSTATE_CLASS;

implementation

function WTFindSessionId(UserName: WideString): Integer;
var
  Sessions, Session: PWTS_SESSION_INFO;
  j, i, dummy: DWORD;
  Buffer: Pointer;
begin
  Result := -1;

  if not WTSEnumerateSessionsW(WTS_CURRENT_SERVER_HANDLE, 0, 1, Sessions, j) then begin
    WTSFreeMemory(Sessions);
    Exit;
  end;

  Session := Sessions;

  for i := 0 to j-1 do begin
    if (i > 0) then Inc(Session);
    if (Session.State <> WTSActive) then continue;

    if (not WTSQuerySessionInformationW(WTS_CURRENT_SERVER_HANDLE, Session.SessionId, WTSUserName, Buffer, dummy)) then continue;

    if (WideString(Buffer) = UserName) then Result := Session.SessionId;
    WTSFreeMemory(Buffer);
    if (Result > -1) then Break;
  end;

  WTSFreeMemory(Sessions);
end;


function WTSWitchUser(UserName, Password: WideString): Boolean;
var
  SessionId: Integer;
begin
  Result := False;
  SessionId := WTFindSessionId(UserName);
  if (sessionId < 0) then Exit;

  WTSDisconnectSession(WTS_CURRENT_SERVER_HANDLE, WTS_CURRENT_SESSION, True);
  Result := WTSConnectSessionW(WTFindSessionId(UserName), WTSGetActiveConsoleSessionId(), PWideChar(Password), True);
end;


function WTGetUserState(UserName: WideString): WTS_CONNECTSTATE_CLASS;
var
  br: DWORD;
  Buffer: LPTSTR;
begin
  WTSQuerySessionInformationW(0, WTFindSessionId(UserName), WTSConnectState, Pointer(Buffer), br);
  Result := WTS_CONNECTSTATE_CLASS(Buffer^);
end;

end.
