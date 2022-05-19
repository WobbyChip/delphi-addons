unit ECDriver;

interface

uses
  SysUtils, Windows, WinSvc, WinRing0, VersionHelper;

function IsWow64Process(hProcess: THandle; var Wow64Process: Boolean): Boolean; stdcall; external 'kernel32.dll';

const
  NULL = 0;
  HEAP_NO_SERIALIZE = $00000001;
  HEAP_ZERO_MEMORY = $00000008;

const
  OLS_DRIVER_ID = 'WinRing0_1_2_0';
  OLS_DRIVER_FILE_NAME_WIN_NT_X86 = 'WinRing0x86.sys';
  OLS_DRIVER_FILE_NAME_WIN_NT_X64 = 'WinRing0x64.sys';

const
  METHOD_BUFFERED = 0;
  FILE_ANY_ACCESS = 0;
  FILE_READ_ACCESS = 1;
  FILE_WRITE_ACCESS = 2;

const
  OLS_TYPE = 40000;
  IOCTL_OLS_GET_REFCOUNT = (OLS_TYPE shl 16) or (FILE_ANY_ACCESS shl 14) or ($801 shl 2) or METHOD_BUFFERED;
  IOCTL_OLS_READ_IO_PORT_BYTE = (OLS_TYPE shl 16) or (FILE_READ_ACCESS shl 14) or ($833 shl 2) or METHOD_BUFFERED;
  IOCTL_OLS_WRITE_IO_PORT_BYTE = (OLS_TYPE shl 16) or (FILE_WRITE_ACCESS shl 14) or ($836 shl 2) or METHOD_BUFFERED;

const
  OLS_DLL_NO_ERROR = 0;
  OLS_DLL_DRIVER_NOT_LOADED = 1;
  OLS_DLL_DRIVER_NOT_FOUND = 2;
  OLS_DLL_DRIVER_NOT_LOADED_ON_NETWORK = 3;
  OLS_DLL_UNKNOWN_ERROR = 4;

const
  OLS_DRIVER_TYPE_UNKNOWN = 0;
  OLS_DRIVER_TYPE_WIN_NT_X86 = 1;
  OLS_DRIVER_TYPE_WIN_NT_X64 = 2;

const
  OLS_DRIVER_INSTALL = 1;
  OLS_DRIVER_REMOVE = 2;
  OLS_DRIVER_SYSTEM_INSTALL = 3;
  OLS_DRIVER_SYSTEM_UNINSTALL = 4;

type
  OLS_WRITE_IO_PORT_INPUT = record
    PortNumber: Cardinal;
    CharData: Byte;
  end;


type
  TDriverManager = class
    protected
      gHandle: THandle;
      function installDriver(hSCManager: SC_HANDLE; DriverId, DriverPath: WideString): Boolean;
      function removeDriver(hSCManager: SC_HANDLE; DriverId: WideString): Boolean;
      function startDriver(hSCManager: SC_HANDLE; DriverId: WideString): Boolean;
      function stopDriver(hSCManager: SC_HANDLE; DriverId: WideString): Boolean;
      function isSystemInstallDriver(hSCManager: SC_HANDLE; DriverId, DriverPath: WideString): Boolean;
      function openDriver: Boolean;
    public
      constructor Create;
      destructor Destroy; override;
      function manage(DriverId, DriverPath: WideString; Func: Word): Boolean;
    end;


type
  TECDriver = class(TDriverManager)
    private
      gDriverPath: WideString;
      gInitDll: Boolean;
      gDllStatus: Byte;
      gDriverType: Byte;
    protected
      function driverFileExistence: Byte;
    public
      bResult: Boolean;
      bytesReturned: DWORD;
      driverFileExist: Boolean;

      constructor Create;
      destructor Destroy; override;
      function initialize: Boolean;
      procedure deinitialize;
      function readIoPortByte(port: Byte): Byte;
      procedure writeIoPortByte(port, value: Byte);
  end;

implementation


//=======================================================
//DriverManager==========================================
//=======================================================


constructor TDriverManager.Create;
begin
  inherited Create;
  gHandle := INVALID_HANDLE_VALUE;
end;


destructor TDriverManager.Destroy;
begin
  inherited Destroy;
end;


function TDriverManager.manage(DriverId, DriverPath: WideString; Func: Word): Boolean;
var
  hService: SC_HANDLE;
  hSCManager: SC_HANDLE;
  rCode: Boolean;
begin
  rCode := False;
  Result := False;

  if ((DriverId = '') or (DriverPath = '')) then Exit;
  hSCManager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if (hSCManager = NULL) then Exit;

  case Func of
    OLS_DRIVER_INSTALL: begin
      if (installDriver(hSCManager, DriverId, DriverPath))
        then rCode := startDriver(hSCManager, DriverId);
    end;
    OLS_DRIVER_REMOVE: begin
      if (not isSystemInstallDriver(hSCManager, DriverId, DriverPath)) then begin
        stopDriver(hSCManager, DriverId);
        rCode := removeDriver(hSCManager, DriverId);
      end;
    end;
    OLS_DRIVER_SYSTEM_INSTALL: begin
      if (isSystemInstallDriver(hSCManager, DriverId, DriverPath)) then begin
        rCode := True;
      end else begin
        if (not openDriver) then begin
          stopDriver(hSCManager, DriverId);
          removeDriver(hSCManager, DriverId);
          if (installDriver(hSCManager, DriverId, DriverPath)) then startDriver(hSCManager, DriverId);
          openDriver;
        end;

        hService := OpenServiceW(hSCManager, PWideChar(DriverId), SERVICE_ALL_ACCESS);
        if (hService <> NULL) then begin
          rCode := ChangeServiceConfigW(hService, SERVICE_KERNEL_DRIVER, SERVICE_AUTO_START, SERVICE_ERROR_NORMAL, PWideChar(DriverPath), nil, nil, nil, nil, nil, nil);
          CloseServiceHandle(hService);
        end;
      end;
    end;
    OLS_DRIVER_SYSTEM_UNINSTALL: begin
      if (not isSystemInstallDriver(hSCManager, DriverId, DriverPath)) then begin
        rCode := True;
      end else begin
        if (gHandle <> INVALID_HANDLE_VALUE) then begin
          CloseHandle(gHandle);
          gHandle := INVALID_HANDLE_VALUE;
        end;

        if (stopDriver(hSCManager, DriverId))
          then rCode := removeDriver(hSCManager, DriverId);
      end;
    end;
  else rCode := False;
  end;

  if (hSCManager <> NULL) then CloseServiceHandle(hSCManager);
  Result := rCode;
end;


function TDriverManager.installDriver(hSCManager: SC_HANDLE; DriverId, DriverPath: WideString): Boolean;
var
  hService: SC_HANDLE;
  rCode: Boolean;
begin
  rCode := False;
  hService := CreateServiceW(hSCManager, PWideChar(DriverId), PWideChar(DriverId), SERVICE_ALL_ACCESS, SERVICE_KERNEL_DRIVER, SERVICE_DEMAND_START, SERVICE_ERROR_NORMAL, PWideChar(DriverPath), nil, nil, nil, nil, nil);

  if (hService = NULL) then begin
    if (GetLastError = ERROR_SERVICE_EXISTS) then rCode := True;
  end else begin
    rCode := True;
    CloseServiceHandle(hService);
  end;

  Result := rCode;
end;


function TDriverManager.removeDriver(hSCManager: SC_HANDLE; DriverId: WideString): Boolean;
var
  hService: SC_HANDLE;
  rCode: Boolean;
begin
  hService := OpenServiceW(hSCManager, PWideChar(DriverId), SERVICE_ALL_ACCESS);

  if (hService = NULL) then begin
    rCode := True;
  end else begin
    rCode := DeleteService(hService);
    CloseServiceHandle(hService);
  end;

  Result := rCode;
end;


function TDriverManager.startDriver(hSCManager: SC_HANDLE; DriverId: WideString): Boolean;
var
  hService: SC_HANDLE;
  rCode: Boolean;
  lpServiceArgVectors: PChar;
begin
  rCode := False;
  lpServiceArgVectors := nil;
  hService := OpenServiceW(hSCManager, PWideChar(DriverId), SERVICE_ALL_ACCESS);

  if (hService <> NULL) then begin
    if (not StartService(hService, 0, lpServiceArgVectors)) then begin
      if (GetLastError = ERROR_SERVICE_ALREADY_RUNNING) then rCode := True;
    end else begin
      rCode := True;
    end;
  end;

  CloseServiceHandle(hService);
  Result := rCode;
end;


function TDriverManager.stopDriver(hSCManager: SC_HANDLE; DriverId: WideString): Boolean;
var
  hService: SC_HANDLE;
  rCode: Boolean;
  serviceStatus: SERVICE_STATUS;
begin
  rCode := False;
  hService := OpenServiceW(hSCManager, PWideChar(DriverId), SERVICE_ALL_ACCESS);

  if (hService <> NULL) then begin
    rCode := ControlService(hService, SERVICE_CONTROL_STOP, serviceStatus);
    CloseServiceHandle(hService);
  end;

  Result := rCode;
end;


function TDriverManager.isSystemInstallDriver(hSCManager: SC_HANDLE; DriverId, DriverPath: WideString): Boolean;
var
  hService: SC_HANDLE;
  rCode: Boolean;
  dwSize: DWORD;
  lpServiceConfig: PQueryServiceConfig;
begin
  rCode := False;
  hService := OpenServiceW(hSCManager, PWideChar(DriverId), SERVICE_ALL_ACCESS);

  if (hService <> NULL) then begin
    QueryServiceConfig(hService, nil, 0, dwSize);
    lpServiceConfig := PQueryServiceConfig(HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwSize));
    QueryServiceConfig(hService, lpServiceConfig, dwSize, dwSize);

    if (lpServiceConfig.dwStartType = SERVICE_AUTO_START) then rCode := True;
    CloseServiceHandle(hService);
    HeapFree(GetProcessHeap, HEAP_NO_SERIALIZE, lpServiceConfig);
  end;

  Result := rCode;
end;


function TDriverManager.openDriver: Boolean;
begin
  gHandle := CreateFile(PChar('\\.\' + OLS_DRIVER_ID), GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Result := (gHandle <> INVALID_HANDLE_VALUE);
end;


//=======================================================
//ECDriver===============================================
//=======================================================


constructor TECDriver.Create;
begin
  inherited Create;
  gInitDll := False;
  gDllStatus := OLS_DLL_UNKNOWN_ERROR;
  gDriverType := OLS_DRIVER_TYPE_UNKNOWN;
end;


destructor TECDriver.Destroy;
begin
  deinitialize;
  inherited Destroy;
end;


function TECDriver.driverFileExistence: Byte;
var
  hFile: Cardinal;
  findData: WIN32_FIND_DATAW;
  Buffer: array[0..MAX_PATH-1] of WideChar;
  root: array [0..3] of WideChar;
  wow64: Boolean;
begin
  Result := OLS_DLL_NO_ERROR;

  if ((gDriverType = OLS_DRIVER_TYPE_UNKNOWN) and IsWindowsVersionOrGreater(5, 0, 0)) then begin
    gDllStatus := OLS_DLL_NO_ERROR;
    IsWow64Process(GetCurrentProcess, wow64);
    GetWindowsDirectoryW(Buffer, MAX_PATH);

    if wow64 then begin
      gDriverType := OLS_DRIVER_TYPE_WIN_NT_X64;
      gDriverPath := WideString(Buffer) + '\Temp\' + OLS_DRIVER_FILE_NAME_WIN_NT_X64;
      SaveByteArray(WinRing0x64, gDriverPath);
    end else begin
      gDriverType := OLS_DRIVER_TYPE_WIN_NT_X86;
      gDriverPath := WideString(Buffer) + '\Temp\' + OLS_DRIVER_FILE_NAME_WIN_NT_X86;
      SaveByteArray(WinRing0x86, gDriverPath);
    end;
  end;

  hFile := FindFirstFileW(PWideChar(gDriverPath), findData);
  if (hFile = INVALID_HANDLE_VALUE) then Result := OLS_DLL_DRIVER_NOT_FOUND;
  FindClose(hFile);

  root[0] := gDriverPath[1];
  root[1] := ':';
  root[2] := '\';
  root[3] := #00;

  if ((root[0] = '\') or (GetDriveTypeW(root) = DRIVE_REMOTE)) then Result := OLS_DLL_DRIVER_NOT_LOADED_ON_NETWORK;
  driverFileExist := (Result = OLS_DLL_NO_ERROR);
end;


function TECDriver.initialize: Boolean;
var
  i: Integer;
begin
  if (gInitDll = False) then begin
    if (driverFileExistence = OLS_DLL_NO_ERROR) then begin
      for i := 0 to 4 do begin
        if (openDriver) then begin
          gDllStatus := OLS_DLL_NO_ERROR;
          Break;
        end;

        manage(OLS_DRIVER_ID, gDriverPath, OLS_DRIVER_REMOVE);
        if (not manage(OLS_DRIVER_ID, gDriverPath, OLS_DRIVER_INSTALL)) then begin
          gDllStatus := OLS_DLL_DRIVER_NOT_LOADED;
          Continue;
        end;

        if (openDriver) then begin
          gDllStatus := OLS_DLL_NO_ERROR;
          Break;
        end;

        Sleep(100*i);
      end;
    end;
    gInitDll := True;
  end;

  Result := (gDllStatus = OLS_DLL_NO_ERROR);
end;


procedure TECDriver.deinitialize;
var
  isHandel: Boolean;
  length, refCount: DWORD;
begin
  isHandel := (gHandle <> INVALID_HANDLE_VALUE);

  if (gInitDll and isHandel) then begin
    refCount := 0;
    DeviceIoControl(gHandle, Cardinal(IOCTL_OLS_GET_REFCOUNT), nil, 0, @refCount, SizeOf(refCount), length, nil);

    if (refCount = 1) then begin
      CloseHandle(gHandle);
      gHandle := INVALID_HANDLE_VALUE;
      manage(OLS_DRIVER_ID, gDriverPath, OLS_DRIVER_REMOVE);
    end;

    if (isHandel) then begin
      CloseHandle(gHandle);
      gHandle := INVALID_HANDLE_VALUE;
    end;

    gInitDll := False;
  end;

  DeleteFileW(PWideChar(gDriverPath));
end;


function TECDriver.readIoPortByte(port: Byte): Byte;
var
  value: Byte;
begin
  value := 0;
  bResult := DeviceIoControl(gHandle, Cardinal(IOCTL_OLS_READ_IO_PORT_BYTE), @port, SizeOf(port), @value, SizeOf(value), bytesReturned, nil);
  Result := value;
end;


procedure TECDriver.writeIoPortByte(port, value: Byte);
var
  inBuf: OLS_WRITE_IO_PORT_INPUT;
  nInBufferSize: Cardinal;
begin
  inBuf.PortNumber := port;
  inBuf.CharData := value;
  nInBufferSize := NativeUInt(@OLS_WRITE_IO_PORT_INPUT(nil^).CharData) + SizeOf(inBuf.CharData);
  bResult := DeviceIoControl(gHandle, Cardinal(IOCTL_OLS_WRITE_IO_PORT_BYTE), @inBuf, nInBufferSize, nil, 0, bytesReturned, nil);
end;

end.
