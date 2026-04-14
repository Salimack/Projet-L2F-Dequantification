#===========================================================
Ce module gère l'interface graphique de l'application L2F2.
Il dépend de GLMakie, GraphMakie, NativeFileDialog et ZipFile.
=====================================#

using GLMakie
using Graphs
using GraphMakie
using NativeFileDialog
using ZipFile

const DOSSIER_DATA = joinpath(dirname(@__FILE__), "data")
const DEBUG = true

function creer_interface()

    GLMakie.activate!(title = "L2F2 — Déquantification", focus_on_show = true)
    figure = Figure(size = (1300, 660), figure_padding = 30, backgroundcolor = RGBf(0.10, 0.11, 0.14))

    mkpath(joinpath(DOSSIER_DATA, "temp"))
    for f in readdir(joinpath(DOSSIER_DATA, "temp"), join=true)
        rm(f)
    end

    graphe_obs        = Observable(SimpleDiGraph())
    positions_obs     = Observable(Point2f[])
    branches_obs      = Observable(0)
    texte_dynamique   = @lift(string($branches_obs) * " branche(s)")
    progression_obs   = Observable((0, 0))
    texte_progression = @lift begin
        niv, tot = $progression_obs
        tot > 0 ? "Niveau $niv" : ""
    end
    texte_taille = @lift begin
        niv, tot = $progression_obs
        tot > 0 ? "Signal : $tot valeurs" : ""
    end
    solution_obs      = Observable(String[])
    prog_actuelle     = Observable(1)
    est_lance         = Observable(false)
    continuer         = Ref{Bool}(true)
    texte_erreur      = Ref{Any}(nothing)
    total_branches_ref = Ref{Int}(1)
    label_bouton_import = @lift($prog_actuelle == 1 ? "Importer x" : "Importer xQ et P")
    couleur_branche   = @lift($branches_obs / total_branches_ref[] * 100 <= 5.0 ? :green : :red)
    couleur_bouton_lancer = @lift($prog_actuelle == 2 ? :green : :lightgray)
    xQ_charge = Ref{Union{Nothing, Vector{Int16}}}(nothing)
    P_charge  = Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}}}(nothing)

    layout_gauche = figure[1, 1] = GridLayout(alignmode = Outside(20))
    colsize!(figure.layout, 1, Fixed(250))

    layout_boutons_import = layout_gauche[2, 1] = GridLayout()
    bouton_exporter = Button(layout_boutons_import[1, 1], label = "Exporter les solutions", height = 38, tellwidth = false, buttoncolor = RGBf(0.22, 0.52, 0.95), labelcolor = :white, font = :bold, strokewidth = 0)
    colgap!(layout_boutons_import, 100)

    Label(layout_gauche[3, 1], "Liste des solutions :", halign = :left, padding = (0, 0, 10, 0), fontsize=13, font=:bold, color = RGBf(0.55, 0.58, 0.65))

    ax_liste = Axis(layout_gauche[4, 1],
        backgroundcolor = RGBf(0.10, 0.11, 0.14),
        xgridvisible = false, ygridvisible = false
    )
    hidedecorations!(ax_liste)
    hidespines!(ax_liste)
    rowsize!(layout_gauche, 4, Relative(1))
    scroll_offset = Ref{Int}(0)
    MAX_VIS = 16

    layout_droite = figure[1, 2] = GridLayout()
    ax = Axis(layout_droite[1, 1], title = "Déquantification", titlesize=24, titlecolor = RGBf(0.88, 0.90, 0.95), backgroundcolor = RGBf(0.08, 0.09, 0.11), alignmode = Outside(10))
    hidedecorations!(ax)

    grille_bas = layout_droite[2, 1] = GridLayout(tellheight = true)

    bouton_import = Button(grille_bas[1, 1], label = label_bouton_import, height = 42, tellwidth = false, font = :bold, buttoncolor = RGBf(0.20, 0.22, 0.28), labelcolor = RGBf(0.88, 0.90, 0.95), strokewidth = 0)
    bouton_lancer = Button(grille_bas[1, 2], label = "Lancer", buttoncolor = couleur_bouton_lancer, height = 42, tellwidth = false, font = :bold, labelcolor = :white, strokewidth = 0)
    bouton_arreter = Button(grille_bas[1, 3], label = "Arrêter", buttoncolor = RGBf(0.88, 0.28, 0.22), height = 42, tellwidth = false, font = :bold, labelcolor = :white, strokewidth = 0)
    bouton_telecharger_xQP = Button(grille_bas[1, 4], label = "Télécharger xQ et P", height = 42, tellwidth = false, font = :bold, buttoncolor = RGBf(0.20, 0.22, 0.28), labelcolor = RGBf(0.88, 0.90, 0.95), strokewidth = 0)

    rowsize!(layout_droite, 1, Relative(1))
    rowsize!(layout_droite, 2, Auto())
    colgap!(grille_bas, 10)
    rowgap!(layout_droite, 10)

    graphplot!(ax, graphe_obs, layout = _ -> positions_obs[], node_size = 12, node_color = RGBf(0.22, 0.52, 0.95), edge_color = RGBf(0.30, 0.33, 0.40), arrow_show = false)

    text!(ax, 0, 0,
        text = texte_dynamique,
        space = :relative, align = (:left, :bottom),
        offset = (15, 15), fontsize = 22, font = :bold, color = couleur_branche)

    text!(ax, 1, 0,
        text = texte_progression,
        space = :relative, align = (:right, :bottom),
        offset = (-15, 38), fontsize = 14, font = :bold,
        color = RGBf(0.55, 0.58, 0.65))

    text!(ax, 1, 0,
        text = texte_taille,
        space = :relative, align = (:right, :bottom),
        offset = (-15, 15), fontsize = 14,
        color = RGBf(0.45, 0.48, 0.55))

    mis_a_jour_arbre_cb = (arbre) -> mis_a_jour_arbre(graphe_obs, positions_obs, arbre)

    function mis_a_jour_branches(branches_obs::Observable, nb_branches::Int)
        DEBUG && println("mis_a_jour_branches appelé avec ", nb_branches)
        branches_obs[] = nb_branches
        sleep(0.0)
    end

    mis_a_jour_branches_cb = (n) -> begin
        mis_a_jour_branches(branches_obs, n)
    end

    mis_a_jour_progression_cb = (niv, tot) -> begin
        progression_obs[] = (niv, tot)
    end

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

    on(bouton_telecharger_xQP.clicks) do x
        if prog_actuelle[] == 2
            telecharger_xQP(DOSSIER_DATA)
        end
    end

    on(bouton_lancer.clicks) do _
        DEBUG && println("Lancer cliqué, prog_actuelle = ", prog_actuelle[])
        if prog_actuelle[] == 2
            continuer[] = true
            progression_obs[] = (0, 0)
            lancer_animation(ax, texte_erreur, xQ_charge, P_charge, est_lance, graphe_obs, branches_obs, solution_obs, mis_a_jour_arbre_cb, mis_a_jour_branches_cb, mis_a_jour_progression_cb, joinpath(DOSSIER_DATA, "temp"), continuer)
        end
    end

    on(graphe_obs) do _
        autolimits!(ax)
    end

    on(bouton_arreter.clicks) do x
        arreter_animation(est_lance, continuer)
    end

    on(bouton_exporter.clicks) do x
        telecharger_solutions(solution_obs[])
    end

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

    DEBUG && println("OUVERTURE DE L'APPLICATION")
    display(figure)
    wait(display(figure))
end


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
    mis_a_jour_progression::Function,
    dossier::String, continuer
)
    DEBUG && println("lancer_animation appelé")

    if isnothing(xQ_charge[]) || isnothing(P_charge[])
        DEBUG && println("Données manquantes")
        return
    end

    if !isnothing(texte_erreur[])
        delete!(ax_graphe, texte_erreur[])
        texte_erreur[] = nothing
    end
    graphe_obs[]   = SimpleDiGraph()
    branches_obs[] = 0
    solution_obs[] = String[]

    mkpath(dossier)
    for f in readdir(dossier, join=true)
        rm(f)
    end

    est_lance[] = true

    @async begin
        DEBUG && println("@async commence")
        try
            ajouter_solution = (chemin_solution) -> begin
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
            mis_a_jour_progression,
            ajouter_solution,
            dossier,
            continuer
        )
        catch e
            DEBUG && println("ERREUR : ", e)
        finally
            est_lance[] = false
            DEBUG && println("Nombre de solutions stockées: ", length(solution_obs[]))
        end
    end
    DEBUG && println("fin de lancer_animation")
end


function arreter_animation(est_lance::Observable{Bool}, continuer::Ref{Bool})
    est_lance[] = false
    continuer[] = false
end


function mis_a_jour_branches(branches_obs::Observable, nb_branches::Int)
    DEBUG && println("mis_a_jour_branches appelé avec ", nb_branches)
    branches_obs[] = nb_branches
    sleep(0.1)
end


function telecharger_xQP(dossier_source::String)
    dossier_dest = pick_folder()
    if dossier_dest == "" || isnothing(dossier_dest)
        return
    end
    dossier_xQP = joinpath(dossier_dest, "xQP")
    mkpath(dossier_xQP)
    cp(joinpath(dossier_source, "xQ.dat"), joinpath(dossier_xQP, "xQ.dat"), force=true)
    cp(joinpath(dossier_source, "P.ppm"),  joinpath(dossier_xQP, "P.ppm"), force=true)
    DEBUG && println("Téléchargement de xq et P")
end


function importer_xQP(
    ax_graphe::Axis,
    xQ_charge::Ref{Union{Nothing, Vector{Int16}}},
    P_charge::Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}}},
    texte_erreur::Ref{Any})

    trouve = true
    dossier = pick_folder()
    if dossier == ""
        trouve = false
    end
    xq = ""
    p  = ""
    if trouve
        liste_fichiers = readdir(dossier, join=true)
        for fichier in liste_fichiers
            if endswith(fichier, ".dat")
                xq = fichier
            elseif endswith(fichier, ".ppm")
                p = fichier
            end
        end
        if xq == "" || p == ""
            affiche_erreur(ax_graphe, "Fichiers xQ et/ou P introuvables.", texte_erreur)
            DEBUG && println("Erreur: fichiers xQ et/ou P introuvables")
            trouve = false
        end
        if trouve
            xQ_charge[] = collect(reinterpret(Int16, read(xq)))
            P_charge[]  = lire_p(p)
            DEBUG && println("Importation du dossier xQ et P")
        end
    end
    return
end


function telecharger_solutions(solutions::Vector{String})
    dossier_dest = pick_folder()
    if isempty(solutions) || dossier_dest == ""
        return nothing
    end
    chemin_zip = joinpath(dossier_dest, "solutions_trouvees.zip")
    w = ZipFile.Writer(chemin_zip)
    for chemin in solutions
        f = ZipFile.addfile(w, basename(chemin))
        write(f, read(chemin))
    end
    close(w)
    DEBUG && println("Toutes les solutions exportees dans un fichier Zip")
end


function indexer_noeuds!(graphe::SimpleDiGraph, noeud::Noeud, indices::Dict{Noeud,Int})
    add_vertex!(graphe)
    indices[noeud] = nv(graphe)
    for enfant in noeud.enfants
        indexer_noeuds!(graphe, enfant, indices)
    end
end

function relier_aretes!(graphe::SimpleDiGraph, noeud::Noeud, indices::Dict{Noeud,Int})
    for enfant in noeud.enfants
        add_edge!(graphe, indices[noeud], indices[enfant])
        relier_aretes!(graphe, enfant, indices)
    end
end

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

function calculer_profondeur!(noeud::Noeud, profondeurs::Dict{Noeud,Int}, prof::Int)
    profondeurs[noeud] = prof
    for enfant in noeud.enfants
        calculer_profondeur!(enfant, profondeurs, prof + 1)
    end
end

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
    return graphe, positions
end

function mis_a_jour_arbre(graphe_obs::Observable, positions_obs::Observable, arbre::Arbre)
    g, pos = convertir_arbre(arbre)
    if nv(g) == 0
        graphe_obs[]    = SimpleDiGraph(1)
        positions_obs[] = [Point2f(0.5, 0.0)]
    else
        positions_obs[] = pos
        graphe_obs[]    = g
    end
    yield()
end

function affiche_erreur(ax_graphe::Axis, message::String, texte_erreur::Ref{Any})
    if !isnothing(texte_erreur[])
        delete!(ax_graphe, texte_erreur[])
    end
    texte_erreur[] = text!(ax_graphe, message,
        position = (0.5, 0.5), align = (:center, :center),
        color = :red, fontsize = 20
    )
end

function preparer_donnees(x::Vector{Int16},
    xQ_ref::Ref{Union{Nothing, Vector{Int16}}},
    P_ref::Ref{Union{Nothing, Dict{Tuple{Int16,Int16}, Int}}},
    dossier_sauvegarde::String)
    xQ_ref[] = sous_quantifier(x)
    P_ref[]  = construire_p(x)
    mkpath(dossier_sauvegarde)
    sauvegarder_xq(xQ_ref[], joinpath(dossier_sauvegarde, "xQ.dat"))
    sauvegarder_p(P_ref[],   joinpath(dossier_sauvegarde, "P.ppm"))
end

function importer_fichier(ax_graphe::Axis, texte_erreur::Ref{Any})::Vector{Int16}
    chemin = pick_file()
    if chemin == ""
        return Int16[]
    end
    serie = open(chemin, "r") do fichier
        collect(reinterpret(Int16, read(fichier)))
    end
    if isempty(serie)
        affiche_erreur(ax_graphe, "Fichier vide.", texte_erreur)
        return Int16[]
    end
    if length(serie) < 2
        affiche_erreur(ax_graphe, "Fichier contenant moins de deux valeurs", texte_erreur)
        return Int16[]
    end
    return serie
end
