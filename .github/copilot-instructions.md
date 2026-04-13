# Instructions Copilot — La Vie d'un Homme

## Contexte du projet

**La Vie d'un Homme** est un blog personnel au format journal intime numérique, développé avec **Blazor WebAssembly** (.NET / C#).
L'ambiance visuelle est chaleureuse et intimiste : tons crème, marrons et ocre, inspirés du papier vieilli et des carnets d'écriture.

## Stack technique

- **Framework** : Blazor WebAssembly (`.razor`)
- **Langage** : C# + HTML + CSS
- **Styles** : CSS scoped par composant (`.razor.css`) + feuille globale (`wwwroot/css/app.css`)
- **Bootstrap** : présent mais utilisé de façon minimale

## Charte graphique

| Élément              | Valeur                 |
|----------------------|------------------------|
| Fond de page         | `#fdf8f0`              |
| Texte principal      | `#3a2e20`              |
| Accent / liens       | `#7a5c3c`              |
| Bordures / séparateurs | `#c49a6c` / `#e0c9a0` |
| Fond des entrées     | `#fff9ef`              |
| Police principale    | `Georgia`, `Times New Roman`, serif |

Le menu latéral suit la même palette chaude (fond `#3a2e20`, texte crème `#fdf8f0`).

## Conventions de code

- Les **articles** sont des fichiers `.razor` dans le dossier `Pages/`, décorés d'un `@page "/..."`.
- Chaque article utilise les classes CSS : `.journal-cover`, `.journal-entry`, `.entry-date`, `.entry-signature`.
- Les **dates** des entrées sont écrites en français (ex. : `Avril 2025`).
- La **signature** d'une entrée est `— L'auteur`.
- Le style doit rester cohérent avec l'ambiance journal intime : sobre, élégant, sans éléments UI décoratifs superflus.
- Évite Bootstrap autant que possible ; préfère le CSS scoped.

## Bonnes pratiques

- Ajouter chaque nouvel article dans le `NavMenu.razor` avec un `<NavLink>` adapté.
- Ne pas introduire de dépendances JS tierces sauf absolue nécessité.
- Respecter la typographie serif pour tous les contenus éditoriaux.
- Les commentaires de code sont en **français**.
