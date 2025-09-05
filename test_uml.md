---
title: Exemple simple d'héritage
---
classDiagram
    Animal <|-- Chien
    Animal <|-- Chat

    class Animal {
        -nom: string
        -age: int
        +manger(): void
        +dormir(): void
    }

    class Chien {
        -race: string
        +aboyer(): void
    }

    class Chat {
        -couleur: string
        +miauler(): void
    }
