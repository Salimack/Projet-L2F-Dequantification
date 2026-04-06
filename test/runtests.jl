using Test

@testset "Execution des tests" begin
    include("test_arbre.jl")
    include("test_construction.jl")
    include("test_dequantification.jl")
end