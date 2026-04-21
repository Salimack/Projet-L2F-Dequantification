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


const DOSSIER_DATA = joinpath(dirname(@__FILE__), "data")
const DEBUG_INTERFACE = false

"""
    creer_interface()::Nothing

Initialise la fenêtre et réinitialise le dossier de sauvegarde des solutions trouvées lors de la dérnière session.
Initialise tous les observables définis.
Crée les layout.
Définit le comportement lié aux boutons.
"""
function creer_interface()

    #=========================================
    INITIALISATION DE LA FENETRE
    - GLMakie.activate() - initialise la fenetre, on force la fenetre a se placer en premier plan à l'ouverture
    Défintion de la taille de la fenetre et des marges de sécurité
    ===========================================# 
    GLMakie.activate!(title = "Projet de déquantification",focus_on_show  = true)
    figure = Figure(size = (1200, 500), figure_padding = 60, backgroundcolor = :lightblue)

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
    #changement dynamique du texte affiché à l'écran
    texte_dynamique = @lift(string($branches_obs) * " branche(s)") 

    #Observable des solutions restantes.
    solution_obs          = Observable(String[])  

    #Observable indiquant si l'animation est en cours. Vaut true si elle l'est, false sinon
    est_lance             = Observable(false)

    # Ref{Bool} passé à l'algorithme pour l'interrompre
    continuer = Ref{Bool}(true)

    #texte d'erreur affiché dans l'axe
    texte_erreur = Ref{Any}(nothing)

    #texte de succès affiché à l'ecran
    message_succes_obs = Observable("")
    
    #couleur des noeuds
    couleurs_obs = Observable(Vector{Symbol}())


    #========================================================
     Données chargées par l"utilisateur
     Les variables suivantes valent nothing si rien n'a été chargé
    =========================================================#
    xQ_charge = Ref{Union{Nothing, Vector{Int16}}}(nothing)
    P_charge  = Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}}}(nothing)


    #====================================================
    Layout et les boutons
    L'intarface est divisée comme suit
    COLONNE GAUCHE
        contient le bouton "exporter les solutions" et le bouton "telecharger xQ et P"
    
    COLONNE DROITE
        contient l'arbre ainsi que les boutons de navigation (lancer et arrêter) et les boutons (importerx/importer xQ et P)
    ================================================#

    #COLONNE GAUCHE
    layout_gauche = figure[1, 1] = GridLayout(alignmode = Outside(20))
    colsize!(figure.layout, 1, Fixed(270))
    
    #sous-grille pour aligner les boutons
    layout_boutons_export = layout_gauche[2, 1] = GridLayout()
    bouton_exporter = Button(layout_boutons_export[1, 1], label = "Exporter les solutions", height = 40, tellwidth = false)
    bouton_telecharger_xQP = Button(layout_boutons_export[1,2], label = "Telecharger xQ et P",height = 40, tellwidth = false)
    
    colgap!(layout_boutons_export,120) #espace entre les boutons pour la clarté
    
    #Les solutions
    Label(layout_gauche[3, 1], "Liste des solutions :", halign = :left, padding = (0, 0, 10, 0), fontsize=18, font=:bold)
    layout_liste = layout_gauche[4,1] = GridLayout(halign =:left, valign = :top, tellheight=false)

    #Box invisible pour pousser tout le contenu vers le haut
    layout_gauche[9, 1] = Box(figure, visible = false) 
    rowsize!(layout_gauche, 9, Relative(1)) 

    #COLONNE DROITE
   layout_droite = figure[1, 2] = GridLayout()
   ax = Axis(layout_droite[1, 1], title = "Déquantification", titlesize=30,alignmode = Outside(10)) #zone de dessin
   hidedecorations!(ax) # On supprime les axes et les coordonnées



   #Les boutons en dessous de l'axis (zone de dessin)
   grille_bas = layout_droite[2, 1] = GridLayout(tellheight = true)
   #Message de succes
   label_succes = Label(grille_bas[1,0], text = message_succes_obs, font = :bold,fontsize= 16, color = :green)
 
   #bouton d'importation x
    bouton_import    = Button(grille_bas[1, 1], label = "Importer x", height = 45, tellwidth = false,font = :bold)

    #bouton de lancemenent de l'algorithme
    bouton_lancer      = Button(grille_bas[1, 2], label = "Lancer", buttoncolor = :green, height = 45, tellwidth = false,font = :bold)

    #bouton d'arrêt de l'algo
    bouton_arreter     = Button(grille_bas[1, 3], label = "Arrêter", buttoncolor = :tomato, height = 45, tellwidth = false,font = :bold)

    #bouton d'importation du dossier contenant xQ et P
    bouton_import_xQP = Button(grille_bas[1, 4], label = "Importer xQ et P", height = 45, tellwidth = false, font = :bold)

    # GESTION DE LESPACE
    rowsize!(layout_droite, 1, Relative(1))
    rowsize!(layout_droite, 2, Auto())

    # Espace entre les boutons et entre le graphe
    colgap!(grille_bas, 10)
    rowgap!(layout_droite, 10)

    # Dessin de l'arbre
    graphplot!(ax, graphe_obs, layout = _ -> positions_obs[], node_size = 20, node_color = couleurs_obs, edge_color = :gray, arrow_show = false)

   
   # affichage du nombre de branches affiché à l'écran
   text!(ax, 0, 0,
    text = texte_dynamique, 
    space = :relative, 
    align = (:left, :bottom), 
    offset = (15, 15), 
    fontsize = 24, 
    font = :bold)


    #=============================================================================================
    fonctions passées à dequantifier
    Permet de lier l'interface directement à l'algorithme
    ========================================================================================#

    # met à jour le graphe affiché à chaque modification de l'arbre
    mis_a_jour_arbre_cb = (arbre) -> mis_a_jour_arbre(graphe_obs, positions_obs, couleurs_obs, arbre)

    #met à jour le nombre de branches affiché
    mis_a_jour_branches_cb = (n) -> mis_a_jour_branches(branches_obs, n)
   mis_a_jour_branches_cb = (n) -> begin
    DEBUG_INTERFACE && println("mis_a_jour_branches appelé avec ", n)
    mis_a_jour_branches(branches_obs, n)
end

    #==============================================================
    EVENEMENTS
    On définit le comportement de chaque bouton
   ==================================================================#

   # bouton importer: charge les fichiers importés et affiche les messages d'erreur ou de réussite
   on(bouton_import.clicks) do x
    x = importer_fichier(ax, texte_erreur, message_succes_obs)
    if !isempty(x)
        preparer_donnees(x, xQ_charge, P_charge, DOSSIER_DATA)
    end
end
   
   #bouton importer le dossier xQ et P
   on(bouton_import_xQP.clicks) do x
    importer_xQP(ax, xQ_charge, P_charge, texte_erreur,message_succes_obs)
end

   #bouton télécharger xQ et P
   on(bouton_telecharger_xQP.clicks) do x
        telecharger_xQP(DOSSIER_DATA,message_succes_obs)
   end

   # bouton de lancement
   on(bouton_lancer.clicks) do _
       DEBUG_INTERFACE && println("Lancer cliqué")
       DEBUG_INTERFACE && println("xQ_charge = ", isnothing(xQ_charge[]) ? "nothing" : "chargé")
       DEBUG_INTERFACE && println("P_charge = ", isnothing(P_charge[]) ? "nothing" : "chargé")
       if !isnothing(xQ_charge[]) && !isnothing(P_charge[])
        continuer[] = true
        DEBUG_INTERFACE && println("Taille de P: ",length(P_charge[]))
        DEBUG_INTERFACE && println("Nombre d'occurence dans P du couple le plus frequent: ",maximum(values(P_charge[])))
        lancer_animation(ax::Axis,texte_erreur::Ref{Any},xQ_charge, P_charge,est_lance,graphe_obs, branches_obs, solution_obs,mis_a_jour_arbre_cb, mis_a_jour_branches_cb,joinpath(DOSSIER_DATA, "temp"), continuer)
       end
   end

   #Cadrage automatique du graphe
   on(graphe_obs) do _
    autolimits!(ax)
end

   # bouton arrêter ( géré grâce à la reference continuer)
   on(bouton_arreter.clicks) do x
       arreter_animation(est_lance, continuer)
   end

   # bouton exporter
   on(bouton_exporter.clicks) do x
       telecharger_solutions(solution_obs[],message_succes_obs)
   end


   #les solutions
   on(solution_obs) do chemins
    foreach(delete!, contents(layout_liste))
    for (i, chemins) in enumerate(chemins)
        Label(layout_liste[i, 1], basename(chemins), halign = :left)
    end
end

   #========================================================================
     affichage de la fenetre
    ========================================================================#
    println("OUVERTURE DE L'APPLICATION")
    display(figure)
    wait(display(figure))
end



"""
    lancer_animation(Axis x Ref{Any}xRef{Union{Nothing, Vector{Int16}}} x Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}}} x Observable{Bool} x Observable{SimpleDiGraph} x Observable{Float64}xObservable{Int} x Observable{Vector{String}}x FunctionxFunctionxString x Ref{Bool})::Nothing

Vérifie que les données sont chargées, réinitialise l'interface graphique, met à jour le dossier de sauvegarde et lance l'animation.

# Paramètres:
- l’axe dans lequel vit le graphe,
- la référence du texte d’erreur qui s’affichera à la place de l’arbre,
- les références vers xQ et P,
- l’observable est_lance indiquant que l’animation est en cours,
- l’observable graphe_obs contenant l’arbre et se mettant à jour au fur et à mesure de la déquantification,
- l’observable branche_obs mettant à jour le nombre de branches restantes,
- l’observable solutions_obs stockant toutes les solutions trouvées,
- les fonctions mis_a_jour_arbre, mis_a_jour_branches,
- le dossier de sauvegarde des solutions,
- la référence est_lance qui permet de mettre la reference continuer à false si l'utilisateur clique sur arrêter.
Note: continuer est la référence permettant de prévenir l'algorithme que l'utilisateur a cliqué sur arrêter.
"""
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
    DEBUG_INTERFACE && println("lancer_animation appelé")

#=
Initialisation et réinitialisation
- verifie que les données sont chargées, prépare le dossier de sauvegarde et change l'etat est_lance à true
=#

#Verifie si les donnees sont chargées
    if isnothing(xQ_charge[]) || isnothing(P_charge[])
        DEBUG_INTERFACE && println("Données manquantes")
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
    Lance l'algorithme en mode asynchrone pour garantir la mise à jour du nombre de branche et du graphe parallèlement.
    A l'issue, remet l'état de est_lance à false et liste toutes les solutions trouvées
    ========#
    @async begin
        DEBUG_INTERFACE && println("@async commence")
        try
            ajouter_solution = (chemin_solution) -> begin
            #ajout de la solution dans liste
            liste = solution_obs[]
            push!(liste, chemin_solution)
            solution_obs[] = liste
            DEBUG_INTERFACE && println("Solution ajoutée: ", basename(chemin_solution))
        end
            DEBUG_INTERFACE && println("Avant déquantifier")
            dequantifier(
                xQ_charge[],
                P_charge[],
                mis_a_jour_arbre,
                mis_a_jour_branches,
                ajouter_solution,
                dossier, continuer
            )
        catch e
            DEBUG_INTERFACE && println("ERREUR : ", e)
        finally
            #signal que l'algo se termine, quoi qu'il arrive
            est_lance[] = false

            #liste toutes les solutions du dossier
            #solution_obs[] = readdir(dossier, join=true)
            DEBUG_INTERFACE && println("Nombre de solutions stockées: ", length(solution_obs[]))
        end
    end
    DEBUG_INTERFACE && println("fin de lancer_animation")
end


"""
    arreter_animation(Observable{Bool})::Nothing

Arrête l'animation si l'utilisateur clique sur le bouton arrêter.

# Paramètres:
- la référence est_lance qui permet de prévenir l'algorithme que l'utilisateur a cliqué sur le bouton d'arrêt.
"""
function arreter_animation(est_lance::Observable{Bool}, continuer::Ref{Bool})
    est_lance[] = false #signal pour l'interface graphique
    continuer[] = false #signal pour l'algorithme
end



"""
    mis_a_jour_branches(Observable{Int} x Int)::Nothing
Met à jour le nombre de branches affiché à l'écran au fur et à mesure de l'animation.

# Paramètres:
- observable du nombre de branches.
- nouvelle valeur qu'on va mettre à jour.
"""
function mis_a_jour_branches(branches_obs::Observable, nb_branches::Int)
    DEBUG_INTERFACE && println("mis_a_jour_branches appelé avec ", nb_branches)
    branches_obs[] = nb_branches

    #on gère la vitessse de l'animation
    sleep(0.1) 
end



"""
    telecharger_xQP(String x Observable{String})::Nothing

Copie xQ.dat et P.ppm depuis le dossier de l'application vers un dossier choisi par l'utilisateur.

# Paramètres:
- dossier de sauvearde de xQ et P dans l'application.
- observable message_succes_obs permettant d'afficher un message pour indiquer que le téléchargement a réussi.
"""
function telecharger_xQP(dossier_source::String, message_succes_obs)
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
    affiche_succes(message_succes_obs, "Téléchargement de xQ et P réussi")
    DEBUG_INTERFACE && println("Téléchargement de xq et P")
end

"""
    importer_xQP(Axis x Ref{Union{Nothing, Vector{Int16}}} x Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}}} x Ref{Any} x Observable{String})::Nothing

Importe le dossier contenant `xQ` et `P` et indique à l'interface si le chargement a réussi.
Affiche un message d'erreur en cas d'erreur (fichiers non trouvables) ou un message de réussite en cas de succès.

# Paramètres:
- l'axe dans lequel seront affiché les messages d'erreurs.
- les références `xQ_charge` et `P_charge` permettant de notifier l'interface (notamment lancer_animation) que les données ont bien été chargé.
- référence du texte d'erreur
- observable du message de réussite
"""
function importer_xQP(
    ax_graphe::Axis,
    xQ_charge::Ref{Union{Nothing, Vector{Int16}}},
    P_charge::Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}}},
    texte_erreur::Ref{Any},
    message_succes_obs)

   
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
            DEBUG_INTERFACE && println("Erreur: fichiers xQ et/ou P introuvables")
            trouve = false
        end

        if trouve
            xQ_charge[] = lire_serie(xq)
            P_charge[] = lire_p(p)
            affiche_succes(message_succes_obs, "Importation du dossier xQ et P réussie")
            DEBUG_INTERFACE && println("Importation du dossier xQ et P")
        end
    end
    return 
end



"""
    telecharger_solutions(vector{String} x Observable{String})::Nothing

Télécharge les solutions dans un dossier choisi par l'utilisateur en format ZIP.

# Paramètres:
- liste des solutions générées
- observable du message de succès en cas de réussite du téléchargement.
"""
function telecharger_solutions(
    solutions::Vector{String},message_succes_obs
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
    affiche_succes(message_succes_obs, "Toutes les solutions ont été exporté avec succès")
    DEBUG_INTERFACE && println("Toutes les solutions exportees dans un fichier Zip")
end



#=============================================
CONSTRUCTION DE L ARBRE MANUELLEMENT
=================================================#

"""
    indexer_noeuds!(SimpleDiGraph x Noeud x Dict{Noeud,Int})::Nothing

Parcourt l'arbre en profondeur et donne identifiant unique à chaque noeud.

# Paramètres :
- `graphe` : le graphe auquel on ajoute les noeuds
- `noeud` : noeud courant à indexer
- `indices` : dictionnaire associant chaque noeud à son identifiant dans le graphe
"""
function indexer_noeuds!(graphe::SimpleDiGraph, noeud::Noeud, indices::Dict{Noeud,Int})
    #ajout d'un noeud
    add_vertex!(graphe)
    indices[noeud] = nv(graphe) #nv(graphe) renvoie le nombre de noeud actuel 
    for enfant in noeud.enfants
        indexer_noeuds!(graphe, enfant, indices)
    end
end


"""
    relier_aretes!(SimpleDiGraph x Noeud x Dict{Noeud,Int})::Nothing

Parcourt l'arbre en profondeur et relie chaque noeud à ses enfants dans le graphe.

# Paramètres :
- `graphe` : le graphe dans lequel on ajoute les arêtes
- `noeud` : noeud courant à traiter
- `indices` : dictionnaire associant chaque noeud à son identifiant dans le graphe
"""
function relier_aretes!(graphe::SimpleDiGraph, noeud::Noeud, indices::Dict{Noeud,Int})
    for enfant in noeud.enfants
        add_edge!(graphe, indices[noeud], indices[enfant])
        relier_aretes!(graphe, enfant, indices)
    end
end


"""
    calculer_x!(Noeud x Dict{Noeud,Float32} x Ref{Int})::Nothing

Calcule la position horizontale de chaque noeud pour l'affichage.  
Les feuilles sont placées de gauche à droite.  
Les autres noeuds sont au centre entre leurs enfants.

# Paramètres :
- `noeud` : noeud courant à traiter
- `x_pos` : dictionnaire associant chaque noeud à sa position horizontale
- `compteur` : compteur partagé incrémenté à chaque feuille rencontrée
"""
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


"""
    calculer_profondeur!(Noeud x Dict{Noeud,Int} x Int)::Nothing

Calcule la profondeur de chaque noeud dans l'arbre pour déterminer sa position verticale.  
La racine est à la profondeur 0, ses enfants sont à la profondeur 1 etc.

# Paramètres :
- `noeud` : noeud courant à traiter
- `profondeurs` : dictionnaire associant chaque noeud à sa profondeur
- `prof` : profondeur courante
"""
function calculer_profondeur!(noeud::Noeud, profondeurs::Dict{Noeud,Int}, prof::Int)
    profondeurs[noeud] = prof
    for enfant in noeud.enfants
        calculer_profondeur!(enfant, profondeurs, prof + 1)
    end
end


"""
    convertir_arbre(Arbre)::(SimpleDiGraph, Vector{Point2f})

Convertit la structure `Arbre` en un `SimpleDiGraph`.

# Paramètres :
- `arbre` : l'arbre à convertir

# Retourne :
- le graphe orienté représentant l'arbre
- un vecteur avec les positions de chaque noeud.
- un vecteur avec la couleur de chaque sommet (bleu si vivant, rouge sinon)
"""
function convertir_arbre(arbre::Arbre)
    graphe      = SimpleDiGraph()
    indices     = Dict{Noeud, Int}()
    x_pos       = Dict{Noeud, Float32}()
    profondeurs = Dict{Noeud, Int}()
    compteur    = Ref(0)

    indexer_noeuds!(graphe, arbre.racine, indices)
    relier_aretes!(graphe, arbre.racine, indices)
    calculer_x!(arbre.racine, x_pos, compteur)
    calculer_profondeur!(arbre.racine, profondeurs, 0)

    positions = Vector{Point2f}(undef, nv(graphe))
    for (noeud, i) in indices
        positions[i] = Point2f(x_pos[noeud], -Float32(profondeurs[noeud]))
    end

    couleurs = Vector{Symbol}(undef, nv(graphe))
    for (noeud, i) in indices
        couleurs[i] = noeud.vivant ? :blue : :red
    end

    return graphe, positions, couleurs
end


"""
    mis_a_jour_arbre(Observable x Observable x Observable x Arbre)::Nothing

Met à jour les observables du graphe et ses postions.

# Paramètres :
- `graphe_obs` : observable du graphe affiché
- `positions_obs` : observable des positions des noeuds
- `arbre` : l'arbre courant issu de l'algorithme
"""
function mis_a_jour_arbre(graphe_obs, positions_obs, couleurs_obs, arbre)
    g, pos, col = convertir_arbre(arbre)
    if nv(g) == 0
        graphe_obs[]    = SimpleDiGraph(1)
        positions_obs[] = [Point2f(0.5, 0.0)]
        couleurs_obs[]  = [:blue]
    else
        positions_obs[] = pos
        couleurs_obs[]  = col
        graphe_obs[]    = g
    end
end


"""
    affiche_erreur(Axis x String x Ref):: Nothing

Affiche un message d'erreur à l'ecran, dans l'emplacement (=`Axis`) du graphe.

# Paramètres:
- l'axe du graphe dans lequel va s'afficher le message d'erreur.
- le message.
- la référence du texte d'erreur
"""
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


"""
    affiche_succes(Observable{String} x String)::Nothing

Affiche un message de succès dans le cas où l'importation ou l'exportation des fichiers/dossiers réussit

# Paramètres:
- observable du message de réussite
- message de réussite
"""
function affiche_succes(message_succes_obs, texte::String)
    message_succes_obs[] = texte

    #disparition du message au bout de 3 secondes
    @async begin
        sleep(3)
        message_succes_obs[] = ""
    end
end

"""
    preparer_donnes(Vector{Int16} x Ref{Union{Nothing, Vector{Int16}}} x Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}} x String)

La fonction calcule xQ, la série sous-quantifiée à 1 bit de x et P l'histogramme des couples. Elle les sauvegarde dans un dossier pour que l'utilisateur puisse les récupérer et les stocke dans leurs références respectives (xQ_ref et P_ref) pour lancer_animation

# Paramètres:
- la série x
- référence de x
- référence de P
- dossier de sauvegarde
"""
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




"""
    importer_fichier(Axis x Ref x Observable{String}):: Vector{Int16}

Ouvre l'explorateur de fichiers natif et charge le fichier x séléctionné. 
En cas de réussite, affiche un message de réussite, sinon affiche un message d'erreurs dans l'emplacement du graphe.

# Paramètres:
- on passe en entrée l'axe du graphe afin de gérer les erreur
- référence `texte_erreur`
- observable `message_succès`
"""
function importer_fichier(ax_graphe::Axis, texte_erreur::Ref{Any},message_succes_obs)::Vector{Int16}

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
        DEBUG_INTERFACE && println("Fichier vide")
        return Int16[]
    end

    #Traitement du cas où le fichier ne possède pas assez de données
    if length(serie) < 2
        affiche_erreur(ax_graphe, "Fichier contenant moins de deux valeurs", texte_erreur)
        DEBUG_INTERFACE && println("Fichier contenant moins de deux valeurs")
        return Int16[]
    end
    affiche_succes(message_succes_obs, "Importation du fichier réussi")

    return serie
end