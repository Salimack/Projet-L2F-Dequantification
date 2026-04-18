# construction.jl

Ce module est le programme auxiliaire de l'application.

Il prend en entrée la série temporelle `x` au format binaire Int16 et génère `xQ`, la version sous-quantifiée à 1 bit de `x`, et `P`, l'histogramme des couples de valeurs successives de `x`.

`xQ` est sauvegardé dans un fichier `.dat` et `P` est sauvegardé dans un fichier `.ppm`.

Ces deux fichiers sont ensuite utilisés par le programme principal comme entrée.

Ce module n'a aucune dépendance interne ni externe.

## API

```@autodocs
Modules = [L2F2_Dequantification_App]
Pages = ["construction.jl"]
```