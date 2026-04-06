# test_arbre.jl
# teste toutes les fonctions de arbre.jl

using Test
include("../src/algorithme/arbre.jl")

@testset "creer_arbre" begin
    a = creer_arbre()
    # chez dina creer_arbre cree deja une racine
    @test a.racine !== nothing
    @test a.nb_branche == 0
end

@testset "est_feuille" begin
    a = creer_arbre()
    @test est_feuille(a.racine) == true

    P = Dict{Tuple{Int16,Int16},Int}((Int16(0), Int16(4)) => 1)
    ajouter_enfant!(a, a.racine, Int16(4), false, P)
    @test est_feuille(a.racine) == false
end

@testset "ajouter_enfant!" begin
    P = Dict{Tuple{Int16,Int16},Int}(
        (Int16(8), Int16(11)) => 3,
        (Int16(3), Int16(5)) => 1
    )

    a = creer_arbre()
    enfant = ajouter_enfant!(a, a.racine, Int16(4), false, P)

    @test length(a.racine.enfants) == 1
    @test enfant.valeur == Int16(4)
    @test enfant.pos == false
    @test enfant.histogramme !== nothing     # lenfant a une copie de P
    @test enfant.parent === a.racine
    @test a.nb_branche == 1
end

@testset "supprimer_noeud!" begin
    P = Dict{Tuple{Int16,Int16},Int}(
        (Int16(8), Int16(11)) => 3,
        (Int16(3), Int16(5)) => 1
    )

    a = creer_arbre()
    e1 = ajouter_enfant!(a, a.racine, Int16(4), false, P)
    e2 = ajouter_enfant!(a, a.racine, Int16(5), true, P)

    supprimer_noeud!(a, a.racine, e1)
    @test length(a.racine.enfants) == 1
    @test a.racine.enfants[1].valeur == Int16(5)
    @test a.nb_branche == 1
end

@testset "compter_branches" begin
    P = Dict{Tuple{Int16,Int16},Int}((Int16(2), Int16(4)) => 2, (Int16(2), Int16(5)) => 5)

    a = creer_arbre()
    e1 = ajouter_enfant!(a, a.racine, Int16(4), false, P)
    e2 = ajouter_enfant!(a, a.racine, Int16(5), true, P)

    # compter_branches prend un Noeud chez dina et compte les feuilles par recursion
    @test compter_branches(a.racine) == 2
end

@testset "extraire_serie" begin
    P = Dict{Tuple{Int16,Int16},Int}((Int16(0), Int16(2)) => 1, (Int16(2), Int16(3)) => 1, (Int16(3), Int16(4)) => 1)

    a = creer_arbre()
    e1 = ajouter_enfant!(a, a.racine, Int16(2), false, P)
    e2 = ajouter_enfant!(a, e1, Int16(3), true, P)
    e3 = ajouter_enfant!(a, e2, Int16(4), false, P)

    serie = extraire_serie(e3)
    # extraire_serie de dina remonte jusqua noeud !== nothing
    # donc ca inclut la racine (valeur 0)
    @test serie == [Int16(0), Int16(2), Int16(3), Int16(4)]
end