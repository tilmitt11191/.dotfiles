@echo off
cd /d %~dp0

echo Install cygwin start. GUI install wizard will launch.
echo Please additionally install
echo   git
echo   wget
echo   ca-certificates
echo   gnup
echo   openssl-perl
pause
dir ..\cygwin\
call ..\cygwin\setup-x86_64.exe
echo Cygwin install finished.
pause