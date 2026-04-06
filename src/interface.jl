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

function creer_interface()

    #=========================================
    INITIALISATION DE LA FENETRE
    - GLMakie.activate() - initialise la fenetre, on force la fenetre a se placer en premier plan à l'ouverture
    Défintion de la taille de la fenetre et des marges de sécurité
    ===========================================# 
    GLMakie.activate!(title = "Projet de déquantification",focus_on_show  = true)
    figure = Figure(size = (1200, 500), figure_padding = 60, backgroundcolor = :lightgrey)

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

    #Observable du pourcentage des branches restantes
    pourcent_obs          = Observable(0.0)
    texte_dynamique = @lift(string(round($pourcent_obs, digits = 2)) * " %") #on arrondit à l'écran le pourcentage à 2 chiffres après la virgule

   
    #=On va gérer en parallèle le vecteur contenant toutes les solutions (solution_obs) et le vecteur(selection_obs) contenant les booléens qui enregistrent l'état des solutions (cochés ou pas/true ouo false) =#
    selection_obs = Observable(Bool[]) #Ovservables des solutions choisis par l'utilisateur
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

    #Observable du label du bouton d'importation. vaut "Importer x" en phase 1, ou alors "Importer xQ et P" en phase 2
    label_bouton_import   = @lift($prog_actuelle == 1 ? "Importer x" : "Importer xQ et P")

    #Observable de la couleur du pourcentage. Il sera affiché en vert s'il devient inferieur ou egal à 5%, rouge sinon
    couleur_pourcent      = @lift($pourcent_obs <= 5.0 ? :green : :red)

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
        contient les boutons "tout selectionner" et "exporter" ainsi que les solutions trouvées
    
    COLONNE DROITE
        contient l'arbre ainsi que les boutons de navigation (lancer et arrêter) et les boutons (importerx/xQ et P et telecharger xQ et P)
    ================================================#

    #COLONNE GAUCHE
    layout_gauche = figure[1, 1] = GridLayout(alignmode = Outside(20))
    colsize!(figure.layout, 1, Fixed(250))
    
    #sous-grille pour aligner les boutons
    layout_boutons_import = layout_gauche[2, 1] = GridLayout()
    bouton_tout_selectionner = Button(layout_boutons_import[1, 1], label = "Tout selectionner", height = 40, tellwidth = false)
    bouton_exporter = Button(layout_boutons_import[1, 2], label = "Exporter", height = 40, tellwidth = false)
    
    colgap!(layout_boutons_import, 100) #espace entre les boutons pour la clarté
    
    #Les solutions
    Label(layout_gauche[3, 1], "Liste des solutions :", halign = :left, padding = (0, 0, 10, 0))
    #liste_solutions = Menu(layout_gauche[4, 1], options = [""], tellwidth = false)

    layout_liste = layout_gauche[4,1] = GridLayout(halign =:left, tellheight=false)


    #Box invisible pour pousser tout le contenu vers le haut
    layout_gauche[5, 1] = Box(figure, visible = false) 
    rowsize!(layout_gauche, 5, Relative(1)) 

    #COLONNE DROITE
   layout_droite = figure[1, 2] = GridLayout()
   ax = Axis(layout_droite[1, 1], title = "Déquantification", titlesize=30,alignmode = Outside(10)) #zone de dessin
   hidedecorations!(ax) # On supprime les axes et les coordonnées

   #Les boutons en dessous de l'axis (zone de dessin)
   grille_bas = layout_droite[2, 1] = GridLayout(tellheight = true)

   # boutons de navigation et d'importation/exportation

   #bouton dynamique: soit importer x, soit importer xQ/P
    bouton_import    = Button(grille_bas[1, 1], label = label_bouton_import, height = 45, tellwidth = false)

    #bouton de lancemenent de l'algorithme
    bouton_lancer      = Button(grille_bas[1, 2], label = "Lancer", buttoncolor = couleur_bouton_lancer, height = 45, tellwidth = false)

    #bouton d'arrêt de l'algo
    bouton_arreter     = Button(grille_bas[1, 3], label = "Arrêter", buttoncolor = :tomato, height = 45, tellwidth = false)

    #bouton d'exportation du dossier contenant xQ et P
    bouton_telecharger_xQP = Button(grille_bas[1, 4], label = "Télécharger xQ et P", height = 45, tellwidth = false)

    # GESTION DE LESPACE
    rowsize!(layout_droite, 1, Relative(1))
    rowsize!(layout_droite, 2, Auto())

    # Espace entre les boutons et entre le graphe
    colgap!(grille_bas, 10)
    rowgap!(layout_droite, 10)

    # Dessin de l'arbre
   graphplot!(ax, graphe_obs,node_size  = 10,node_color = :blue,edge_color = :gray,arrow_show = false)
   
   # affichage dynamique du pourcentage
   text!(ax, 0, 0,
    text = texte_dynamique,    # On passe l'observable ici
    space = :relative, 
    align = (:left, :bottom), 
    offset = (15, 15), 
    fontsize = 24, 
    font = :bold, 
    color = couleur_pourcent) #si pourcentage <= 5%, il sera affiché en vert sinon en rouge


    #=============================================================================================
    fonctions passées à dequantifier
    Permet de lier l'interface directement à l'algorithme
    ========================================================================================#

    # met à jour le graphe affiché à chaque modification de l'arbre
    mis_a_jour_arbre_cb = (arbre) -> mis_a_jour_arbre(graphe_obs, arbre)

    # met à jour le pourcentage affiché
   mis_a_jour_pourcent_cb = (p) -> mis_a_jour_pourcent(pourcent_obs, p)

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
       println("Lancer cliqué, prog_actuelle = ", prog_actuelle[])
       println("xQ_charge = ", isnothing(xQ_charge[]) ? "nothing" : "chargé")
       println("P_charge = ", isnothing(P_charge[]) ? "nothing" : "chargé")
       if prog_actuelle[] == 2
        continuer[] = true
           lancer_animation(ax::Axis,texte_erreur::Ref{Any},xQ_charge, P_charge,est_lance,graphe_obs, pourcent_obs, solution_obs,mis_a_jour_arbre_cb, mis_a_jour_pourcent_cb,joinpath(DOSSIER_DATA, "temp"), continuer)
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
    chemin_solutions = solution_obs[]
    selection = selection_obs[]

    chemins_coches = String[]
    for i in 1:length(chemin_solutions)
        if selection[i] == true
            push!(chemins_coches, chemin_solutions[i])
        end
    end

       telecharger_solutions(chemins_coches, length(chemin_solutions))
   end

   # --- bouton tout sélectionner
   on(bouton_tout_selectionner.clicks) do x
       n = length(solution_obs[])
       if n>0
       #On met tous les booléens a true: signifie alors que tous les fichiers ont été coché par l'utilisateur
       selection_obs[] = fill(true, n)
       println("Toutes les solutions ont été sélectionné")
       end
   end


   #comportement de la liste des solutions
   on(solution_obs) do chemins
    foreach(delete!, contents(layout_liste))
    selection_obs[] = fill(false, length(chemins))
    for (i, chemins) in enumerate(chemins)
        nom_fichier = basename(chemins)

        # On crée la case à cocher
        cb = Checkbox(layout_liste[i, 1], checked = false)
        Label(layout_liste[i, 2], nom_fichier, halign = :left)

        on(cb.checked) do x
            selection_obs[][i] = x
        end
        
        # Quand on clique sur la case, on met à jour notre tableau de sélection
        on(selection_obs) do etat
            if i<= length(etat)
            cb.checked[] = etat[i]
            end
        end
    end
end

   #========================================================================
     affichage de la fenetre
    ========================================================================#
    println("OUVERTURE DE L'APPLICATION")
    display(figure)
    
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
    pourcent_obs::Observable{Float64},
    solution_obs::Observable{Vector{String}},
    mis_a_jour_arbre::Function,
    mis_a_jour_pourcent::Function,
    dossier::String, continuer
)
    println("lancer_animation appelé")

#=
Initialisation et réinitialisation
- verifie que les données sont chargées, prépare le dossier de sauvegarde et change l'etat est_lance à true
=#

#Verifie si les donnees sont chargées
    if isnothing(xQ_charge[]) || isnothing(P_charge[])
        println("Données manquantes")
        return
    end

    #reinitialise l'interface
    if !isnothing(texte_erreur[])
        delete!(ax_graphe, texte_erreur[])
        texte_erreur[] = nothing
    end
    graphe_obs[]   = SimpleDiGraph()
    pourcent_obs[] = 0.0
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
        println("@async commence")
        try
            ajouter_solution = (chemin_solution) -> begin
            #ajout de la solution dans liste
            liste = solution_obs[]
            push!(liste, chemin_solution)
            solution_obs[] = liste
            println("Solution ajoutée: ", basename(chemin_solution))
        end
            println("Avant déquantifier")
            dequantifier(
                xQ_charge[],
                P_charge[],
                mis_a_jour_arbre,
                mis_a_jour_pourcent,
                ajouter_solution,
                dossier, continuer
            )
        catch e
            println("ERREUR : ", e)
        finally
            est_lance[] = false

            #liste toutes les solutions du dossier
            #solution_obs[] = readdir(dossier, join=true)
            println("Nombre de solutions stockées: ", length(solution_obs[]))
        end
    end
    println("fin de lancer_animation")
end


function arreter_animation(est_lance::Observable{Bool}, continuer::Ref{Bool})
    est_lance[] = false #signal pour l'algorithme
    continuer[] = false #signal pour l'interface graphique
end


#= Met à jour le pourcentage affiché et la fluidité de l'interface =#
function mis_a_jour_pourcent(pourcent_obs::Observable, nouveau_pourcent::Float64)
    println("mis_a_jour_pourcent appelé avec ", nouveau_pourcent)
    pourcent_obs[] = nouveau_pourcent
    #=
    on gère la vitessse de l'animation
    =#
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
    println("Téléchargement de xq et P")
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
            println("Erreur: fichiers xQ et/ou P introuvables")
            trouve = false
        end

        if trouve

        xQ_charge[] = collect(reinterpret(Int16, read(xq)))
        P_charge[] = lire_p(p)
        println("Importation du dossier xQ et P")
        end
    end
    return 
end


#= 
Prend en entrée le vecteur des fichiers selectionnés par l'utilisateur et le nombre de solutions généré par le programme
Télécharge les solutions sélectionnées dans un dossier choisi par l'utilisateur
Si plusieurs fichiers, génère une archive ZIP =#
function telecharger_solutions(
    solutions_select::Vector{String},
    total::Int
)

    dossier_dest = pick_folder()
    if isempty(solutions_select) || dossier_dest == ""
        return nothing
    end

    #L'utilisateur a tout sélectionné
    if length(solutions_select) == total
        chemin_zip = joinpath(dossier_dest, "solutions.zip")
        w = ZipFile.Writer(chemin_zip)
            for chemin in solutions_select
                f = ZipFile.addfile(w, basename(chemin))

                #copie le fichier dans le zip
                write(f, read(chemin))
            end
            println("Toutes les solutions exportees dans un fichier Zip")
            close(w)
    
    #L'utilisateur n'a pas tout sélectionné
    else
        for chemin in solutions_select
            #copie 
            cp(chemin, joinpath(dossier_dest, basename(chemin)))
        end
        println("Solution[s] selectionnee[s] exportee[s]")
    end
end




#= Convertit notre structure Arbre en SimpleDiGraph pour que GraphMakie puisse le manipuler.
 Parcourt l'arbre en profondeur avec une pile pour éviter un dépassement de mémoire =#

function convertir_arbre(arbre::Arbre) ::SimpleDiGraph
    #=
    Initialisation
        -creation du graphe vide
        -creation du dictionnaire pour les indices
        SimpleDiGraph stocke des entiers pour représenter les noeuds.
        Ce dictionnaire va nous permettre de faire correspondre l'indice avec le noeud

        -creation de la pile avec la racine
    =#

    graphe = SimpleDiGraph()
    indices = Dict{Noeud, Int}()
    pile = [arbre.racine]


    #=
    Parcourt de l'arbre en profondeur
    =#
    while !isempty(pile)
        noeud = pop!(pile)

        # on ajoute un sommet pour ce noeud et on mémorise son indice
        add_vertex!(graphe)
        indices[noeud] = nv(graphe) #la fonction nv() nous donne l'indice du sommet ajouté

        # on relie ce noeud à son parent s'il en possède un
        if noeud.parent !== nothing
            add_edge!(graphe, indices[noeud.parent], indices[noeud]) #création d'une arête
        end

        # on finit par empiler les enfants
        for enfant in reverse(noeud.enfants)
            push!(pile, enfant)
        end
    end

    return graphe
end


#= Met à jour le graphe affiché à chaque modification de l'arbre
et convertit la structure Arbre en SimpleDiGraph pour GraphMakie =#
function mis_a_jour_arbre(graphe_obs::Observable, arbre::Arbre)
    println("Entree dans mis_a_jour_arbre")
    graphe_obs[] = convertir_arbre(arbre)
    println("Fin de mis_a_jour_arbre")
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
        println("Fichier vide")
        return Int16[]
    end

    #Traitement du cas où le fichier ne possède pas asseez de données
    if length(serie) < 2
        affiche_erreur(ax_graphe, "Fichier contenant moins de deux valeurs", texte_erreur)
        println("Fichier contenant moins de deux valeurs")
        return Int16[]
    end

    return serie
end