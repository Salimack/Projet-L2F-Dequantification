# ============================================================
# dequantification.jl
# Rôle : Prend xQ et P en entrée, fait l'algo de déquantification
#        (construction + élagage simultanés avec un parcours en profondeur)
#        et génère autant de fichiers solution que de branches restantes
# ============================================================

#importer arbre.jl (include arbre.jl)


# ------------------------------------------------------------
# LECTURE DES ENTRÉES
# ------------------------------------------------------------

"""
lire_xQ(chemin) -> Vecteur
lire_P(chemin) -> dictionnaire

"""

# ------------------------------------------------------------
# ALGORITHME PRINCIPAL
# ------------------------------------------------------------

"""
fonction principale de dequantification

fonction qui va generer autant de solutions que de branche sortante
"""