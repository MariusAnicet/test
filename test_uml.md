---
title: APPLICATION SPORTIVE
---
classDiagram
namespace Main {
    class User{
        -id_user: int
        -nom_user: string
        -email_user: string
        -mot_de_passe: string
        +creer_activite(fichier_gpx: File) Activite
        +consulter_activites() List~Activite~
        +modifier_activite(activite: Activite) void
        +supprimer_activite(activite: Activite) void
        +suivre_user(user: User) void
        +liker_activite(activite: Activite) void
        +commenter_activite(activite: Activite, commentaire: string) void
        +obtenir_statistiques() Statistiques
    }

    class Activite {
        -id_activite: int
        -titre: string
