# La Vie d'un Homme

Un journal intime numérique — émotions, anecdotes et fragments du quotidien.  
Ce projet est construit avec **Blazor WebAssembly (.NET 8)** et déployé automatiquement sur **GitHub Pages**.

🌐 **Site en ligne :** [https://lustaaa.github.io/la-vie-d-un-homme](https://lustaaa.github.io/la-vie-d-un-homme)

---

## 📖 Mode d'emploi

### 🛠 Ajouter une nouvelle page (entrée de journal)

1. Dans le dossier `Pages/`, créez un nouveau fichier `.razor`.  
   Exemple : `Pages/MonJournal.razor`

2. Ajoutez votre contenu avec la directive `@page` :

   ```razor
   @page "/mon-journal"

   <PageTitle>Mon Journal — La Vie d'un Homme</PageTitle>

   <div class="journal-entry">
       <p class="entry-date">Avril 2025</p>
       <h2>Un titre</h2>
       <p>Le contenu de votre entrée...</p>
       <p class="entry-signature">— L'auteur</p>
   </div>
   ```

3. Ajoutez un lien vers cette page dans `Layout/NavMenu.razor` :

   ```razor
   <div class="nav-item px-3">
       <NavLink class="nav-link" href="mon-journal">
           <span aria-hidden="true"></span> Mon Journal
       </NavLink>
   </div>
   ```

4. Poussez vos modifications vers la branche `main`. Le workflow GitHub Actions déploiera automatiquement les changements.

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

---

## 🗂 Structure du projet

```
├── Pages/
│   └── Home.razor          # Page d'accueil (journal intime)
├── Layout/
│   ├── MainLayout.razor    # Mise en page principale
│   └── NavMenu.razor       # Menu de navigation
├── wwwroot/
│   ├── css/app.css         # Styles du journal
│   └── index.html          # Point d'entrée HTML
├── .github/workflows/
│   └── deploy.yml          # Workflow GitHub Actions
└── LaVieApp.csproj         # Fichier projet .NET
```
