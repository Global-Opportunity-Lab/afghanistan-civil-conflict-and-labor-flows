"""
run_paper_figures_tables.py

Runs the Python figure scripts in paper_figures_tables/ in sequence.
Must be executed with code/ as the working directory:

    cd path/to/repo/code
    python3 run_paper_figures_tables.py

Before running, set up the virtual environment from the repo root:

    python3 -m venv pft_env
    source pft_env/bin/activate          # macOS / Linux
    pip install -r code/requirements_paper_figures_tables.txt

Outputs:
  FigS3.py  — prints MODIS-Landsat comparison table to stdout
  FigS11.py — writes paper_figures_tables/output/figS11.pdf
"""

import subprocess
import sys
import os
from datetime import datetime


def run_script(path: str) -> None:
    print(f"[{datetime.now():%H:%M:%S}] Running {path} ...")
    result = subprocess.run(
        [sys.executable, path],
        cwd=os.path.dirname(os.path.abspath(__file__)),  # always run from code/
    )
    if result.returncode != 0:
        raise RuntimeError(f"{path} exited with code {result.returncode}")
    print("  done.")


if __name__ == "__main__":
    run_script("paper_figures_tables/FigS3.py")
    run_script("paper_figures_tables/FigS11.py")

    print("\nAll Python scripts finished.")
    print("FigS11 PDF: paper_figures_tables/output/figS11.pdf")
