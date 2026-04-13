&#x20;                                       ██╗     ██████╗ ███████╗██████╗

                                        ██║     ╚════██╗██╔════╝╚════██╗
                                        ██║      █████╔╝█████╗   █████╔╝
                                        ██║     ██╔═══╝ ██╔══╝  ██╔═══╝
                                        ███████╗███████╗██║     ███████╗
                                        ╚══════╝╚══════╝╚═╝     ╚══════╝

&#x20;                                       # Projet L2F2 - Déquantification
                                              \*Version 1.0, 2026\*
                                    Ce fichier README a été généré le \[01-03-2026]
                                        Dernière mise à jour le : \[24-03-2026].






# DESCRIPTION

Cette application permet de visualiser en temps réel la construction et l'élagage d'un arbre binaire représentant toutes les reconstructions possibles d'une série temporelle à partir de sa version sous-quantifiée à 1 bit.
Vous pouvez interagir avec l'animation en la stoppant, en l'avançant ou en la reculant et suivre l'efficacité de cet algorithme avec le pourcentage représentant le taux de branches restantes après élagage.









# PREREQUIS

Avant de lancer l'application, assurez-vous d'avoir:

* la version 1.10 de Julia disponible sur https://julialang.org/downloads/.
Si vous voulez avoir une version plus récente, assurez vous qu'elle soit compatible avec la bibliothèque graphique GLMakie
* une carte graphique compatible avec OpenGL 3.3+
* de préférence un système d'exploitation récent (Windows 10/11, MacOS 10.14+ ou Linux)
* 4 Go minimum (on recommande 8 Go)







# INSTALLATION

Le lancement de l'application dépend ensuite de votre système d'exploitation.



* Si vous êtes un utilisateur sous Windows
Vous pouvez dans un premier temps double-cliquer directement sur le fichier "install.bat" (qui installera les dépendances) et ensuite run.bat(qui lancera l'application).
Notez que si vous installez les dépendances une fois, il ne sera pas nécessaire de le refaire au prochain lancement de l'application.

Vous pouvez aussi l'exécuter depuis le terminal. Pour ce faire, placez-vous dans le dossier du projet avec la commande:
cd cheminVersLeProjet
puis cliquez
'install.bat'
et ensuite,
'run.bat'



* Si vous êtes un utilisateur sous une distribution Linux ou sous MacOs
Vous ouvrez un terminal et y cliquez:
cd cheminVersLeProjet
Par défaut vous ne pouvez pas exécuter des scripts.
Cliquez donc 'chmod +x install.sh' suivi de 'chmod +x run.sh'
Cliquez ensuite './install.sh' pour installer les dépendances puis './run.sh' pour lancer l'application.
Notez que si vous installez les dépendances une fois, il ne sera pas nécessaire de le refaire au prochain lancement de l'application.


L'installation des dépendances et le lancement de l'application peuvent prendre du temps au départ. Veuillez patienter.

=====================================================================

# FONCTIONNALITES

Cette application vous propose trois grandes fonctionnalités.

Elle permet premièrement de générer et de récupérer sous la forme d'un dossier l'histogramme du jeu de données que vous aurez soumis ainsi que sa version sous-quantifiée.

Elle permet aussi de récupérer les solutions trouvées sous la forme de fichiers binaires codés sur 16 bits en élaguant un arbre binaire représentant toutes les reconstructions possibles du jeu de données initial.

Enfin, l'interface graphique permet de visualiser la construction et l'élagage de cet arbre ainsi que le pourcentage de branches restantes.
Des boutons sont aussi mis à disposition pour pouvoir interagir avec l'animation.







# GUIDE UTILISATEUR:

Au lancement de l'application, cliquez sur le bouton **Importer x** et sélectionnez votre série temporelle au format binaire 16 bits depuis votre système de fichiers.
Vous pourrez ensuite lancer l'application en cliquant sur le bouton **lancer**.
Vous avez la possibilité d'appuyer sur le bouton **arreter** après lancement pour stopper l'animation.
Notez cependant que si par la suite vous cliquez à nouveau sur **lancer**, l'animation redémarrera depuis le début.

Si vous le souhaitez, vous pourrez (seulement après un premier lancement de l'animation) importer un dossier contenant xQ et P (en cliquant sur **importer xQ et P**) et lancer l'animation en cliquant sur **lancer** avec ces données.


Tous les résultats seront affichés dans la liste des résultats.
Vous avez la possibilité de tous les récupérer au format Zip en cliquant sur **exporter les solutions**.
Vous pouvez aussi telecharger un dossier contenant xQ et P générés grâce à l'algorithme en cliquant sur **telecharger xQ et P**.

Notez qu'il est nécessaire d'importer des fichiers non vides et contenant suffisamment de données, soit plus de deux.







# GUIDE TECHNIQUE

Le projet est organisé comme suit:

C:.
├── LICENSE.txt
├── Manifest.toml
├── Project.toml
├── README.md
├── doc
│   ├── Cahier_recette_L2F2_Version_1.2.pdf
│   └── cahierCharges_Version_1.3.pdf
├── install.bat
├── install.sh
├── run.bat
├── run.sh
├── src
│   ├── algorithme
│   │   ├── arbre.jl
│   │   ├── construction.jl
│   │   └── dequantification.jl
│   ├── application.jl
│   ├── data
│   │   ├── P.ppm
│   │   ├── temp
│   │   └── xQ.dat
│   └── interface.jl
└── test
    ├── data
    │   ├── input
    │   │   ├── P.ppm
    │   │   ├── x10.dat
    │   │   ├── x100.dat
    │   │   ├── x200.dat
    │   │   ├── x500.dat
    │   │   ├── x999.dat
    │   │   ├── x9999.dat
    │   │   ├── x99994.dat
    │   │   ├── x_AR1_940.dat
    │   │   ├── x_AR1_9980.dat
    │   │   └── x_AR1_99882.dat
    │   └── temp
    ├── runtests.jl
    ├── test_arbre.jl
    ├── test_construction.jl
    └── test_dequantification.jl



### Dépendances

L'application repose sur quatre bibliothèques externes, toutes installées automatiquement par les scripts de lancement.

GLMakie est la bibliothèque graphique principale. Elle s'appuie sur OpenGL pour le rendu et fournit les éléments d'interface tels que les boutons par exemple.
Une carte graphique compatible OpenGL 3.3 est donc fortement conseillée.

GraphMakie permet la visualisation des graphes. Elle est utilisée pour afficher et mettre à jour l'arbre binaire pendant l'animation.

NativeFileDialog ouvre le sélecteur de fichiers natif du système d'exploitation.

ZipFile permet de regrouper les séries candidates dans une archive ZIP.



### Fonctionnement de l'algorithme

L'algorithme repose sur une propriété simple :
pour chaque valeur sous-quantifiée "xQ\[n]", la valeur originale "x\[n]" est soit "xQ\[n]" (valeur paire), soit "xQ\[n] + 1" (valeur impaire).
L'ensemble de toutes les reconstructions possibles est donc représentable sous la forme d'un arbre binaire.



L'algorithme utilise l'histogramme des couples de x, la série originale. 

Cet histogramme, implémenté sous la forme d'un dictionnaire, révèle les couples qui existent et plus précisément leur occurrence dans la série de base.

Il ne donne pas leur ordre d'apparition, qui pourra être identifié avec l'arbre binaire.



* l'algorithme parcourt l'arbre en profondeur.
* pour chaque nœud:

&#x09;- il génère les deux fils possibles et vérifie si le couple formé est compatible avec l'histogramme

&#x09;	- si le couple est compatible: les fils copient l'histogramme de leur père et décrémentent l'occurrence du nouveau couple formé. 

&#x09;	On répète ces opérations récursivement sur les fils.



&#x09;	- sinon on élague le père récursivement.

&#x09;


# DOCUMENTATION

La documentation complète du projet se trouve dans le dossier "doc/" et comprend le cahier des charges, le cahier de recette et le cahier de conception général et détaillé. Ce dernier décrit en particulier l'architecture du projet, les structures de données et le détail de chaque fonction.







# AUTEURS

Développé par Abdallah BENALI, Dina KANGNI, Mohammed ZOUAD et Salim Achak.

Sous la direction de Gaël MAHE et de David JANISZEK.
Dans le cadre de l'UE Projet Professionnel dans l'université Paris Cité.







# LICENSE

Ce projet est distribué sous licence Apache 2.0.

Toute réutilisation ou redistribution commerciale doit mentionner explicitement les auteurs.

Pour plus d'informations, vous pouvez vous référer à la documentation du projet.

\---

