# Projet L2F2 — Déquantification

**Version 1.0, 2026**  
Dernière mise à jour : 25/04/2026

---

## Description

Cette application implémente un algorithme de déquantification à 1 bit sur des séries temporelles.

La sous-quantification à 1 bit supprime le bit de poids faible de chaque valeur d'une série `x`. Elle produit `xQ` où chaque valeur est le nombre pair inférieur ou égal. Cette opération est irréversible : pour chaque `xQ[n]`, la valeur originale `x[n]` vaut soit `xQ[n]` soit `xQ[n] + 1`.

L'application exploite l'histogramme `P` des couples de valeurs successives de `x`. Elle construit un arbre binaire représentant toutes les séries possibles compatibles avec cet histogramme et `xQ`, puis l'élague progressivement en éliminant les branches incompatibles avec `P`. Les séries restantes à la fin de l'élagage sont toutes les solutions possibles, parmi lesquelles figure nécessairement la série originale `x`.

L'interface graphique permet de visualiser en temps réel la construction et l'élagage de cet arbre, d'interagir avec l'animation via les boutons de contrôle, et d'exporter les solutions trouvées.

> Cette application est une application de recherche qui ne tente pas de trouver la série originale mais toutes les séries qu'on PEUT trouver.

---

## Prérequis

- Julia **1.10.11** — disponible sur https://julialang.org/downloads/ (si version plus récente, vérifier la compatibilité avec GLMakie)
- Carte graphique compatible **OpenGL 3.3+**
- Système d'exploitation récent (Windows 10/11, macOS 10.14+, ou Linux)
- **4 Go de RAM minimum** (8 Go recommandés)

---

## Installation

### Windows

Double-cliquez sur `install.bat` pour installer les dépendances, puis sur `run.bat` pour lancer l'application.

Depuis le terminal :
```
cd cheminVersLeProjet
install.bat
run.bat
```

> Si Windows bloque les fichiers `.bat` : clic droit → Propriétés → cocher "Débloquer" en bas.

### Linux / macOS

```bash
cd cheminVersLeProjet
chmod +x install.sh run.sh
./install.sh
./run.sh
```

> L'installation des dépendances peut prendre du temps au premier lancement. Veuillez patienter.

---

## Fonctionnalités

- Génération de `xQ` (série sous-quantifiée) et de `P` (histogramme des couples) à partir d'un fichier `x`
- Reconstruction des séries candidates via construction et élagage d'un arbre binaire
- Visualisation animée en temps réel de la construction et de l'élagage de l'arbre
- Export des solutions trouvées en fichiers `.dat` ou archive ZIP
- Import d'un dossier `xQ` + `P` existant pour relancer l'algorithme sans reimporter `x`

---

## Guide utilisateur

1. Cliquez sur **Importer x** et sélectionnez votre série temporelle au format binaire 16 bits
2. Cliquez sur **Lancer** pour démarrer l'algorithme
3. Cliquez sur **Arrêter** pour interrompre l'animation à tout moment
4. Les solutions trouvées apparaissent dans la liste à gauche
5. Cliquez sur **Exporter les solutions** pour les télécharger en ZIP
6. Cliquez sur **Telecharger xQ et P** pour récupérer les données générées
7. Cliquez sur **Effacer** pour réinitialiser l'interface

> Vous pouvez aussi importer directement un dossier contenant `xQ.dat` et `P.ppm` via **Importer xQ et P**.

---

## Guide technique

### Structure du projet

```
.
├── install.bat                  # script d'installation Windows
├── install.sh                   # script d'installation Linux/macOS
├── run.bat                      # script de lancement Windows
├── run.sh                       # script de lancement Linux/macOS
├── LICENSE.txt                  # licence Apache 2.0
├── Manifest.toml                # versions exactes des dépendances
├── Project.toml                 # déclaration des dépendances
├── README.md
├── src/
│   ├── L2F2_Dequantification_App.jl   # point d'entrée
│   ├── interface.jl                   # interface graphique
│   └── algorithme/
│       ├── arbre.jl                   # structures Noeud et Arbre
│       ├── construction.jl            # génération de xQ et P
│       └── dequantification.jl        # algorithme principal
│   └── data/
│       └── temp/                      # solutions générées
└── test/
    ├── runtests.jl
    ├── test_arbre.jl
    ├── test_construction.jl
    ├── test_dequantification.jl
    └── data/
        ├── input/                     # jeux de données de test
        └── temp/
```

### Lancer les tests

```bash
cd cheminVersLeProjet
julia --project=. test/runtests.jl
```

### Dépendances

| Bibliothèque | Rôle |
|---|---|
| GLMakie | Interface graphique (OpenGL) |
| GraphMakie | Visualisation de l'arbre |
| NativeFileDialog | Explorateur de fichiers natif |
| ZipFile | Export des solutions en ZIP |

Toutes les dépendances sont installées automatiquement par `install.bat` / `install.sh`.

### Fonctionnement de l'algorithme

Pour chaque valeur sous-quantifiée `xQ[n]`, la valeur originale `x[n]` est soit `xQ[n]` (pair) soit `xQ[n] + 1` (impair). L'ensemble de toutes les reconstructions possibles est représentable sous la forme d'un arbre binaire.

L'algorithme parcourt cet arbre en profondeur (DFS). Pour chaque nœud, il génère les deux fils possibles et vérifie si le couple formé est compatible avec l'histogramme `P`. Si oui, le fils hérite de `P` et décrémente l'occurrence du couple. Sinon, la branche est élaguée. À la fin, les branches restantes sont les solutions candidates.

---

## Auteurs

Développé par **Abdallah BENALI**, **Dina KANGNI**, **Mohammed ZOUAD** et **Salim ACHAK**.  
Sous la direction de **Gaël MAHÉ** et **David JANISZEK**.  
Dans le cadre de l'UE Projet Professionnel — Université Paris Cité, 2026.

---

## Licence

Ce projet est distribué sous licence **Apache 2.0**.  
Toute réutilisation ou redistribution commerciale doit mentionner explicitement les auteurs.  
Voir `LICENSE.txt` pour plus de détails.