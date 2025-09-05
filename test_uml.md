classDiagram
    Animal <|-- Chien
    Animal <|-- Chat

    class Animal {
        +manger()
        +dormir()
    }

    class Chien {
        +aboyer()
    }

    class Chat {
        +miauler()
    }
