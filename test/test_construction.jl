# ============================================================
# test_construction.jl
# Teste toutes les fonctions de construction.jl
# ============================================================

using Test
include("../src/algorithme/construction.jl")

# ------ lire_serie ------
@testset "lire_serie" begin
    chemin_tmp = tempname()
    open(chemin_tmp, "w") do f
        write(f, Int16(2))
        write(f, Int16(4))
        write(f, Int16(7))
    end

    x = lire_serie(chemin_tmp)
    @test x == Int16[2, 4, 7]
    @test eltype(x) == Int16

    rm(chemin_tmp)

    @test_throws Exception lire_serie("fichier_qui_nexiste_pas.txt")
end

# ------ sous_quantifier ------
@testset "sous_quantifier" begin
    x = Int16[2, 3, 4, 5, 6, 7]
    xQ = sous_quantifier(x)

    @test xQ == Int16[2, 2, 4, 4, 6, 6]   # les impairs deviennent le pair inférieur
    @test xQ[1] == Int16(2)                # pair reste pair
    @test xQ[2] == Int16(2)                # 3 → 2
    @test xQ[4] == Int16(4)                # 5 → 4
end

# ------ construire_p ------
@testset "construire_p" begin
    x = Int16[2, 3, 2, 3]
    P = construire_p(x)

    # couples : (2,3), (3,2), (2,3) → (2,3) apparaît 2 fois, (3,2) 1 fois
    @test P[(Int16(2), Int16(3))] == 2
    @test P[(Int16(3), Int16(2))] == 1
    @test length(P) == 2

    # série d'un seul élément → P vide
    P2 = construire_p(Int16[5])
    @test isempty(P2)
end

# ------ sauvegarder_xq + lire_serie (aller-retour) ------
@testset "sauvegarder_xq" begin
    xQ = Int16[2, 4, 6]
    chemin_tmp = tempname()

    sauvegarder_xq(xQ, chemin_tmp)
    xQ_relu = lire_serie(chemin_tmp)

    @test xQ_relu == xQ

    rm(chemin_tmp)
end

# ------ sauvegarder_p + lire_p (aller-retour) ------
@testset "sauvegarder_p et lire_p" begin
    P = Dict{Tuple{Int16,Int16},Int}(
        (Int16(2), Int16(3)) => 2,
        (Int16(3), Int16(2)) => 1
    )
    chemin_tmp = tempname()

    sauvegarder_p(P, chemin_tmp)
    P_relu = lire_p(chemin_tmp)

    @test P_relu[(Int16(2), Int16(3))] == 2
    @test P_relu[(Int16(3), Int16(2))] == 1
    @test length(P_relu) == 2

    rm(chemin_tmp)
end