@echo off
echo Compiling process_signal.m to a standalone executable...
"C:\Program Files\Polyspace\R2021a\bin\win64\mcc.exe" -v -m process_signal.m -a Functions/ -o thamani_processor
if %ERRORLEVEL% equ 0 (
    echo Compilation successful!
    echo Ensure the target Docker container runs the MATLAB Runtime for R2021a.
) else (
    echo Compilation failed.
)
