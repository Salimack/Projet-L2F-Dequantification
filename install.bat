@echo off
juliaup default 1.10
echo "Installation des dependances en cours..."
julia --project=. -e "import Pkg; Pkg.instantiate()"
echo "Installation reussie."
pause