# test_dequantification.jl
# teste toutes les fonctions de dequantification.jl

using Test
include("../src/algorithme/dequantification.jl")

# ------ est_compatible ------
@testset "est_compatible" begin
    P = Dict{Tuple{Int16,Int16},Int}((Int16(2), Int16(3)) => 1, (Int16(2), Int16(4)) => 0)

    noeud = Noeud(Int16(2), nothing, false, Noeud[], P)

    @test est_compatible(noeud, Int16(3)) == true
    @test est_compatible(noeud, Int16(4)) == false
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

    rm(chemin, force=true)
    rm(chemin2, force=true)
end

# ------ elaguer! ------
@testset "elaguer!" begin
    arbre = creer_arbre()

    P = Dict{Tuple{Int16,Int16},Int}((Int16(0), Int16(2)) => 1, (Int16(2), Int16(4)) => 1)
    e1 = ajouter_enfant!(arbre, arbre.racine, Int16(2), false, P)
    e2 = ajouter_enfant!(arbre, e1, Int16(4), false, P)

    @test arbre.nb_branche == 2

    elaguer!(arbre, e2)

    @test arbre.nb_branche == 1
    @test length(e1.enfants) == 0
end

@testset "elaguer! garde le frere" begin
    arbre = creer_arbre()

    P = Dict{Tuple{Int16,Int16},Int}((Int16(0), Int16(2)) => 1, (Int16(2), Int16(4)) => 1, (Int16(2), Int16(5)) => 1)
    e1 = ajouter_enfant!(arbre, arbre.racine, Int16(2), false, P)
    e2 = ajouter_enfant!(arbre, e1, Int16(4), false, P)
    e3 = ajouter_enfant!(arbre, e1, Int16(5), true, P)

    @test arbre.nb_branche == 3

    elaguer!(arbre, e2)

    @test arbre.nb_branche == 2
    @test length(e1.enfants) == 1
    @test e1.enfants[1].valeur == Int16(5)
end

# ------ dequantifier (test simple) ------
@testset "dequantifier cas simple" begin
    xQ = Int16[2, 2]
    P = Dict{Tuple{Int16,Int16},Int}(
        (Int16(2), Int16(2)) => 0,
        (Int16(2), Int16(3)) => 1,
        (Int16(3), Int16(2)) => 0,
        (Int16(3), Int16(3)) => 0
    )

    solutions_trouvees = String[]

    fonction_arbre(a) = nothing
    fonction_pourcent(p) = nothing
    fonction_progression(niv, tot) = nothing
    fonction_solution(chemin) = push!(solutions_trouvees, chemin)

    dossier_temp = joinpath(@__DIR__, "data", "temp")
    mkpath(dossier_temp)

    est_lance = Ref{Bool}(true)

    dequantifier(xQ, P, fonction_arbre, fonction_pourcent, fonction_progression, fonction_solution, dossier_temp, est_lance)

    @test length(solutions_trouvees) >= 1

    for chemin in solutions_trouvees
        rm(chemin, force=true)
    end
end

@testset "dequantifier aucune solution" begin
    xQ = Int16[2, 2]
    P = Dict{Tuple{Int16,Int16},Int}()

    solutions_trouvees = String[]

    fonction_arbre(a) = nothing
    fonction_pourcent(p) = nothing
    fonction_progression(niv, tot) = nothing
    fonction_solution(chemin) = push!(solutions_trouvees, chemin)

    dossier_temp = joinpath(@__DIR__, "data", "temp")
    mkpath(dossier_temp)

    est_lance = Ref{Bool}(true)

    dequantifier(xQ, P, fonction_arbre, fonction_pourcent, fonction_progression, fonction_solution, dossier_temp, est_lance)

    @test length(solutions_trouvees) == 0
end