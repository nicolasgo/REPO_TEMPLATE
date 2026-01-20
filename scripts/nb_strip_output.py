#!/usr/bin/env python3
# cell: nb_strip_output_py
# Nettoie les outputs d'un notebook (.ipynb) pour réduire le bruit en commit.
# Usage: python scripts/nb_strip_output.py notebooks/dev.ipynb
import sys, json
from pathlib import Path

def main(p: Path) -> int:
    nb = json.loads(p.read_text(encoding="utf-8"))
    for cell in nb.get("cells", []):
        if cell.get("cell_type") == "code":
            cell["outputs"] = []
            cell["execution_count"] = None
    p.write_text(json.dumps(nb, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return 0

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python scripts/nb_strip_output.py <notebook.ipynb>")
        raise SystemExit(2)
    raise SystemExit(main(Path(sys.argv[1])))
