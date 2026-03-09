# ============================================================
# application.jl
# Rôle : Point d'entrée principal de l'application. c'est ici qu'il y aura le main
#        Gère l'interface graphique et orchestre les appels
#        à construction.jl et dequantification.jl nos 2p 
# ============================================================

include("algorithm/construction.jl")
include("algorithm/dequantification.jl")
include("algorithm/arbre.jl")

# Librairie graphique a voir


# ------------------------------------------------------------
# INTERFACE GRAPHIQUE
# ------------------------------------------------------------

"""
lancer_application()

Fonction principale qui crée et lance la fenêtre de l'application.
La fenêtre contient :
    - Un bouton "Charger x.txt" → ouvre un explorateur de fichiers
    - Un bouton "Lancer la déquantification"
    - Une zone de visualisation de l'arbre (mis à jour en temps réel)
    - Un affichage du nombre de branches restantes
    - Un affichage des solutions trouvées .......

charger_fichier() -> String
ouvre l'explorateur, fichier txt, retourne le chemin absolu du fichier, un fichier à la fois
   
+ d'autres fonctions

"""

lancer_application() ---> c'est notre main
