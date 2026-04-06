#========================================
Ce module définit les structures Noeud et Arbre ainsi que les fonctions associées
===========================================#


mutable struct Noeud
    valeur::Int16
    parent :: Union{Nothing, Noeud}
    pos::Bool # false = pair (fils bas) true = impair (fils haut)
    enfants::Vector{Noeud}
    histogramme:: Union{Nothing, Dict{Tuple{Int16, Int16}, Int}} #l'histogramme de la racine est Nothing
end

mutable struct Arbre
    racine :: Union{Nothing, Noeud}
    nb_branche :: Int
end


# cree un noeud avec la valeur, le compteur P et la position
# exemple : creer_noeud(4, 3, false) -> noeud avec valeur=4, histogramme=3, pos=false, enfants=[]

function creer_arbre()::Arbre
    racine = Noeud(Int16(0), nothing, false, Noeud[], nothing)
    return Arbre(racine, 0)
end

    function creer_noeud(
        valeur::Int16,
        parent ::Union{Nothing, Noeud},
        pos::Bool,
        histogramme::Dict{Tuple{Int16, Int16}, Int}
        )::Noeud

        return Noeud(valeur,parent,pos,Noeud[], copy(histogramme))
    end


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
    return enfant
end

# supprime un noeud de la liste denfants de son parent
# sert a elaguer quand une branche est impossible
# exemple : supprimer_noeud!(parent, e1) -> enleve e1 de parent.enfants
function supprimer_noeud!(
    arbre::Arbre,
    parent::Noeud,
    noeud::Noeud)

    filter!(enfant -> enfant !== noeud, parent.enfants)
    arbre.nb_branche -= 1
end

# compte le nombre de feuilles dans larbre, fonctionne par recursion
# exemple : si larbre a 3 feuilles -> retourne 3
function compter_branches(n::Noeud)
    if est_feuille(n)
        return 1
    end
    total = 0
    for enfant in n.enfants
        total += compter_branches(enfant)
    end
    return total
end

    # retourne une copie independante de la sequence
    # sans copy() si on modifie loriginal ca modifie aussi le resultat
    # exemple : extraire_serie([2,3,4,5]) -> [2,3,4,5]
    function extraire_serie(n::Noeud)::Vector{Int16}
        sequence = Vector{Int16}()
        noeud = n

        #Remontons de n à la racine afin d'en extraire la branche
        while noeud.parent !== nothing
            push!(sequence, noeud.valeur)
            noeud = noeud.parent
        end

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

        return sequence
    end