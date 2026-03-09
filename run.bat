@echo off

cd /d "%~dp0"

where julia >nul 2>&1
if %errorlevel% neq 0 (
    echo Julia n'est pas installe. Vous pouvez installer la derniere version depuis https://julialang.org
    exit /b 1
)

echo Veuillez patienter, installation des dependances en cours...
julia --project=. -e "using Pkg; Pkg.resolve()"
if %errorlevel% neq 0 (
    echo Erreur lors de l'installation des dependances......
    exit /b 1
)

echo Lancement de l'application...
julia --project=. src/application.jl
if %errorlevel% neq 0 (
    echo Erreur lors du lancement de l'application.....
    exit /b 1
)
pause