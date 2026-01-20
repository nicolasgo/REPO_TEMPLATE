# repo__TEMPLATE__data_pipeline

Template de repo pour projets data/pandas (pipelines + notebooks) — prêt à copier/“Use as template”.

> Renomme `_template_pkg` (package Python) + ajuste `pyproject.toml` / imports.

## Démarrage rapide
1. Renommer le repo
2. Renommer le package Python: `src/_template_pkg` → `src/<nom_pkg>`
3. Créer l’env (conda ou autre), puis:
   - `pip install -e .`
4. Utiliser `notebooks/` pour le dev exploratoire
5. Écrire le runbook minimal: `docs/runbook.md`

## Règles
- Pas de data/exports/secrets dans Git (`data/` est ignoré)
- Notebooks: chaque cellule commence par `# cell: ...` (collapsible)
- Helpers: commencent par `_...`
- pandas: zéro warnings (SettingWithCopy/FutureWarning), dtypes stables

> Date de génération: 2026-01-20
