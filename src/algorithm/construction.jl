# ============================================================
# construction.jl
# Rôle : À partir de x.txt, génère xQ et P
#        et les sauvegarde dans le dossier data
# ============================================================


# ------------------------------------------------------------
# FONCTIONS
# ------------------------------------------------------------

"""
lire_x(chemin) -> vecteur d'entier
Ouvre le fichier en mode "r" (lecture seule). charge x

calculer_xQ(tableau sorti de lire_x) -> vecteur d'entiers
à partir de x calcul xQ
 - si x(n) est pair   → xQ(n) = x(n)
 - si x(n) est impair → xQ(n) = x(n) + 1

calculer_P(tableau sorti de lire_x) -> dictionnaire
construit l'histogramme des couples successives de x 

sauvegarder_xQ(xQ, chemin)
sauvegarde xQ

sauvegarder_P(P, chemin)
sauvegarde P

ecrire une fonction qui appelle toutes les fonctions listées plus haut dans le bon ordre
- lire serie, calculer xQ, calculer P, sauvegegarder xQ, sauvegarder P

"""
