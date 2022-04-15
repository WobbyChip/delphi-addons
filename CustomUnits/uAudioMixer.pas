unit uAudioMixer;

interface

uses
  Windows, SysUtils, Messages, Classes, MMSystem, AMixer;

type
  TDeviceChangeCallback = procedure(wParam: Integer);
  TMixerChangeCallback = procedure(Msg: Integer; hMixer: HMIXER; MxId: Integer);

type
  PMixer = ^TMixer;
  TMixer = record
    MxId: Integer;
    hMixer: HMIXER;
  end;

var
  DeviceChangeCallback: TDeviceChangeCallback;
  MixerChangeCallback: TMixerChangeCallback;
  LWndClass: TWndClass;
  WinHandle: HWND;
  ThreadID: LongWord = 0;
  mixerList: Tlist;

procedure SetDeviceChangeCallback(Proc: TDeviceChangeCallback);
procedure SetMixerChangeCallback(Proc: TMixerChangeCallback);
procedure RunMixerCallback(Msg: Integer; hMixer: HMIXER);
procedure OpenAllMixers;
procedure CloseAllMixers;

function isDefault(DeviceId: Integer): Boolean; overload;
function isDefault(Name: WideString): Boolean; overload;
function GetMixerMicrophoneName(Index: Integer): WideString;
function GetMixerMicrophone(Name: WideString): Integer;
function GetDefaultMixerMicrophone: Integer;
function SetMicrophoneVolume(DeviceId, Value, Mute: Integer): Boolean;
function GetMicrophoneVolume(DeviceId: Integer): Integer;

implementation

function ChangeWindowMessageFilter(msg: Cardinal; Action: Dword): BOOL; stdcall; external 'user32.dll';


function WndProc(hWnd, Msg: Longint; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
begin
  if (Msg = WM_DEVICECHANGE) and Assigned(DeviceChangeCallback) then DeviceChangeCallback(wParam);
  if (Msg = WM_DEVICECHANGE) and Assigned(MixerChangeCallback) then OpenAllMixers;
  if ((Msg = MM_MIXM_LINE_CHANGE) or (Msg = MM_MIXM_CONTROL_CHANGE)) and Assigned(MixerChangeCallback) then RunMixerCallback(Msg, wParam);
  Result := DefWindowProc(hWnd, Msg, wParam, lParam);
end;


procedure MessageLoop;
var
  Msg: TMsg;
begin
  FillChar(LWndClass, SizeOf(LWndClass), 0);
  LWndClass.hInstance := HInstance;
  LWndClass.lpszClassName := PChar(IntToStr(Random(MaxInt)) + 'Wnd');
  LWndClass.Style := CS_PARENTDC;
  LWndClass.lpfnWndProc := @WndProc;

  Windows.RegisterClass(LWndClass);
  WinHandle := CreateWindow(LWndClass.lpszClassName, nil, 0,0,0,0,0,0,0, HInstance, nil);

  while GetMessage(Msg, 0,0,0) do begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;


procedure SetDeviceChangeCallback(Proc: TDeviceChangeCallback);
begin
  if Assigned(Proc) and (WinHandle = 0) then begin
    ThreadID := BeginThread(nil, 0, Addr(MessageLoop), nil, 0, ThreadID);
    while WinHandle = 0 do Sleep(1);
  end;

  DeviceChangeCallback := Proc;
end;


procedure SetMixerChangeCallback(Proc: TMixerChangeCallback);
begin
  if Assigned(Proc) and (WinHandle = 0) then begin
    ThreadID := BeginThread(nil, 0, Addr(MessageLoop), nil, 0, ThreadID);
    while WinHandle = 0 do Sleep(1);
  end;

  MixerChangeCallback := Proc;

  if Assigned(Proc)
    then OpenAllMixers
    else CloseAllMixers;
end;


procedure RunMixerCallback(Msg: Integer; hMixer: HMIXER);
var
  i: Integer;
  Mixer: PMixer;
begin
  if not Assigned(MixerChangeCallback) then Exit;

  for i := 0 to mixerList.Count-1 do begin
    Mixer := mixerList.Items[i];
    if Mixer.hMixer = hMixer then MixerChangeCallback(Msg, Mixer.hMixer, Mixer.MxId)
  end;
end;


function GetMixerHandle(i: Integer): Integer;
begin
  Result := -1;
  if mixerOpen(@Result, i, WinHandle, 0, CALLBACK_WINDOW OR MIXER_OBJECTF_MIXER) = MMSYSERR_NOERROR then Exit;
  if mixerOpen(@Result, i, WinHandle, 0, CALLBACK_WINDOW) = MMSYSERR_NOERROR then Exit;
end;


procedure OpenAllMixers;
var
  i: Integer;
  Mixer: PMixer;
begin
  if mixerList.Count > 0 then CloseAllMixers;

  for i := waveOutGetNumDevs to waveOutGetNumDevs+waveInGetNumDevs-1 do begin
    Mixer := New(PMixer);
    Mixer^.MxId := i;
    Mixer^.hMixer := GetMixerHandle(i);
    if Mixer^.hMixer > -1 then mixerList.Add(Mixer);
  end;
end;


procedure CloseAllMixers;
var
  i: Integer;
begin
  for i := 0 to mixerList.Count-1 do mixerClose(PMixer(mixerList.Items[i]).hMixer);
  mixerList.Clear;
end;


//GetMixerMicrophoneName
function GetMixerMicrophoneName(Index: Integer): WideString;
var
  MixerCaps: TMixerCapsW;
begin
  mixerGetDevCapsW(Index, @MixerCaps, SizeOf(MixerCaps));
  Result := WideString(MixerCaps.szPname);
end;
//GetMixerMicrophoneName


//GetMixerMicrophone
function GetMixerMicrophone(Name: WideString): Integer;
var
  i: Integer;
  MixerCaps: TMixerCapsW;
begin
  Result := -1;

  for i := waveOutGetNumDevs to waveOutGetNumDevs+waveInGetNumDevs-1 do begin
    mixerGetDevCapsW(i, @MixerCaps, SizeOf(MixerCaps));
    if Name = WideString(MixerCaps.szPname) then Result := i;
  end;
end;
//GetMixerMicrophone


//isDefault
function isDefault(DeviceId: Integer): Boolean;
begin
  Result := (DeviceId = GetDefaultMixerMicrophone);
end;
//isDefault


//isDefault
function isDefault(Name: WideString): Boolean;
begin
  Result := (GetMixerMicrophone(Name) = GetDefaultMixerMicrophone);
end;
//isDefault


//GetDefaultMixerMicrophone
function GetDefaultMixerMicrophone: Integer;
const
  DRVM_MAPPER = $2000;
  DRVM_MAPPER_PREFERRED_GET = DRVM_MAPPER + 21;
  DRVM_MAPPER_PREFERRED_SET = DRVM_MAPPER + 22;
var
  dw1, dw2, i: Cardinal;
  WaveCaps: TWaveInCapsW;
  MixerCaps: TMixerCapsW;
begin
  Result := -1;
  dw1 := $FFFFFFFF;
  dw2 := 0;

  waveInMessage(WAVE_MAPPER, DRVM_MAPPER_PREFERRED_GET, DWORD(@dw1), DWORD(@dw2));
  if dw1 = $FFFFFFFF then Exit;
  waveInGetDevCapsW(dw1, @WaveCaps, SizeOf(WaveCaps));

  for i := waveOutGetNumDevs to waveOutGetNumDevs+waveInGetNumDevs-1 do begin
    mixerGetDevCapsW(i, @MixerCaps, SizeOf(MixerCaps));
    if WideString(WaveCaps.szPname) = WideString(MixerCaps.szPname) then Result := i;
  end;
end;
//GetDefaultMixerMicrophone


//SetMicrophoneVolume
function SetMicrophoneVolume(DeviceId, Value, Mute: Integer): Boolean;
var
  Mixer: TAudioMixer;
  Volume: Integer;
begin
  Mixer := TAudioMixer.Create(nil);
  Mixer.MixerId := DeviceId;
  Volume := -1;
  if Value > 100 then Value := 100;
  if Value > -1 then Volume := Round((65535/100)*Value);
  Result := Mixer.SetVolume(0, -1, Volume, Volume, Mute);
  Mixer.Free;
end;
//SetMicrophoneVolume


//GetMicrophoneVolume
function GetMicrophoneVolume(DeviceId: Integer): Integer;
var
  Mixer: TAudioMixer;
  Volume, Mute: Integer;
  t: Boolean;
begin
  Mixer := TAudioMixer.Create(nil);
  Mixer.MixerId := DeviceId;
  Volume := -1;
  Mixer.GetVolume(0, -1, Volume, Volume, Mute, t, t, t, t);
  Result := Round(Volume/(65535/100));
  Mixer.Free;
end;
//GetMicrophoneVolume


initialization
  Randomize;
  mixerList := TList.Create;
  ChangeWindowMessageFilter(WM_DEVICECHANGE, 1);
end.
