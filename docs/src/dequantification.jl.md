# dequantification.jl

Ce module est le programme principal de l'application.

Il prend en entrée `xQ` et `P` produits par `construction.jl` et reconstruit toutes les séries qu'il peut trouver via la construction et l'élagage de l'arbre binaire qu'on parcourt en profondeur.

Il génère et sauvegarde toutes les solutions trouvées dans le format `.dat` dans le dossier data/temp de l'application.

`x` doit figurer parmi les solutions trouvées.

Ce module dépend de `arbre.jl`.

## API

```@autodocs
Modules = [L2F2_Dequantification_App]
Pages = ["dequantification.jl"]
```