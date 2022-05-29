# TelegramFreeSpaceAlert

## What is it?  
A simple program to be run as a scheduled task, and to send notifications via Telegram when free space on certain drives is less than a pre-configured limit.  
  
## Why use it?  
Primarily on Windows platforms, when you don't want to install Python/Node.js/Go/Ruby just to run a simple script. There are always VBScript and Powershell, but I rarely saw them used for this purpose.
  
## Usage  
```TelegramFreeSpaceAlert /botToken=<Telegram_bot_token> /chatId=<Telegram_chat_id> [/compName=<custom_machine_name>] <drv>:=<limit>...```  
\<drv\>: drive letter
\<limit\>: lower free space limit to check against. Can have suffixes K, M, G, T for Kibi-, Mebi-, Gibi-, and Tebibytes respectively (base-1024, Kilo-, Mega- and others being base-1000 nowadays).  
Example:   
```
TelegramFreeSpaceAlert /botToken=XXXX:YYYYYY /chatId=ZZZZZ C:=80G
```  
Explanation: when run, if free space on drive C: is less than 80 Gibibytes, the app will send the following message via Telegram to the specified chat:  
```
ALERT from DESKTOP-DX291:  
Disk space on drive C: = 47 GB (limit = 80 GB)
```  
You can set a more descriptive machine name like this:   
```TelegramFreeSpaceAlert /botToken=XXXX:YYYYYY /chatId=ZZZZZ /compName=Office-2nd-Floor C:=80G```   
Limits can be set for multiple drives, eg.  
```TelegramFreeSpaceAlert /botToken=XXXX:YYYYYY /chatId=ZZZZZ /compName=Boss-PC C:=200G D:=500G E:=1T```   
All options are case insensitive.   
  
## Technical details  
Written in Delphi, should compile fine with with versions XEx, 10.x and up.  
Three backends can be used for HTTP(s) communication, depending on conditional defines:  
 * WinInet - standard TNetHTTPClient component which uses Win32 API. Doesn't require any additional libraries, but can have issues with newer TLS versions on older OSes;  
 * Curl - uses [curl4delphi library](https://github.com/Mercury13/curl4delphi), recent versions handle newer TLS protocols fine, requires libcurl.dll to be present in app directory; good option for older OSes;  
 * Grijjy - uses Grijjy.Http module from the [Grijjy Foundation framework](https://github.com/grijjy/GrijjyFoundation) for Delphi.
  
## Todo list  
- [ ] a little refactoring (maybe)  
- [ ] add message template option  
- [ ] add config file support (maybe)  
- [ ] add quiet and verbose options  
- [ ] add support for base-1000 units (maybe)  
