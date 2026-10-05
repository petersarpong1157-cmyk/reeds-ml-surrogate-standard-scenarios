# Data

Raw NREL data are not redistributed in this repository.

Download the 2024 Standard Scenarios dataset from the official OEDI record:

- Dataset DOI: https://doi.org/10.25984/2504171
- Report DOI: https://doi.org/10.2172/2496240

Expected raw files:

1. `StdScen24_annual_states.csv`
2. `StdScen24_annual_national.csv`
3. `StdScen24_annual_balancingAreas.csv`
4. `StdScen24_transmission_capacities.csv`

Place them in `data/raw/`.

The CSV files use three documentation/header rows before the machine-readable column names, so the R workflow imports them using `readr::read_csv(..., skip = 3)`.
