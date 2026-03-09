# ============================================================
# test_arbre.jl
# Teste toutes les fonctions de arbre.jl
# ============================================================

using Test
include("../src/algorithm/arbre.jl")

# ------ creer_noeud ------
@testset "creer_noeud" begin
    n = creer_noeud(4)
    @test n.valeur == 4          # la valeur est bien 4
    @test n.enfants == Noeud[]   # la liste d'enfants est bien vide
end

# ------ est_feuille ------
@testset "est_feuille" begin
    n = creer_noeud(4)
    @test est_feuille(n) == true          # sans enfants = feuille

    ajouter_enfant!(n, 5)
    @test est_feuille(n) == false         # avec un enfant = plus une feuille
end

# ------ ajouter_enfant! ------
@testset "ajouter_enfant!" begin
    parent = creer_noeud(2)
    enfant = ajouter_enfant!(parent, 3)

    @test length(parent.enfants) == 1     # le parent a bien 1 enfant
    @test enfant.valeur == 3              # l'enfant a bien la valeur 3
    @test est_feuille(enfant) == true     # l'enfant n'a pas d'enfants
end

# ------ supprimer_noeud! ------
@testset "supprimer_noeud!" begin
    parent = creer_noeud(2)
    e1 = ajouter_enfant!(parent, 3)
    e2 = ajouter_enfant!(parent, 4)

    supprimer_noeud!(parent, e1)
    @test length(parent.enfants) == 1     # il reste 1 enfant
    @test parent.enfants[1].valeur == 4   # c'est bien e2 qui reste
end

# ------ compter_branches ------
@testset "compter_branches" begin
    # arbre :      0
    #            /   \
    #           2     3
    #          / \
    #         4   5
    # feuilles : 4, 5, 3  →  3 branches

    racine = creer_noeud(0)
    e1 = ajouter_enfant!(racine, 2)
    e2 = ajouter_enfant!(racine, 3)
    ajouter_enfant!(e1, 4)
    ajouter_enfant!(e1, 5)

    @test compter_branches(racine) == 3
end

# ------ extraire_serie ------
@testset "extraire_serie" begin
    seq = [2, 3, 4, 5]
    resultat = extraire_serie(seq)

    @test resultat == [2, 3, 4, 5]   # la série est bien retournée

    push!(seq, 99)                    # on modifie l'original
    @test resultat == [2, 3, 4, 5]   # le résultat n'a pas changé (copy)
end