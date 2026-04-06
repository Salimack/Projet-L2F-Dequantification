# ============================================================
# test_dequantification.jl
# Teste toutes les fonctions de dequantification.jl
# ============================================================

using Test
include("../src/algorithme/dequantification.jl")

# ------ est_compatible ------
@testset "est_compatible" begin
    # on cree un noeud avec un histogramme qui autorise le couple (2, 3) une fois
    P = Dict{Tuple{Int16,Int16},Int}((Int16(2), Int16(3)) => 1, (Int16(2), Int16(4)) => 0)

    noeud = Noeud(Int16(2), P, false, nothing, Noeud[])

    # (2, 3) est dans P avec count > 0 -> compatible
    @test est_compatible(noeud, Int16(3)) == true

    # (2, 4) est dans P mais count = 0 -> pas compatible
    @test est_compatible(noeud, Int16(4)) == false

    # (2, 99) n'existe pas dans P -> pas compatible
    @test est_compatible(noeud, Int16(99)) == false
end

# ------ sauvegarder_solution ------
@testset "sauvegarder_solution" begin
    # on cree un dossier temporaire pour les tests
    dossier_temp = joinpath(@__DIR__, "data", "temp")
    mkpath(dossier_temp)

    solution = Int16[2, 3, 4, 5]
    compteur = Ref{Int}(0)

    chemin = sauvegarder_solution(solution, dossier_temp, compteur)

    # le compteur a ete incremente
    @test compteur[] == 1

    # le fichier existe
    @test isfile(chemin)

    # le nom du fichier est correct
    @test endswith(chemin, "solution_1.dat")

    # deuxieme appel -> solution_2.dat
    chemin2 = sauvegarder_solution(solution, dossier_temp, compteur)
    @test compteur[] == 2
    @test endswith(chemin2, "solution_2.dat")

    # nettoyage
    rm(chemin, force=true)
    rm(chemin2, force=true)
end

# ------ elaguer! ------
@testset "elaguer!" begin
    # arbre : racine(0) -> e1(2) -> e2(4)
    # si on elague e2, e1 devient feuille sans parent valide -> e1 aussi elague
    arbre = creer_arbre()
    arbre.racine = Noeud(Int16(0), nothing, false, nothing, Noeud[])

    e1 = ajouter_enfant!(arbre, arbre.racine, Int16(2), nothing, false)
    e2 = ajouter_enfant!(arbre, e1, Int16(4), nothing, false)

    @test arbre.nb_branches == 2

    elaguer!(arbre, e2)

    # e2 supprime, e1 devient feuille et se fait elaguer aussi
    @test arbre.nb_branches == 0
    @test isempty(arbre.racine.enfants)
end

@testset "elaguer! garde le frere" begin
    # arbre : racine(0) -> e1(2) avec deux enfants e2(4) et e3(5)
    # si on elague e2, e1 a encore e3 donc e1 reste
    arbre = creer_arbre()
    arbre.racine = Noeud(Int16(0), nothing, false, nothing, Noeud[])

    e1 = ajouter_enfant!(arbre, arbre.racine, Int16(2), nothing, false)
    e2 = ajouter_enfant!(arbre, e1, Int16(4), nothing, false)
    e3 = ajouter_enfant!(arbre, e1, Int16(5), nothing, true)

    @test arbre.nb_branches == 3

    elaguer!(arbre, e2)

    # e2 supprime mais e1 a encore e3 donc e1 reste
    @test arbre.nb_branches == 2
    @test length(e1.enfants) == 1
    @test e1.enfants[1].valeur == Int16(5)
end

# ------ dequantifier (test simple) ------
@testset "dequantifier cas simple" begin
    # signal original : x = [2, 3]
    # sous-quantifie : xQ = [2, 2]
    # P = histogramme des couples de x : (2, 3) apparait 1 fois
    xQ = Int16[2, 2]
    P = Dict{Tuple{Int16,Int16},Int}(
        (Int16(2), Int16(2)) => 0,
        (Int16(2), Int16(3)) => 1,
        (Int16(3), Int16(2)) => 0,
        (Int16(3), Int16(3)) => 0
    )

    # on recupere les solutions via le callback
    solutions_trouvees = String[]

    # callbacks bidon pour les tests (on sen fiche de laffichage)
    fonction_arbre(a) = nothing
    fonction_pourcent(p) = nothing
    fonction_solution(chemin) = push!(solutions_trouvees, chemin)

    dossier_temp = joinpath(@__DIR__, "data", "temp")
    mkpath(dossier_temp)

    dequantifier(xQ, P, fonction_arbre, fonction_pourcent, fonction_solution, dossier_temp)

    # on devrait trouver au moins une solution qui contient le couple (2, 3)
    @test length(solutions_trouvees) >= 1

    # nettoyage des fichiers generes
    for chemin in solutions_trouvees
        rm(chemin, force=true)
    end
end

@testset "dequantifier aucune solution" begin
    # xQ = [2, 2] mais P est vide -> aucun couple autorise -> 0 solutions
    xQ = Int16[2, 2]
    P = Dict{Tuple{Int16,Int16},Int}()

    solutions_trouvees = String[]

    fonction_arbre(a) = nothing
    fonction_pourcent(p) = nothing
    fonction_solution(chemin) = push!(solutions_trouvees, chemin)

    dossier_temp = joinpath(@__DIR__, "data", "temp")
    mkpath(dossier_temp)

    dequantifier(xQ, P, fonction_arbre, fonction_pourcent, fonction_solution, dossier_temp)

    # aucune solution possible
    @test length(solutions_trouvees) == 0
end