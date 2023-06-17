# PLM-ZIG

**Auteurs**: Chloé Fontaine, Luca Coduri

Le projet que nous avons décidé de réaliser en utilisant le langage Zig est un mini moteur physique qui gère l'interaction entre des sphères dans un environnement soumis à la gravité. Pour rappel, Zig est un langage de programmation compilé, impératif, polyvalent et typé statiquement, conçu comme une alternative aux langages traditionnels tels que C et C++, offrant de hautes performances tout en minimisant les risques d'erreurs.

Dans ce projet, notre objectif était de tirer pleinement parti des performances du langage pour la gestion des collisions, ainsi que de ses fonctionnalités de sécurité visant à éviter les "memory leaks" grâce à l'allocateur dédié du langage.

Selon les spécifications du cahier des charges, les fonctionnalités que nous devions implémenter étaient les suivantes :

- Gestion de la gravité
- Gestion des collisions entre des sphères de même taille

En ce qui concerne les fonctionnalités souhaitées mais non obligatoires, nous avions les objectifs suivants :

- Ajout d'une prise en charge multithread pour l'application
- Rendre l'application déterministe afin de pouvoir afficher une forme spécifique

# Implémentation

## Physique du monde

Nous avons choisi d'utiliser la méthode de Verlet pour gérer les déplacements des corps dans notre environnement. Cette méthode est définie par l'équation suivante :

$x(t+Δt)=x(t)+v(t)Δt+\frac{1}{2}a(t)Δt^2$

, avec $x = position$, $t = temps$, $v = vitesse$ et $a = accélération$.

En termes simples, cela signifie que nous calculons la différence entre la nouvelle position du corps et sa position précédente, puis l'ajoutons à sa position actuelle pour déterminer sa prochaine position. Dans notre cas, nous avons défini un $Δt$ fixe de $\frac{1}{60}$, pour reproduire le fait de mettre à jour les positions des objets toutes les $\frac{1}{60}$ème de seconde, et d’obtenir ainsi une simulation déterministe. En revanche, le fait de définir un $Δt$ constant impacte la fluidité du rendu visuelle, car plus le temps entre le rendu de deux images augmente, plus les sphères ralentissent.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/bf7638b8-ccde-465a-a0ad-22bfaff9bccb/Untitled.png)

En plus du déplacement, nous avons également pris en compte l'accélération, qui correspond à la gravité du monde. Cela signifie que chaque corps dans notre environnement est soumis à une accélération constante vers le bas en raison de la gravité. Cette accélération est ajoutée à la formule de Verlet pour calculer les positions mises à jour des corps à chaque itération du moteur physique.

Il est important de noter que nous utilisons cette méthode car c’est une approche numérique pour approximer les mouvements physiques, souvent utilisée pour des simulations en temps réel, comme celle que nous avons développée.

## Détection des collisions

Une fois que toutes les sphères ont été déplacées, notre prochaine étape consiste à détecter les éventuelles collisions entre elles et à les corriger. Pour ce faire, nous avons exploré différentes méthodes expérimentales afin de déterminer celle qui était la plus efficace dans notre cas.

### Approche “gloutonne”

Cette méthode consiste à comparer la position de chaque sphère avec celle de toutes les autres sphères présentes dans l'environnement. Si une collision est détectée, nous procédons à une correction de la position des sphères concernées. Cependant, nous avons constaté que cette approche présentait des limitations en termes de performances.

Cette méthode dite “force brute” a une complexité algorithmique de $O(n^2)$, ce qui signifie que pour chaque objet, nous devons le comparer à tous les autres. Par exemple, avec 100 objets, cela nécessite 10 000 comparaisons. Par conséquent, cette méthode devient rapidement inefficace, en particulier lorsque le nombre d'objets augmente.

### Méthode “Quadtree”

L'approche précédente présentait un problème majeur : elle effectuait des comparaisons inutiles. Par exemple, il était évident que deux objets positionnés aux extrémités opposées de l'environnement ne pouvaient pas entrer en collision. Pour résoudre ce problème, il nous faut partitionner l’espace. Plusieurs méthodes existent mais nous souhaitions essayer d’implémenter un Quadtree.

La méthode Quadtree consiste à organiser les objets dans des cellules. Un Quadtree est une structure arborescente où chaque nœud possède 4 enfants. Nous représentons cette structure sous forme de grille. Lorsqu'un certain seuil d'objets est atteint dans une cellule donnée, la grille est subdivisée en 4 nouvelles cellules, créant ainsi une hiérarchie arborescente. Ce processus de subdivision peut être répété de manière récursive pour créer une structure de Quadtree adaptée à la distribution des objets dans l'environnement.

![Source : https://www.educative.io/answers/what-is-a-quadtree-how-is-it-used-in-location-based-services](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/6ee9e45e-ad43-4c21-9962-783d259a3514/Untitled.png)

Source : https://www.educative.io/answers/what-is-a-quadtree-how-is-it-used-in-location-based-services

Après avoir effectué cette subdivision de l’espace, nous répartissons chaque objet dans les cellules, en fonction de leur position. Puis, au lieu de comparer chaque objet avec tous les autres, nous ne comparons que les objets qui se trouvent dans la même cellule, et celles adjacentes.

Prenons l’exemple suivant, avec un seuil de 4 :

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/74b4c24a-31da-46c3-9072-0705908b242b/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/bf0680fa-eadb-47c0-a0b8-5427526a2178/Untitled.png)

On observe que tous les objets ont été distribués dans l’arbre, en fonction de leur position et de la cellule à laquelle ils appartiennent.

Cependant, l’utilisation des Quadtree n’est pas adaptée à notre problème. En effet, dans notre cas, nos objets sont dynamique et concentrés au même endroit de l’environnement. Les Quadtrees sont généralement plus efficaces lorsque peu d'objets subissent des déplacements. Nous évitons ainsi de devoir reconstruire l’arbre en entier à chaque itération du moteur de collision. Dans notre scénario, il serait nécessaire de reconstruire complètement l'arbre à chaque itération du moteur de collision, ce qui peut entraîner une perte de performances significative. De plus cette approche est plus difficile à multi-threader que la suivante, qui est bien plus appropriée à notre situation.

### Méthode “Uniform Grid”

Cette méthode s’avère être la plus efficace que nous avons testé dans notre simulation. En partant du principe que toutes les sphères de notre environnement ont la même taille, nous subdivisons l'espace en cellules de la même taille que le diamètre des sphères. Pour représenter cet espace dans notre code, nous utilisons une matrice où chaque élément correspond à une cellule. Chaque objet du monde est ajouté à toutes les cellules qu'il chevauche. Cela signifie qu'un objet peut être présent dans plusieurs cellules de la grille, en fonction de sa position.

L'exemple suivant illustre comment chaque objet est ajouté aux différentes cellules de la grille :

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/6523a208-ef4b-43fa-9360-72bbe4c35352/Untitled.png)

Ensuite, pour chaque cellule de la grille, nous comparons les positions de tous les objets qui lui appartiennent. Si une collision est détectée, nous corrigeons les positions des objets concernés.

Cette méthode permet de réduire considérablement le nombre de comparaisons nécessaires pour détecter les collisions, car nous ne comparons que les objets présents dans la même cellule ou les cellules adjacentes.

### Multithreading

Dans le but d'améliorer les performances de notre programme et de pouvoir intégrer un plus grand nombre de sphères, nous avons choisi de multi-threader notre programme. La tâche la plus coûteuse en termes de ressources dans notre programme est l'itération sur la matrice pour vérifier les collisions potentielles au sein des cellules. C'est pourquoi nous avons décidé de diviser la matrice en un nombre équivalent de threads et de répartir la charge de travail entre eux.

Prenons l’exemple d’un programme multithreadé avec 2 threads. Nous avons envisagé une approche initiale consistant à diviser la matrice en 2 parties égales, attribuant chaque partie à l'un des 2 threads, comme illustré dans le schéma à droite.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/fd19d452-25ef-41ea-84f1-f5c624767aa4/Untitled.png)

Cependant, cette division de la matrice pose un problème potentiel. Les objets qui chevauchent les deux parties sont traités simultanément par les deux threads. Cela peut entraîner un comportement non déterministe et imprévisible, ce qui est indésirable car nous souhaitons afficher une image à l’aides des sphères à la prochaine itération du programme.

Pour résoudre ce problème, nous avons adopté une approche légèrement différente. Nous divisons encore par 2 chaque partie appartenant à un thread.

Par exemple, comme illustré dans le schéma à droite, le thread 1 est responsable des parties “T1-A” et “T1-B”. Chaque thread effectue simultanément le traitement de sa partie A, puis ils sont synchronisés avant de procéder à la partie B.

Cela permet de garantir un comportement déterministe, en évitant le traitement d’objets par plusieurs threads de manière simultanée.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/8ac0560d-e7a2-4a2e-8c01-1398bf3b5027/Untitled.png)

## Affichage d’une image

Lors des étapes précédentes, nous avons réussi à garantir le comportement déterministe de notre programme. Cela signifie que chaque objet dans notre monde aura toujours le même comportement, et sa position finale sera donc identique à chaque exécution. En lançant une seule fois le programme, nous pouvons ainsi déterminer l'emplacement final de chaque sphère.

En utilisant cette information, nous pouvons créer une image en interpolant la position de chaque objet dans cette image et en attribuant la couleur du pixel correspondant à la sphère. Lorsque nous relançons le programme, nous pouvons donc voir cette image s’afficher.

# Retour d’expérience

Au cours de la réalisation de notre projet, nous avons pu expérimenter plusieurs aspects du langage que nous avons particulièrement apprécié. Voici quelques exemples qui se sont révélés particulièrement intéressants :

- **Détection des “memory leaks”** : Nous avions de grandes attentes en ce qui concerne la détection et la gestion des “memory leaks” grâce aux allocateurs de Zig. Cette fonctionnalité s'est révélée extrêmement utile et nous l'avons beaucoup appréciée. En revanche, nous avons rencontré une limitation de cette fonctionnalité avec l’utilisation de librairies C. Par exemple, nous avons utilisé la librairie SDL pour le rendu graphique de notre moteur physique. Malheureusement, les potentiels "memory leaks" générés par cette librairie n'ont pas pu être détectés au moment de l'exécution de notre programme, car elle utilise son propre allocateur de mémoire C plutôt que celui de Zig.
- **Utilisation du “comptime”** : L’utilisation du `comptime` nous a permis d’effectuer des opérations lourdes à la compilation, telle que lire un fichier et de l’intégrer au préalable dans notre exécutable.
- **Langage agréable** : Finalement l’utilisation d’un langage intégrant des fonctionnalités modernes et davantage “haut niveau” que le C était très appréciable pour la réalisation de ce projet.

En revanche, nous avons rencontré certaines difficultés liées à l’utilisation du Zig et à son manque de maturité, telles que :

- **L'absence d'un gestionnaire de paquets** : Nous avons constaté que Zig ne disposait pas encore d'un système de gestion de paquets bien établi. Cela signifie que nous devions gérer manuellement les dépendances externes nécessaires à notre projet, ce qui a parfois été laborieux et a nécessité des efforts supplémentaires pour s'assurer que toutes les dépendances étaient correctement intégrées et mises à jour.
- **Version du langage** : nous avons fait l’erreur de développer notre projet avec une version du langage en développement, ce qui a introduit des difficultés supplémentaires lors de la collaboration entre membres de l'équipe utilisant des versions différentes. Entre deux version du compilateur, il pouvait y avoir des “breaking changes” qui rendaient certaine partie de notre code non compilable.

# Sources

Verlet :

https://en.wikipedia.org/wiki/Verlet_integration

https://www.algorithm-archive.org/contents/verlet_integration/verlet_integration.html

Quadtree :

https://www.geeksforgeeks.org/quad-tree/

https://www.educative.io/answers/what-is-a-quadtree-how-is-it-used-in-location-based-services
