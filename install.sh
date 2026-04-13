#!/bin/bash
echo "Installation des dependances en cours..."
julia --project=. -e "import Pkg; Pkg.instantiate()"
echo "Installtion terminee."