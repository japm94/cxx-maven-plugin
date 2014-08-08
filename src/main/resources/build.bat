REM build.bat generic VS2008 solution builder
REM option 1 [%1] is solution directory
REM option 2 [%2] is solution filename [mysolution.sln]
REM option 3 [%3] is build type [rebuild | clean | build]
REM option 4 [%4] is visual studio project config [debug | release]
REM option 5 [%5] is platform [win32 | ?]
REM option 6 [%6] is architecture [x86 | amd64 | ia64 | x86_amd64 | x86_ia64]
REM option 7 [%7] is project version to set [x.y.z.t]
REM option 8 [%8] is additional compiler options
REM use simple quote + double quote ['"] to enclose option 8 in order to specify one or more options with '=' char inside.
REM use escaped double quote [\"] inside global quotation to specify string typed option values
REM Example : ['"/DOPTION_1=value /DOPTION_2=\"litteral_string\""'] (VC compiler /D option do not support space char inside value)
REM additional compiler options will be added to Env vars $(EXTERNAL_COMPILER_OPTIONS) and $(EXTERNAL_RCC_OPTIONS).
REM put those Env vars in all vcproj projects properties your solution contains:
REM put $(EXTERNAL_COMPILER_OPTIONS) under [Configuration Properties->C/C++->Command Line] (in both Debug and Release configs)
REM and put $(EXTERNAL_RCC_OPTIONS) under [Configuration Properties->Resources->Command Line] (in both Debug and Release configs)
REM
REM VS Solutions design recomandations :
REM   - In all your vcproj, set [Configuration Properties->General->Output Directory] to
REM     $(SolutionDir)$(PlatformName)\$(ConfigurationName), in both Debug and Release configs
REM   - In all your vcproj, set [Configuration Properties->General->Intermediate Directory] to 
REM     $(ProjectDir)$(PlatformName)\$(ConfigurationName), in both Debug and Release configs
echo OFF
:: setlocal

IF [%3] == [rebuild] (
   :: There is no custom clean step in VS2008 so we clean OutputDir Manually
   echo delete folder "%1\%5\%4" if exist
   rmdir /s /q "%1\%5\%4"
)

IF [%3] == [clean] (
   :: There is no custom clean step in VS2008 so we clean OutputDir Manually
   echo delete folder "%1\%5\%4\" if exist
   rmdir /s /q "%1\%5\%4"
)

set MAJORNUMBER=0
set MINORNUMBER=4
set BUILDNUMBER=0
set MODIFICATIONNUMBER=1728
IF [%7]==[] (
	echo version not defined, use default
) ELSE (
	for /f "tokens=1-4 delims=." %%a in ("%7") do (
	   set MAJORNUMBER=%%a
	   set MINORNUMBER=%%b
	   set BUILDNUMBER=%%c
	   set MODIFICATIONNUMBER=%%d
	)
)

set DATEYEAR=2014
set DATEMONTH=7
set DATEDAY=6
setlocal EnableDelayedExpansion
FOR /F "skip=1 tokens=1-6" %%A IN ('WMIC Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') DO (
    if "%%B" NEQ "" (
        SET /A FDATE=%%F*10000+%%D*100+%%A
        SET /A FTIME=%%B*10000+%%C*100+%%E
		SET DATEYEAR=%%F
		SET DATEMONTH=%%D
		SET DATEDAY=%%A
    )
)

call "%PROGRAMFILES%\Microsoft Visual Studio 9.0\VC\vcvarsall.bat" %6
echo call qmake to find QTDIR...
qmake -query QT_INSTALL_PREFIX > tmpBuildFile 
set /p QTDIR= < tmpBuildFile 
del tmpBuildFile 
echo QTDIR is [%QTDIR%]

pushd "%1" 
::%~8 remove quotes at begin and end of %8
set ADDITIONAL_OPTIONS=%~8
echo ADDITIONAL_OPTIONS is [%ADDITIONAL_OPTIONS%]
:: UGLY ack to pass DEFINE using command line to msbuild script 
:: ... since /p:DefineConstants="whatEver=something" do not work with MS c++ projects
:: env VARS $(EXTERNAL_COMPILER_OPTIONS) and $(EXTERNAL_RCC_OPTIONS) are invoked in MS3DEtancheiteBobine project,
:: under options->C/C++->Command Line (in both Debug and Release configs)
:: and options->Resources->Command Line (in both Debug and Release configs)
:: VCC needs '/D' options
:: ! space char after first '=' char bellow, is important !
set EXTERNAL_COMPILER_OPTIONS= %ADDITIONAL_OPTIONS% /DSV_MAJORNUMBER=%MAJORNUMBER% /DSV_MINORNUMBER=%MINORNUMBER% /DSV_BUILDNUMBER=%BUILDNUMBER% /DSV_MODIFICATIONNUMBER=%MODIFICATIONNUMBER% /DSV_DATEYEAR=%DATEYEAR% /DSV_DATEMONTH=%DATEMONTH% /DSV_DATEDAY=%DATEDAY%
echo EXTERNAL_COMPILER_OPTIONS is [%EXTERNAL_COMPILER_OPTIONS%]
:: while RCC needs '/d' options
set EXTERNAL_RCC_OPTIONS=%EXTERNAL_COMPILER_OPTIONS: /D= /d%
echo EXTERNAL_RCC_OPTIONS is [%EXTERNAL_RCC_OPTIONS%]
::msbuild /help 
::/verbosity:q|m|n|d|diag|
msbuild %2 /p:Configuration=%4;Platform=%5 /t:%3 /verbosity:d
popd

:: There is no custom clean step in VS2008 so we exit successfully whatever to avoid false negative
IF [%3] == [clean] exit 0
REM errorlevel come from msbuild
exit %errorlevel%
REM endlocal