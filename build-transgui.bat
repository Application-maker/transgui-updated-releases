@echo off
set now=%date:~6,4%%date:~3,2%%date:~0,2%

:: BatchGotAdmin

   ::  --> Check for permissions
   if "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
   :: >nul 2>&1 = ignore output of command and ignore error messages
      >nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
      ) 
   else (
      >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
      )
   
      :: --> If error flag set, we do not have admin.
   
   if '%errorlevel%' NEQ '0' (
      echo Requesting administrative privileges...
      goto UACPrompt
      )
      else (
         goto gotAdmin
         )
   
   :UACPrompt
      echo Set UAC = CreateObject^("Shell.Application"^) > "TEMP\getadmin.vbs"
      set params= %*
      echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "TEMP\getadmin.vbs"
      "TEMP\getadmin.vbs"
      del "TEMP\getadmin.vbs"
      exit /B
   
   :gotAdmin
      pushd "%CD%"
      CD /D "%~dp0"


where choco >nul 2>&1
:: Install Chocolatey
if %errorLevel% == 0 (
   echo Found Chocolatey
   choco --version
) else (
   echo Install Chocolatey...
   @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
)

:: Install git
choco install git


:: Check the arguments
if NOT %1%==--no-clone (
   if NOT %1%==-nc (
      if NOT %1%==--no-update (
         if NOT %1%==-nu (
            if exist .\transgui\ (
               :: Remove old repository files
               rm -rf .\transgui
               )
            :: Clone the repository
            git clone https://github.com/transmission-remote-gui/transgui.git
            )
         )
      )
   )


cd .\transgui\setup\win_amd64
:: Instead of checking dependencies using this script, we check using author's script
.\install_deps.bat

.\make_setup.bat
.\make_zipdist.bat

cd ..\..

:: Install github cli
choco install gh

set /p VERSION=< .\VERSION.txt

:: Release the build
gh release create "%VERSION%" -t "%now%" --repo Max-Gouliaev/transgui-updated-releases -n "" .\Release\*