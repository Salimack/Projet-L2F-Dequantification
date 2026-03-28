# arbre.jl
# definit la structure noeud et arbre et les fonctions pour manipuler l'arbre

mutable struct Noeud
    valeur::Int16
    histogramme::Union{Dict{Tuple{Int16,Int16},Int}, Nothing}
    pos::Bool
    parent::Union{Nothing, Noeud}
    enfants::Vector{Noeud}
end

mutable struct Arbre
    racine::Union{Nothing, Noeud}
    nb_branches::Int
end

# cree un arbre vide
function creer_arbre()
    return Arbre(nothing, 0)
end

# retourne true si le noeud na pas denfants
# exemple : est_feuille(noeud) -> true si noeud.enfants est vide
function est_feuille(n::Noeud)
    return isempty(n.enfants)
end

# cree un enfant et lajoute au parent, incremente nb_branches dans larbre
# exemple : ajouter_enfant!(arbre, parent, Int16(4), nothing, false) -> cree Noeud(4,...) et lajoute a parent.enfants
function ajouter_enfant!(a::Arbre, parent::Noeud, valeur::Int16, histogramme::Union{Dict{Tuple{Int16,Int16},Int}, Nothing}, pos::Bool)
    enfant = Noeud(valeur, histogramme, pos, parent, Noeud[])
    push!(parent.enfants, enfant)
    a.nb_branches += 1
    return enfant
end

# supprime un noeud de la liste denfants de son parent, decremente nb_branches
# exemple : supprimer_noeud!(arbre, parent, noeud) -> enleve noeud de parent.enfants
function supprimer_noeud!(a::Arbre, parent::Noeud, noeud::Noeud)
    filter!(enfant -> enfant !== noeud, parent.enfants)
    a.nb_branches -= 1
    return nothing
end

# retourne le nombre de branches restantes
# exemple : compter_branches(arbre) -> 3 si larbre a 3 branches
function compter_branches(a::Arbre)
    return a.nb_branches
end

# remonte de noeud en noeud jusqu'a la racine et retourne la sequence
# exemple : extraire_serie(feuille) -> [2, 3, 4, 5]
function extraire_serie(n::Noeud)
    sequence = Int16[]
    cur = n
    while cur.parent !== nothing
        push!(sequence, cur.valeur)
        cur = cur.parent
    end
    reverse!(sequence)
    return sequence
end