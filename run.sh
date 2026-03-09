#!/bin/bash
cd "$(dirname "$0")"

if ! command -v julia &> /dev/null; then
    echo "Julia n'est pas installé. Vous pouvez installer la dernière version depuis https://julialang.org"
    exit 1
fi

echo "Veuillez patienter, installation des dépendances en cours..."
if ! julia --project=. -e "using Pkg; Pkg.resolve()"; then
    echo "Erreur lors de l'installation des dépendances."
    exit 1
fi

echo "Lancement de l'application..."
julia --project=. src/application.jl