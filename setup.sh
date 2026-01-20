#!/usr/bin/env bash
# cell: setup_sh
# setup.sh — Bootstrap DEV + runtime (macOS/conda friendly)
#
# Ce script finalise un nouveau projet issu du template:
# - (Optionnel) crée/active un env conda
# - installe le projet (pip editable) + deps
# - bootstrap Git (init si nécessaire)
# - installe/active nbstripout pour nettoyer les outputs .ipynb au commit
# - ajoute .gitattributes notebook-friendly (si absent)
#
# Usage:
#   ./setup.sh
#   ./setup.sh --env myenv --python 3.12
#   ./setup.sh --env myenv --python 3.12 --no-conda
#   ./setup.sh --no-git
#
# Notes:
# - Le script n'essaie pas de modifier la config git globale.
# - Il ne push pas et ne configure pas de remote.

set -euo pipefail

ENV_NAME=""
PYTHON_VERSION="3.12"
USE_CONDA="1"
SETUP_GIT="1"

# --- Détecter si le script est "sourcé" (exécuté dans le shell courant)
# Si non sourcé, conda activate ne peut pas persister après la fin du script.
_IS_SOURCED="0"
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  _IS_SOURCED="1"
fi

if [[ "${_IS_SOURCED}" == "0" && "${USE_CONDA}" == "1" ]]; then
  echo "ERROR: Ce script doit être sourcé pour que 'conda activate' persiste."
  echo "Lance-le ainsi:"
  echo "  source ./setup.sh --env <env_name> --python <version>"
  echo "ou:"
  echo "  . ./setup.sh --env <env_name> --python <version>"
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENV_NAME="${2:-}"
      shift 2
      ;;
    --python)
      PYTHON_VERSION="${2:-3.12}"
      shift 2
      ;;
    --no-conda)
      USE_CONDA="0"
      shift 1
      ;;
    --no-git)
      SETUP_GIT="0"
      shift 1
      ;;
    -h|--help)
      cat << 'EOF'
Usage:
  ./setup.sh
  ./setup.sh --env <conda_env_name> --python <3.12>
  ./setup.sh --env <conda_env_name> --python <3.12> --no-conda
  ./setup.sh --no-git

Comportement:
- Runtime: pip install -e . + requirements.txt (si présent)
- Dev: bootstrap Git (init si nécessaire), nbstripout, .gitattributes
EOF
      exit 0
      ;;
    *)
      echo "Argument inconnu: $1"
      exit 2
      ;;
  esac
done

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${PROJECT_ROOT}"

echo "==> project_root: ${PROJECT_ROOT}"
echo "==> use_conda: ${USE_CONDA}"
echo "==> setup_git: ${SETUP_GIT}"
echo "==> env_name: ${ENV_NAME:-<none>}"
echo "==> python_version: ${PYTHON_VERSION}"

# -----------------------
# 1) Bootstrap Git (init minimal)
# -----------------------
if [[ "${SETUP_GIT}" == "1" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git introuvable dans le PATH."
    exit 1
  fi

  if [[ ! -d ".git" ]]; then
    echo "==> init git repo (main)"
    git init >/dev/null
    git switch -c main >/dev/null 2>&1 || git checkout -b main >/dev/null
  else
    echo "==> git repo détecté"
  fi

  # .gitattributes minimal pour éviter certains conflits
  if [[ ! -f ".gitattributes" ]]; then
    cat > .gitattributes << 'EOF'
# Notebooks: évite le bruit et aide à diff/merge
*.ipynb text eol=lf
EOF
    echo "==> .gitattributes créé"
  fi

  # Vérif rapide .gitignore (sans l'écraser)
  if [[ -f ".gitignore" ]]; then
    MISSING=0
    for pat in ".env" "data/" "*.parquet" "*.csv" ".ipynb_checkpoints/"; do
      if ! grep -qxF "${pat}" .gitignore; then
        echo "WARN: .gitignore ne contient pas exactement: ${pat}"
        MISSING=1
      fi
    done
    if [[ "${MISSING}" == "1" ]]; then
      echo "==> Suggestion: ajouter les patterns manquants dans .gitignore (manuel)."
    fi
  else
    echo "WARN: .gitignore absent."
  fi
fi

# -----------------------
# 2) Conda (optionnel)
# -----------------------
if [[ "${USE_CONDA}" == "1" && -n "${ENV_NAME}" ]]; then
  if command -v conda >/dev/null 2>&1; then
    CONDA_BASE="$(conda info --base)"
    # shellcheck disable=SC1090
    source "${CONDA_BASE}/etc/profile.d/conda.sh"

    if conda env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
      echo "==> conda env existe: ${ENV_NAME}"
    else
      echo "==> création conda env: ${ENV_NAME} (python=${PYTHON_VERSION})"
      conda create -y -n "${ENV_NAME}" "python=${PYTHON_VERSION}" >/dev/null
      echo "==> env créé"
    fi

    echo "==> activation conda env: ${ENV_NAME}"
    conda activate "${ENV_NAME}"
  else
    echo "WARN: conda non détecté. Installation dans le Python actif."
  fi
fi

# -----------------------
# 3) Python/pip
# -----------------------
if ! command -v python >/dev/null 2>&1; then
  echo "ERROR: python introuvable dans le PATH."
  exit 1
fi

echo "==> python: $(python --version)"
python -m pip install -U pip >/dev/null

# Install projet en editable si possible
if [[ -f "pyproject.toml" ]]; then
  echo "==> pip install -e ."
  python -m pip install -e . >/dev/null
else
  echo "WARN: pyproject.toml absent. Skip installation editable."
fi

# Deps additionnelles
if [[ -f "requirements.txt" ]]; then
  echo "==> pip install -r requirements.txt"
  python -m pip install -r requirements.txt >/dev/null
fi

# .env (optionnel)
if [[ -f ".env.example" && ! -f ".env" ]]; then
  echo "==> création .env depuis .env.example"
  cp ".env.example" ".env"
fi

# -----------------------
# 4) nbstripout (dev quality pour notebooks)
# -----------------------
if [[ "${SETUP_GIT}" == "1" ]]; then
  echo "==> installation nbstripout"
  python -m pip install nbstripout >/dev/null

  echo "==> activation nbstripout (repo local)"
  nbstripout --install >/dev/null

  # Bonus: activer un "clean" automatique des outputs au commit
  # (nbstripout le fait via filtres git; pas besoin de hook custom)
  echo "==> nbstripout OK"
fi

cat << EOF

✅ Setup terminé.

À faire ensuite (manuel):
- Ajouter un remote si nouveau repo:
    git remote add origin git@github.com:ORG/REPO.git
    git push -u origin main

EOF
