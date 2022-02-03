unit uYouTubeYtDownload;

interface

uses
  SysUtils, Windows, Classes, Variants, ActiveX, SHDocVw, Functions;

type
  PYouTubeMediaYtDownload = ^TYouTubeMediaYtDownload;
  TYouTubeMediaYtDownload = record
    Size: Int64;
    SizeString: String;
    Exstension: String;
    Quality: String;
    Name: WideString;
    URL: WideString;
  end;

type
  TYouTubeYtDownload = class
    private
      LYouTubeVideo: TList;
      LYouTubeAudio: TList;
    public
      constructor Create;
      destructor Destroy; override;
      procedure ParseAudio(ID: String);
      function GetAudioCount: Integer;
      function GetAudioItem(Index: Integer): PYouTubeMediaYtDownload;
      procedure ParseVideo(ID: String);
      function GetVideoCount: Integer;
      function GetVideoItem(Index: Integer): PYouTubeMediaYtDownload;
      function GetVideoTitle(ID: String): WideString;
  end;

var
  LWndClass: TWndClass;
  AppName: String;
  WinHandle: HWND;

function GetWebBrowserHTML(URL: WideString): WideString;

implementation


constructor TYouTubeYtDownload.Create;
begin
  inherited Create;

  LYouTubeVideo := TList.Create;
  LYouTubeAudio := TList.Create;
end;


destructor TYouTubeYtDownload.Destroy;
var
  i: Integer;
begin
  for i := 0 to LYouTubeVideo.Count-1 do Dispose(LYouTubeVideo[i]);
  for i := 0 to LYouTubeAudio.Count-1 do Dispose(LYouTubeAudio[i]);

  LYouTubeVideo.Free;
  LYouTubeAudio.Free;

  inherited Destroy;
end;


procedure TYouTubeYtDownload.ParseAudio(ID: String);
var
  HTML, Name: WideString;
  YouTubeMedia: PYouTubeMediaYtDownload;
  i, Position: Integer;
begin
  for i := 0 to LYouTubeAudio.Count-1 do Dispose(LYouTubeAudio[i]);
  LYouTubeAudio.Clear;

  HTML := GetWebBrowserHTML('https://www.yt-download.org/api/button/mp3/' + ID);
  Position := Pos('https://www.yt-download.org/download/', HTML);
  if Position <= 0 then Exit;

  Name := GetVideoTitle(ID);

  while Position > 0 do begin
    YouTubeMedia := New(PYouTubeMediaYtDownload);
    YouTubeMedia^.Name := Name;
    YouTubeMedia^.Size := 0;

    HTML := Copy(HTML, Position, Length(HTML));
    YouTubeMedia^.URL := Copy(HTML, 1, Pos('"', HTML)-1);

    Position := Pos('text-xl font-bold text-shadow-1 uppercase', HTML);
    HTML := Copy(HTML, Position+43, Length(HTML));
    YouTubeMedia^.Exstension := '.' + LowerCase(Copy(HTML, 1, Pos('<', HTML)-1));

    Position := Pos('text-shadow-1', HTML);
    HTML := Copy(HTML, Position+14, Length(HTML));
    YouTubeMedia^.Quality := Copy(HTML, 1, Pos('<', HTML)-1);
    YouTubeMedia^.Quality := StringReplace(YouTubeMedia^.Quality, ' ', '', [rfReplaceAll, rfIgnoreCase]);

    Position := Pos('text-shadow-1', HTML);
    HTML := Copy(HTML, Position+14, Length(HTML));
    YouTubeMedia^.SizeString := Copy(HTML, 1, Pos('<', HTML)-1);

    LYouTubeAudio.Add(YouTubeMedia);
    Position := Pos('https://www.yt-download.org/download/', HTML);
  end;
end;


function TYouTubeYtDownload.GetAudioCount: Integer;
begin
  Result := LYouTubeAudio.Count;
end;


function TYouTubeYtDownload.GetAudioItem(Index: Integer): PYouTubeMediaYtDownload;
begin
  Result := PYouTubeMediaYtDownload(LYouTubeAudio.Items[Index]);
end;


procedure TYouTubeYtDownload.ParseVideo(ID: String);
var
  HTML, Name: WideString;
  YouTubeMedia: PYouTubeMediaYtDownload;
  i, Position: Integer;
begin
  for i := 0 to LYouTubeVideo.Count-1 do Dispose(LYouTubeVideo[i]);
  LYouTubeVideo.Clear;

  HTML := GetWebBrowserHTML('https://www.yt-download.org/api/button/videos/' + ID);
  Position := Pos('https://www.yt-download.org/download/', HTML);
  if Position <= 0 then Exit;

  Name := GetVideoTitle(ID);

  while Position > 0 do begin
    YouTubeMedia := New(PYouTubeMediaYtDownload);
    YouTubeMedia^.Name := Name;
    YouTubeMedia^.Size := 0;

    HTML := Copy(HTML, Position, Length(HTML));
    YouTubeMedia^.URL := Copy(HTML, 1, Pos('"', HTML)-1);

    Position := Pos('text-xl font-bold text-shadow-1 uppercase', HTML);
    HTML := Copy(HTML, Position+43, Length(HTML));
    YouTubeMedia^.Exstension := '.' + LowerCase(Copy(HTML, 1, Pos('<', HTML)-1));

    Position := Pos('text-shadow-1', HTML);
    HTML := Copy(HTML, Position+14, Length(HTML));
    YouTubeMedia^.Quality := Trim(Copy(HTML, 1, Pos('<', HTML)-1));

    Position := Pos('text-shadow-1', HTML);
    HTML := Copy(HTML, Position+14, Length(HTML));
    YouTubeMedia^.SizeString := Copy(HTML, 1, Pos('<', HTML)-1);

    LYouTubeVideo.Add(YouTubeMedia);
    Position := Pos('https://www.yt-download.org/download/', HTML);
  end;
end;


function TYouTubeYtDownload.GetVideoCount: Integer;
begin
  Result := LYouTubeVideo.Count;
end;


function TYouTubeYtDownload.GetVideoItem(Index: Integer): PYouTubeMediaYtDownload;
begin
  Result := PYouTubeMediaYtDownload(LYouTubeVideo.Items[Index]);
end;


function TYouTubeYtDownload.GetVideoTitle(ID: String): WideString;
var
  MemoryStream: TMemorySTream;
  HTML: WideString;
  Position: Integer;
begin
  MemoryStream := TMemoryStream.Create;
  URLDownloadToStream('https://noembed.com/embed?url=https://www.youtube.com/watch?v=' + ID, MemoryStream);
  HTML := StreamToWideString(MemoryStream);
  MemoryStream.Free;

  Position := Pos('"title":', HTML);
  if Position <= 0 then Exit;

  HTML := Copy(HTML, Position+9, Length(HTML));
  Result := Copy(HTML, 1, Pos(',', HTML)-2);
end;


function GetWebBrowserHTML(URL: WideString): WideString;
var
  WebBrowser: TWebBrowser;
begin
  WebBrowser := TWebBrowser.Create(nil);
  WebBrowser.ParentWindow := WinHandle;
  WebBrowser.Silent := True;
  WebBrowser.Navigate(URL);

  while WebBrowser.Busy do Wait(1);
  while VarIsClear(WebBrowser.OleObject.Document) do Wait(1);
  while VarIsClear(WebBrowser.OleObject.Document.documentElement) do Wait(1);
  while VarIsClear(WebBrowser.OleObject.Document.documentElement.outerhtml) do Wait(1);

  Result := WebBrowser.OleObject.Document.documentElement.outerhtml;
  WebBrowser.Destroy;
end;


function WindowProc(hWnd, Msg: Longint; wParam: WPARAM; lParam: LPARAM): Longint; stdcall;
begin
  Result := DefWindowProc(hWnd, Msg, wParam, lParam);
end;


initialization
  Randomize;
  AppName := IntToStr(Random(MaxInt));

  FillChar(LWndClass, SizeOf(LWndClass), 0);
  LWndClass.hInstance := HInstance;
  LWndClass.lpszClassName := PChar(AppName + 'Wnd');
  LWndClass.Style := CS_PARENTDC;
  LWndClass.lpfnWndProc := @WindowProc;

  Windows.RegisterClass(LWndClass);
  WinHandle := CreateWindow(LWndClass.lpszClassName, PChar(AppName), 0,0,0,0,0,0,0, HInstance, nil);
  OleInitialize(nil); //Needed if you use console application
end.
