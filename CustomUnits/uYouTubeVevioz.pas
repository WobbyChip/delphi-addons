unit uYouTubeVevioz;

interface

uses
  SysUtils, Windows, Classes, Variants, ActiveX, SHDocVw, Functions;

type
  PYouTubeMediaVevioz = ^TYouTubeMediaVevioz;
  TYouTubeMediaVevioz = record
    Size: Int64;
    SizeString: String;
    Exstension: String;
    Quality: String;
    Name: WideString;
    URL: WideString;
  end;

type
  TYouTubeVevioz = class
    private
      LYouTubeVideo: TList;
      LYouTubeAudio: TList;
    public
      constructor Create;
      destructor Destroy; override;
      procedure ParseAudio(ID: String; getSize: Boolean);
      function GetAudioCount: Integer;
      function GetAudioItem(Index: Integer): PYouTubeMediaVevioz;
      procedure ParseVideo(ID: String; getSize: Boolean);
      function GetVideoCount: Integer;
      function GetVideoItem(Index: Integer): PYouTubeMediaVevioz;
  end;

var
  LWndClass: TWndClass;
  AppName: String;
  WinHandle: HWND;

function GetWebBrowserHTML(URL: WideString): WideString;

implementation


constructor TYouTubeVevioz.Create;
begin
  inherited Create;

  LYouTubeVideo := TList.Create;
  LYouTubeAudio := TList.Create;
end;


destructor TYouTubeVevioz.Destroy;
var
  i: Integer;
begin
  for i := 0 to LYouTubeVideo.Count-1 do Dispose(LYouTubeVideo[i]);
  for i := 0 to LYouTubeAudio.Count-1 do Dispose(LYouTubeAudio[i]);

  LYouTubeVideo.Free;
  LYouTubeAudio.Free;

  inherited Destroy;
end;


procedure TYouTubeVevioz.ParseAudio(ID: String; getSize: Boolean);
var
  HTML, Name, Tag: WideString;
  YouTubeMedia: PYouTubeMediaVevioz;
  i, Position: Integer;
begin
  for i := 0 to LYouTubeAudio.Count-1 do Dispose(LYouTubeAudio[i]);
  LYouTubeAudio.Clear;
  HTML := GetWebBrowserHTML('https://api.vevioz.com/@api/mp3/' + ID);

  Position := Pos('data-yt-title', HTML);
  if Position <= 0 then Exit;
  HTML := Copy(HTML, Position+15, Length(HTML));
  Name := Copy(HTML, 1, Pos('>', HTML)-2);

  Position := Pos('-tag', HTML);
  while Position > 0 do begin
    YouTubeMedia := New(PYouTubeMediaVevioz);
    YouTubeMedia^.Name := Name;

    HTML := Copy(HTML, Position+6, Length(HTML));
    Tag := Copy(HTML, 1, Pos('"', HTML)-1);

    HTML := Copy(HTML, Pos('media-ext', HTML)+10, Length(HTML));
    YouTubeMedia^.Exstension := '.' + WideLowerCase(Copy(HTML, 1, Pos('<', HTML)-1));

    HTML := Copy(HTML, Pos('media-qlt', HTML)+10, Length(HTML));
    YouTubeMedia^.Quality := WideLowerCase(Copy(HTML, 1, Pos('<', HTML)-1));
    if (Pos('kbps', YouTubeMedia^.Quality) <= 0) then YouTubeMedia^.Quality := 'Unknown';

    YouTubeMedia^.URL := 'https://api.vevioz.com/download/' + Tag + '/' + Name + YouTubeMedia^.Exstension;

    if (getSize) then begin
      YouTubeMedia^.Size := WebFileSize(YouTubeMedia^.URL);
    end else begin
      YouTubeMedia^.Size := 0;
      HTML := Copy(HTML, Pos('media-sz', HTML)+9, Length(HTML));
      YouTubeMedia^.SizeString := Copy(HTML, 1, Pos('<', HTML)-1);
    end;

    LYouTubeAudio.Add(YouTubeMedia);
    Position := Pos('-tag', HTML);
  end;
end;


function TYouTubeVevioz.GetAudioCount: Integer;
begin
  Result := LYouTubeAudio.Count;
end;


function TYouTubeVevioz.GetAudioItem(Index: Integer): PYouTubeMediaVevioz;
begin
  Result := PYouTubeMediaVevioz(LYouTubeAudio.Items[Index]);
end;


procedure TYouTubeVevioz.ParseVideo(ID: String; getSize: Boolean);
var
  HTML, Name, Tag: WideString;
  YouTubeMedia: PYouTubeMediaVevioz;
  i, Position: Integer;
begin
  for i := 0 to LYouTubeVideo.Count-1 do Dispose(LYouTubeVideo[i]);
  LYouTubeVideo.Clear;
  HTML := GetWebBrowserHTML('https://api.vevioz.com/@api/videos/' + ID);

  Position := Pos('data-yt-title', HTML);
  if Position <= 0 then Exit;
  HTML := Copy(HTML, Position+15, Length(HTML));
  Name := Copy(HTML, 1, Pos('>', HTML)-2);

  Position := Pos('-tag', HTML);
  while Position > 0 do begin
    YouTubeMedia := New(PYouTubeMediaVevioz);
    YouTubeMedia^.Name := Name;

    HTML := Copy(HTML, Position+6, Length(HTML));
    Tag := Copy(HTML, 1, Pos('"', HTML)-1);

    HTML := Copy(HTML, Pos('media-ext', HTML)+10, Length(HTML));
    YouTubeMedia^.Exstension := '.' + WideLowerCase(Copy(HTML, 1, Pos('<', HTML)-1));

    HTML := Copy(HTML, Pos('media-qlt', HTML)+10, Length(HTML));
    YouTubeMedia^.Quality := WideLowerCase(Copy(HTML, 1, Pos('<', HTML)-1));
    if (Pos('p', YouTubeMedia^.Quality) <= 0) then YouTubeMedia^.Quality := 'Unknown';

    YouTubeMedia^.URL := 'https://api.vevioz.com/download/' + Tag + '/' + Name + YouTubeMedia^.Exstension;
    if (getSize) then begin
      YouTubeMedia^.Size := WebFileSize(YouTubeMedia^.URL);
    end else begin
      YouTubeMedia^.Size := 0;
      HTML := Copy(HTML, Pos('media-sz', HTML)+9, Length(HTML));
      YouTubeMedia^.SizeString := Copy(HTML, 1, Pos('<', HTML)-1);
    end;

    LYouTubeVideo.Add(YouTubeMedia);
    Position := Pos('-tag', HTML);
  end;
end;


function TYouTubeVevioz.GetVideoCount: Integer;
begin
  Result := LYouTubeVideo.Count;
end;


function TYouTubeVevioz.GetVideoItem(Index: Integer): PYouTubeMediaVevioz;
begin
  Result := PYouTubeMediaVevioz(LYouTubeVideo.Items[Index]);
end;


function GetWebBrowserHTML(URL: WideString): WideString;
var
  WebBrowser: TWebBrowser;
begin
  WebBrowser := TWebBrowser.Create(nil);
  WebBrowser.ParentWindow := WinHandle;
  WebBrowser.Silent := True;
  WebBrowser.Navigate(URL);

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
