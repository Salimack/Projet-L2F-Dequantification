#=
Ce module réalise l'algorithme de dequantification de la serie xQ à partir de P, l'histogramme
=#
include("arbre.jl")



# verifie si noeud.valeur et valeur sont compatibles avec P
function est_compatible(noeud::Noeud, valeur::Int16)::Bool
    if haskey(noeud.histogramme, (noeud.valeur, valeur))
        return noeud.histogramme[(noeud.valeur, valeur)] > 0
    end
    return false
end


# construit le nom du fichier et retourne son chemin
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


# elague l'arbre de maniere recursive
function elaguer!(arbre::Arbre, n::Noeud)::Nothing
    supprimer_noeud!(arbre, n.parent, n)

    if n.parent.parent !== nothing && est_feuille(n.parent)
        elaguer!(arbre, n.parent)
    end

    return nothing
end


# developpe et elague l'arbre binaire des solutions
function developper(
    arbre::Arbre,
    noeud::Noeud,
    xQ::Vector{Int16},
    niveau::Int,
    mis_a_jour_arbre::Function,
    mis_a_jour_pourcent::Function,
    ajouter_solution::Function,
    max_feuille::Ref{Int},
    chemin::String,
    compteur_solutions::Ref{Int})::Nothing

    # cas de base : on a parcouru tout xQ
    if niveau == length(xQ) + 1
        solution = extraire_serie(noeud)
        chemin_solution = sauvegarder_solution(solution, chemin, compteur_solutions)
        ajouter_solution(chemin_solution)
    else
        xQn = xQ[niveau]
        valeurs_possibles = [xQn, xQn + Int16(1)]
        valide = 0

        for valeur in valeurs_possibles
            if est_compatible(noeud, valeur)
                P_copie = copy(noeud.histogramme)
                P_copie[(noeud.valeur, valeur)] -= 1

                # pos = false si pair, true si impair
                enfant = ajouter_enfant!(arbre, noeud, valeur, P_copie, valeur % 2 != 0)

                valide += 1
                developper(arbre, enfant, xQ, niveau + 1, mis_a_jour_arbre, mis_a_jour_pourcent, ajouter_solution, max_feuille, chemin, compteur_solutions)
            end
        end

        # le parent na plus besoin de P, ses enfants ont leur copie
        noeud.histogramme = nothing

        if valide == 0
            elaguer!(arbre, noeud)
        end

        mis_a_jour_arbre(arbre)

        pourcentage = arbre.nb_branches / max_feuille[] * 100
        mis_a_jour_pourcent(pourcentage)
    end

    return nothing
end


# point d'entree du programme principal
function dequantifier(
    xQ::Vector{Int16},
    P::Dict{Tuple{Int16, Int16}, Int},
    mis_a_jour_arbre::Function,
    mis_a_jour_pourcent::Function,
    ajouter_solution::Function,
    chemin::String)

    arbre = creer_arbre()
    compteur_solutions = Ref{Int}(0)
    max_feuille = Ref{Int}(0)

    # creer la racine (noeud fictif qui sert juste de point de depart)
    arbre.racine = Noeud(Int16(0), nothing, false, nothing, Noeud[])

    enfant_gauche = ajouter_enfant!(arbre, arbre.racine, xQ[1], copy(P), false)
    enfant_droit = ajouter_enfant!(arbre, arbre.racine, xQ[1] + Int16(1), copy(P), true)

    max_feuille[] = arbre.nb_branches
    mis_a_jour_arbre(arbre)

    developper(arbre, enfant_gauche, xQ, 2, mis_a_jour_arbre, mis_a_jour_pourcent, ajouter_solution, max_feuille, chemin, compteur_solutions)

    developper(arbre, enfant_droit, xQ, 2, mis_a_jour_arbre, mis_a_jour_pourcent, ajouter_solution, max_feuille, chemin, compteur_solutions)
end