# test_dequantification.jl
# teste toutes les fonctions de dequantification.jl

using Test
include("../src/algorithme/dequantification.jl")

# ------ est_compatible ------
@testset "est_compatible" begin
    P = Dict{Tuple{Int16,Int16},Int}((Int16(2), Int16(3)) => 1, (Int16(2), Int16(4)) => 0)

    # ordre des champs chez dina : (valeur, parent, pos, enfants, histogramme)
    noeud = Noeud(Int16(2), nothing, false, Noeud[], P)

    # (2, 3) est dans P avec count > 0 -> compatible
    @test est_compatible(noeud, Int16(3)) == true

    # (2, 4) est dans P mais count = 0 -> pas compatible
    @test est_compatible(noeud, Int16(4)) == false

    # (2, 99) nexiste pas dans P -> pas compatible
    @test est_compatible(noeud, Int16(99)) == false
end

# ------ sauvegarder_solution ------
@testset "sauvegarder_solution" begin
    dossier_temp = joinpath(@__DIR__, "data", "temp")
    mkpath(dossier_temp)

    solution = Int16[2, 3, 4, 5]
    compteur = Ref{Int}(0)

    chemin = sauvegarder_solution(solution, dossier_temp, compteur)

    @test compteur[] == 1
    @test isfile(chemin)
    @test endswith(chemin, "solution_1.dat")

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

    P = Dict{Tuple{Int16,Int16},Int}((Int16(0), Int16(2)) => 1, (Int16(2), Int16(4)) => 1)
    e1 = ajouter_enfant!(arbre, arbre.racine, Int16(2), false, P)
    e2 = ajouter_enfant!(arbre, e1, Int16(4), false, P)

    @test arbre.nb_branche == 2

    elaguer!(arbre, e2)

    # e2 supprime, e1 devient feuille et se fait elaguer aussi
    @test arbre.nb_branche == 0
    @test isempty(arbre.racine.enfants)
end

@testset "elaguer! garde le frere" begin
    arbre = creer_arbre()

    P = Dict{Tuple{Int16,Int16},Int}((Int16(0), Int16(2)) => 1, (Int16(2), Int16(4)) => 1, (Int16(2), Int16(5)) => 1)
    e1 = ajouter_enfant!(arbre, arbre.racine, Int16(2), false, P)
    e2 = ajouter_enfant!(arbre, e1, Int16(4), false, P)
    e3 = ajouter_enfant!(arbre, e1, Int16(5), true, P)

    @test arbre.nb_branche == 3

    elaguer!(arbre, e2)

    # e2 supprime mais e1 a encore e3 donc e1 reste
    @test arbre.nb_branche == 2
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

    solutions_trouvees = String[]

    # callbacks bidon pour les tests
    fonction_arbre(a) = nothing
    fonction_pourcent(p) = nothing
    fonction_solution(chemin) = push!(solutions_trouvees, chemin)

    dossier_temp = joinpath(@__DIR__, "data", "temp")
    mkpath(dossier_temp)

    # est_lance a true pour que lalgo tourne jusquau bout
    est_lance = Ref{Bool}(true)

    dequantifier(xQ, P, fonction_arbre, fonction_pourcent, fonction_solution, dossier_temp, est_lance)

    @test length(solutions_trouvees) >= 1

    for chemin in solutions_trouvees
        rm(chemin, force=true)
    end
end

@testset "dequantifier aucune solution" begin
    # P vide -> aucun couple autorise -> 0 solutions
    xQ = Int16[2, 2]
    P = Dict{Tuple{Int16,Int16},Int}()

    solutions_trouvees = String[]

    fonction_arbre(a) = nothing
    fonction_pourcent(p) = nothing
    fonction_solution(chemin) = push!(solutions_trouvees, chemin)

    dossier_temp = joinpath(@__DIR__, "data", "temp")
    mkpath(dossier_temp)

    est_lance = Ref{Bool}(true)

    dequantifier(xQ, P, fonction_arbre, fonction_pourcent, fonction_solution, dossier_temp, est_lance)

    @test length(solutions_trouvees) == 0
end