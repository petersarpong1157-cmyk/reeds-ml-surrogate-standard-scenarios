# ReEDS machine-learning surrogate validation — 2024 Standard Scenarios

Reproducibility materials for the revised study:

**Validation-Unit Choice and Generalization Reliability in Machine-Learning Surrogates of Electricity-System Scenarios: Evidence from NREL ReEDS**

This repository investigates **how the unit of validation changes estimated predictive reliability** of machine-learning surrogates trained on National Renewable Energy Laboratory (NREL) 2024 ReEDS Standard Scenarios. The principal contrast is **random observation-level validation** versus **complete policy–sensitivity scenario-level holdout**; the two designs assess different prediction tasks.

## Study design

- Full source dataset: 61 ReEDS scenarios, 48 states, 9 model years (2026–2050), 26,352 state–scenario–year rows.
- Balanced experimental subset: **51 configurations**, from 17 sensitivity families × 3 policy regimes; **22,032 observations**.
- Primary complete-scenario holdout: **34 configurations** (14,688 observations) for training and **17** (7,344 observations) for testing, one withheld policy configuration within each sensitivity family.
- Methods: Linear Regression, Random Forest, XGBoost.
- Targets: state-level utility-scale PV capacity (`upv_MW`, MW); net lifecycle CO₂e (`co2e_net_mt` converted to million metric tons, Mt).
- Robustness comparison: **20 observation-level partitions and 20 scenario-level partitions per target** (80 run-level records in the supplied four files). Repeated scenario assignments use a balanced 6/6/5 policy allocation. The finite scenario set means assignments can overlap.

## Central validation results

**Means across 20 runs per design (exported run-level CSVs rechecked for consistency):**

| Target | Validation unit | Mean RMSE | Mean MAE | Mean predictive R² |
|---|---|---:|---:|---:|
| PV capacity | Random observations | 2,082.93 MW | 899.50 MW | 0.99020 |
| PV capacity | Complete scenarios | 3,239.12 MW | 1,229.47 MW | 0.97627 |
| Net lifecycle CO₂e | Random observations | 2.0123 Mt | 1.0587 Mt | 0.99141 |
| Net lifecycle CO₂e | Complete scenarios | 3.5701 Mt | 1.5453 Mt | 0.97160 |

Scenario-level mean RMSE is **55.5% higher** for PV and **77.4% higher** for CO₂e; corresponding MAE increases are **36.7%** and **46.0%**. These are *descriptive contrasts between prediction tasks*, not causal effects of a validation switch or tests of statistical significance.

The main finding is **not** a novel cross-validation algorithm. It is an application-specific estimate of how much evaluation conclusions change when the withheld unit corresponds to the intended scenario-combination use case.

## Files added with this update

| File | Contents |
|---|---|
| `results/validation/PV_random_validation_20_runs.csv` | 20 random observation-level PV test evaluations |
| `results/validation/CO2e_random_validation_20_runs.csv` | 20 random observation-level CO₂e test evaluations |
| `results/validation/Supplementary_Table_S5_PV_Repeated_Holdouts.csv` | 20 balanced scenario-level PV evaluations |
| `results/validation/Supplementary_Table_S6_CO2e_Repeated_Holdouts.csv` | 20 balanced scenario-level CO₂e evaluations |
| `results/validation/validation_summary_exact.csv` | Mean, SD, median, and ranges by outcome and validation method |
| `results/validation/validation_effect_exact.csv` | Descriptive between-design mean differences |
| `figures/Figure3_Sensitivity_Family_RMSE.png` | Combined PV/CO₂e sensitivity-family error diagnostic |

If identical files already exist elsewhere in this repository, **keep one authoritative copy** and adjust these paths accordingly. This update does not alter existing R analysis scripts, previously archived data, citation metadata, or licensed content.

## Primary-holdout model comparison

| Outcome | Model | RMSE | MAE | Predictive R² |
|---|---|---:|---:|---:|
| PV | Linear Regression | 8,372 MW | 4,656 MW | 0.838 |
| PV | Random Forest | 4,475 MW | 2,096 MW | 0.954 |
| PV | XGBoost | 2,994 MW | 1,212 MW | 0.979 |
| Net lifecycle CO₂e | Linear Regression | 12.8 Mt | 8.40 Mt | 0.646 |
| Net lifecycle CO₂e | Random Forest | 4.77 Mt | 2.30 Mt | 0.951 |
| Net lifecycle CO₂e | XGBoost | 2.84 Mt | 1.43 Mt | 0.983 |

These values were reported for the original primary split and are distinct from the means of 20 repeated partitions.

## Reproducing the analysis

1. Download the **2024 NREL ReEDS Standard Scenarios** data from the official dataset DOI: https://doi.org/10.25984/2504171 (report: https://doi.org/10.2172/2496240).
2. Place source files in `data/raw/` (not included in GitHub):
   - `StdScen24_annual_states.csv`
   - `StdScen24_annual_national.csv`
   - `StdScen24_annual_balancingAreas.csv`
   - `StdScen24_transmission_capacities.csv`
3. Inspect the existing repository `code/` scripts and associated software provenance. The source files use three leading documentation rows (`readr::read_csv(..., skip = 3)`).
4. For numerical checking without refitting models, compare the four run-level CSVs against `validation_summary_exact.csv` and `validation_effect_exact.csv`.

**Reproducibility qualification:** The exported run-level metrics and summary calculations have been checked for internal consistency, but a clean, end-to-end rerun of model training from the original NREL datasets has **not** been independently established for this revision. Existing code includes exploratory/development stages; do not claim a fresh clean run solely because the CSV checks pass.

### Important interpretation limits

- Withheld complete configurations use *policy and sensitivity levels present elsewhere in training*. This is **unseen-combination generalization**, not arbitrary extrapolation to unseen policy regimes, states, or technologies.
- The scenario-level repeated fits used fixed hyperparameters selected during original model development; they were **not** independently tuned in each holdout. Previously evaluated configurations may appear in other repeated assignments.
- Random observation and complete-scenario splitting measure **different generalization targets**; row-count matching alone does not isolate a causal effect.
- The Figure 3 family-level diagnostics correspond to **one held-out policy configuration per family** under the primary split. They are not policy-averaged family effects.
- Permutation importance measures predictive reliance, not causal impact.

## Citation and archival provenance

The existing repository includes `CITATION.cff`, an MIT license, and a prior Zenodo archive DOI: https://doi.org/10.5281/zenodo.23170134. **Check whether that archived release includes this update before citing it as the archive for the revised version.** If not, publish a new versioned release/archive and use its appropriate DOI.

## Manuscript venue

The latest author-prepared manuscript draft is being tailored for *Energy Sources, Part B: Economics, Planning, and Policy*. This does **not** imply journal acceptance or publication.

## License and data rights

Retain the repository's existing MIT license for author-created code. The NREL data are not redistributed here; users must obtain them directly under the data source's own terms.
