@ECHO off

::--------------------- You can modify the batch file in this area ----------------------

:: Edit the file formats targetted here - Do not add any space before and after the line
SET VideoFormats=mp4 mkv m4a m4v f4v f4a m4b m4r f4b mov wmv wma webm flv avi
SET ImageFormats=jpg jpeg png webp tiff tif raw bmp heif heic
SET MusicFormats=mp3 aac flac aiff alac m4a cda wav opus ogg

:: Edit the default settings here - To remove a default setting, leave empty (spaces aren't allowed)
SET "DisplayText="				&::Display title, warning, documentation, known bugs text (y/n) (blank=y)
SET "input=" 					&::Set a default path for the input folder (e.g. C:\Users\username\Desktop - Do not add quotation marks)
SET "output="					&::Set a default path for the output folder. Will automatically set CustomOutput to "y"
SET "CustomOutput=n"			&::Default answer for the custom output directory prompt. Ignored if the variable "output" has a default path. (y/n)
SET "target="				&::Default answer for types of file targetted (v nor i nor m) (v = videos - i = images - m = musics)
REM SET "SubfolderSearch="		&::Default answer for searching subfolders (y/n)
SET "RenameOutput="			&::Default answer for the rename input option (y/n)
SET "RenameInput="				&::Default answer for the rename output option (y/n). Will set RenameOutput to y
SET "ExcludeCompressed=n"		&::Default answer for the exlude already compressed files option (y/n)

::----------------------------------------------------------------------------------------

:: Prerequisites
SETLOCAL enableextensions enabledelayedexpansion 
IF /I "%DisplayText%" == "n" GOTO INPUTFORMATTING
FOR /F "delims=: tokens=*" %%A IN ('findstr /B ::: "%~f0"') do @echo(%%A
FOR /F %%A IN ('copy /Z "%~dpf0" NUL') DO SET "CR=%%A"
:RETRYCHOICE0
IF NOT EXIST "%appdata%\ffmpeg\ffmpeg.exe" <NUL SET /PE=FFmpeg, a needed library, isn't installed
IF NOT EXIST "%appdata%\ffmpeg\ffmpeg.exe" SET /P download=. Download and install it? (150kb) (y/n) : 
IF "%download%" == "y" <NUL SET /P F=Downloading... Please do not close... !CR!
IF "%download%" == "y" powershell -command "cd $env:AppData; iwr https://www.dropbox.com/s/bm35bhltnfv26uj/ffmpeg.zip?dl=1 -o ffmpeg.zip; Expand-Archive ffmpeg.zip; rm ffmpeg.zip"
IF "%download%" == "y" ECHO FFmpeg was successfully installed.    
IF NOT EXIST "%appdata%\ffmpeg\ffmpeg.exe" ECHO To use Pressor, please install FFmpeg. && ECHO Exiting... && PAUSE>NUL && EXIT /B
:::
:::     _____   ______ _______ _______ _______  _____   ______
:::    |_____] |_____/ |______ |______ |______ |     | |_____/
:::    |       |    \_ |______ ______| ______| |_____| |    \_
::: 
::: WARNING : THIS PROGRAM IS EXPERIMENTAL AND COULD BREAK YOUR SYSTEM IF USED BADLY
:::
::: DOCUMENTATION & BUGS :
::: - Pressor is a utility which simplify media batch compressions.
::: - Targetted file formats and default options are editable in the batch file
::: - Renaming multiple files that have the same exact last 
:::   modification date will result in a failure of this feature.
:::

:INPUTFORMATTING
SET BatchVideoFormats1=%VideoFormats: =" "*.%
SET BatchVideoFormats1="*.%BatchVideoFormats1%"
SET BatchImageFormats1=%ImageFormats: =" "*.%
SET BatchImageFormats1="*.%BatchImageFormats1%"
SET BatchMusicFormats1=%MusicFormats: =" "*.%
SET BatchMusicFormats1="*.%BatchMusicFormats1%"
SET BatchVideoFormats2=%VideoFormats: = *.%
SET BatchVideoFormats2=*.%BatchVideoFormats2%
SET BatchImageFormats2=%ImageFormats: = *.%
SET BatchImageFormats2=*.%BatchImageFormats2%
SET BatchMusicFormats2=%MusicFormats: = *.%
SET BatchMusicFormats2=*.%BatchMusicFormats2%
SET PSVideoFormats=%VideoFormats: =','*.%
SET PSVideoFormats='*.%PSVideoFormats%'
SET PSImageFormats=%ImageFormats: =','*.%
SET PSImageFormats='*.%PSImageFormats%'
SET PSMusicFormats=%MusicFormats: =','*.%
SET PSMusicFormats='*.%PSMusicFormats%'

:INPUT 	
SET InvalidSkip=false
IF NOT "%input%" == "" GOTO RETRYCHOICE1
<NUL SET /P A=Please choose your input folder :!CR!
SET "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Input folder',0,0).self.path""
FOR /F "usebackq delims=" %%I IN (`powershell %psCommand%`) DO SET "input=%%I"
:RETRYCHOICE1
ECHO %input% | FIND "{" >NUL && IF ERRORLEVEL 1 (BREAK) ELSE (SET input=)
IF "%InvalidSkip%" == "true" SET /P retry1= Do you want to retry? (y/n) (blank=n) : 
IF "%InvalidSkip%" == "true" SET InvalidSkip=false && GOTO SKIP2
IF NOT EXIST "%input%" ECHO Invalid input directory                 && SET /P retry1=Do you want to retry? (y/n) (blank=n) : 
:SKIP2
IF NOT EXIST "%input%" IF /I "%retry1%" == "y" SET input=&& SET retry1=&& GOTO INPUT
IF NOT EXIST "%input%" IF /I "%retry1%" == "n" ECHO Exiting... && PAUSE>NUL && EXIT /B
IF NOT EXIST "%input%" IF "%retry1%" == "" ECHO Exiting... && PAUSE>NUL && EXIT /B
IF NOT EXIST "%input%" IF NOT "%retry1%" == "" ECHO Invalid input "%retry1%" && SET InvalidSkip=true&& GOTO RETRYCHOICE1
ECHO Input : %input%                           
CD "%input%"

:CHECKING
<NUL SET /P D=Detecting convertable files... !CR!
>NUL 2>NUL DIR /a-d /s %BatchVideoFormats1% && SET VideoExist=video&& SET FileExist=video&& SET FExist=v&& SET Vexist=v&& SET ToCountFormats=%BatchVideoFormats2%&& SET SLASH1=/&& SET SLASH2=/
>NUL 2>NUL DIR /a-d /s %BatchImageFormats1% && SET ImageExist=image&& SET FileExist=%FileExist%%SLASH1%image&& SET FExist=%FExist%%SLASH1%i&& SET Iexist=i&& SET ToCountFormats=%ToCountFormats% %BatchImageFormats2%&& SET SLASH2=/
>NUL 2>NUL DIR /a-d /s %BatchMusicFormats1% && SET MusicExist=music&& SET FileExist=%FileExist%%SLASH2%music&& SET FExist=%FExist%%SLASH2%m&& SET Mexist=m&& SET ToCountFormats=%ToCountFormats% %BatchMusicFormats2%
SET TotalCount=0&& FOR /R %%A IN (%ToCountFormats%) DO SET /a TotalCount+=1
SET VideoCount=0&& FOR /R %%A IN (%BatchVideoFormats2%) DO SET /a VideoCount+=1
SET ImageCount=0&& FOR /R %%A IN (%BatchImageFormats2%) DO SET /a ImageCount+=1
SET MusicCount=0&& FOR /R %%A IN (%BatchMusicFormats2%) DO SET /a MusicCount+=1
IF "%TotalCount%" LSS "2" (SET TotalCountText=file) ELSE (SET TotalCountText=files)
IF "%VideoCount%" LSS "2" (SET VideoCountText=video) ELSE (SET VideoCountText=videos)
IF "%ImageCount%" LSS "2" (SET ImageCountText=image) ELSE (SET ImageCountText=images)
IF "%MusicCount%" LSS "2" (SET MusicCountText=music) ELSE (SET MusicCountText=musics)
ECHO Detected : %TotalCount% %TotalCountText% (%VideoCount% %VideoCountText%, %ImageCount% %ImageCountText%, %MusicCount% %MusicCountText%)
IF "%VideoExist%" == "" IF "%ImageExist%" == "" IF "%MusicExist%" == "" ECHO Input doesn't contain convertable files && SET InvalidSkip=true&& SET input=&& GOTO RETRYCHOICE1

:CUSTOMOUTPUT
IF NOT "%output%" == "" GOTO OUTPUTCHECK
IF NOT "%CustomOutput%" == "" GOTO SKIP1
SET /P CustomOutput=Set a custom output directory? (y/n) (blank=n) : && !CR!
:SKIP1
IF /I "%CustomOutput%" == "y" GOTO OUTPUT
IF /I "%CustomOutput%" == "n" GOTO TARGET
IF /I "%CustomOutput%" == "" GOTO TARGET
ECHO Invalid custom input "%CustomOutput%"
SET CustomOutput=&& GOTO CUSTOMOUTPUT

:OUTPUT
SET output=
<NUL SET /P C=Please choose your output folder :!CR!
SET "psCommand="(new-object -COM 'Shell.Application')^
.BrowseForFolder(0,'Output folder',0,0).self.path""
FOR /F "usebackq delims=" %%I IN (`powershell %psCommand%`) DO SET "output=%%I"
:OUTPUTCHECK
ECHO %output% | FIND "{" >NUL && IF ERRORLEVEL 1 (BREAK) ELSE (SET output=)
IF NOT EXIST "%output%" ECHO Invalid output directory "%output%"                && SET /P retry2=Do you want to retry? (y/n) (blank=n) : 
IF NOT EXIST "%output%" IF /I "%retry2%" == "y" GOTO OUTPUT
IF NOT EXIST "%output%" IF /I "%retry2%" == "n" ECHO Exiting... && PAUSE>NUL && EXIT /B
IF NOT EXIST "%output%" IF /I "%retry2%" == "" ECHO Exiting... && PAUSE>NUL && EXIT /B
IF "%output%" == "%input%" SET CustomOutput=n
ECHO Output : %output%                           

:TARGET
IF "%Vexist%" == "v" IF "%Iexist%" == "" IF "%Mexist%" == "" SET TargetVideo=true&& GOTO SENDTO1 
IF "%Vexist%" == "" IF "%Iexist%" == "i" IF "%Mexist%" == "" SET TargetImage=true&& GOTO SENDTO1
IF "%Vexist%" == "" IF "%Iexist%" == "" IF "%Mexist%" == "m" SET TargetMusic=true&& GOTO SENDTO1
IF NOT "%target%" == "" GOTO SKIP2
SET /P target=Target !FileExist! files? (!FExist!) (blank=!Vexist!!Iexist!!Mexist!) : 
IF "%target%" == "" IF "%Vexist%" == "v" SET TargetVideo=true
IF "%target%" == "" IF "%Iexist%" == "i" SET TargetImage=true
IF "%target%" == "" IF "%Mexist%" == "m" SET TargetMusic=true
:SKIP2
ECHO %target% | find /I "v" >NUL && IF ERRORLEVEL 1 (BREAK) ELSE (IF "%Vexist%" == "v" SET TargetVideo=true)
ECHO %target% | find /I "i" >NUL && IF ERRORLEVEL 1 (BREAK) ELSE (IF "%Iexist%" == "i" SET TargetImage=true)
ECHO %target% | find /I "m" >NUL && IF ERRORLEVEL 1 (BREAK) ELSE (IF "%Mexist%" == "m" SET TargetMusic=true)
:SENDTO1
IF "%TargetVideo%" == "true" SET PSformats=%PSVideoFormats%&& SET VIRGULE1=,&&SET VIRGULE2=,
IF "%TargetImage%" == "true" SET PSformats=%PSFormats%%VIRGULE1%%PSImageFormats%&& SET VIRGULE2=,
IF "%TargetMusic%" == "true" SET PSformats=%PSFormats%%VIRGULE2%%PSMusicFormats%
IF NOT "%PSFormats%" == "" GOTO RENAMEOPTIONS
ECHO Invalid file format input "!target!"
SET target=&& GOTO TARGET

:RENAMEOPTIONS
IF "%RenameInput%" == "y" SET RenameOutput=y&& powershell -command "Get-ChildItem -Recurse %PSformats% | Rename-Item -NewName { $_.LastWriteTime.toString(\"yyyy MM-dd HH-mm\") + ' input' + $_.Extension }" && GOTO EXCLUDECOMPRESSED
IF "%RenameInput%" == "n" GOTO EXCLUDECOMPRESSED
IF NOT "%RenameInput%" == "" ECHO Invalid "rename input" answer.
IF "%RenameOutput%" == "y" GOTO RENAMEADDINPUT
IF "%RenameOutput%" == "n" GOTO RENAMEADDINPUT
IF NOT "%RenameOutput%" == "" ECHO Invalid "rename output" answer.
SET /P rename=Rename files to timestamps ? (i=input+output / o=output / e=exclusively / n) (blank=n) : 
:SKIP3
IF "%rename%" == "" GOTO RENAMEADDINPUT
ECHO %rename% | find /I "i" >NUL && IF ERRORLEVEL 1 (BREAK) ELSE (SET RenameInput=y)
ECHO %rename% | find /I "o" >NUL && IF ERRORLEVEL 1 (BREAK) ELSE (SET RenameOutput=y)
IF "%RenameInput%" == "y" SET RenameOutput=y&& powershell -command "Get-ChildItem -Recurse %PSformats% | Rename-Item -NewName { $_.LastWriteTime.toString(\"yyyy MM-dd HH-mm\") + ' input' + $_.Extension }" && GOTO EXCLUDECOMPRESSED
IF "%RenameOutput%" == "y" GOTO RENAMEADDINPUT
IF /I "%rename%" == "e" powershell -command "Get-ChildItem -Recurse %PSformats% | Rename-Item -NewName { $_.LastWriteTime.toString(\"yyyy MM-dd HH-mm\") + $_.Extension }" && ECHO Done && PAUSE>NUL && EXIT /B
IF /I "%rename%" == "n" GOTO EXCLUDECOMPRESSED
IF /I "%rename%" == "" GOTO EXCLUDECOMPRESSED
SET RenameInput=&& SET RenameOutput=
ECHO Invalid renaming option "%rename%"
SET rename=&& GOTO RENAMEOPTIONS

:RENAMEADDINPUT
powershell -command "Get-ChildItem -Recurse %PSformats% | Rename-Item -NewName {$_.Name -replace ' input', '' }"
powershell -command "Get-ChildItem -Recurse %PSformats% | Rename-Item -NewName { $_.Basename + ' input' + $_.Extension }"

:EXCLUDECOMPRESSED
SET excluded= ffmpeg
IF "%ExcludeCompressed%" == "y" GOTO SENDTO2
IF "%ExcludeCompressed%" == "n" SET excluded=&& GOTO SENDTO2
IF NOT "%ExcludeCompressed%" == "" ECHO Invalid input "%ExcludeCompressed%" as the answer for the exclude compressed files prompt
SET ExcludeCompressed=undefined
SET BatchFormats=%PSFormats:'=%
SET BatchFormats=%BatchFormats:,= %
FOR /R %%i IN (%BatchFormats%) DO ((ECHO "%%i" | FIND " ffmpeg" 1>NUL) && (SET ConvertedFiles=true))
IF "%ConvertedFiles%" == "true" SET /P ExcludeCompressed=Exclude already compressed files (ending with "ffmpeg") ? (y/n) (blank=y) : 
IF "%ExcludeCompressed%" == "y" GOTO SENDTO2
IF "%ExcludeCompressed%" == "undefined" GOTO SENDTO2
IF "%ExcludeCompressed%" == "n" SET excluded=&& GOTO SENDTO2
ECHO Invalid input "%ExcludeCompressed%"

:SENDTO2
IF "%TargetVideo%" == "true" GOTO VIDEOOPTIONS
IF "%TargetImage%" == "true" GOTO IMAGEOPTIONS
IF "%TargetMusic%" == "true" GOTO MUSICOPTIONS

:VIDEOOPTIONS
:: options here
::-vf "transpose=1,2,3"
::-b:v 5000k
IF "%TargetImage%" == "true" GOTO IMAGEOPTIONS
IF "%TargetMusic%" == "true" GOTO MUSICOPTIONS
GOTO SENDTO3

:IMAGEOPTIONS
:: options here
::-vf "transpose=1,2,3"
IF "%TargetMusic%" == "true" GOTO MUSICOPTIONS
GOTO SENDTO3

:MUSICOPTIONS
:: options here
GOTO SENDTO3

:SENDTO3
IF "%TargetVideo%" == "true" GOTO COMPRESSIONVIDEO
IF "%TargetImage%" == "true" GOTO COMPRESSIONIMAGE
IF "%TargetMusic%" == "true" GOTO COMPRESSIONMUSIC

:COMPRESSIONVIDEO
FOR /R %%i IN (%BatchVideoFormats2%) DO (
	(ECHO "%%i" | FIND "%excluded%" 1>NUL) || (
		%appdata%\ffmpeg\ffmpeg.exe -loglevel error -stats -i "%%~fi" -c:v hevc_amf -c:a libopus -b:a 128k -maxrate 192k -minrate 64k -strict -2 -b:v 5000k "%%~dpni ffmpeg.mp4"
		powershell  ^(ls '%%~dpni ffmpeg.mp4'^).CreationTime = ^(ls '%%~fi'^).CreationTime
		powershell  ^(ls '%%~dpni ffmpeg.mp4'^).LastWriteTime = ^(ls '%%~fi'^).LastWriteTime
		IF "%RenameOutput%" == "y" powershell -command "Get-ChildItem '%%~dpni ffmpeg.mp4' | Rename-Item -NewName { $_.LastWriteTime.toString(\"yyyy MM-dd HH-mm\") + ' ffmpeg' + $_.Extension }"
		IF "%RenameOutput%" == "y" powershell -command "Get-ChildItem '%%~dpni ffmpeg.mp4' | Rename-Item -NewName {$_.Name -replace ' input', '' }"
		)
	)
IF "%TargetImage%" == "true" GOTO COMPRESSIONIMAGE
IF "%TargetMusic%" == "true" GOTO COMPRESSIONMUSIC
GOTO END

:COMPRESSIONIMAGE
FOR /R %%i IN (%BatchImageFormats2%) DO (
	(ECHO "%%i" | FIND "%excluded%" 1>NUL) || (
		%appdata%\ffmpeg\ffmpeg.exe -loglevel error -stats -i "%%~fi" "%%~dpni ffmpeg.jpg"
		powershell  ^(ls '%%~dpni ffmpeg.jpg'^).CreationTime = ^(ls '%%~fi'^).CreationTime
		powershell  ^(ls '%%~dpni ffmpeg.jpg'^).LastWriteTime = ^(ls '%%~fi'^).LastWriteTime
		IF "%RenameOutput%" == "y" powershell -command "Get-ChildItem '%%~dpni ffmpeg.jpg' | Rename-Item -NewName { $_.LastWriteTime.toString(\"yyyy MM-dd HH-mm\") + ' ffmpeg' + $_.Extension }"
		IF "%RenameOutput%" == "y" powershell -command "Get-ChildItem '%%~dpni ffmpeg.jpg' | Rename-Item -NewName {$_.Name -replace ' input', '' }"
		)
	)
IF "%TargetMusic%" == "true" GOTO COMPRESSIONMUSIC
GOTO END

:COMPRESSIONMUSIC
FOR /R %%i IN (%BatchMusicFormats2%) DO (
	(ECHO "%%i" | FIND "%excluded%" 1>NUL) || (
		%appdata%\ffmpeg\ffmpeg.exe -loglevel error -stats -i "%%~fi" -b:a 128k -maxrate 192k "%%~dpni ffmpeg.mp3"
		IF "%RenameOutput%" == "y" powershell -command "Get-ChildItem '%%~dpni ffmpeg.mp3' | Rename-Item -NewName { $_.LastWriteTime.toString(\"yyyy MM-dd HH-mm\") + ' ffmpeg' + $_.Extension }"
		IF "%RenameOutput%" == "y" powershell -command "Get-ChildItem '%%~dpni ffmpeg.mp3' | Rename-Item -NewName {$_.Name -replace ' input', '' }"
		)
	)

:END
ENDLOCAL && ECHO Done && IF NOT "%output%" == "" (explorer "%output%") ELSE (explorer "%input%")
PAUSE>NUL && EXIT /B
