#========================================================
Ce module realise lalgorithme de dequantification de la serie xQ a partir de P lhistogramme
on construit un arbre binaire et on elague les branches impossibles au fur et a mesure
================================================================#
include("arbre.jl")


# verifie si le couple (noeud.valeur, valeur) est dans P et si son compte est > 0
function est_compatible(noeud::Noeud, valeur::Int16)::Bool
    couple = (noeud.valeur, valeur)
    if haskey(noeud.histogramme, couple)
        return noeud.histogramme[couple] > 0
    end
    return false
end


# construit le nom du fichier solution et lecrit en binaire
function sauvegarder_solution(solution::Vector{Int16}, chemin_dossier::String, compteur_solutions::Ref{Int})
    compteur_solutions[] += 1
    numero = string(compteur_solutions[])
    nom_fichier = "solution_" * numero * ".dat"
    chemin_fichier = joinpath(chemin_dossier, nom_fichier)
    open(chemin_fichier, "w") do fichier
        write(fichier, solution)
    end
    return chemin_fichier
end


# elague le noeud sans remonter
function elaguer!(arbre::Arbre, n::Noeud)
    if n.parent === nothing
        return
    end
    supprimer_noeud!(arbre, n.parent, n)
end


# parcours en profondeur sans elagage pendant le DFS
# on garde juste les branches qui arrivent au bout
function developper(
    arbre::Arbre,
    noeud::Noeud,
    xQ::Vector{Int16},
    niveau::Int,
    mis_a_jour_arbre::Function,
    mis_a_jour_branches::Function,
    mis_a_jour_progression::Function,
    ajouter_solution::Function,
    chemin::String,
    compteur_solutions::Ref{Int},
    est_lance::Ref{Bool})::Nothing

    if !est_lance[]
        return
    end

    if niveau == length(xQ) + 1
        solution = extraire_serie(noeud)
        chemin_solution = sauvegarder_solution(solution, chemin, compteur_solutions)
        ajouter_solution(chemin_solution)
        mis_a_jour_branches(compteur_solutions[])
    else
        mis_a_jour_progression(niveau, length(xQ))

        xQn = xQ[niveau]
        valeurs_possibles = [xQn, xQn + Int16(1)]

        for valeur in valeurs_possibles
            if !est_lance[]
                return
            end

            if est_compatible(noeud, valeur)
                P_copie = copy(noeud.histogramme)
                P_copie[(noeud.valeur, valeur)] -= 1
                enfant = ajouter_enfant!(arbre, noeud, valeur, valeur % 2 != 0, P_copie)
                mis_a_jour_arbre(arbre)
                developper(arbre, enfant, xQ, niveau + 1, mis_a_jour_arbre, mis_a_jour_branches, mis_a_jour_progression, ajouter_solution, chemin, compteur_solutions, est_lance)
            end
        end

        noeud.histogramme = nothing
    end

    return nothing
end


# point dentree : cree larbre et lance le DFS sur les deux fils de la racine
function dequantifier(
    xQ::Vector{Int16},
    P::Dict{Tuple{Int16, Int16}, Int},
    mis_a_jour_arbre::Function,
    mis_a_jour_branches::Function,
    mis_a_jour_progression::Function,
    ajouter_solution::Function,
    chemin::String,
    est_lance::Ref{Bool})

    arbre = creer_arbre()
    compteur_solutions = Ref{Int}(0)

    arbre.racine = Noeud(Int16(0), nothing, false, Noeud[], nothing)

    enfant_gauche = ajouter_enfant!(arbre, arbre.racine, xQ[1], false, copy(P))
    enfant_droit  = ajouter_enfant!(arbre, arbre.racine, xQ[1] + Int16(1), true, copy(P))

    mis_a_jour_arbre(arbre)

    developper(arbre, enfant_gauche, xQ, 2, mis_a_jour_arbre, mis_a_jour_branches, mis_a_jour_progression, ajouter_solution, chemin, compteur_solutions, est_lance)

    if !est_lance[]
        return
    end

    developper(arbre, enfant_droit, xQ, 2, mis_a_jour_arbre, mis_a_jour_branches, mis_a_jour_progression, ajouter_solution, chemin, compteur_solutions, est_lance)
end