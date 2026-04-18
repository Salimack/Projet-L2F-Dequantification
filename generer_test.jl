# generer_test.jl
using Random

function generer_dat(n::Int, chemin::String)
    open(chemin, "w") do f
        for i in 1:n
            println(f, rand(Int16))
        end
    end
end

generer_dat(100, "x100N.dat")