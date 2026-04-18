#============================================================
Ce module à pour rôle de générer xQ et P à partir de x.txt puis de les sauvegarder dans le dossier data
============================================================#



"""
    lire_serie(String)::Vector{Int16}

Prend en entrée le chemin de x et stock les données dans un vecteur.

Vérifie si le fichier est vide.

# Paramètres:
- chemin
"""
function lire_serie(chemin::String)::Vector{Int16}
    if !isfile(chemin)
        error("Fichier introuvable")
    end

    #sans reinterpret, on lit les valeurs comme des UInt8 au lieu de les lire comme des Int16
    vecteur = reinterpret(Int16, read(chemin)) 

    if isempty(vecteur)
        error("Le fichier est vide")
    end

    return collect(vecteur)
end



"""
    sous_quantifier(Vector{Int16})::Vector{Int16}
    
Transforme chaque valeur de la série temporelle x construit avec lire_serie() en l'entier pair inférieur ou égal.

Autrement dit, construit xQ.

# Paramètres:
- série temporelle x
"""
function sous_quantifier(x::Vector{Int16})::Vector{Int16}
    return [v & Int16(-2) for v in x]
    # l'opérateur & avec -2 force le bit de poids faible à 0
end

"""
    construire_p(Vector{Int16})::Dict{Tuple{Int16, Int16}, Int}

Construit P sous la forme d'un dictionnaire, avec comme clé le couple x[n-1], x[n], et comme valeur son nombre d’apparition. 

# Paramètres:
- série temporelle x.
"""
function construire_p(x::Vector{Int16})
    P = Dict{Tuple{Int16, Int16}, Int}()
    # on initialise le dictionnaire vide

    for n in 2:length(x)
        c = (x[n-1], x[n])
        # si la clé existe on l'incrémente sinon on la met à 1
        P[c] = get(P, c, 0) + 1
    end

    return P
end


"""
    sauvegarder_xq(Vector{Int16} x String)::Nothing

Sauvegarde la série sous-quantifiée xQ dans un fichier.

# Paramètres:
- chemin du fichier de sauvegarde.
"""
function sauvegarder_xq(xQ::Vector{Int16}, chemin::String)
    open(chemin, "w") do f
        write(f, xQ)
    end
end


"""
    sauvegarder_p(Dict{Tuple{Int16, Int16}, Int} x String)::Nothing

Sauvegarde le dictionnaire P dans un fichier.

# Paramètres:
- chemin du fichier de sauvegarde.
"""
function sauvegarder_p(P::Dict{Tuple{Int16, Int16}, Int}, chemin::String)
    open(chemin, "w") do f
        for (cle, c) in P
            println(f, "$(cle[1]) $(cle[2]) $c")
        end
    end
end


"""
    lire_p(String):: Dict{Tuple{Int16,Int16},Int}

Construit la représentation du fichier qui contient P sous la forme d'un dictionnaire.

# Paramètres:
- fichier qui contient P
"""
function lire_p(fichier_p::String)::Dict{Tuple{Int16,Int16},Int}
    p = Dict{Tuple{Int16,Int16},Int}()

    open(fichier_p, "r") do f
        for ligne in eachline(f)
            parties = split(ligne)
            cle1 = parse(Int16, parties[1])
            cle2 = parse(Int16, parties[2])
            valeur = parse(Int, parties[3])
            p[(cle1, cle2)] = valeur
        end
    end

    return p
end


