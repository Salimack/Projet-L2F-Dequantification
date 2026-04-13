@echo off
@echo off
set SCRIPT_DIR=%~dp0
julia "--project=%SCRIPT_DIR%" "%SCRIPT_DIR%src\application.jl"
pause