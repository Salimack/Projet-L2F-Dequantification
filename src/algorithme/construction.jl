# ============================================================
# construction.jl
# Rôle : À partir de x.txt, génère xQ et P
#        et les sauvegarde dans le dossier data
# ============================================================


# ------------------------------------------------------------
# FONCTIONS
# ------------------------------------------------------------

function lire_serie(chemin::String)::Vector{Int16}
    # vérifie que le fichier existe
    if !isfile(chemin)
        error("Fichier introuvable")
    end

    # lit le fichier ligne par ligne et convertit en Int16
    lignes = readlines(chemin)

    # vérifie que le fichier n'est pas vide
    if isempty(lignes)
        error("Le fichier est vide")
    end

    return parse.(Int16, lignes)
end


# transforme chaque nombre du vecteur en l'entier pair inférieur ou égal
function sous_quantifier(x::Vector{Int16})::Vector{Int16}
    return [v & Int16(-2) for v in x]
    # l'opérateur & avec -2 force le bit de poids faible à 0
end


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


function sauvegarder_xq(xQ::Vector{Int16}, chemin::String)
    open(chemin, "w") do f
        for n in xQ
            println(f, n)
        end
    end
end


function sauvegarder_p(P::Dict{Tuple{Int16, Int16}, Int}, chemin::String)
    open(chemin, "w") do f
        for (cle, c) in P
            println(f, "$(cle[1]) $(cle[2]) $c")
        end
    end
end


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


function generer_donnees(x_chemin::String, xQ_chemin::String, P_chemin::String)
    x  = lire_serie(x_chemin)
    xQ = sous_quantifier(x)
    P  = construire_p(x)
    sauvegarder_xq(xQ, xQ_chemin)
    sauvegarder_p(P, P_chemin)
end