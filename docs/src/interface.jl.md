# interface.jl

Ce module gère l'interface graphique de l'application. 


## Dépendances externes
- **GLMakie**: gère l'interface graphique: boutons, layout...
- **GraphMakie**: gère la visualisation de l'arbre binaire.
- **NativeFileDialog**: ouvre le sélecteur de fichiers natif du système.
- **ZipFile**: permet l'export des solutions dans une archive ZIP

L'interface se divise en deux colonnes. La colonne gauche affiche la liste des solutions trouvées, le bouton d'export et le bouton télécharger xQ et P. La colonne droite affiche l'arbre en cours de construction ainsi que les boutons de navigation : **Importer x**, **Lancer**, **Arrêter** et **Importer xQ et P**.

Le nombre de branches restantes est affiché en temps réel et mis à jour à chaque appel de la fonction `developper` du module **déquantification.jl**.

Ce module dépend de `dequantification.jl` et `arbre.jl`.

## API

```@autodocs
Modules = [L2F2_Dequantification_App]
Pages = ["interface.jl"]
```