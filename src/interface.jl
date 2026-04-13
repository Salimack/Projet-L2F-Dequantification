#===========================================================
Ce module gère l'interface graphique de l'application L2F2.
Il dépend de GLMakie, GraphMakie, NativeFileDialog et ZipFile.

- GLMakie - bibliothèque graphique
- Graphs - fournit SimpleDiGraph, le graphe qui stocke l'arbre
- NativeFileDialog - bibliothèque ouvrant les systèmes de fichiers natif des différents systèmes d'exploitation
- ZipFile - permet la création de fichiers zip
=====================================#

using GLMakie
using Graphs
using GraphMakie
using NativeFileDialog
using ZipFile

#========================================
Chemin absolu du dossier data dans lequel les solutions sont enregistrées
========================================#
const DOSSIER_DATA = joinpath(dirname(@__FILE__), "data")
const DEBUG = true

function creer_interface()

    #=========================================
    INITIALISATION DE LA FENETRE
    - GLMakie.activate() - initialise la fenetre, on force la fenetre a se placer en premier plan à l'ouverture
    Défintion de la taille de la fenetre et des marges de sécurité
    ===========================================# 
    GLMakie.activate!(title = "L2F2 — Déquantification", focus_on_show = true)
    figure = Figure(size = (1300, 660), figure_padding = 30, backgroundcolor = RGBf(0.10, 0.11, 0.14))

    #réinitialisation du dossier temp qui contiendra les solutions trouvées par l'algorithme
    mkpath(joinpath(DOSSIER_DATA, "temp"))
    for f in readdir(joinpath(DOSSIER_DATA, "temp"), join=true)
        rm(f)
    end


    #==============================================================
     OBSERVABLES
     Initialise tous les élements de l'interface graphique à leurs observables
    =====================================================================#
    #Observable du graphe: contient le graphe et permet de le mettre à jour
    graphe_obs            = Observable(SimpleDiGraph())

    #Observable de la position des noeuds
    positions_obs = Observable(Point2f[])

    #  Observable du nombre de branches restants
    branches_obs          = Observable(0)
    texte_dynamique = @lift(string($branches_obs) * " branche(s)") #changement dynamique du texte affiché à l'écran


    solution_obs          = Observable(String[])  #Observable des solutions restantes

    #Nous allons differencier le programme 1 (importation de x) du programme 2 (importation de xQ et P)
    prog_actuelle         = Observable(1)
    #// NOTE: Je ne suis plus trop sûre de faire 2 programmes ....

    #Observable indiquant si l'animation est en cours. Vaut true si elle l'est, false sinon
    est_lance             = Observable(false)

    # Ref{Bool} passé à l'algorithme pour l'interrompre
    continuer = Ref{Bool}(true)

    #texte d'erreur affiché dans l'axe
    texte_erreur = Ref{Any}(nothing)

    #//TODO: à paufiner pour la couleur affiché à l'écran (pour l'instant ça reste rouge)
    total_branches_ref = Ref{Int}(1)

    #Observable du label du bouton d'importation. vaut "Importer x" en phase 1, ou alors "Importer xQ et P" en phase 2
    label_bouton_import   = @lift($prog_actuelle == 1 ? "Importer x" : "Importer xQ et P")

    # Observable de la couleur du nombre affiché: vert si on a moins de 5% de branches, sinon rouge
    couleur_branche      = @lift($branches_obs / total_branches_ref[] * 100 <= 5.0 ? :green : :red)

    #Observable pour le bouton "Lancer".
    couleur_bouton_lancer = @lift($prog_actuelle == 2 ? :green : :lightgray)


    #========================================================
     Données chargées par l"utilisateur
     Les variables suivantes valent nothing si rien n'a été chargé
    =========================================================#
    xQ_charge = Ref{Union{Nothing, Vector{Int16}}}(nothing)
    P_charge  = Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}}}(nothing)


    #====================================================
    Layout et les boutons
    L'inerface est divisée comme suit
    COLONNE GAUCHE
        contient le bouton "exporter les solutions" ainsi que les solutions trouvées
    
    COLONNE DROITE
        contient l'arbre ainsi que les boutons de navigation (lancer et arrêter) et les boutons (importerx/xQ et P et telecharger xQ et P)
    ================================================#

    #COLONNE GAUCHE
    layout_gauche = figure[1, 1] = GridLayout(alignmode = Outside(20))
    colsize!(figure.layout, 1, Fixed(250))
    
    #sous-grille pour aligner les boutons
    layout_boutons_import = layout_gauche[2, 1] = GridLayout()
    bouton_exporter = Button(layout_boutons_import[1, 1], label = "Exporter les solutions", height = 38, tellwidth = false, buttoncolor = RGBf(0.22, 0.52, 0.95), labelcolor = :white, font = :bold, strokewidth = 0)
    
    colgap!(layout_boutons_import, 100) #espace entre les boutons pour la clarté
    
    #Les solutions
    Label(layout_gauche[3, 1], "Liste des solutions :", halign = :left, padding = (0, 0, 10, 0), fontsize=13, font=:bold, color = RGBf(0.55, 0.58, 0.65))
    #liste_solutions = Menu(layout_gauche[4, 1], options = [""], tellwidth = false)

    ax_liste = Axis(layout_gauche[4, 1],
        backgroundcolor = RGBf(0.10, 0.11, 0.14),
        xgridvisible = false, ygridvisible = false
    )
    hidedecorations!(ax_liste)
    hidespines!(ax_liste)
    rowsize!(layout_gauche, 4, Relative(1))
    scroll_offset = Ref{Int}(0)
    MAX_VIS = 16 

    #COLONNE DROITE
   layout_droite = figure[1, 2] = GridLayout()
   ax = Axis(layout_droite[1, 1], title = "Déquantification", titlesize=24, titlecolor = RGBf(0.88, 0.90, 0.95), backgroundcolor = RGBf(0.08, 0.09, 0.11), alignmode = Outside(10)) #zone de dessin
   hidedecorations!(ax) # On supprime les axes et les coordonnées

   #Les boutons en dessous de l'axis (zone de dessin)
   grille_bas = layout_droite[2, 1] = GridLayout(tellheight = true)

   # boutons de navigation et d'importation/exportation

   #bouton dynamique: soit importer x, soit importer xQ/P
    bouton_import = Button(grille_bas[1, 1], label = label_bouton_import, height = 42, tellwidth = false, font = :bold, buttoncolor = RGBf(0.20, 0.22, 0.28), labelcolor = RGBf(0.88, 0.90, 0.95), strokewidth = 0)

    #bouton de lancemenent de l'algorithme
    bouton_lancer = Button(grille_bas[1, 2], label = "Lancer", buttoncolor = couleur_bouton_lancer, height = 42, tellwidth = false, font = :bold, labelcolor = :white, strokewidth = 0)

    #bouton d'arrêt de l'algo
    bouton_arreter = Button(grille_bas[1, 3], label = "Arrêter", buttoncolor = RGBf(0.88, 0.28, 0.22), height = 42, tellwidth = false, font = :bold, labelcolor = :white, strokewidth = 0)

    #bouton d'exportation du dossier contenant xQ et P
    bouton_telecharger_xQP = Button(grille_bas[1, 4], label = "Télécharger xQ et P", height = 42, tellwidth = false, font = :bold, buttoncolor = RGBf(0.20, 0.22, 0.28), labelcolor = RGBf(0.88, 0.90, 0.95), strokewidth = 0)

    # GESTION DE LESPACE
    rowsize!(layout_droite, 1, Relative(1))
    rowsize!(layout_droite, 2, Auto())

    # Espace entre les boutons et entre le graphe
    colgap!(grille_bas, 10)
    rowgap!(layout_droite, 10)

    # Dessin de l'arbre
   graphplot!(ax, graphe_obs, layout = _ -> positions_obs[], node_size = 12, node_color = RGBf(0.22, 0.52, 0.95), edge_color = RGBf(0.30, 0.33, 0.40), arrow_show = false)
   
   # affichage dynamique du pourcentage
   text!(ax, 0, 0,
    text = texte_dynamique,    # On passe l'observable ici
    space = :relative, 
    align = (:left, :bottom), 
    offset = (15, 15), 
    fontsize = 24, 
    font = :bold, 
    color = couleur_branche)


    #=============================================================================================
    fonctions passées à dequantifier
    Permet de lier l'interface directement à l'algorithme
    ========================================================================================#

    # met à jour le graphe affiché à chaque modification de l'arbre
    mis_a_jour_arbre_cb = (arbre) -> mis_a_jour_arbre(graphe_obs, positions_obs, arbre)

    #met à jour le nombre de branches affiché
   mis_a_jour_branches_cb = (n) -> begin
    DEBUG && println("mis_a_jour_branches appelé avec ", n)
    mis_a_jour_branches(branches_obs, n)
end

    #==============================================================
    EVENEMENTS
    On définit le comportement de chaque bouton
   ==================================================================#

   #= bouton importer: change de role selon l'étape du projet
   si prog_actuelle[] = 1, alors il permet l'importation de x
   =#
   on(bouton_import.clicks) do x
       if prog_actuelle[] == 1
           x = importer_fichier(ax, texte_erreur)
           if !isempty(x)
               preparer_donnees(x, xQ_charge, P_charge, DOSSIER_DATA)
               prog_actuelle[] = 2
           end
          
       else
           importer_xQP(ax, xQ_charge, P_charge, texte_erreur)
       end
   end

   #bouton télécharger xQ et P: disponible seulement après la phase 1
   on(bouton_telecharger_xQP.clicks) do x
       if prog_actuelle[] == 2
           telecharger_xQP(DOSSIER_DATA)
       end
   end

   # bouton de lancement
   on(bouton_lancer.clicks) do _
       DEBUG && println("Lancer cliqué, prog_actuelle = ", prog_actuelle[])
       DEBUG && println("xQ_charge = ", isnothing(xQ_charge[]) ? "nothing" : "chargé")
       DEBUG && println("P_charge = ", isnothing(P_charge[]) ? "nothing" : "chargé")
       if prog_actuelle[] == 2
        continuer[] = true
        DEBUG && println("Taille de P: ",length(P_charge[]))
        DEBUG && println("Nombre d'occurence dans P du couple le plus frequent: ",maximum(values(P_charge[])))

           lancer_animation(ax::Axis,texte_erreur::Ref{Any},xQ_charge, P_charge,est_lance,graphe_obs, branches_obs, solution_obs,mis_a_jour_arbre_cb, mis_a_jour_branches_cb,joinpath(DOSSIER_DATA, "temp"), continuer)
       end
   end

   #Cadre automatiquement la vue du graphe  pour que tout l'arbre reste visible 
   on(graphe_obs) do _
    autolimits!(ax)
end

   # --- bouton arrêter (est géré grâce à la reference continuer)
   on(bouton_arreter.clicks) do x
       arreter_animation(est_lance, continuer)
   end

   # --- bouton exporter ---
   on(bouton_exporter.clicks) do x
       telecharger_solutions(solution_obs[])
   end


   # liste des solutions dessinée dans ax_liste avec scroll automatique
   on(solution_obs) do chemins
       empty!(ax_liste.scene.plots)
       n = length(chemins)
       if n == 0; return; end
       scroll_offset[] = max(0, n - MAX_VIS)
       debut = scroll_offset[] + 1
       fin   = min(n, scroll_offset[] + MAX_VIS)
       ylims!(ax_liste, 0, MAX_VIS)
       xlims!(ax_liste, 0, 1)
       for (j, chemin) in enumerate(chemins[debut:fin])
           y = MAX_VIS - j
           bg = j % 2 == 0 ? RGBf(0.15, 0.17, 0.20) : RGBf(0.12, 0.13, 0.16)
           poly!(ax_liste, Point2f[(0,y),(1,y),(1,y+1),(0,y+1)], color=bg, strokewidth=0)
           text!(ax_liste, 0.04, y+0.25, text=basename(chemin), fontsize=12, color=RGBf(0.88,0.90,0.95), space=:data)
       end
   end

   #========================================================================
     affichage de la fenetre
    ========================================================================#
    DEBUG && println("OUVERTURE DE L'APPLICATION")
    display(figure)
    wait(display(figure))
end






#===========================================
Lance l'animation de l'arbre, stockes les solutions trouvées et met à jour leur dossier de sauvegarde
===========================================#
function lancer_animation(
    ax_graphe::Axis,
    texte_erreur::Ref{Any},
    xQ_charge::Ref{Union{Nothing, Vector{Int16}}},
    P_charge::Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}}},
    est_lance::Observable{Bool},
    graphe_obs::Observable{SimpleDiGraph{Int64}},
    branches_obs::Observable{Int},
    solution_obs::Observable{Vector{String}},
    mis_a_jour_arbre::Function,
    mis_a_jour_branches::Function,
    dossier::String, continuer
)
    DEBUG && println("lancer_animation appelé")

#=
Initialisation et réinitialisation
- verifie que les données sont chargées, prépare le dossier de sauvegarde et change l'etat est_lance à true
=#

#Verifie si les donnees sont chargées
    if isnothing(xQ_charge[]) || isnothing(P_charge[])
        DEBUG && println("Données manquantes")
        return
    end

    #reinitialise l'interface
    if !isnothing(texte_erreur[])
        delete!(ax_graphe, texte_erreur[])
        texte_erreur[] = nothing
    end
    graphe_obs[]   = SimpleDiGraph()
    branches_obs[] = 0
    solution_obs[] = String[]

    # vide le dossier de stockage des solutions
    mkpath(dossier)
    for f in readdir(dossier, join=true)
        rm(f)
    end

    est_lance[] = true

    #=====
    Lance l'algorithme en mode asynchrone pour garantir la mise à jour du pourcentage et du graphe parallèlement.
    A l'issue, remet l'état de est_lance à false et liste toutes les solutions trouvées
    ========#
    @async begin
        DEBUG && println("@async commence")
        try
            ajouter_solution = (chemin_solution) -> begin
            #ajout de la solution dans liste
            liste = solution_obs[]
            push!(liste, chemin_solution)
            solution_obs[] = liste
            DEBUG && println("Solution ajoutée: ", basename(chemin_solution))
        end
            DEBUG && println("Avant déquantifier")
            dequantifier(
                xQ_charge[],
                P_charge[],
                mis_a_jour_arbre,
                mis_a_jour_branches,
                ajouter_solution,
                dossier, continuer
            )
        catch e
            DEBUG && println("ERREUR : ", e)
        finally
            est_lance[] = false

            #liste toutes les solutions du dossier
            #solution_obs[] = readdir(dossier, join=true)
            DEBUG && println("Nombre de solutions stockées: ", length(solution_obs[]))
        end
    end
    DEBUG && println("fin de lancer_animation")
end


function arreter_animation(est_lance::Observable{Bool}, continuer::Ref{Bool})
    est_lance[] = false #signal pour l'algorithme
    continuer[] = false #signal pour l'interface graphique
end


#= Met à jour le pourcentage affiché et la fluidité de l'interface =#
function mis_a_jour_branches(branches_obs::Observable, nb_branches::Int)
    DEBUG && println("mis_a_jour_branches appelé avec ", nb_branches)
    branches_obs[] = nb_branches
    #on gère la vitessse de l'animation
    sleep(0.1) 
end



#=
Copie xQ.dat et P.ppm depuis le dossier de l'application vers un dossier choisi par l'utilisateur.
Prend en entrée le chemin du dossier source où xQ.dat et P.ppm sont générés
=#
function telecharger_xQP(dossier_source::String)
    dossier_dest = pick_folder()

    if dossier_dest == "" || isnothing(dossier_dest)
        return
    end

    dossier_xQP = joinpath(dossier_dest, "xQP")
    mkpath(dossier_xQP)

    if dossier_dest == "" || isnothing(dossier_dest)
        return
    end
    cp(joinpath(dossier_source, "xQ.dat"), joinpath(dossier_xQP, "xQ.dat"), force=true)
    cp(joinpath(dossier_source, "P.ppm"),  joinpath(dossier_xQP, "P.ppm"), force=true)
    DEBUG && println("Téléchargement de xq et P")
end

#=
Importe le dossier contenant xQ et P
=#
function importer_xQP(
    ax_graphe::Axis,
    xQ_charge::Ref{Union{Nothing, Vector{Int16}}},
    P_charge::Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}}},
    texte_erreur::Ref{Any})
   
    trouve = true
    dossier = pick_folder()

    if dossier==""
        trouve = false
    end

    xq =""
    p = ""

    if trouve

    liste_fichiers = readdir(dossier, join=true)
    
    for fichier in liste_fichiers
        #si le fichier finit par .dat, il s'agit de xQ
        if endswith(fichier, ".dat")
            xq = fichier
        
        #si le fichier finit par .ppm, il s'agit de P
        elseif endswith(fichier, ".ppm")
            p = fichier
        end
    end

        #Si on ne trouve pas xQ ou P, on affiche une erreur
        if xq=="" || p==""
            affiche_erreur(ax_graphe, "Fichiers xQ et/ou P introuvables.", texte_erreur)
            DEBUG && println("Erreur: fichiers xQ et/ou P introuvables")
            trouve = false
        end

        if trouve

        xQ_charge[] = collect(reinterpret(Int16, read(xq)))
        P_charge[] = lire_p(p)
        DEBUG && println("Importation du dossier xQ et P")
        end
    end
    return 
end


#= 
Prend en entrée le vecteur des fichiers selectionnés par l'utilisateur et le nombre de solutions généré par le programme
Télécharge les solutions sélectionnées dans un dossier choisi par l'utilisateur
Si plusieurs fichiers, génère une archive ZIP =#
function telecharger_solutions(
    solutions::Vector{String},
)

    dossier_dest = pick_folder()
    if isempty(solutions) || dossier_dest == ""
        return nothing
    end

    chemin_zip = joinpath(dossier_dest, "solutions_trouvees.zip")
    w = ZipFile.Writer(chemin_zip)

    for chemin in solutions
        f = ZipFile.addfile(w, basename(chemin))
        #copie le fichier dans le zip
        write(f, read(chemin))
    end
    close(w)
    DEBUG && println("Toutes les solutions exportees dans un fichier Zip")
end


#=============================================
CONSTRUCTION DE L ARBRE MANUELLEMENT
=================================================#

#Chaque noeud recoit un identifiant unique 
function indexer_noeuds!(graphe::SimpleDiGraph, noeud::Noeud, indices::Dict{Noeud,Int})
    #ajout d'un noeud
    add_vertex!(graphe)
    indices[noeud] = nv(graphe) #nv(graphe) renvoie le nombre de noeud actuel 
    for enfant in noeud.enfants
        indexer_noeuds!(graphe, enfant, indices)
    end
end

# Passe 2 : relier les arêtes
function relier_aretes!(graphe::SimpleDiGraph, noeud::Noeud, indices::Dict{Noeud,Int})
    for enfant in noeud.enfants
        add_edge!(graphe, indices[noeud], indices[enfant])
        relier_aretes!(graphe, enfant, indices)
    end
end

#Position de chaque noeud horizontalement
function calculer_x!(noeud::Noeud, x_pos::Dict{Noeud,Float32}, compteur::Ref{Int})
    if isempty(noeud.enfants)
        compteur[] += 1
        x_pos[noeud] = Float32(compteur[])
    else
        for enfant in noeud.enfants
            calculer_x!(enfant, x_pos, compteur)
        end
        x_pos[noeud] = (x_pos[first(noeud.enfants)] + x_pos[last(noeud.enfants)]) / 2
    end
end

# Postion verticalement 
function calculer_profondeur!(noeud::Noeud, profondeurs::Dict{Noeud,Int}, prof::Int)
    profondeurs[noeud] = prof
    for enfant in noeud.enfants
        calculer_profondeur!(enfant, profondeurs, prof + 1)
    end
end

#= Convertit notre structure Arbre en SimpleDiGraph pour que GraphMakie puisse le manipuler.
 Parcourt l'arbre en profondeur avec une pile pour éviter un dépassement de mémoire =#

function convertir_arbre(arbre::Arbre)
    graphe     = SimpleDiGraph()
    indices    = Dict{Noeud, Int}()
    x_pos      = Dict{Noeud, Float32}()
    profondeurs = Dict{Noeud, Int}()
    compteur   = Ref(0)


    indexer_noeuds!(graphe, arbre.racine, indices)
    relier_aretes!(graphe, arbre.racine, indices)
    calculer_x!(arbre.racine, x_pos, compteur)
    calculer_profondeur!(arbre.racine, profondeurs, 0)

    positions = Vector{Point2f}(undef, nv(graphe))

    #on place chaque noeud à sa position (x,y)
    for (noeud, i) in indices
        positions[i] = Point2f(x_pos[noeud], -Float32(profondeurs[noeud]))
    end

    return graphe, positions
end

function mis_a_jour_arbre(graphe_obs::Observable, positions_obs::Observable, arbre::Arbre)
    g, pos = convertir_arbre(arbre)
    if nv(g) == 0
        #On place un noeud "fantome": GraphMakie ne sais pas construire un graphe à partir de "rien"
        graphe_obs[]    = SimpleDiGraph(1)
        positions_obs[] = [Point2f(0.5, 0.0)]
    else
        #On met à jour les positions et le graphe
        positions_obs[] = pos
        graphe_obs[]    = g 
    end
end

#= Affiche un message d'erreur à l'emplacement du graphe. =#
function affiche_erreur(ax_graphe::Axis, message::String, texte_erreur::Ref{Any})
    if !isnothing(texte_erreur[])
        delete!(ax_graphe, texte_erreur[])
    end
    texte_erreur[] = text!(ax_graphe, message,
        position = (0.5, 0.5),
        align = (:center, :center),
        color = :red,
        fontsize = 20
    )
end

#=
La fonction calcule xQ et P.
Elle les sauvegarde dans un dossier pour que l'utilisateur puisse les récupérer
Enfin, elle les stocke dans leurs références respectives (xQ_ref et P_ref) pour lancer_animation().
=#
function preparer_donnees(x::Vector{Int16},
    xQ_ref::Ref{Union{Nothing, Vector{Int16}}},
    P_ref::Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}}},
    dossier_sauvegarde::String )

    xQ_ref[] = sous_quantifier(x)
    P_ref[]  = construire_p(x)

    mkpath(dossier_sauvegarde) #creation du dossier de sauvegarde
    sauvegarder_xq(xQ_ref[], joinpath(dossier_sauvegarde, "xQ.dat"))
    sauvegarder_p(P_ref[], joinpath(dossier_sauvegarde, "P.ppm"))
end


#=Prend en entrée l’axe dans lequel va s’afficher l’arbre pour afin de gérer les erreurs et retourne x.
Ouvre l’explorateur de fichier et charge la série s’il n’y a pas d’erreurs=#

function importer_fichier(ax_graphe::Axis, texte_erreur::Ref{Any})::Vector{Int16}

    chemin = pick_file()
    if chemin == ""
        return Int16[]
    end

    serie = open(chemin, "r") do fichier
        #=
        read() lit le fichier en octets et retourne donc Vector{UInt8}
        Il est donc nécessaire de les interpreter comme des entiers 16 bits (reinterpret) et de les convertir en tableau (collect)
        =#
        collect(reinterpret(Int16, read(fichier)))
    end

    #Traitement du cas où le fichier est vide
    if isempty(serie)
        affiche_erreur(ax_graphe, "Fichier vide.", texte_erreur)
        DEBUG && println("Fichier vide")
        return Int16[]
    end

    #Traitement du cas où le fichier ne possède pas asseez de données
    if length(serie) < 2
        affiche_erreur(ax_graphe, "Fichier contenant moins de deux valeurs", texte_erreur)
        DEBUG && println("Fichier contenant moins de deux valeurs")
        return Int16[]
    end

    return serie
end