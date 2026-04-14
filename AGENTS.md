# Agent articles

Quand un utilisateur dit qu'il a ajoute ou modifie un texte dans `content/articles`, considere que le Markdown est la source de verite du blog.

## Procedure a suivre

1. Identifie les fichiers Markdown ajoutes, modifies ou supprimes dans `content/articles` en priorite via `git status` puis, si besoin, via un diff avec la branche de base.
2. Pour chaque article Markdown modifie, corrige **uniquement l'orthographe** dans le fichier source. Ne reformule pas, ne change pas le ton, ne raccourcis pas et ne reecris pas le texte.
3. Gere la correspondance prenom → abréviation :
   a. **Important** : Si le front matter contient deja un champ `correspondance` (dictionnaire YAML bloc multi-ligne, cles indentees sous `correspondance:`), utilise cette table telle quelle pour l'anonymisation du corps du texte. La valeur d'une abréviation peut etre d'une seule lettre (ex : `Margaux: "M"`) ou de plusieurs lettres (ex : `Justine: "Ju"`) — les deux sont valides. **Ne jamais regenerer ni remplacer une abréviation si le prenom est deja present dans la table, quelle que soit la longueur de l'abréviation.**
   b. Si le champ `correspondance` est absent, detecte dans le corps du texte tous les mots qui semblent etre des prenoms (commence par une majuscule, n'est pas en debut de phrase ni un titre connu), genere pour chacun une abréviation par defaut (deux premieres lettres en conservant la casse initiale, ex : Melanie → Me, Justine → Ju, Aurelie → Au, Laurent → La), puis ecris ce dictionnaire dans le front matter sous la cle `correspondance` au format YAML bloc multi-ligne (chaque entree indentee de deux espaces sur sa propre ligne) avant de continuer. Cette table generee sera visible dans la PR pour etre validee par l'auteur.
   c. Dans le corps du texte (hors front matter YAML), applique la correspondance pour remplacer chaque prenom par son abréviation. N'anonymise pas les termes qui ne sont pas des prenoms.
4. Verifie que le front matter YAML respecte le contrat suivant :
   - obligatoires : `title`, `writing_date`
   - optionnels : `published`, `listed`, `signature`, `layout`, `series`, `part`, `correspondance`
5. Lance `pwsh -File ./scripts/Generate-Articles.ps1`.
6. Controle les fichiers generes :
   - `Pages/Articles/GeneratedArticle_*.razor`
   - `Pages/Home.razor` si un Markdown utilise `layout: home`
   - `Layout/NavMenu.razor`
7. Si un article Markdown est supprime ou passe en `published: false`, la page Razor correspondante et son lien de menu doivent disparaitre.
8. Si `listed: false`, conserve la page publiee mais retire le lien du menu.
9. Si l'article appartient a une serie (`series` + `part`), preserve la navigation precedent/suivant et la liste complete de la serie.

## Contraintes importantes

- Ne modifie jamais directement une page generee pour corriger son contenu : corrige toujours le Markdown source puis regenere.
- Le workflow GitHub Actions automatise la regeneration structurelle, mais la correction orthographique releve du travail de l'agent quand un humain lui demande de traiter un article.
- Les fichiers sous `content/articles/_templates` sont des modeles et ne doivent pas etre publies.
- `layout: home` signifie que le Markdown source doit alimenter `Pages/Home.razor` plutot qu'une page d'article classique.
- Le champ `correspondance` utilise le format YAML bloc multi-ligne : la cle `correspondance:` est sur sa propre ligne, et chaque entree prenom/abréviation est indentee de deux espaces en dessous (ex : `  Margaux: "M"`). Ce format est different d'une valeur scalaire et doit etre lu comme un dictionnaire.
