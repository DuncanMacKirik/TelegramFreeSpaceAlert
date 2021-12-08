program TelegramFreeSpaceAlert;

{$APPTYPE CONSOLE}

{.$DEFINE BACKEND_WININET}
{$DEFINE BACKEND_CURL}
{.$DEFINE BACKEND_GRIJJY}

uses
     System.RegularExpressions, System.SysUtils, System.NetEncoding,
     Winapi.Windows,
{$IFDEF BACKEND_WININET}
     System.Net.HttpClient, System.Net.HttpClientComponent
{$ENDIF}
{$IFDEF BACKEND_CURL}
     Curl.Easy, Curl.Lib
{$ENDIF}
{$IFDEF BACKEND_GRIJJY}
     Grijjy.Http
{$ENDIF}
     ;

const
     SPC_1KB = 1024;
     SPC_1MB = 1024 * SPC_1KB;
     SPC_1GB = 1024 * SPC_1MB;
     SPC_1TB: Int64 = 1024 * Int64(SPC_1GB);

     //TGM_BOT_TOKEN = 'XXX';
     //TGM_CHAT_ID = 'YYY';
     //Presets: array of string = ['C:=16G', 'D:=40G'];

procedure CheckResponseCode(const Code: Integer);
begin
     if Code <> 200 then
          raise Exception.Create('Response code is not 200 (OK)');
end;

procedure PerformHTTPGETRequest(const URL: string);
var
{$IFDEF BACKEND_WININET}
     WHTTP: TNetHTTPClient;
     Res: IHTTPResponse;
begin
     WHTTP := TNetHTTPClient.Create(nil);
     try
          Res := WHTTP.Get(URL);
          CheckResponseCode(Res.StatusCode);
     finally
          FreeAndNil(WHTTP);
     end;
end;
{$ENDIF}
{$IFDEF BACKEND_CURL}
     curl : ICurl;
begin
     curl := CurlGet;

     curl
          .SetUrl(URL)
          .SetSslVerifyPeer(False)
          .SetFollowLocation(True)
          .SwitchRecvToString
          .Perform;
     CheckResponseCode(curl.ResponseCode);

     curl := nil;
end;
{$ENDIF}
{$IFDEF BACKEND_GRIJJY}
     GHTTP: TgoHttpClient;
begin
     GHTTP := TgoHttpClient.Create;
     try
         GHTTP.Get(URL);
         CheckResponseCode(GHTTP.ResponseStatusCode);
     finally
         HttpClientManager.Release(GHTTP);
     end;
end;
{$ENDIF}

function GetFreeDiskSpace(const Folder: string): Int64;
var
     FreeAvailable, TotalSpace: Int64;
begin
     if not System.SysUtils.GetDiskFreeSpaceEx(PChar(Folder), FreeAvailable, TotalSpace, nil) then
           raise Exception.Create('Cannot get free disk space');
     Result := FreeAvailable;
end;

procedure SendAlert(const botToken, chatId, Msg: string);
var
     URL: string;
begin
     URL := 'https://api.telegram.org/bot' + botToken +
          '/sendMessage?chat_id=' + chatId + '&text=' +
          TNetEncoding.URL.Encode(Msg);
     PerformHTTPGETRequest(URL);
end;

function GetHostname: string;
var
     buffer    : PChar;
     bufferSize: DWORD;
begin
     bufferSize := MAX_COMPUTERNAME_LENGTH + 1;
     GetMem(buffer, bufferSize * SizeOf(char));
     try
          GetComputerName(buffer, bufferSize);
          SetLength(Result, StrLen(buffer));
          if Result <> '' then
               Move(buffer^, Result[1], Length(Result) * SizeOf(char));
     finally
          FreeMem(buffer);
     end;
end;


var
     Preset, Folder, FreeSpace, FSU: string;
     Params: TArray<string>;
     rgxFSL: TRegEx;
     mchFSL: TMatch;
     FSL, FDS: Int64;
     i: Integer;
     drv, Msg: string;
     botToken, chatId: string;
begin
     rgxFSL.Create('^([\d]+)([KMGT]?)$');
     Msg := '';
     botToken := '';
     chatId := '';
     for i := 1 to ParamCount do
     begin
          Preset := ParamStr(i);
          if CharInSet(Preset[1], ['/', '-']) then
          begin
               Params := Preset.Substring(1).Split(['=']);
               if Length(Params) <> 2 then
                    raise EArgumentException.Create('Invalid option format');
               if Params[0].ToUpper = 'BOTTOKEN' then
                    botToken := Params[1]
               else
               if Params[0].ToUpper = 'CHATID' then
                    chatId := Params[1]
               else
                    raise EArgumentException.Create('Unknown option');
               Continue;
          end;
          Params := Preset.Split(['=']);
          Folder := IncludeTrailingPathDelimiter(Params[0]);
          drv := ExtractFileDrive(Folder);
          FreeSpace := Params[1];
          WriteLn(drv, ' / ', FreeSpace);
          FreeSpace := FreeSpace.Trim.ToUpper;
          mchFSL := rgxFSL.Match(FreeSpace);
          if mchFSL.Success = False then
               raise EArgumentException.Create('Invalid free space limit parameter');
          FSL := StrToInt(mchFSL.Groups[1].Value);
          FSU := mchFSL.Groups[2].Value;
          if FSU = 'K' then
               FSL := FSL * SPC_1KB;
          if FSU = 'M' then
               FSL := FSL * SPC_1MB;
          if FSU = 'G' then
               FSL := FSL * SPC_1GB;
          if FSU = 'T' then
               FSL := FSL * SPC_1TB;
          FDS := GetFreeDiskSpace(Folder);
          if FDS < FSL then
          begin
               Msg := Msg + Format('Disk space on drive %s = %.02f GB (limit = %.02f GB)',
                    [drv, FDS / Int64(SPC_1GB), FSL / Int64(SPC_1GB)], TFormatSettings.Invariant) + #10;
          end;
     end;
     if botToken = '' then
          raise EArgumentNilException.Create('No bot token specified');
     if chatId = '' then
          raise EArgumentNilException.Create('No chat ID specified');
     if Msg <> '' then
     begin
          Msg := 'ALERT from ' + GetHostname + ':' + #10 + Msg;
          SendAlert(botToken, chatId, Msg);
     end;
end.
