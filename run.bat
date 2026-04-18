@echo off

cd /d "%~dp0"
set SCRIPT_DIR=%~dp0

echo Veuillez patienter. Lancement du script.....
julia --project=. e "include(\"src/L2F2_Dequantification_App.jl")"