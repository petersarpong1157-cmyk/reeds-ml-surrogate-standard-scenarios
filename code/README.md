# Code

This folder contains two versions of the analysis script.

- `NREL_ReEDS_Standard_Scenarios.R` — exact text of the author's uploaded R script.
- `reeds_ml_surrogate_analysis_portable.R` — repository-portable copy with file paths changed only so the workflow can run from the repository root.

For the portable script:

1. Download the four official NREL/OEDI Standard Scenarios CSV files.
2. Place them in `data/raw/`.
3. Run the script from the repository root.
4. Generated files are directed to `results/generated/`.

The analytical logic, model specifications, seeds, validation design, tuning grids, and calculations are unchanged in the portable copy. The path edits do not alter the research analysis.
