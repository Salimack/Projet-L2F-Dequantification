# L2F2 — Documentation de l' application de déquantification

Vous vous trouvez sur la documentation officielle du projet L2F2, développé par Abdallah Benali, 
Dina Kangni, Salim Achak et Mohammed Zouad dans le cadre de l'UE Projet Professionnel de licence 
d'informatique à l'Université Paris Cité, sous la direction de Gaël Mahé.


# En quoi consisite l'application?

La quantification désigne l'opération qui consiste à représenter des valeurs continues sous forme 
discrète, en réduisant le nombre de bits utilisés. 

Nous nous concontrons sur la sous-quantification à 1 bit: elle consiste à supprimer le bit de poids faible de séries déjà discrètes , divisant par deux le nombre de valeurs représentables.

Cette opération est irréversible.

Ce projet consisite à tenter de retrouver la série originale ou un ensemble restreint de séries, à partir de sa 
version sous-quantifiée et de l'histogramme de ses couples de valeurs successives.


# Algorithme

Pour reconstruire `x` à partir de `xQ`, on exploite l'histogramme `P` des couples de valeurs successives de la série originale. `P` prend la forme d'un dictionnaire `Dict{Tuple{Int16,Int16}, Int}` avec chaque clé `(x[n-1], x[n])` qui représente le couple étudié et chaque valeur qui représente le nombre de fois que ce couple apparaît dans `x`.

Toutes les reconstructions possibles sont représentées par un arbre binaire. Chaque nœud détient une copie de `P`.
Lorsqu'un nœud crée un enfant, il vérifie que le couple formé est compatible avec son histogramme, puis le décrémente et le transmet à son fils. Si le couple est incompatible, l'enfant est élagué. Si l'élagage rend le parent feuille, celui-ci est élagué à son tour, récursivement, jusqu'à ce que son père soit la racine.

L'arbre est parcouru en profondeur. Une branche est une solution lorsque sa profondeur est égale à la taille de `xQ`.


# Modules

`arbre.jl`: Structures `Noeud` et `Arbre` et autres fonctions associées.

`construction.jl`: Programme auxiliaire, génère `xQ` et `P` à partir de `x`.

`dequantification.jl`: Programme principal, construit, élague l'arbre, prend en entrée xQ et P, génère toutes les solutions possibles.

`interface.jl`: Interface graphique.


# Pour plus d'informations

Vous pouvez télécharger les cahier des charges, de recette et les cahiers de conception générale et détaillée:

[Cahier de recette](assets/[L2F2]Cahier_de_recette_v1.0.pdf)

[Cahier des charges](assets/[L2F2]Cahier_des_charges_v1.0.pdf)

[Cahier de conception générale et détaillée](assets/[L2F2]Cahier_conception_generale_detaillee_v1.0.pdf)