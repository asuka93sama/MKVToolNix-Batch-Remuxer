@echo off
setlocal

:: Имя иконки
set "ICON_FILE=icon.ico"
:: Имя ярлыка на рабочем столе
set "SHORTCUT_NAME=MKVToolNix Batch Remuxer"

:: Рабочая папка (где лежит скрипт)
set "WORK_DIR=%~dp0"
:: Убираем trailing slash, чтобы не ломались кавычки в PowerShell
if "%WORK_DIR:~-1%"=="\" set "WORK_DIR=%WORK_DIR:~0,-1%"

set "ICON_PATH=%WORK_DIR%\%ICON_FILE%"

:: === Поиск последней версии HTA (обратная сортировка по имени) ===
set "LAST_FILE="
for /f "delims=" %%F in ('dir /b /o-n "%WORK_DIR%\MKVToolNix Batch Remuxer v*.hta" 2^>nul') do (
    if not defined LAST_FILE set "LAST_FILE=%%F"
)

if not defined LAST_FILE (
    echo Error: MKVToolNix Batch Remuxer v*.hta not found in:
    echo   %WORK_DIR%
    pause
    exit /b 1
)

set "TARGET_PATH=%WORK_DIR%\%LAST_FILE%"
echo [*] Found latest version: %LAST_FILE%

:: === Проверка иконки ===
if not exist "%ICON_PATH%" (
    echo Warning: %ICON_FILE% not found. Shortcut will use default icon.
    set "ICON_PATH=%SystemRoot%\System32\shell32.dll,0"
)

:: === Временный PS1-файл (принимает параметры) ===
set "PS_SCRIPT=%TEMP%\_mkv_shortcut_%RANDOM%.ps1"

:: === Записываем PowerShell-скрипт С ПАРАМЕТРАМИ ===
>  "%PS_SCRIPT%" echo param(
>> "%PS_SCRIPT%" echo     [string]$TargetPath,
>> "%PS_SCRIPT%" echo     [string]$WorkDir,
>> "%PS_SCRIPT%" echo     [string]$IconPath,
>> "%PS_SCRIPT%" echo     [string]$ShortcutName
>> "%PS_SCRIPT%" echo ^)
>> "%PS_SCRIPT%" echo $desktop = [Environment]::GetFolderPath('Desktop'^)
>> "%PS_SCRIPT%" echo $lnkPath = Join-Path $desktop ($ShortcutName + '.lnk'^)
>> "%PS_SCRIPT%" echo $ws = New-Object -ComObject WScript.Shell
>> "%PS_SCRIPT%" echo $sc = $ws.CreateShortcut($lnkPath^)
>> "%PS_SCRIPT%" echo $sc.TargetPath = $TargetPath
>> "%PS_SCRIPT%" echo $sc.WorkingDirectory = $WorkDir
>> "%PS_SCRIPT%" echo $sc.IconLocation = $IconPath
>> "%PS_SCRIPT%" echo $sc.Description = $ShortcutName
>> "%PS_SCRIPT%" echo $sc.Save(^)

:: === Запускаем PowerShell-скрипт С АРГУМЕНТАМИ ===
echo Creating shortcut on Desktop...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -TargetPath "%TARGET_PATH%" -WorkDir "%WORK_DIR%" -IconPath "%ICON_PATH%" -ShortcutName "%SHORTCUT_NAME%"

:: === Удаляем временный файл ===
del /f /q "%PS_SCRIPT%" >nul 2>&1

:: === Проверка результата ===
for /f "usebackq tokens=*" %%D in (`powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')"`) do set "DESKTOP=%%D"

if exist "%DESKTOP%\%SHORTCUT_NAME%.lnk" (
    echo.
    echo Done! Shortcut '%SHORTCUT_NAME%' created on your Desktop.
) else (
    echo.
    echo Error: Failed to create shortcut.
)

timeout /t 3 >nul
endlocal