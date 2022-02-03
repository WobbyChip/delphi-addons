unit NetBlock;

interface

uses
  Windows, MMSystem;

type
  PMIB_TCPROW = ^MIB_TCPROW;
  MIB_TCPROW = packed record
    dwState: DWORD;
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
    dwRemoteAddr: DWORD;
    dwRemotePort: DWORD;
  end;

  PMIB_TCPTABLE = ^MIB_TCPTABLE;
  MIB_TCPTABLE = packed record
    dwNumEntries: DWORD;
    Table: array [0..MaxWord] of MIB_TCPROW;
  end;

  PNetBlockInfo = ^TNetBlockInfo;
  TNetBlockInfo = packed record
    dwBlockMode: DWORD;
    dwResolution: DWORD;
    dwTimer: DWORD;
  end;

  TGetTcpTable = function(pTcpTable: PMIB_TCPTABLE; dwSize: PDWORD; bOrder: BOOL): DWORD; stdcall;
  TSetTcpEntry = function(pTcpRow: PMIB_TCPROW): DWORD; stdcall;

const
  IPHLPAPI_NAME = 'iphlpapi.dll';
  GETTCPTABLE_NAME = 'GetTcpTable';
  SETTCPENTRY_NAME = 'SetTcpEntry';
  MIB_TCP_STATE_DELETE_TCB = 12;
  NB_TABLE_SIZE = 1024;
  NB_BLOCK_NONE = 0;
  NB_BLOCK_INTERNET = 1;
  NB_BLOCK_ALL = 2;

function SetNetBlock(lpNetBlockInfo: PNetBlockInfo): DWORD;
function StatNetBlock(lpNetBlockInfo: PNetBlockInfo): DWORD;
procedure StopNetBlock;

var
  x: DWORD = 0;
  hIphlp: HMODULE = 0;
  dwResolution: DWORD = 0;
  dwBlockMode: DWORD = 0;
  dwTimer: DWORD = 0;
  dwProcError: DWORD = 0;
  _GetTcpTable: TGetTcpTable = nil;
  _SetTcpEntry: TSetTcpEntry = nil;

implementation

procedure NetBlockTimerProc(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD); stdcall;
var
  lpTable: PMIB_TCPTABLE;
  lpRow: PMIB_TCPROW;
  bRemove: Boolean;
  dwReturn: DWORD;
  dwSize: DWORD;
begin
  Inc(x);
  dwSize := (NB_TABLE_SIZE * SizeOf(MIB_TCPROW)) + SizeOf(DWORD);  //Start with an optimal table size
  GetMem(lpTable, dwSize);  //Allocate memory for the table
  dwReturn := _GetTcpTable(lpTable, @dwSize, False);  //Get the table
 
  //We may have to reallocate and try again
  if (dwReturn = ERROR_INSUFFICIENT_BUFFER) then begin
    ReallocMem(lpTable, dwSize);  //Reallocate memory for new table
    dwReturn := _GetTcpTable(lpTable, @dwSize, False);  //Make the call again
  end;
 
  //Check for succes
  if (dwReturn = ERROR_SUCCESS) then begin
    //Iterate the table
    for dwSize := 0 to Pred(lpTable^.dwNumEntries) do begin
      //Get the row
      lpRow := @lpTable^.Table[dwSize];
      //Check for 0.0.0.0 address
      if (lpRow^.dwLocalAddr = 0) or (lpRow^.dwRemoteAddr = 0) then Continue;
      //What blocking mode are we in
      case dwBlockMode of
        //Need to check the first two bytes in network address
        NB_BLOCK_INTERNET: bRemove := not (Word(Pointer(@lpRow^.dwLocalAddr)^) = Word(Pointer(@lpRow^.dwRemoteAddr)^));
        //Need to check all four bytes in network address
        NB_BLOCK_ALL: bRemove := not (lpRow^.dwLocalAddr = lpRow^.dwRemoteAddr);
      else
        bRemove := False;  //No checking
      end;
      //Do we need to remove the entry?
      if bRemove then begin
        //Set entry state
        lpRow^.dwState := MIB_TCP_STATE_DELETE_TCB;
        //Remove the TCP entry
        _SetTcpEntry(lpRow);
      end;
    end;
  end;
  FreeMem(lpTable);  //Free the table
end;


function StatNetBlock(lpNetBlockInfo: PNetBlockInfo): DWORD;
begin
  //Parameter check
  if not(Assigned(lpNetBlockInfo)) then Result := ERROR_INVALID_PARAMETER  //Null buffer
  else begin
    //Fill in the current settings
    lpNetBlockInfo^.dwResolution := dwResolution;
    lpNetBlockInfo^.dwBlockMode := dwBlockMode;
    lpNetBlockInfo^.dwTimer := dwTimer;
    Result := ERROR_SUCCESS;  //Success
  end;
end;


function SetNetBlock(lpNetBlockInfo: PNetBlockInfo): DWORD;
begin
  //Parameter check
  if not(Assigned(lpNetBlockInfo)) then begin
    StopNetBlock;  //Treat the same way as if StopNetBlock had been called
    Result := ERROR_SUCCESS;  //Success
  end else if (@_GetTcpTable = @_SetTcpEntry) then
    Result := dwProcError //Failed to load library or get the function pointers
  else if (lpNetBlockInfo^.dwResolution = 0) then
    Result := ERROR_INVALID_PARAMETER  //Invalid time specified
  else if (lpNetBlockInfo^.dwBlockMode > NB_BLOCK_ALL) then
    Result := ERROR_INVALID_PARAMETER  //Invalid blocking mode
  else begin
    if (dwTimer > 0) then timeKillEvent(dwTimer);  //Kill the current timer if the blocking is running
    dwTimer := 0;  //Clear timer tracking handle
    dwBlockMode := lpNetBlockInfo^.dwBlockMode;  //Save off the current block mode and resolution
    dwResolution := lpNetBlockInfo^.dwResolution;
    if (dwBlockMode = NB_BLOCK_NONE) then Result := ERROR_SUCCESS
    else begin
      //Create the timer to handle the network blocking
      dwTimer := timeSetEvent(lpNetBlockInfo^.dwResolution, 0, @NetBlockTimerProc, 0, TIME_PERIODIC or TIME_CALLBACK_FUNCTION);
      //Check timer handle
      if (dwTimer = 0) 
        then Result := GetLastError  //Failure
        else Result := ERROR_SUCCESS;  //Succes
    end;
  end;
end;


procedure StopNetBlock;
begin
  //This will stop the current net blocking
  if (dwTimer > 0) then begin
    timeKillEvent(dwTimer);  //Kill the timer
    dwBlockMode := NB_BLOCK_NONE;  //Reset all values
    dwResolution := 0;
    dwTimer := 0;
  end;
end;
 
initialization
  hIphlp := LoadLibrary(IPHLPAPI_NAME);  //Load the ip helper api library
  //Attempt to get the function addresses
  if (hIphlp > 0) then begin
    @_GetTcpTable := GetProcAddress(hIpHlp, GETTCPTABLE_NAME);
    if not (Assigned(@_GetTcpTable)) then dwProcError := GetLastError
    else begin
      @_SetTcpEntry := GetProcAddress(hIpHlp, SETTCPENTRY_NAME);
      if not(Assigned(@_SetTcpEntry)) then dwProcError := GetLastError
    end;
  end else
    dwProcError := GetLastError; //Save off the error
finalization
  if (dwTimer > 0) then timeKillEvent(dwTimer);  //Kill the timer if running
  @_GetTcpTable := nil;  //Clear function
  @_SetTcpEntry := nil;  //Clear function
  if (hIphlp > 0) then FreeLibrary(hIphlp);  //Free the ip helper api library
end.