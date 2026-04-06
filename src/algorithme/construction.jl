# ============================================================
# construction.jl
# Rôle : À partir de x.txt, génère xQ et P
#        et les sauvegarde dans le dossier data
# ============================================================


# ------------------------------------------------------------
# FONCTIONS
# ------------------------------------------------------------

"""
lire_x(chemin) -> vecteur d'entier
Ouvre le fichier en mode "r" (lecture seule). charge x

calculer_xQ(tableau sorti de lire_x) -> vecteur d'entiers
à partir de x calcul xQ
 - si x(n) est pair   → xQ(n) = x(n)
 - si x(n) est impair → xQ(n) = x(n) + 1

calculer_P(tableau sorti de lire_x) -> dictionnaire
construit l'histogramme des couples successives de x 

sauvegarder_xQ(xQ, chemin)
sauvegarde xQ

sauvegarder_P(P, chemin)
sauvegarde P

ecrire une fonction qui appelle toutes les fonctions listées plus haut dans le bon ordre
- lire serie, calculer xQ, calculer P, sauvegegarder xQ, sauvegarder P

"""
function lire_serie(chemin::String)::Vector{Int16}
    # vérifie que le fichier existe
    if !isfile(chemin)
        error("Fichier introuvable")
    end

# ouvre le fichier en mode lecture
vecteur = read(chemin, Vector{Int16})   

    #verifie que le tableau n'est pas vide
    if isempty(vecteur)
        error("Le fichier est vide")
    end

    return vecteur
end


# transforme chaque nombre du vecteur en l'entier pair inférieur ou égal.
function sous_quantifier(x::Vector{Int16})::Vector{Int16}
    return [v & Int16(-2) for v in x]
    #l'operateur & avec -2 permet de forcer le bit de poid faible à 0
end



function construire_p(x::Vector{Int16})
    P = Dict{Tuple{Int16, Int16}, Int}()
    # on initialise le dictionnaire vide

    for n in 2:length(x)
        c = (x[n-1], x[n])
        
        #si la clé existe on l'incrémente sinon on la met à 1
        P[c] = get(P, c, 0) + 1   
    end

    return P
end




function sauvegarder_xq(xQ::Vector{Int16}, chemin::String)

    fichier=open(chemin,"w")
    
    for n in xQ
        write(fichier,n)
    end 

    close(fichier)

end



function sauvegarder_p(P::Dict{Tuple{Int16, Int16}, Int},chemin::String)
    fichier = open(chemin, "w")
    for (cle, c) in P
        write(fichier, cle[1])   
        write(fichier, cle[2])   
        write(fichier, c) 
    end
    close(fichier)
    
end

function lire_p(fichier_p::String)::Dict{Tuple{Int16,Int16},Int}

    p = Dict{Tuple{Int16,Int16},Int}()

    #reconstruction de P dans un dictionnaire
    open(fichier_p, "r") do f
        while !eof(f)
            cle1 = read(f, Int16)
            cle2 = read(f, Int16)

            valeur = read(f, Int)
            p[(cle1, cle2)] = valeur
        end
    end

    return p
end


function generer_donnees(x_chemin::String, xQ_chemin::String, P_chemin::String)
    x  = lire_serie(x_chemin)
    xQ = sous_quantifier(x)
    P  = construire_p(x)
    sauvegarder_xq(xQ,xQ_chemin)
    sauvegarder_P(P, P_chemin)
end