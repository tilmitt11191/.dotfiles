@echo off
cd /d %~dp0
dir
pause
exit

echo Install cygwin start. GUI install wizard will launch.
echo Please additionally install
echo   git
echo   wget
echo   ca-certificates
echo   gnup
echo   openssl-perl
call cygwin\setup-x86_64.exe
echo Cygwin install finished.
echo Launch Cygwin
pause