# PLM-ZIG

Auteurs: Chloé Fontaine, Luca Coduri

## Expliquer les avantages et inconvénients du langage étudié

Avantages de Zig :

Sécurité et fiabilité : Zig met l'accent sur la sécurité et la fiabilité du code en utilisant des fonctionnalités telles que la vérification des limites d'indexation, le contrôle des erreurs et la gestion explicite de la mémoire.

Performances : Zig est un langage de programmation à compilation rapide, qui permet de créer des programmes à haute performance.

Interopérabilité : Zig est compatible avec le code C et peut facilement interagir avec les bibliothèques C existantes.

Simplicité : Zig a une syntaxe simple et facile à apprendre, avec un ensemble de fonctionnalités limité mais puissant.

Conception orientée objet : Zig prend en charge une conception orientée objet légère, permettant une organisation claire du code et une réutilisation facile.

Inconvénients de Zig :

Maturité : Zig est un langage relativement nouveau et en cours de développement, il peut donc être sujet à des changements fréquents et à des erreurs.

Communauté : La communauté de Zig est encore petite par rapport à d'autres langages de programmation populaires, ce qui peut rendre difficile la recherche de ressources et de support.

Bibliothèques : Zig n'a pas encore la même quantité de bibliothèques que certains des langages de programmation plus populaires, ce qui peut rendre le développement de certaines applications plus difficile.

Documentation : La documentation de Zig peut être limitée, et il peut être difficile de trouver des exemples ou des guides pour certains problèmes spécifiques.

En somme, Zig est un langage de programmation prometteur qui offre des avantages en matière de sécurité, de performance, d'interopérabilité et de simplicité, mais qui est encore en développement et qui peut présenter des défis liés à la maturité, à la communauté, aux bibliothèques et à la documentation. Si vous êtes intéressé par l'apprentissage de Zig, il peut être utile de considérer ces facteurs pour déterminer s'il est adapté à vos besoins et à votre niveau d'expérience.

## Présenter ce langage à une audience d’ingénieurs

Zig est un language basé sur le C, il contient donc beaucoup de similitude dans la syntaxe.

Voici un exemple simple:

```c++
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, {s}!\n", .{"World"});
}
```

Mais contient quelques particularitées:

defer: deferpermet d'exécuter du code en sortie du scope

```c++
test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect(x == 7);
}
```

Erreur:
La gestion des erreurs est obligatoire dans ce language. Il est impossible de passer à coté d'une erreur sans le gérer. Voici un exemple:

```c++
const std = @import("std");

const MyError = error{
    Omg,
    SoNoob,
};

pub fn main() void {
    var value: i32 = errorTest() catch |err| switch (err) {
        error.Omg => 10,
        error.SoNoob => 20,
    };
    std.debug.print("{d}\n", .{value});
}

pub fn errorTest() MyError!i32 {
    return MyError.Omg;
}
```

## Rédiger un rapport concis expliquant les concepts fondamentaux du langage

Zig est un langage de programmation open-source, conçu pour offrir une expérience de développement de logiciels plus rapide et plus sûre. Il est basé sur le C, mais offre des fonctionnalités modernes telles que la gestion explicite de la mémoire, la vérification des limites d'indexation et la gestion d'erreurs, ce qui permet de développer des programmes plus fiables, plus rapides et plus sécurisés. Zig est également compatible avec le code C, ce qui facilite l'intégration avec les bibliothèques existantes.

L'une des principales caractéristiques de Zig est sa syntaxe simple et intuitive, qui le rend facile à apprendre pour les programmeurs de tous niveaux. Il dispose également d'un système de types fort et d'une vérification statique des types, ce qui permet de détecter les erreurs de type dès la phase de compilation.

Zig est également conçu pour être très performant, grâce à une compilation rapide et à un faible surcoût de temps d'exécution. Il utilise une optimisation agressive et des techniques de compilation modernes pour générer du code machine efficace.

Zig prend également en charge une conception orientée objet légère, ce qui permet une organisation claire du code et une réutilisation facile. Il dispose également d'un système de modules flexible qui permet de gérer facilement les dépendances du code.

Enfin, Zig est un langage en évolution constante, avec une communauté active de contributeurs et de développeurs. La communauté fournit un support actif, des exemples de code et des ressources pour aider les programmeurs à apprendre et à utiliser le langage.

En somme, Zig est un langage de programmation moderne et puissant, qui offre une combinaison unique de sécurité, de performance, de simplicité et de compatibilité avec le code C. Il est idéal pour les ingénieurs et les développeurs qui cherchent à développer des applications rapides, sûres et fiables, tout en bénéficiant d'un environnement de développement flexible et en évolution constante.

## Mettre en œuvre ces concepts dans un application concrète et originale

## Présenter cette application en détaillant son architecture logicielle

## Rédiger un rapport concis d’implémentation
