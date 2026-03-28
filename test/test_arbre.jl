# test_arbre.jl
# teste toutes les fonctions de arbre.jl

using Test
include("../src/algorithm/arbre.jl")

@testset "creer_arbre" begin
    a = creer_arbre()
    @test a.racine === nothing
    @test a.nb_branches == 0
end

@testset "est_feuille" begin
    a = creer_arbre()
    parent = Noeud(Int16(0), nothing, false, nothing, Noeud[])
    a.racine = parent
    @test est_feuille(parent) == true
    ajouter_enfant!(a, parent, Int16(4), nothing, false)
    @test est_feuille(parent) == false
end

@testset "ajouter_enfant!" begin
    a = creer_arbre()
    parent = Noeud(Int16(0), nothing, false, nothing, Noeud[])
    a.racine = parent
    enfant = ajouter_enfant!(a, parent, Int16(4), nothing, false)
    @test length(parent.enfants) == 1
    @test enfant.valeur == Int16(4)
    @test enfant.pos == false
    @test enfant.histogramme === nothing
    @test enfant.parent === parent
    @test a.nb_branches == 1
end

@testset "supprimer_noeud!" begin
    a = creer_arbre()
    parent = Noeud(Int16(0), nothing, false, nothing, Noeud[])
    a.racine = parent
    e1 = ajouter_enfant!(a, parent, Int16(4), nothing, false)
    e2 = ajouter_enfant!(a, parent, Int16(5), nothing, true)
    supprimer_noeud!(a, parent, e1)
    @test length(parent.enfants) == 1
    @test parent.enfants[1].valeur == Int16(5)
    @test a.nb_branches == 1
end

@testset "compter_branches" begin
    a = creer_arbre()
    parent = Noeud(Int16(0), nothing, false, nothing, Noeud[])
    a.racine = parent
    ajouter_enfant!(a, parent, Int16(4), nothing, false)
    ajouter_enfant!(a, parent, Int16(5), nothing, true)
    @test compter_branches(a) == 2
end

@testset "extraire_serie" begin
    a = creer_arbre()
    racine = Noeud(Int16(0), nothing, false, nothing, Noeud[])
    a.racine = racine
    e1 = ajouter_enfant!(a, racine, Int16(2), nothing, false)
    e2 = ajouter_enfant!(a, e1, Int16(3), nothing, true)
    e3 = ajouter_enfant!(a, e2, Int16(4), nothing, false)
    @test extraire_serie(e3) == [Int16(2), Int16(3), Int16(4)]
end