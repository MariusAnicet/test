---
title: Exemple simplifié - Héritage Activité / Cyclisme
---
classDiagram
    class User {
        -id_user: int
        -nom_user: string
        +creer_activite(fichier_gpx: File) Activite
    }

    class Activite {
        -id_activite: int
        -titre: string
        -date_activite: Date
        +modifier() void
    }

    class Cyclisme {
        -type_velo: string
        -denivele: float
        +calculer_puissance() float
    }

   

    %% Relation simple
    User "1" --> "*" Activite : crée
