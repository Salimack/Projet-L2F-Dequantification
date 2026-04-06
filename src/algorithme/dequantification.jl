#========================================================
Ce module realise lalgorithme de dequantification de la serie xQ a partir de P lhistogramme
on construit un arbre binaire et on elague les branches impossibles au fur et a mesure
================================================================#
include("arbre.jl")



# verifie si le couple (noeud.valeur, valeur) est autorise par P
# on regarde dans lhistogramme du noeud si le couple existe et si son compteur est > 0
# si le couple n'est pas dans P du tout ca retourne false aussi
function est_compatible(noeud::Noeud, valeur::Int16)::Bool
   
    println("Vérification si parent=", noeud.valeur, " et enfant=", valeur, " sont compatibles")

    if haskey(noeud.histogramme, (noeud.valeur, valeur))
        println("Histogramme équivalent avec le noeud")
        return noeud.histogramme[(noeud.valeur, valeur)] > 0
    end
    println("Histogramme non équivalent avec le noeud")
    return  false
end


#Extrait la solution trouvée
function extraire_serie(noeud::Noeud)
    sequence = Int16[]
    noeud_courant = noeud

    while noeud_courant.parent !== nothing
        push!(sequence, noeud_courant.valeur)
        noeud_courant = noeud_courant.parent
    end

    reverse!(sequence)
    println("Solution extraite: ", sequence)

    return  sequence
end



# sauvegarde une solution (un vecteur de Int16) dans un fichier .dat
# le compteur sincremente a chaque appel pour avoir solution_1 solution_2 etc
# joinpath construit le chemin proprement quel que soit lOS
function sauvegarder_solution(solution::Vector{Int16}, chemin_dossier::String, compteur_solutions::Ref{Int})
    compteur_solutions[] += 1
    numero = string(compteur_solutions[])
    nom_fichier = "solution_"*numero*".dat"
    chemin_fichier = joinpath(chemin_dossier, nom_fichier)

    # do ... end cest un bloc qui ferme automatiquement le fichier a la fin
    open(chemin_fichier, "w") do fichier
        write(fichier, solution)
        println("Sauvegarde de la solution reussie")
    end
    
    return chemin_fichier
end


# elague une feuille et remonte recursivement
# si apres suppression le parent devient feuille lui aussi on le vire aussi
# sauf si le parent est directement sous la racine (parent.parent === nothing) la on arrete
function elaguer!(arbre::Arbre, n::Noeud)
    supprimer_noeud!(arbre, n.parent, n)

    #Verifions que n.parent n'est pas la racine
    #La racine est un noeud fictife, elle ne peut pas être supprimée, en aucun cas
    if n.parent.parent !==nothing && est_feuille(n.parent)
        elaguer!(arbre, n.parent)
    end

    return nothing
end


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
    mis_a_jour_pourcent::Function,
    ajouter_solution::Function,
    max_feuille::Ref{Int},
    chemin::String,
    compteur_solutions::Ref{Int},
    est_lance::Ref{Bool})::Nothing  

    #Arret de l'algorithme si l'utilisateur a cliqué sur le bouton arrêter 
    if !est_lance[]
        return
    end


    # cas de base : on a parcouru tout xQ donc cette branche est une solution
    if niveau == length(xQ) + 1
        println("[SOLUTION TROUVEE AU NIVEAU ", niveau)
        solution = extraire_serie(noeud)    # remonte la branche pour recuperer la sequence
        chemin_solution = sauvegarder_solution(solution, chemin, compteur_solutions)
        ajouter_solution(chemin_solution)
    else

        #On met a jour max_feuille au fur et à mesure de la progression de l'algorithme
        if arbre.nb_branche > max_feuille[]
            max_feuille[] = arbre.nb_branche
        end
        
        #mis à jour du pourcentage.
        if max_feuille[]>0
            pourcentage = (compter_branches(arbre.racine)/max_feuille[])*100.0
            mis_a_jour_pourcent(pourcentage)
        end
       

        #=pour chaque niveau, on teste xQn et xQn+1
        Si le couple (noeud.valeur, valeur) existe dans P, on crée un enfant avec une COPIE de P qu'on décrémente
        =#
        xQn = xQ[niveau]
        valeurs_possibles = [xQn, xQn + Int16(1)]  # pair et impair
        #compteur qui compte combien de candidats sont pairs ou impairs
        valide = 0

        println("[NIVEAU ", niveau, "] valeur noeud=", noeud.valeur, " | candidats=", valeurs_possibles)

        for valeur in valeurs_possibles
            #Si l'utilisteur clique sur arreter l'algorithme doit s'arreter
            if !est_lance[]
                return
            end

            if est_compatible(noeud, valeur)
                # on copie P pour pas que les branches se marchent dessus
                P_copie = copy(noeud.histogramme)
                P_copie[(noeud.valeur, valeur)] -= 1    # on decremente le couple utilise

                # pos = true si impair false si pair
                enfant = ajouter_enfant!(arbre, noeud, valeur, valeur % 2 != 0 , P_copie)

                if arbre.nb_branche>max_feuille[]
                    max_feuille[] = arbre.nb_branche
                end

                valide += 1
                mis_a_jour_arbre(arbre)

                developper(arbre, enfant, xQ, niveau + 1, mis_a_jour_arbre, mis_a_jour_pourcent, ajouter_solution, max_feuille, chemin, compteur_solutions, est_lance)
            end
        end

        # le parent na plus besoin de P: ses enfants ont chacun leur copie => libération de la mémoire
        noeud.histogramme = nothing

        
        #=Si valide == 0, cela signifie que aucun des deux enfants est compatible avec l'algorithme.
        Leur parent doit aussi être élagué de manière récursive
        Si le noeud n'a pas d'enfants alors que nous ne sommes pas au dernier niveau, il faut aussi élaguer=#
        if valide == 0 || isempty(noeud.enfants)
            if niveau <= length(xQ)
                println("ELAGAGE noeud=", noeud.valeur, " parent=", noeud.parent.valeur)
                elaguer!(arbre, noeud)
                pourcentage = compter_branches(arbre.racine)/max_feuille[]*100
                mis_a_jour_pourcent(pourcentage)
            end

        mis_a_jour_arbre(arbre)
    end
end
    return nothing
end


#=
Cette fonction est le point d’entrée de notre programme principal. 
Elle prend en entrée xQ, l’histogramme original, les fonctions misAJourArbre(), misAJourPourcent(), ajouterSolution() du module interface.jl, et le chemin du dossier de sauvegarde des solutions.
Elle initialise l'arbre et copie l’histogramme, pour garantir l’existence de l’original. 
Elle crée ensuite les deux premiers nœuds (xQ(1) et xQ(1)+1).
Elle initialise le compteur de solutions et le maximum de feuilles rencontré pour calculer le pourcentage de branches restantes.
Puis elle appelle developper() sur chacun des deux premiers nœuds.

=#
function dequantifier(
    xQ::Vector{Int16},
    P::Dict{Tuple{Int16, Int16}, Int},
    mis_a_jour_arbre::Function,
    mis_a_jour_pourcent::Function,
    ajouter_solution::Function,
    chemin::String,
    est_lance::Ref{Bool})

    println("Appel de dequantifier")
    println("Taille de xQ : ", length(xQ))

    arbre = creer_arbre()
    println("arbre cree")

    compteur_solutions = Ref{Int}(0)
    max_feuille = Ref{Int}(0)

    # la racine est un noeud fictif qui ne sert que de point de départ à notre arbre
    arbre.racine = Noeud(Int16(0), nothing, false, Noeud[], nothing)

    # les 2 premiers candidats pour xQ[1] la valeur paire et impaire
    enfant_gauche = ajouter_enfant!(arbre, arbre.racine, xQ[1], false, copy(P))
    enfant_droit = ajouter_enfant!(arbre, arbre.racine, xQ[1] + Int16(1), true, copy(P))

    max_feuille[] = arbre.nb_branche
    mis_a_jour_arbre(arbre)

    # on lance le DFS sur chaque branche de depart
    developper(arbre, enfant_gauche, xQ, 2, mis_a_jour_arbre, mis_a_jour_pourcent, ajouter_solution, max_feuille, chemin, compteur_solutions, est_lance)

    #Si l'utilisateur appuie sur arreter l'algoroithme doit s'arreter
    if !est_lance[]
        return
    end

    developper(arbre, enfant_droit, xQ, 2, mis_a_jour_arbre, mis_a_jour_pourcent, ajouter_solution, max_feuille, chemin, compteur_solutions, est_lance)

    pourcentage = compter_branches(arbre.racine) / max_feuille[] * 100
    mis_a_jour_pourcent(pourcentage)
    println("calcul final: ",compter_branches(arbre.racine),"/",max_feuille[],"=",pourcentage)


    println("==Fin de déquantifier")
    println("Nombre maximal de branches observé: ", max_feuille[])
    println("Nombre total de solutions trouvées: ", compteur_solutions[])
end