using Pkg
Pkg.activate(@__DIR__)

using Documenter
using L2F2_Dequantification_App


makedocs(
    modules = [L2F2_Dequantification_App],
    sitename = "Déquant-App de L2F2",
    format = Documenter.HTML(prettyurls = false),
    remotes = nothing,
    warnonly = true ,
    pages = [
        "Accueil" => "index.md",
        "arbre.jl" => "arbre.jl.md",
        "construction.jl" => "construction.jl.md",
        "dequantification" => "dequantification.jl.md",
        "interface.jl" => "interface.jl.md"
    ]
)