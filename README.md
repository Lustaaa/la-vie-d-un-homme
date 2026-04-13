# La Vie d'un Homme

Un journal intime numérique — émotions, anecdotes et fragments du quotidien.  
Ce projet est construit avec **Blazor WebAssembly (.NET 8)** et déployé automatiquement sur **GitHub Pages**.

🌐 **Site en ligne :** [https://lustaaa.github.io/la-vie-d-un-homme](https://lustaaa.github.io/la-vie-d-un-homme)

---

## 📖 Mode d'emploi

### 🛠 Ajouter un nouvel article

Les articles ne sont plus écrits directement dans `Pages/`.  
La **source de vérité** est maintenant le dossier `content/articles/`.

1. Créez un fichier Markdown dans `content/articles/` ou dans un sous-dossier.  
   Exemple : `content/articles/2026/mon-article.md`

2. Renseignez le front matter YAML :

   ```md
   ---
   title: Mon titre
   writing_date: Avril 2025
   published: false
   listed: false
   signature: Juste un homme
   layout: article
   series:
   part:
   ---

   Mon texte en markdown.
   ```

3. Écrivez ensuite le contenu en Markdown.

4. Générez les pages Blazor depuis le Markdown :

   ```powershell
   pwsh -File .\scripts\Generate-Articles.ps1
   ```

5. Les fichiers générés apparaîtront dans `Pages/Articles/` et le menu sera mis à jour automatiquement dans `Layout/NavMenu.razor`.

---

### 🧾 Contrat YAML

| Champ | Obligatoire | Type | Défaut | Rôle |
|------|------|------|------|------|
| `title` | Oui | Texte | — | Titre affiché sur la page et dans le menu |
| `writing_date` | Oui | Texte | — | Date éditoriale en français, par exemple `Avril 2025`, `10 Novembre 2024` ou `1er Novembre 2024` |
| `published` | Non | Booléen | `false` | Si `false`, aucune page n'est générée |
| `listed` | Non | Booléen | `false` | Si `true`, l'article apparaît dans le menu |
| `signature` | Non | Texte | `Juste un homme` | Signature affichée en bas de l'article |
| `layout` | Non | Texte | `article` | `article` pour une page de blog classique, `home` pour générer `Pages/Home.razor` |
| `series` | Non | Texte | vide | Nom d'une suite d'articles |
| `part` | Non | Nombre | vide | Ordre de l'article dans la série |

#### Règles importantes

- `published: false` : l'article reste un brouillon, aucune page `.razor` ne doit exister.
- `published: true` + `listed: false` : la page est générée mais n'apparaît pas dans le menu.
- `published: true` + `listed: true` : la page est générée et ajoutée au menu.
- Le slug de l'URL est généré automatiquement à partir du titre et de la date éditoriale, sous la forme `yyyy-MM-titre`.
- `writing_date` accepte soit un mois au format `Avril 2025`, soit une date plus précise comme `10 Novembre 2024` ou `1er Novembre 2024`.
- `layout: home` génère `Pages/Home.razor` et n'ajoute pas ce contenu dans la liste des articles.
- Les fichiers dans `content/articles/_templates/` servent de modèles et ne sont jamais publiés.

---

### ✍️ Markdown supporté

Le générateur prend en charge :

- titres Markdown (`#`, `##`, `###`)
- paragraphes
- gras et italique
- listes à puces
- listes numérotées
- liens
- citations

Les pages générées restent cohérentes avec le thème du journal intime.

---

### 🔁 Séries d'articles

Pour relier plusieurs textes entre eux :

```md
---
title: Partie 2
writing_date: Mai 2025
published: true
listed: true
series: Une histoire
part: 2
---
```

Quand plusieurs articles publiés partagent la même valeur `series`, l'application affiche automatiquement :

- le lien vers la partie précédente
- le lien vers la partie suivante
- la liste complète de la série

---

### 🤖 Utiliser l'agent GitHub

Le dépôt contient :

- `AGENTS.md` pour expliquer à l'agent comment traiter les articles
- `.github/copilot-instructions.md` pour donner le contexte global du projet
- `.github/workflows/copilot-setup-steps.yml` pour préparer l'environnement de l'agent

Depuis l'onglet **Agents** de GitHub, vous pouvez demander par exemple :

> J'ai ajouté un texte dans `content/articles`, détecte les fichiers modifiés, corrige uniquement l'orthographe du Markdown sans changer mon style, puis régénère les pages du blog.

L'agent doit :

1. détecter les Markdown ajoutés, modifiés ou supprimés
2. corriger uniquement l'orthographe du Markdown source
3. relancer `scripts/Generate-Articles.ps1`
4. laisser les pages générées comme simple projection du Markdown

> L'orthographe est corrigée par l'agent manuel, pas par le workflow automatique.

---

### 🔄 Workflow automatique

Le workflow `.github/workflows/generate-articles.yml` :

1. se déclenche au push sur `main` quand le contenu Markdown ou le générateur change
2. régénère `Pages/Articles/` et `Layout/NavMenu.razor`
3. lance un `dotnet build`
4. ouvre une pull request si des fichiers générés ont changé

Le workflow de déploiement GitHub Pages continue ensuite à publier l'application une fois les fichiers générés fusionnés.

---

### 🏠 Générer la page d'accueil depuis Markdown

Vous pouvez aussi piloter l'accueil depuis un Markdown source, par exemple :

```md
---
title: Bonjour
writing_date: 1er Novembre 2024
published: true
listed: false
signature: L'auteur
layout: home
---

Votre texte d'accueil en Markdown.
```

Quand `layout: home` est utilisé :

- le générateur remplace `Pages/Home.razor`
- le contenu ne devient pas un article classique dans `Pages/Articles/`
- la page reste stylée comme le reste du journal

---

### 🌐 Activer GitHub Pages (première fois)

1. Rendez-vous dans les **Settings** du dépôt GitHub.
2. Accédez à l'onglet **Pages**.
3. Sous **Source**, choisissez la branche `gh-pages` et le dossier `/ (root)`.
4. Sauvegardez. Le site sera publié à : `https://lustaaa.github.io/la-vie-d-un-homme`

> **Note :** La branche `gh-pages` est créée automatiquement par le workflow après le premier push sur `main`.

---

### ✅ Vérifier le déploiement

Après chaque commit sur `main`, l'onglet **Actions** du dépôt affiche l'état du déploiement.

Pour vérifier la génération des articles en local :

```powershell
pwsh -File .\scripts\Generate-Articles.ps1
dotnet build
```

> Si `dotnet build` échoue avec une erreur NuGet SSL vers `https://api.nuget.org/v3/index.json`, le blocage vient de l'accès réseau local et non du flux de génération lui-même.

---

## 🗂 Structure du projet

``` 
├── content/
│   └── articles/           # Sources Markdown des articles
├── Pages/
│   ├── Articles/           # Pages .razor générées
│   └── Home.razor          # Page d'accueil (journal intime)
├── Layout/
│   ├── MainLayout.razor    # Mise en page principale
│   └── NavMenu.razor       # Menu de navigation avec zone générée
├── scripts/
│   └── Generate-Articles.ps1
├── wwwroot/
│   ├── css/app.css         # Styles du journal
│   └── index.html          # Point d'entrée HTML
├── .github/workflows/
│   ├── copilot-setup-steps.yml
│   ├── deploy.yml
│   └── generate-articles.yml
├── AGENTS.md               # Instructions pour l'agent GitHub
├── .github/copilot-instructions.md
└── LaVieApp.csproj         # Fichier projet .NET
```
