#========================================================
Ce module realise l'algorithme de dequantification de la serie xQ a partir de P lhistogramme
on construit un arbre binaire et on elague les branches impossibles au fur et à mesure.
Il génère par la suite toutes les solutions trouvées
================================================================#

const DEBUG = true

"""
    est_compatible(Noeud x valeur):: Bool

Verifie si le couple (noeud.valeur, valeur) est autorisé par P c'est-à-dire si son compteur est > 0
si le couple n'est pas dans P, on retourne false.

# Paramètres:
- noeud n présent dans l'arbre.
- valeur du noeud qu'on veut rajouter dans l'arbre comme enfant de n.
"""
function est_compatible(noeud::Noeud, valeur::Int16)::Bool
    couple = (noeud.valeur, valeur)
    if haskey(noeud.histogramme, couple)
        return noeud.histogramme[couple] > 0
    end
    DEBUG && println("Histogramme non équivalent avec le noeud")
    return false
end



"""
    sauvegarder_solution(Vector{Int16} x String x Ref{Int} ) :: Nothing

Sauvegarde une solution dans un fichier binaire .dat.
On définit un compteur qui s'incremente à chaque appel pour pouvoir enregistrer les différentes solutions sous divers noms: solution_1, solution_2, ..., solution_n

# Paramètres:
- vecteur de solution trouvé grâce à l'algorithme
- chemin du dossier de sauvegarde de cette solution
- compteur_solution qui va permettre de construire le nom du fichier.
"""
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



"""
    elaguer!(Arbre x Noeud):: Nothing

Supprime une branche de l’arbre en supprimant une feuille et en remontant récursivement si le parent devient feuille à son tour.4

# CAS DE BASE:
si le parent est fils de la racine, on arrête la suppression récursive.

# Paramètres:
- l'arbre
- la branche qu'on souhaite supprimer (on passe donc une feuille)
"""
function elaguer!(arbre::Arbre, n::Noeud)
    if n.parent === nothing
        return
    end
    supprimer_noeud!(arbre, n.parent, n)
    if est_feuille(n.parent)
        elaguer!(arbre, n.parent)
    end
end



"""
    developper(Arbre x Nœud x Vector{Int16} x Int x Function x Function x Function x String x Ref{Int} x Ref{Bool}):: Nothing

Développe et élague en même temps l'arbre binaire.

L’algorithme parcours l’arbre en profondeur. 

Au nième niveau, le nœud courant a deux fils possibles au niveau n+1 : la valeur paire (soit xQ(n)) et la valeur impaire (soit xQ(n)+1).

Pour chacun de ses fils, on vérifie que le couple (x(n),x(n+1)) possède une occurrence dans l’histogramme du père.

Si c’est le cas, le fils hérite de cet histogramme et décrémente le couple qui maintenant existe dans l’arbre.

On applique cet algorithme récursivement au niveau n+2.

Dans un but d’optimisation de la mémoire, on supprime l’histogramme du père, une fois ses enfants possibles crées puisqu’il peut être retrouvable à l'aide de ses fils.

Si aucun des deux fils ne peut former un couple compatible avec l'histogramme, le père devient donc une feuille et on l’élague. 

Si son frère est aussi une feuille, leur père est supprimé à son tour, et ainsi de suite, récursivement.

# CAS DE BASE:

Lorsqu’une série est trouvée, on l’extrait via extraire_solution().

A chaque modification de l’arbre, l’interface est mise à jour via la fonction mis_a_jour_arbre() du module interface.jl.


# Paramètres:
-	l’arbre,
-	le nœud courant,
-	la série sous-quantifiée xQ,
-	le niveau courant dans xQ,
-	les fonctions mis_a_jour_arbre(), mis_a_jour_branches(), ajouter_solution() du module interface.jl,
-	le dossier de sauvegarde des solutions trouvées,
-	le compteur de solutions initialisés dans dequantifier() qui va nous permettre de nommer les fichiers (solutionX_1, solutionX_2, …, solutionX_n).
-	la référence est_lance qui permet à l’interface d’interrompre l’algorithme
"""
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

    #cas de base : on a parcouru tout xQ donc cette branche est une solution
    if niveau == length(xQ) + 1
        DEBUG && println("[SOLUTION TROUVEE AU NIVEAU ", niveau, "]")
        solution = extraire_serie(noeud)
        chemin_solution = sauvegarder_solution(solution, chemin, compteur_solutions)
        ajouter_solution(chemin_solution)
    else

        xQn = xQ[niveau]
        valeurs_possibles = [xQn, xQn + Int16(1)]
        valide = 0

        DEBUG && println(("Initialisation : fils_pair=", xQ[1], " fils_impair=", xQ[1] + Int16(1)))
        DEBUG && println("Arbre créé, début de la recherche")

        for valeur in valeurs_possibles
            if !est_lance[]
                return
            end

            if est_compatible(noeud, valeur)
                P_copie = copy(noeud.histogramme)
                P_copie[(noeud.valeur, valeur)] -= 1

                enfant = ajouter_enfant!(arbre, noeud, valeur, valeur % 2 != 0, P_copie)


                valide += 1
                mis_a_jour_arbre(arbre)
                mis_a_jour_branches(compter_branches(arbre.racine))

                developper(arbre, enfant, xQ, niveau + 1, mis_a_jour_arbre, mis_a_jour_branches, ajouter_solution, chemin, compteur_solutions, est_lance)
            end
        end

        noeud.histogramme = nothing

        
        if valide == 0 || isempty(noeud.enfants)
            if niveau <= length(xQ)
                DEBUG && println("ELAGAGE noeud=", noeud.valeur, " parent=", noeud.parent.valeur)
                elaguer!(arbre, noeud)
                mis_a_jour_branches(compter_branches(arbre.racine))
            end
        end
        

        mis_a_jour_arbre(arbre)
    end
    return nothing
end


"""
    dequantifier(Vector{Int16} × Dict{Tuple{Int16, Int16}, Int} × Function x Function x Function x String x Ref{Bool})::Nothing

Initialise l'arbre est copie l'histogramme original.

Crée les deux premiers noeuds (xQ(1) et xQ(1)+1)).

Initialise le compteur de solutions pour nommer les fichiers générés.

Apelle enfin developper() sur chacun des deux premiers nœuds.


# Paramètres:
-	xQ,
-	l’histogramme original,
-	les fonctions mis_a_jour_arbre(), mis_a_jour_branches() et ajouter_solution() du module interface.jl,
-	le chemin du dossier de sauvegarde des solutions,
-	la référence est_lance qui permet d’interrompre l’algorithme
"""
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
end