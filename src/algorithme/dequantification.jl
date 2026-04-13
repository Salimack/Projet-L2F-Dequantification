#========================================================
Ce module realise lalgorithme de dequantification de la serie xQ a partir de P lhistogramme
on construit un arbre binaire et on elague les branches impossibles au fur et a mesure
================================================================#
include("arbre.jl")

const DEBUG = true

# verifie si le couple (noeud.valeur, valeur) est autorise par P
# on regarde dans lhistogramme du noeud si le couple existe et si son compteur est > 0
# si le couple n'est pas dans P du tout ca retourne false aussi
function est_compatible(noeud::Noeud, valeur::Int16)::Bool
    couple = (noeud.valeur, valeur)
    if haskey(noeud.histogramme, couple)
        return noeud.histogramme[couple] > 0
    end
    DEBUG && println("Histogramme non équivalent avec le noeud")
    return false
end


# sauvegarde une solution (un vecteur de Int16) dans un fichier .dat
# le compteur sincremente a chaque appel pour avoir solution_1 solution_2 etc
# joinpath construit le chemin proprement quel que soit lOS
function sauvegarder_solution(solution::Vector{Int16}, chemin_dossier::String, compteur_solutions::Ref{Int})
    compteur_solutions[] += 1
    numero = string(compteur_solutions[])
    nom_fichier = "solution_" * numero * ".dat"
    chemin_fichier = joinpath(chemin_dossier, nom_fichier)

    open(chemin_fichier, "w") do fichier
        for v in solution
            println(fichier, v)
        end
        DEBUG && println("Sauvegarde de la solution reussie")
    end

    return chemin_fichier
end


# elague une feuille et remonte recursivement
# si apres suppression le parent devient feuille lui aussi on le vire aussi
# sauf si le parent est directement sous la racine (parent.parent === nothing) la on arrete
function elaguer!(arbre::Arbre, n::Noeud)
    if n.parent === nothing
        return
    end
    supprimer_noeud!(arbre, n.parent, n)
end

    
    #=supprimer_noeud!(arbre, n.parent, n)
    if n.parent.parent !== nothing && est_feuille(n.parent)
        elaguer!(arbre, n.parent)
    end

    return nothing=#
#end


#=coeur de lalgo cest un DFS (parcours en profondeur) recursif
 a chaque niveau on essaie les 2 candidats (pair et impair) pour xQ[niveau]
 si le couple est compatible avec P on cree lenfant et on continue plus profond
 sinon on elague
 les 3 fonctions callback (mis_a_jour_arbre etc) cest pour linterface graphique de dina
 Ref{Int} cest un wrapper pour pouvoir modifier un entier dans une fonction (julia passe par valeur sinon)=#
function developper(
    arbre::Arbre,
    noeud::Noeud,
    xQ::Vector{Int16},
    niveau::Int,
    mis_a_jour_arbre::Function,
    mis_a_jour_branches::Function,
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
                developper(arbre, enfant, xQ, niveau + 1, mis_a_jour_arbre, mis_a_jour_branches, ajouter_solution, chemin, compteur_solutions, est_lance)
            end
        end

        noeud.histogramme = nothing
    end

    return nothing
end


function dequantifier(
    xQ::Vector{Int16},
    P::Dict{Tuple{Int16, Int16}, Int},
    mis_a_jour_arbre::Function,
    mis_a_jour_branches::Function,
    ajouter_solution::Function,
    chemin::String,
    est_lance::Ref{Bool})

    DEBUG && println("Appel de dequantifier")
    DEBUG && println("Taille de xQ : ", length(xQ))

    arbre = creer_arbre()
    DEBUG && println("xQ[1] = ", xQ[1], " enfant_gauche = ", xQ[1], " enfant_droit = ", xQ[1] + Int16(1))
    DEBUG && println("arbre cree")

    compteur_solutions = Ref{Int}(0)

    arbre.racine = Noeud(Int16(0), nothing, false, Noeud[], nothing)

    enfant_gauche = ajouter_enfant!(arbre, arbre.racine, xQ[1], false, copy(P))
    enfant_droit  = ajouter_enfant!(arbre, arbre.racine, xQ[1] + Int16(1), true, copy(P))

    mis_a_jour_arbre(arbre)

    developper(arbre, enfant_gauche, xQ, 2, mis_a_jour_arbre, mis_a_jour_branches, ajouter_solution, chemin, compteur_solutions, est_lance)

    if !est_lance[]
        return
    end

    developper(arbre, enfant_droit, xQ, 2, mis_a_jour_arbre, mis_a_jour_branches, ajouter_solution, chemin, compteur_solutions, est_lance)

    mis_a_jour_branches(compter_branches(arbre.racine))
    DEBUG && println("==Fin de déquantifier")
    DEBUG && println("Taille de xQ : ", length(xQ))
    DEBUG && println("nb_branche final : ", arbre.nb_branche)
    DEBUG && println("total_branches : ", arbre.total_branche)
end