<<<<<<< .mine
# arbre.jl
# definit la structure noeud et arbre et les fonctions pour manipuler l'arbre
||||||| .r40
#=
Ce module définit les structures Noeud et Arbre ainsi que les fonctions associées
=#
=======
#========================================
Ce module définit les structures Noeud et Arbre ainsi que les fonctions associées
===========================================#
>>>>>>> .r47

# un noeud cest une case de larbre
# valeur = le nombre entier stocke
# histogramme = le P des couples, seulement dans les feuilles (les noeuds internes ont nothing)
# pos = false si cest le candidat pair, true si cest limpair
# parent = le noeud au dessus (nothing si cest la racine)
# enfants = les noeuds en dessous, dans un vecteur parce que pendant lelagage on peut en supprimer
mutable struct Noeud
    valeur::Int16
    histogramme::Union{Dict{Tuple{Int16,Int16},Int}, Nothing}
    pos::Bool
    parent::Union{Nothing, Noeud}
    enfants::Vector{Noeud}
end

# larbre cest juste une racine et un compteur de branches
# nb_branches compte les feuilles vivantes pour pas avoir a recompter a chaque fois
mutable struct Arbre
<<<<<<< .mine
    racine::Union{Nothing, Noeud}
    nb_branches::Int
||||||| .r40
    racine :: Union{Nothing, Noeud}
    nbBranche :: Int
=======
    racine :: Union{Nothing, Noeud}
    nb_branche :: Int
>>>>>>> .r47
end

# cree un arbre vide sans racine
function creer_arbre()
    return Arbre(nothing, 0)
end

<<<<<<< .mine
# retourne true si le noeud na pas denfants cad cest un bout de branche
function est_feuille(n::Noeud)
    return isempty(n.enfants)
end
||||||| .r40
function creer_noeud(
    valeur::Int16,
    parent ::Union{Nothing, Noeud},
    pos::Bool,
    histogramme::Dict{Tuple{Int16, Int16}, Int}
    )::Noeud

    return Noeud(valeur,parent,pos,Noeud[], copy(histogramme))
end
=======
    function creer_noeud(
        valeur::Int16,
        parent ::Union{Nothing, Noeud},
        pos::Bool,
        histogramme::Dict{Tuple{Int16, Int16}, Int}
        )::Noeud

        return Noeud(valeur,parent,pos,Noeud[], copy(histogramme))
    end
>>>>>>> .r47

<<<<<<< .mine
# cree un enfant et lajoute au parent
# on incremente nb_branches a chaque ajout
# le ! cest la convention julia pour dire que la fonction modifie ses arguments
function ajouter_enfant!(a::Arbre, parent::Noeud, valeur::Int16, histogramme::Union{Dict{Tuple{Int16,Int16},Int}, Nothing}, pos::Bool)
    enfant = Noeud(valeur, histogramme, pos, parent, Noeud[])
    push!(parent.enfants, enfant)   # push! ajoute a la fin du vecteur
    a.nb_branches += 1
||||||| .r40
# retourne true si le noeud na pas denfants
# exemple : est_feuille(creer_noeud(4, 3, false)) -> true
function est_feuille(noeud::Noeud)
    return isempty(noeud.enfants)
end

# cree un enfant et lajoute au parent, modifie le parent directement
# exemple : ajouter_enfant!(parent, 3, 2, true) -> cree Noeud(3,2,true) et lajoute a parent.enfants
function ajouter_enfant!(
    arbre::Arbre,
    parent::Noeud,
    valeur::Int16,
    pos::Bool,
    P::Dict{Tuple{Int16,Int16}, Int})::Noeud

    enfant = creer_noeud(valeur, parent, pos, P)
    push!(parent.enfants, enfant)
    arbre.nbBranche += 1
=======

# retourne true si le noeud na pas denfants
# exemple : est_feuille(creer_noeud(4, 3, false)) -> true
function est_feuille(noeud::Noeud)
    return isempty(noeud.enfants)
end

# cree un enfant et lajoute au parent, modifie le parent directement
# exemple : ajouter_enfant!(parent, 3, 2, true) -> cree Noeud(3,2,true) et lajoute a parent.enfants
function ajouter_enfant!(
    arbre::Arbre,
    parent::Noeud,
    valeur::Int16,
    pos::Bool,
    P::Dict{Tuple{Int16,Int16}, Int})::Noeud

    enfant = creer_noeud(valeur, parent, pos, P)
    push!(parent.enfants, enfant)
    arbre.nb_branche += 1
>>>>>>> .r47
    return enfant
end

# supprime un noeud des enfants de son parent
# filter! garde seulement ceux qui sont pas le noeud a virer
# !== compare lidentite en memoire pas juste la valeur
function supprimer_noeud!(a::Arbre, parent::Noeud, noeud::Noeud)
    filter!(enfant -> enfant !== noeud, parent.enfants)
<<<<<<< .mine
    a.nb_branches -= 1
    return nothing
||||||| .r40
    arbre.nbBranche -= 1
=======
    arbre.nb_branche -= 1
>>>>>>> .r47
end

# retourne le nombre de branches restantes
# cest juste un raccourci pour acceder a nb_branches
function compter_branches(a::Arbre)
    return a.nb_branches
end

<<<<<<< .mine
# remonte de la feuille jusqu'a la racine en suivant les parent
# on inverse a la fin parce quon a ajoute du bas vers le haut
# ex: feuille(4) -> parent(3) -> parent(2) -> racine => on get [4,3,2] puis reverse => [2,3,4]
function extraire_serie(n::Noeud)
    sequence = Int16[]
    cur = n
    while cur.parent !== nothing
        push!(sequence, cur.valeur)
        cur = cur.parent
    end
||||||| .r40
# retourne une copie independante de la sequence
# sans copy() si on modifie loriginal ca modifie aussi le resultat
# exemple : extraire_serie([2,3,4,5]) -> [2,3,4,5]
function extraire_serie(n::Noeud)::Vector{Int16}
    sequence = Vector{Int16}()
    noeud = n

    #Remontons de n à la racine afin d'en extraire la branche
    while noeud !== nothing
        push!(sequence, noeud.valeur)
        noeud = noeud.parent
    end
=======
    # retourne une copie independante de la sequence
    # sans copy() si on modifie loriginal ca modifie aussi le resultat
    # exemple : extraire_serie([2,3,4,5]) -> [2,3,4,5]
    function extraire_serie(n::Noeud)::Vector{Int16}
        sequence = Vector{Int16}()
        noeud = n

        #Remontons de n à la racine afin d'en extraire la branche
        while noeud !== nothing
            push!(sequence, noeud.valeur)
            noeud = noeud.parent
        end
>>>>>>> .r47
<<<<<<< .mine
    reverse!(sequence)      # reverse! modifie le vecteur sur place
||||||| .r40

    #La serie est dans l'ordre inverse nous devons la renverser
    dernier= length(sequence)
    premier = 1

    while dernier>premier
        temp = sequence[premier]
        sequence[premier] = sequence[dernier]
        sequence[dernier] = temp

        dernier -= 1
        premier += 1
    end

=======

        #La serie est dans l'ordre inverse nous devons la renverser
        dernier= length(sequence)
        premier = 1

        while dernier>premier
            temp = sequence[premier]
            sequence[premier] = sequence[dernier]
            sequence[dernier] = temp

            dernier -= 1
            premier += 1
        end

>>>>>>> .r47
        return sequence
    end