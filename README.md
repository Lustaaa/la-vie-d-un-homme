# la-vie-d-un-homme

Ce projet est un **blog** conçu pour être hébergé avec GitHub Pages. Il utilise Blazor WebAssembly afin de créer une expérience interactive et élégante.

## 📖 Mode d'emploi

### 🛠 Ajouter des pages au blog
Les étapes suivantes vous guideront pour ajouter des pages supplémentaires au blog :
1. Dans votre projet Blazor, ajoutez un fichier `.razor` dans le dossier `Pages`.
   - Par exemple : `MonJournal.razor`
2. Ajoutez le contenu de votre page dans le fichier. Exemple :
   ```razor
   @page "/mon-journal"

   <h1>Mon Journal</h1>
   <p>Ceci est une nouvelle page de mon blog !</p>
   ```
3. Ajoutez un lien vers votre nouvelle page dans la navigation (`NavMenu.razor`) située dans le dossier `Shared`.

   Exemple : Ajoutez ce bloc dans le menu de navigation :
   ```razor
   <NavLink href="/mon-journal" class="nav-link">Mon Journal</NavLink>
   ```

4. Poussez vos modifications vers la branche `main`. Le workflow GitHub Actions déploiera automatiquement vos modifications.

### 🌐 Activer GitHub Pages
1. Rendez-vous dans les **Settings** du dépôt GitHub.
2. Accédez à l'onglet **Pages**.
3. Sous **Source**, choisissez la branche `gh-pages`.

Votre site sera publié à l'adresse : `https://<votre-nom-utilisateur>.github.io/la-vie-d-un-homme`.

### ✅ Vérifiez le déploiement
Après chaque commit sur la branche `main`, GitHub Actions déclenchera automatiquement un déploiement. Vous pouvez vérifier l'état du déploiement sous l'onglet **Actions** dans GitHub.

---

## 📝 À propos
Ce projet est un journal intime numérique retraçant la vie, les sentiments, les désirs et les craintes d'un homme. Écrit en Blazor WebAssembly, il est conçu pour évoluer de manière continue avec de nouveaux chapitres et pages.