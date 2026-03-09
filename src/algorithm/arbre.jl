# ============================================================
# arbre.jl
# Rôle : Définit la structure d'un nœud et les fonctions
#        de base pour manipuler l'arbre de déquantification
# ============================================================


# ------------------------------------------------------------
# STRUCTURE
# ------------------------------------------------------------

# Un nœud contient :
#   - valeur  : le nombre entier stocké dans cette case
#   - enfants : la liste des nœuds qui en descendent
# "mutable" = on peut modifier ses champs après création

mutable struct Noeud
    valeur::Int
    enfants::Vector{Noeud}
    #Avec gauche/droite fixes tu serais obligé de mettre nothing partout et de vérifier à chaque fois. 
    #Avec un Vector c'est plus simple : tu supprimes juste l'enfant de la liste et c'est réglé.
    #C'est pour ça qu'on utilise Vector{Noeud}
end


# ------------------------------------------------------------
# FONCTIONS : creer_noeud, ajouter_enfant!, est_feuille,
#             supprimer_noeud!, compter_branches, extraire_serie
# ------------------------------------------------------------

# ------ creer_noeud ------
# Crée un nœud avec la valeur donnée et aucun enfant.
# Paradigme FONCTIONNEL : on crée et on retourne, sans rien modifier.
#
# Exemple :
#   n = creer_noeud(4)
#   n.valeur   →  4
#   n.enfants  →  []

function creer_noeud(valeur::Int)
    return Noeud(valeur, Noeud[])
    # Noeud(valeur, Noeud[]) = constructeur de la struct
    # Noeud[] = liste vide de type Noeud
end


# ------ ajouter_enfant! ------
# Crée un enfant avec la valeur donnée et l'attache au parent.
# Paradigme IMPERATIF : on modifie le parent directement.
# Le ! signale que la fonction modifie ses arguments.
#
# Exemple :
#   racine = creer_noeud(2)
#   enfant = ajouter_enfant!(racine, 3)
#   racine.enfants  →  [Noeud(3, [])]
#   enfant.valeur   →  3

function ajouter_enfant!(parent::Noeud, valeur::Int)
    enfant = creer_noeud(valeur)       # on crée le nœud enfant
    push!(parent.enfants, enfant)      # on l'ajoute à la liste du parent
    return enfant                      # on retourne l'enfant
end


# ------ est_feuille ------
# Retourne true si le nœud n'a aucun enfant, false sinon.
# Un nœud sans enfant = bout d'une branche = feuille.
# Paradigme FONCTIONNEL : on lit, on ne modifie rien.
#
# Exemple :
#   n = creer_noeud(4)
#   est_feuille(n)          →  true
#   ajouter_enfant!(n, 5)
#   est_feuille(n)          →  false

function est_feuille(n::Noeud)
    return isempty(n.enfants)
    # isempty() retourne true si la liste est vide
end


# ------ supprimer_noeud! ------
# Supprime un nœud (feuille) de la liste d'enfants de son parent.
# Sert à élaguer l'arbre quand une branche est impossible.
# Paradigme IMPERATIF : on modifie le parent. Le ! signale ça.
#
# Exemple :
#   racine = creer_noeud(2)
#   e1 = ajouter_enfant!(racine, 3)
#   e2 = ajouter_enfant!(racine, 4)
#   supprimer_noeud!(racine, e1)
#   racine.enfants  →  [Noeud(4, [])]

function supprimer_noeud!(parent::Noeud, noeud::Noeud)
    # filter! garde seulement les enfants différents de noeud
    # !== compare l'identité : c'est bien le même objet en mémoire ?
    filter!(enfant -> enfant !== noeud, parent.enfants)
    return nothing
end


# ------ compter_branches ------
# Compte le nombre de feuilles dans l'arbre.
# Chaque feuille = une branche candidate encore vivante.
# Paradigme FONCTIONNEL : on parcourt et on compte, sans modifier.
#
# Exemple :
#   racine = creer_noeud(0)
#   e1 = ajouter_enfant!(racine, 2)
#   e2 = ajouter_enfant!(racine, 3)
#   ajouter_enfant!(e1, 4)
#   compter_branches(racine)  →  2

function compter_branches(n::Noeud)
    if est_feuille(n)
        return 1                            # feuille = 1 branche
    end

    total = 0
    for enfant in n.enfants                 # on parcourt chaque enfant
        total += compter_branches(enfant)   # appel récursif
    end
    return total
end


# ------ extraire_serie ------
# Retourne une copie de la séquence de valeurs d'une branche.
# Paradigme FONCTIONNEL : on lit, on ne modifie rien.
#
# Exemple :
#   extraire_serie([2, 3, 4, 5])  →  [2, 3, 4, 5]

function extraire_serie(sequence::Vector{Int})
    return copy(sequence)
    # copy() retourne une copie indépendante
    # sans copy(), modifier l'original modifierait aussi le résultat
end