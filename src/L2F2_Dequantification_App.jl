
#= ===========================================================
Module  L2F2_Dequantification_App.jl
Point d'entrée de l'applictation.
Charge tous les modules et lance l'interface graphique
===========================================================#
module L2F2_Dequantification_App

include("algorithme/arbre.jl")
include("algorithme/construction.jl")
include("algorithme/dequantification.jl")
include("interface.jl")

creer_interface()
end