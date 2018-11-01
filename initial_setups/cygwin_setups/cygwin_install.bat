@echo off
cd /d %~dp0

echo Install cygwin start. GUI install wizard will launch.
echo Please additionally install
echo   git
echo   wget
echo   ca-certificates
echo   gnup
echo   openssl-perl
echo modify "Local Package Directory" to C:\cygwin
pause
call cygwin\setup-x86_64.exe
echo Cygwin install finished.
echo Launch Cygwin
pause