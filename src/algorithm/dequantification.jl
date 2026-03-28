#=
Ce module réalise l'algorithme de dequantificationde la serie xQ à partir de P, l'histogramme
=#
include("arbre.jl")



#Verifie si noeud.valeur et valeur sont compatibles avec P
function estCompatible(noeud::Noeud, valeur::Int16)::Bool
    if haskey(noeud.histogramme, (noeud.valeur, valeur))
        return noeud.histogramme[(noeud.valeur, valeur)] > 0
    end
    return  false
end

#Extrait la solution trouvée
function extraire_solution(noeud::Noeud)
    sequence = []
    noeud_courant = noeud

    while noeud_courant != null
        push!(sequence, noeud_courant.valeur)
        noeud_courant = noeud_courant.parent
    end

    reverse!(sequence)

    return  sequence
end


#Construit le nom du fichier et retourne son chemin
function sauvegarder_solution(solution::Vector{Int16}, chemin_dossier::String, compteur_solutions::Ref{Int})
    compteur_solutions[] += 1
    numero = string(compteur_solutions[])
    nom_fichier = "/solution_"*numero*".dat"
    chemin_fichier = joinpath(chemin_dossier, nom_fichier)

    open(chemin_fichier, "w") do fichier
        write(fichier, solution)
    end

    return chemin_fichier
end


#-elague l'arbre de maniere reniveausif
function elaguer!(arbre::Arbre, n::Noeud)::Nothing

    supprimer_noeud!(arbre, n.parent, n)

    if parent.parent!==nothing && est_feuille(n.parent)
        elaguer!(arbre, n.parent)
    end
end


#Developpe et elague l'arbre binaire des solutions
function developper(
    arbre::Arbre,
    noeud ::Noeud{Int16},
    xQ::Vector{Int16},
    niveau::Int, #position courante dans xQ
    misAJourArbre::Function,
    misAJourPourcent::Function,
    ajouterSolution::Function,
    maxFeuille:: Ref{Int},
    chemin::String,
    compteur_solutions::Int) ::Nothing

    #CAS DE BASE
    if niveau==length(xQ)
        solution = extraire_solution(noeud)
        chemin_solution = sauvegarder_solution(solution, chemin, compteur_solutions)
        ajouterSolution(chemin_solution)
    else
        xQn = xQ[niveau]
        valeurs_possibles = [xQn,xQn+1]
        valide = 0

        for valeurs in valeur_possibles
            if estCompatible(noeud, valeur)
                P_copie = copy(noeud.histogramme)
                P_copie[(noeud.valeur, valeur)] = P_copie[(noeud.valeur, valeur)] - 1

                enfant = ajouter_enfant!(arbre, noeud, valeur, pos, P_copie)

                valide += 1
                developper(arbre, enfant, xQ, niveau + 1, misAJourArbre, misAJourPourcent, ajouterSolution, maxFeuille, chemin, compteur_solutions)
            end
        end

        noeud.histogramme = nothing

        if valide == 0
            elaguer!(arbre, noeud)
        end

        misAJourArbre(arbre)

        pourcentage = arbre.nbBranche/maxFeuille*100
        misAJourPourcent(pourcentage)
    end
end

#Point d'entrée du programme principal
function dequantifier(xQ::Vecotr{Int16},
    P::Dict{Tuple{Int16, Int16}, Int},
    misAJourArbre::Function,
    misAJourPourcent::Function,
    ajouterSolution::Function,
    chemin::String)

    arbre = creer_arbre()
    compteur_solutions = Ref{Int}(0)
    maxFeuille = Ref{Int}(0)

    enfant_gauche = ajouter_enfant!(arbre, arbre.racine, xQ[1], false, copy(P))
    enfant_droit = ajouter_enfant!(arbre, arbre.racine, xQ[1] + Int16(1), true, copy(P))

    maxFeuille[] = arbre.nbBranche
    misAJourArbre(arbre)

    developper(arbre, enfant_gauche, xQ, 2, misAJourArbre, ajouterSolution, misAJourPourcent, maxFeuille, chemin, compteur_solutions)

    developper(arbre, enfant_droit, xQ, 2, misAJourArbre, ajouterSolution, misAJourPourcent, maxFeuille, chemin, compteur_solutions)
end