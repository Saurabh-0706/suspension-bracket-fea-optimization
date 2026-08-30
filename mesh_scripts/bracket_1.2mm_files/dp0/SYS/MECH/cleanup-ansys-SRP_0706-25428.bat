@echo off
set LOCALHOST=%COMPUTERNAME%
if /i "%LOCALHOST%"=="SRP_0706" (taskkill /f /pid 12444)
if /i "%LOCALHOST%"=="SRP_0706" (taskkill /f /pid 26880)
if /i "%LOCALHOST%"=="SRP_0706" (taskkill /f /pid 22884)
if /i "%LOCALHOST%"=="SRP_0706" (taskkill /f /pid 25428)

del /F cleanup-ansys-SRP_0706-25428.bat
