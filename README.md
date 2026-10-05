# Machine Learning Surrogate Models for U.S. Electricity-System Futures

Reproducibility materials for:

**Machine Learning Surrogate Models for Rapid Exploration of U.S. Electricity-System Futures: Evidence from NREL ReEDS Standard Scenarios**

Author: **Peter Sarpong**

## Overview

This project evaluates whether machine-learning surrogate models can reproduce selected state-level outputs from the 2024 NREL Standard Scenarios generated with the Regional Energy Deployment System (ReEDS).

The core experiment uses:

- 51 scenarios
- 17 sensitivity families
- 3 recurring policy regimes
- 48 states
- 9 model years (2026–2050)
- 22,032 state-scenario-year observations
- 34 training scenarios and 17 completely held-out test scenarios

Models compared:

- Linear Regression
- Random Forest
- XGBoost

Prediction targets:

- Utility-scale photovoltaic capacity (`upv_MW`)
- Net lifecycle CO2e emissions (`co2e_net_mt`, converted to Mt CO2e)

## Main verified results

| Outcome | Model | RMSE | MAE | Test R² |
|---|---|---:|---:|---:|
| Utility-scale PV capacity | Linear Regression | 8,372 MW | 4,656 MW | 0.838 |
| Utility-scale PV capacity | Random Forest | 4,475 MW | 2,096 MW | 0.954 |
| Utility-scale PV capacity | XGBoost | 2,994 MW | 1,212 MW | 0.979 |
| Net lifecycle CO2e | Linear Regression | 12.8 Mt | 8.40 Mt | 0.646 |
| Net lifecycle CO2e | Random Forest | 4.77 Mt | 2.30 Mt | 0.951 |
| Net lifecycle CO2e | XGBoost | 2.84 Mt | 1.43 Mt | 0.983 |

Across 20 balanced repeated scenario-combination holdouts, mean XGBoost R² was 0.976 for PV capacity and 0.972 for net lifecycle CO2e.

## Data source

The repository does **not** redistribute the raw NREL Standard Scenarios files.

Source dataset:

Gagnon, P., Pham, A., Cole, W., & Hamilton, A. (2024). *2024 Standard Scenarios: A U.S. Electricity Sector Outlook* [Data set]. Open Energy Data Initiative, National Renewable Energy Laboratory.

Dataset DOI: https://doi.org/10.25984/2504171

Associated report DOI: https://doi.org/10.2172/2496240

Download the source data from the official repository and place the four CSV files in `data/raw/`:

- `StdScen24_annual_states.csv`
- `StdScen24_annual_national.csv`
- `StdScen24_annual_balancingAreas.csv`
- `StdScen24_transmission_capacities.csv`

The files contain documentation/header rows before the machine-readable header. The analysis imports these files with `skip = 3`.

## Validation design

The primary validation does not randomly split state-year rows. Instead, complete policy-sensitivity scenario combinations are withheld from training. This produces 34 training scenarios and 17 test scenarios with zero scenario overlap.

The repeated robustness experiment uses 20 balanced scenario-combination holdouts with 6 current-policy, 6 CO2e-decarbonization, and 5 no-tax-credit-expiration test cases in each repetition.

## Interpretation

Permutation importance is treated as **predictive reliance, not causal effect**.

State and model year are dominant structural predictors. Among scenario assumptions, demand contributes most strongly to PV-capacity prediction, whereas policy regime dominates net-lifecycle-CO2e prediction.

## Repository structure

```text
.
├── README.md
├── CITATION.cff
├── .gitignore
├── code/
├── data/
│   └── README.md
├── results/
│   └── README.md
├── figures/
└── metadata/
    └── ZENODO_METADATA.md
```

## Reproducibility contents

The repository now includes the exact R-exported model-performance, robustness, scenario-error, permutation-importance, and Supplementary Tables S1–S8 supplied by the author.

The `code/` folder contains both the exact uploaded R script and a repository-portable copy whose analytical logic is unchanged; only file paths were adjusted.

Software provenance is stored in `metadata/software/`, including `R_session_info.txt` and package citation records.

Raw NREL Standard Scenarios files are not redistributed. Download them from the official OEDI record and place them in `data/raw/`.

## Scope and limitations

This repository supports reproduction of the published surrogate-model experiment. The trained models are evaluated for scenario-combination generalization within the represented Standard Scenario domain. They are not validated for arbitrary out-of-domain technologies, policies, states, or continuous numerical assumption combinations.

## License

The analysis code and reproducibility package are released under the **MIT License**. The raw NREL Standard Scenarios data are not redistributed and remain subject to the terms of their original source.
