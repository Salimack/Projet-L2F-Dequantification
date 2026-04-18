    #========================================
    Ce module définit les structures Noeud et Arbre ainsi que les fonctions associées
    ===========================================#


    """
        mutable struct Noeud

    Représente un nœud de l’arbre avec un histogramme associé.

    #Champs:
    - valeur = valeur associé au noeud
    - parent = le parent du noeud
    - pos = indique si pair ou impair
    - enfants = liste des fils du noeud
    - histogramme = dictionnaire P associé

    Notez que l'histogramme de la racine est de type Nothing

    """
    mutable struct Noeud
        valeur::Int16
        parent :: Union{Nothing, Noeud}
        pos::Bool # false = pair (fils bas) true = impair (fils haut)
        enfants::Vector{Noeud}
        histogramme:: Union{Nothing, Dict{Tuple{Int16, Int16}, Int}} #l'histogramme de la racine est Nothing
    end
    

    """
        mutable stuct Arbre

    Représente l'arbre binaire de déquantification.

    # Champs
    - racine : La racine de l'arbre.
    """
    mutable struct Arbre
        racine :: Union{Nothing, Noeud}
    end



    """
        creer_arbre()::Arbre

    Crée un arbre vide
    """
    function creer_arbre()::Arbre
        racine = Noeud(Int16(0), nothing, false, Noeud[], nothing)
        return Arbre(racine)
    end


    """
        creer_noeud(Int16 x Nœud x Bool x Dict ) :: Noeud

    Crée un nouveau noeud dans l'arbre.

    # Paramètres:
    - valeur = valeur du noeud
    - parent = noeud parent
    - pos = indique si le noeud est de type pair ou impair
    - histogramme = copie indépendante de l'histogramme
    """
    function creer_noeud(
            valeur::Int16,
            parent ::Union{Nothing, Noeud},
            pos::Bool,
            histogramme::Dict{Tuple{Int16, Int16}, Int}
            )::Noeud

        return Noeud(valeur,parent,pos,Noeud[], copy(histogramme))
    end


    """
        est_feuille(Noeud)::Bool

    Retourne true si le noeud n'a pas d'enfant, false sinon.

    # Paramètres:
    - noeud
    
    """
    function est_feuille(noeud::Noeud)
        return isempty(noeud.enfants)
    end


    """
        ajouter_enfant!(Arbre x Nœud x Int16 x Boolx Dict{Tuple{Int16, Int16}, Int}} ) :: Noeud

    Ajoute un enfant à l'arbre grâce à creer_noeud.

    # Paramètres:
    - Arbre
    - Noeud
    - valeur
    - pos
    - P, le dictionnaire
    """
    function ajouter_enfant!(
        arbre::Arbre,
        parent::Noeud,
        valeur::Int16,
        pos::Bool,
        P::Dict{Tuple{Int16,Int16}, Int})::Noeud

        enfant = creer_noeud(valeur, parent, pos, P)
        push!(parent.enfants, enfant)
        return enfant
    end

  

    """
        supprimer_noeud(Arbre x Nœud x Noeud ):: Noeud

    Supprime un noeud de la liste d'enfants de son parent.

    Sert à élaguer quand une branche est impossible.

    # Paramètres:
    - arbre
    - parent
    - noeud

    Exemple: supprimer_noeud!(arbre, parent, e1) -> enlève e1 de parent.enfants
    """
    function supprimer_noeud!(
        arbre::Arbre,
        parent::Noeud,
        noeud::Noeud)

        filter!(enfant -> enfant !== noeud, parent.enfants)
    end


    """
        compter_branches(noeud)::Int

    Compte le nombre de feuille dans l'arbre.

    Fonctionne par récursion

    # Paramètres:
    - noeud

    Exemple: si l'arbre a 3 feuilles -> retourne 3.
    """
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

 
    """
        extraire_serie(Noeud)::Vector{Int16}

    La fonction extrait la branche en la parcourant du nœud passé en paramètre à la racine.
    
    Retourne la branche dans le bon sens (racine -> nœud)

    # Paramètres:
    - Noeud

    Exemple: extraire_serie([2,3,4,5]) -> [2,3,4,5]
    """
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