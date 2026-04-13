# La Vie d'un Homme

- Projet Blazor WebAssembly .NET 8, au style editorial sobre et chaleureux.
- Les articles publies sont generes a partir des Markdown situes dans `content/articles`.
- Le contrat YAML utilise `title` et `writing_date`.
- La commande de generation est `pwsh -File ./scripts/Generate-Articles.ps1`.
- Les pages generees vivent dans `Pages/Articles/GeneratedArticle_*.razor`.
- Un Markdown avec `layout: home` genere `Pages/Home.razor`.
- Le menu lateral contient une zone generee entre `@* GENERATED ARTICLES START *@` et `@* GENERATED ARTICLES END *@` dans `Layout/NavMenu.razor`.
- Ne pas editer manuellement une page generee pour modifier le contenu d'un article : modifier le Markdown source puis relancer la generation.
- `published: false` signifie qu'aucune page ne doit exister ; `listed: false` signifie qu'une page publiee reste accessible en direct mais disparait du menu.
- Pour les articles d'une serie, utiliser `series` et `part`.
- Validation locale utile :
  1. `pwsh -File ./scripts/Generate-Articles.ps1`
  2. `dotnet build`
- Le build local peut echouer si la restauration NuGet ne peut pas joindre `https://api.nuget.org/v3/index.json`. Si cela arrive, ne pas en deduire que le code est invalide : noter clairement le blocage reseau.
