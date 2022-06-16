unit uReadConsole;

interface

uses
  SysUtils, Windows, Functions;

type
  TReadCallback = procedure(Text: WideString; Line: Integer);
  TExitCallback = procedure;

var
  ReadCallback: TReadCallback;
  ExitCallback: TExitCallback;
  ReadingThread: Cardinal = 0;


procedure StartReadConsole(OnRead: TReadCallback; OnExit: TExitCallback);
procedure StopReadConsole;
function ReadOutput(CommandLine: WideString): WideString;
function ReadOutputByPID(PID: DWORD): WideString;

implementation

procedure ReadConsole;
var
  i, j, nr: Cardinal;
  StdOutHandle: THandle;
  ConsoleInfo: TConsoleScreenBufferInfo;
  CursorPosition, ReadCoord: TCoord;
  Buffer: PAnsiChar;
  S: array of WideChar;
begin
  CursorPosition.X := 0;
  CursorPosition.Y := 0;
  GetMem(Buffer, 1024*1024);

  while True do begin
    StdOutHandle := GetStdHandle(STD_OUTPUT_HANDLE);

    if StdOutHandle = INVALID_HANDLE_VALUE then begin
      if Assigned(ExitCallback) then ExitCallback;
      StopReadConsole;
    end;

    GetConsoleScreenBufferInfo(StdOutHandle, ConsoleInfo);

    if (CursorPosition.X <> ConsoleInfo.dwCursorPosition.X) or (CursorPosition.Y <> ConsoleInfo.dwCursorPosition.Y) then begin
      if (CursorPosition.Y > ConsoleInfo.dwCursorPosition.Y+1) then CursorPosition.Y := 0;

      for i := CursorPosition.Y to ConsoleInfo.dwCursorPosition.Y do begin
        ReadCoord.X := 0;
        ReadCoord.Y := i;
        ReadConsoleOutputCharacterW(StdOutHandle, Buffer, ConsoleInfo.dwSize.X*2, ReadCoord, nr);

        SetLength(S, nr);
        if nr > 0 then for j := 0 to (nr div 2)-1 do S[j] := WideChar(MakeWord(Ord(Buffer[j*2]), Ord(Buffer[j*2+1])));
        if Assigned(ReadCallback) then ReadCallback(TrimRight(WideString(S)), ReadCoord.Y);
      end;

      CursorPosition := ConsoleInfo.dwCursorPosition;
    end;

    Sleep(1);
  end;
end;


procedure StartReadConsole(OnRead: TReadCallback; OnExit: TExitCallback);
begin
  StopReadConsole;
  ReadCallback := OnRead;
  ExitCallback := OnExit;
  ReadingThread := BeginThread(nil, 0, Addr(ReadConsole), nil, 0, ReadingThread);
end;


procedure StopReadConsole;
begin
  ReadCallback := nil;
  ExitCallback := nil;

  if ReadingThread <> 0 then TerminateThread(ReadingThread, 0);
  ReadingThread := 0;
end;


function ReadOutput(CommandLine: WideString): WideString;
var
  i, j, nr: Cardinal;
  hProcess: Cardinal;
  StdOutHandle: THandle;
  ConsoleInfo: TConsoleScreenBufferInfo;
  ReadCoord: TCoord;
  Buffer: PAnsiChar;
  S: array of WideChar;
begin
  Result := '';
  AllocInvisibleConsole('', 0);
  hProcess := WideWinExec(CommandLine, SW_HIDE);
  WaitForSingleObject(hProcess, INFINITE);
  StdOutHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  GetConsoleScreenBufferInfo(StdOutHandle, ConsoleInfo);
  GetMem(Buffer, 1024*1024);

  for i := 0 to ConsoleInfo.dwCursorPosition.Y do begin
    ReadCoord.X := 0;
    ReadCoord.Y := i;
    ReadConsoleOutputCharacterW(StdOutHandle, Buffer, ConsoleInfo.dwSize.X*2, ReadCoord, nr);

    SetLength(S, nr);
    if nr > 0 then for j := 0 to (nr div 2)-1 do S[j] := WideChar(MakeWord(Ord(Buffer[j*2]), Ord(Buffer[j*2+1])));
    Result := Result + TrimRight(WideString(S)) + #13#10;
  end;

  FreeConsole;
end;


function ReadOutputByPID(PID: DWORD): WideString;
var
  i, j, nr: Cardinal;
  StdOutHandle: THandle;
  ConsoleInfo: TConsoleScreenBufferInfo;
  ReadCoord: TCoord;
  Buffer: PAnsiChar;
  S: array of WideChar;
begin
  Result := '';
  if not AttachConsole(PID) then Exit;
  if GetStdHandle(STD_OUTPUT_HANDLE) = INVALID_HANDLE_VALUE then Exit;
  StdOutHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  GetConsoleScreenBufferInfo(StdOutHandle, ConsoleInfo);
  GetMem(Buffer, 1024*1024);

  for i := 0 to ConsoleInfo.dwCursorPosition.Y do begin
    ReadCoord.X := 0;
    ReadCoord.Y := i;
    ReadConsoleOutputCharacterW(StdOutHandle, Buffer, ConsoleInfo.dwSize.X*2, ReadCoord, nr);

    SetLength(S, nr);
    if nr > 0 then for j := 0 to (nr div 2)-1 do S[j] := WideChar(MakeWord(Ord(Buffer[j*2]), Ord(Buffer[j*2+1])));
    Result := Result + TrimRight(WideString(S)) + #13#10;
  end;

  FreeConsole;
end;

end.
