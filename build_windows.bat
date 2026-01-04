@echo off
TITLE Atresplayer Desktop - Windows Build
COLOR 0A
CLS

ECHO ===================================================
ECHO      Atresplayer Desktop - Building for Windows
ECHO ===================================================
ECHO.
ECHO This script must be run on a WINDOWS machine with Flutter installed.
ECHO.

WHERE flutter >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
    ECHO [ERROR] 'flutter' command not found! 
    ECHO Please install Flutter for Windows and add it to your PATH.
    PAUSE
    EXIT /B
)

ECHO 1. Cleaning project...
CALL flutter clean

ECHO.
ECHO 2. Getting dependencies...
CALL flutter pub get

ECHO.
ECHO 3. Building Release Executable...
CALL flutter build windows --release

IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    COLOR 0C
    ECHO [ERROR] Build failed! Check the logs above.
    PAUSE
    EXIT /B
)

ECHO.
ECHO ===================================================
ECHO [SUCCESS] Build generated successfully!
ECHO File located at: build\windows\runner\Release\atresplayer_desktop.exe
ECHO ===================================================
PAUSE
