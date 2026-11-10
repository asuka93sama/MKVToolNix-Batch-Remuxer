@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title Обновление MKVToolNix Batch Remuxer

:: Папка, где находится скрипт
set "WORK_DIR=%~dp0"
if "%WORK_DIR:~-1%"=="\" set "WORK_DIR=%WORK_DIR:~0,-1%"

:: Временная папка для скачивания
set "TEMP_DIR=%TEMP%\MKVRemuxer_Update"
if exist "%TEMP_DIR%" rd /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

echo [1/4] Скачивание архива с GitHub...
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/asuka93sama/MKVToolNix-Batch-Remuxer/archive/refs/heads/main.zip' -OutFile '%TEMP_DIR%\update.zip'"
if not exist "%TEMP_DIR%\update.zip" goto :error

echo [2/4] Распаковка архива...
powershell -NoProfile -Command "Expand-Archive -Path '%TEMP_DIR%\update.zip' -DestinationPath '%TEMP_DIR%\extract' -Force"

:: Находим распакованную папку
set "EXTRACTED_FOLDER="
for /d %%D in ("%TEMP_DIR%\extract\*") do set "EXTRACTED_FOLDER=%%D"
if not defined EXTRACTED_FOLDER goto :error

echo [3/4] Копирование файлов и поиск последней версии...

:: Копируем ВСЕ файлы из репозитория (кроме .hta, их обработаем отдельно)
xcopy "%EXTRACTED_FOLDER%\*.*" "%WORK_DIR%\" /E /Y /I >nul

:: Ищем все HTA файлы в рабочей папке и находим последний
set "LATEST_HTA="
set "MAX_VERSION=0.0.0"

for %%F in ("%WORK_DIR%\MKVToolNix Batch Remuxer v*.hta") do (
    set "filename=%%~nxF"
    :: Извлекаем версию из имени файла (формат: MKVToolNix Batch Remuxer v1.0.XX.hta)
    for /f "tokens=5 delims=v " %%V in ("!filename!") do (
        set "version=%%V"
        set "version=!version:.hta=!"
        :: Сравниваем версии (простое сравнение строк работает для формата X.X.XX)
        if "!version!" GTR "!MAX_VERSION!" (
            set "MAX_VERSION=!version!"
            set "LATEST_HTA=%%~nxF"
        )
    )
)

if not defined LATEST_HTA goto :error

echo [+] Последняя версия: !LATEST_HTA!

:: Удаляем все старые HTA файлы, оставляем только последний
for %%F in ("%WORK_DIR%\MKVToolNix Batch Remuxer v*.hta") do (
    if /I not "%%~nxF"=="!LATEST_HTA!" (
        del /f /q "%%F" >nul
        echo [-] Удалена старая версия: %%~nxF
    )
)

:: Удаляем временные файлы
rd /s /q "%TEMP_DIR%"

echo [4/4] Запуск программы...
echo.
echo Обновление успешно завершено!
echo.

:: Запускаем Ярлык.cmd (он сам откроет актуальный HTA)
if exist "%WORK_DIR%\Ярлык.cmd" (
    call "%WORK_DIR%\Ярлык.cmd"
) else (
    echo [ОШИБКА] Файл Ярлык.cmd не найден!
    pause
    exit /b 1
)

exit /b 0

:error
echo.
echo [ОШИБКА] Не удалось завершить обновление.
echo Проверьте подключение к интернету.
pause
exit /b 1