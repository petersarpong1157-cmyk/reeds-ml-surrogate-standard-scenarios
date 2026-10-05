# PORTABLE REPOSITORY COPY
# Analysis logic is unchanged from the author's uploaded script.
# Only file paths were changed so the script can run from the repository root.
# Raw NREL files belong in data/raw/ and generated outputs go to results/generated/.

# ============================================================
# NREL STANDARD SCENARIOS 2024
# STATE-LEVEL MACHINE LEARNING DATASET
# ============================================================

library(tidyverse)
library(caret)
library(randomForest)
library(xgboost)

dir.create("results/generated", recursive = TRUE, showWarnings = FALSE)

# ============================================================
# CORRECTLY IMPORT NREL STANDARD SCENARIOS 2024 FILES
# ============================================================

library(tidyverse)

StdScen24_annual_balancingAreas <- read_csv(
  "data/raw/StdScen24_annual_balancingAreas.csv",
  skip = 3,
  show_col_types = FALSE
)

StdScen24_annual_national <- read_csv(
  "data/raw/StdScen24_annual_national.csv",
  skip = 3,
  show_col_types = FALSE
)

StdScen24_annual_states <- read_csv(
  "data/raw/StdScen24_annual_states.csv",
  skip = 3,
  show_col_types = FALSE
)

StdScen24_transmission_capacities <- read_csv(
  "data/raw/StdScen24_transmission_capacities.csv",
  skip = 3,
  show_col_types = FALSE
)

dim(StdScen24_annual_balancingAreas)
dim(StdScen24_annual_national)
dim(StdScen24_annual_states)
dim(StdScen24_transmission_capacities)

# ============================================================
# VERIFY MAIN MACHINE LEARNING DATASET
# ============================================================

states <- StdScen24_annual_states

glimpse(states)

cat(
  "Scenarios:",
  n_distinct(states$scenario),
  "\n"
)

cat(
  "Years:",
  n_distinct(states$t),
  "\n"
)

cat(
  "States:",
  n_distinct(states$state),
  "\n"
)

cat(
  "Rows:",
  nrow(states),
  "\n"
)

cat(
  "Missing values:",
  sum(is.na(states)),
  "\n"
)

duplicates <- states %>%
  count(
    scenario,
    state,
    t
  ) %>%
  filter(n > 1)

print(duplicates)

sort(unique(states$t))

# ============================================================
# 3. CHECK MODEL YEARS
# ============================================================

sort(unique(states$t))

# ============================================================
# 4. SCENARIO-POLICY STRUCTURE
# ============================================================

scenario_policy <- states %>%
  distinct(
    scenario,
    policy
  ) %>%
  arrange(
    policy,
    scenario
  )

print(
  scenario_policy,
  n = Inf
)


scenario_policy %>%
  count(
    policy,
    name = "number_of_scenarios"
  ) %>%
  arrange(
    desc(number_of_scenarios)
  ) %>%
  print(n = Inf)


# ============================================================
# 5. PRIMARY TARGET:
# UTILITY-SCALE SOLAR PV CAPACITY
# ============================================================

summary(
  states$upv_MW
)

states %>%
  summarise(
    minimum_MW = min(upv_MW),
    q1_MW = quantile(upv_MW, 0.25),
    median_MW = median(upv_MW),
    mean_MW = mean(upv_MW),
    q3_MW = quantile(upv_MW, 0.75),
    maximum_MW = max(upv_MW)
  )

# ============================================================
# 6. SOLAR CAPACITY BY YEAR
# ============================================================

solar_by_year <- states %>%
  group_by(t) %>%
  summarise(
    mean_upv_MW = mean(upv_MW),
    median_upv_MW = median(upv_MW),
    min_upv_MW = min(upv_MW),
    max_upv_MW = max(upv_MW),
    .groups = "drop"
  )

print(solar_by_year)


ggplot(
  solar_by_year,
  aes(
    x = t,
    y = mean_upv_MW
  )
) +
  geom_line(
    linewidth = 1
  ) +
  geom_point(
    size = 2
  ) +
  labs(
    title = "Average State-Level Utility-Scale PV Capacity",
    subtitle = "NREL ReEDS Standard Scenarios 2024",
    x = "Model Year",
    y = "Mean Utility-Scale PV Capacity (MW)"
  ) +
  theme_minimal()

# ============================================================
# 7. 2050 SCENARIO VARIATION
# ============================================================

solar_2050 <- states %>%
  filter(
    t == 2050
  ) %>%
  group_by(
    scenario,
    policy
  ) %>%
  summarise(
    national_upv_MW = sum(upv_MW),
    .groups = "drop"
  ) %>%
  arrange(
    desc(national_upv_MW)
  )

print(
  solar_2050,
  n = Inf
)

# ============================================================
# 7. CREATE THE 61-SCENARIO MASTER TABLE
# ============================================================

scenario_master <- states %>%
  distinct(
    scenario,
    policy
  ) %>%
  arrange(
    policy,
    scenario
  )

print(
  scenario_master,
  n = Inf
)

cat(
  "\nNumber of unique scenario-policy combinations:",
  nrow(scenario_master),
  "\n"
)


# ============================================================
# 8. COUNT SCENARIOS BY POLICY REGIME
# ============================================================

policy_counts <- scenario_master %>%
  count(
    policy,
    name = "number_of_scenarios"
  ) %>%
  arrange(
    desc(number_of_scenarios)
  )

print(
  policy_counts,
  n = Inf
)

# ============================================================
# 9. LIST ALL 61 SCENARIO NAMES
# ============================================================

scenario_names <- states %>%
  distinct(scenario) %>%
  arrange(scenario)

print(
  scenario_names,
  n = Inf
)



# ============================================================
# 10. EXAMINE UTILITY-SCALE SOLAR PV CAPACITY
# ============================================================

summary(
  states$upv_MW
)

solar_summary <- states %>%
  summarise(
    minimum_MW = min(upv_MW),
    q1_MW = quantile(upv_MW, 0.25),
    median_MW = median(upv_MW),
    mean_MW = mean(upv_MW),
    q3_MW = quantile(upv_MW, 0.75),
    maximum_MW = max(upv_MW),
    sd_MW = sd(upv_MW)
  )

print(solar_summary)


# ============================================================
# 11. HOW MUCH DOES SOLAR CAPACITY VARY ACROSS SCENARIOS?
# ============================================================

solar_2050 <- states %>%
  filter(t == 2050) %>%
  group_by(
    scenario,
    policy
  ) %>%
  summarise(
    national_upv_MW = sum(upv_MW),
    .groups = "drop"
  ) %>%
  arrange(
    desc(national_upv_MW)
  )

print(
  solar_2050,
  n = Inf
)

ggplot(
  solar_2050,
  aes(
    x = reorder(scenario, national_upv_MW),
    y = national_upv_MW
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "2050 Utility-Scale Solar Capacity Across ReEDS Scenarios",
    subtitle = "NREL Standard Scenarios 2024",
    x = "Scenario",
    y = "National Utility-Scale PV Capacity (MW)"
  ) +
  theme_minimal()

# ============================================================
# 12. BUILD THE BALANCED CORE SCENARIO DESIGN
# ============================================================

core_policies <- c(
  "currentPolicies",
  "Decarb_CO2e_100by2035",
  "No_TC_Expiration"
)


core_scenarios <- scenario_master %>%
  
  filter(
    policy %in% core_policies,
    scenario != "Mid_Case_NoNascent"
  ) %>%
  
  mutate(
    
    sensitivity = case_when(
      
      policy == "Decarb_CO2e_100by2035" ~
        str_remove(
          scenario,
          "_CO2e_100by2035$"
        ),
      
      policy == "No_TC_Expiration" ~
        str_remove(
          scenario,
          "_No_TC_Expiration$"
        ),
      
      TRUE ~ scenario
    ),
    
    # One naming inconsistency exists in the downloaded data:
    # DC_Tran under the CO2e policy versus DC_Trans elsewhere.
    sensitivity = recode(
      sensitivity,
      "DC_Tran" = "DC_Trans"
    )
  )


print(
  core_scenarios,
  n = Inf
)


cat(
  "\nCore scenarios:",
  nrow(core_scenarios),
  "\n"
)

cat(
  "Sensitivity families:",
  n_distinct(core_scenarios$sensitivity),
  "\n"
)

cat(
  "Core policies:",
  n_distinct(core_scenarios$policy),
  "\n"
)

# ============================================================
# 13. VERIFY THE 17 x 3 FACTORIAL STRUCTURE
# ============================================================

core_check <- core_scenarios %>%
  
  count(
    sensitivity,
    name = "number_of_policies"
  ) %>%
  
  arrange(
    sensitivity
  )

print(
  core_check,
  n = Inf
)


stopifnot(
  nrow(core_check) == 17,
  all(core_check$number_of_policies == 3)
)


cat(
  "\n17 x 3 CORE SCENARIO STRUCTURE: PASS\n"
)

# ============================================================
# 15. CONVERT SCENARIO SENSITIVITIES INTO ML INPUT FEATURES
# ============================================================

scenario_features <- core_scenarios %>%
  
  mutate(
    
    # --------------------------------------------------------
    # ELECTRICITY / HYDROGEN DEMAND ASSUMPTION
    # --------------------------------------------------------
    
    demand_case = case_when(
      
      sensitivity == "High_H2_and_Demand" ~
        "high_demand_plus_hydrogen",
      
      sensitivity == "High_H2" ~
        "reference_demand_plus_hydrogen",
      
      sensitivity == "High_Demand_Growth" ~
        "high",
      
      sensitivity == "Low_Demand_Growth" ~
        "low",
      
      TRUE ~
        "reference"
    ),
    
    
    # --------------------------------------------------------
    # RENEWABLE + BATTERY COST/PERFORMANCE
    # --------------------------------------------------------
    
    re_cost_case = case_when(
      
      sensitivity == "Adv_RE" ~
        "advanced",
      
      sensitivity == "Con_RE" ~
        "conservative",
      
      TRUE ~
        "moderate"
    ),
    
    
    # --------------------------------------------------------
    # CCS COST/PERFORMANCE
    # --------------------------------------------------------
    
    ccs_case = case_when(
      
      sensitivity == "Adv_CCS" ~
        "advanced",
      
      sensitivity == "Con_CCS" ~
        "conservative",
      
      TRUE ~
        "moderate"
    ),
    
    
    # --------------------------------------------------------
    # NUCLEAR COST
    # --------------------------------------------------------
    
    nuclear_case = case_when(
      
      sensitivity == "Adv_Nuclear" ~
        "advanced",
      
      sensitivity == "Con_Nuclear" ~
        "conservative",
      
      TRUE ~
        "moderate"
    ),
    
    
    # --------------------------------------------------------
    # NATURAL GAS SENSITIVITY
    #
    # Leave the labels exactly as supplied for now.
    # We will verify the Adv_NG / Con_NG numerical mapping
    # before calling them high-price or low-price.
    # --------------------------------------------------------
    
    ng_case = case_when(
      
      sensitivity == "Adv_NG" ~
        "Adv_NG",
      
      sensitivity == "Con_NG" ~
        "Con_NG",
      
      TRUE ~
        "reference"
    ),
    
    
    # --------------------------------------------------------
    # TRANSMISSION AVAILABILITY
    # --------------------------------------------------------
    
    transmission_case = case_when(
      
      sensitivity == "DC_Trans" ~
        "high",
      
      sensitivity == "Limited_Trans" ~
        "low",
      
      TRUE ~
        "reference"
    ),
    
    
    # --------------------------------------------------------
    # DIRECT AIR CAPTURE
    # --------------------------------------------------------
    
    dac_allowed = if_else(
      sensitivity == "DAC",
      "yes",
      "no"
    ),
    
    
    # --------------------------------------------------------
    # RENEWABLE RESOURCE AVAILABILITY
    # --------------------------------------------------------
    
    re_resource_case = if_else(
      sensitivity == "Reduced_RE_Resource",
      "reduced",
      "default"
    )
  )

# ============================================================
# 16. JOIN INPUT FEATURES TO STATE-LEVEL ReEDS OUTPUTS
# ============================================================

ml_data <- states %>%
  
  inner_join(
    scenario_features,
    by = c(
      "scenario",
      "policy"
    )
  ) %>%
  
  select(
    
    # identifiers
    scenario,
    sensitivity,
    state,
    t,
    
    # input assumptions
    policy,
    demand_case,
    re_cost_case,
    ccs_case,
    nuclear_case,
    ng_case,
    transmission_case,
    dac_allowed,
    re_resource_case,
    
    # target
    upv_MW
  )


glimpse(ml_data)


cat(
  "\nML observations:",
  nrow(ml_data),
  "\n"
)

cat(
  "ML scenarios:",
  n_distinct(ml_data$scenario),
  "\n"
)

cat(
  "Sensitivity families:",
  n_distinct(ml_data$sensitivity),
  "\n"
)

cat(
  "Missing values:",
  sum(is.na(ml_data)),
  "\n"
)

# ============================================================
# 17. VALIDATE STATE SUMS AGAINST NREL NATIONAL RESULTS
# ============================================================

national <- StdScen24_annual_national


state_upv_check <- states %>%
  group_by(
    scenario,
    policy,
    t
  ) %>%
  summarise(
    state_sum_upv_MW = sum(upv_MW),
    .groups = "drop"
  )


national_upv_check <- national %>%
  select(
    scenario,
    policy,
    t,
    national_upv_MW = upv_MW
  )


upv_validation <- state_upv_check %>%
  inner_join(
    national_upv_check,
    by = c(
      "scenario",
      "policy",
      "t"
    )
  ) %>%
  mutate(
    difference_MW =
      state_sum_upv_MW - national_upv_MW,
    
    absolute_difference_MW =
      abs(difference_MW),
    
    relative_difference_pct =
      100 *
      absolute_difference_MW /
      pmax(abs(national_upv_MW), 1)
  )


upv_validation %>%
  summarise(
    comparisons = n(),
    max_absolute_difference_MW =
      max(absolute_difference_MW),
    mean_absolute_difference_MW =
      mean(absolute_difference_MW),
    max_relative_difference_pct =
      max(relative_difference_pct)
  ) %>%
  print()

upv_validation %>%
  arrange(
    desc(absolute_difference_MW)
  ) %>%
  select(
    scenario,
    policy,
    t,
    state_sum_upv_MW,
    national_upv_MW,
    difference_MW
  ) %>%
  head(20)



# ============================================================
# 18. CREATE BALANCED SCENARIO-GROUPED TRAIN/TEST SPLIT
# ============================================================

set.seed(20241003)


sensitivities <- sort(
  unique(core_scenarios$sensitivity)
)


# 17 test assignments:
# approximately balanced across the three policy regimes

test_policy_pool <- c(
  rep("currentPolicies", 6),
  rep("Decarb_CO2e_100by2035", 6),
  rep("No_TC_Expiration", 5)
)


test_assignment <- tibble(
  sensitivity = sensitivities,
  test_policy = sample(test_policy_pool)
)


print(
  test_assignment,
  n = Inf
)


split_map <- core_scenarios %>%
  
  left_join(
    test_assignment,
    by = "sensitivity"
  ) %>%
  
  mutate(
    dataset = if_else(
      policy == test_policy,
      "test",
      "train"
    )
  )


split_map %>%
  count(
    dataset,
    policy
  ) %>%
  print()



train_scenarios <- split_map %>%
  filter(dataset == "train") %>%
  pull(scenario)


test_scenarios <- split_map %>%
  filter(dataset == "test") %>%
  pull(scenario)


train_data <- ml_data %>%
  filter(
    scenario %in% train_scenarios
  )


test_data <- ml_data %>%
  filter(
    scenario %in% test_scenarios
  )


cat(
  "\nTraining scenarios:",
  n_distinct(train_data$scenario),
  "\n"
)

cat(
  "Testing scenarios:",
  n_distinct(test_data$scenario),
  "\n"
)

cat(
  "Training observations:",
  nrow(train_data),
  "\n"
)

cat(
  "Testing observations:",
  nrow(test_data),
  "\n"
)

cat(
  "Scenario overlap:",
  length(
    intersect(
      unique(train_data$scenario),
      unique(test_data$scenario)
    )
  ),
  "\n"
)


# ============================================================
# 19. PREPARE MODEL FEATURES
# ============================================================

categorical_features <- c(
  "state",
  "policy",
  "demand_case",
  "re_cost_case",
  "ccs_case",
  "nuclear_case",
  "ng_case",
  "transmission_case",
  "dac_allowed",
  "re_resource_case"
)


for (v in categorical_features) {
  
  all_levels <- sort(
    unique(ml_data[[v]])
  )
  
  train_data[[v]] <- factor(
    train_data[[v]],
    levels = all_levels
  )
  
  test_data[[v]] <- factor(
    test_data[[v]],
    levels = all_levels
  )
}


# Make time easier to interpret

train_data <- train_data %>%
  mutate(
    year_index = (t - 2026) / 3
  )


test_data <- test_data %>%
  mutate(
    year_index = (t - 2026) / 3
  )



# ============================================================
# 20. LINEAR REGRESSION BENCHMARK
# ============================================================

lm_model <- lm(
  
  upv_MW ~
    
    state +
    
    year_index +
    I(year_index^2) +
    
    policy +
    
    demand_case +
    
    re_cost_case +
    
    ccs_case +
    
    nuclear_case +
    
    ng_case +
    
    transmission_case +
    
    dac_allowed +
    
    re_resource_case,
  
  data = train_data
)


summary(lm_model)


# ============================================================
# 21. LINEAR MODEL TEST PREDICTIONS
# ============================================================

lm_pred <- predict(
  lm_model,
  newdata = test_data
)


# Solar capacity cannot physically be negative

lm_pred <- pmax(
  lm_pred,
  0
)

# ============================================================
# 22. TEST-SET PERFORMANCE
# ============================================================

rmse_lm <- RMSE(
  lm_pred,
  test_data$upv_MW
)

mae_lm <- MAE(
  lm_pred,
  test_data$upv_MW
)

r2_lm <- R2(
  lm_pred,
  test_data$upv_MW
)


lm_results <- tibble(
  Model = "Linear Regression",
  RMSE_MW = rmse_lm,
  MAE_MW = mae_lm,
  R2 = r2_lm
)


print(lm_results)


lm_results <- lm_results %>%
  mutate(
    NRMSE_pct =
      100 *
      RMSE_MW /
      mean(test_data$upv_MW),
    
    NMAE_pct =
      100 *
      MAE_MW /
      mean(test_data$upv_MW)
  )


print(lm_results)


# ============================================================
# 23. COMMON TEST-SET EVALUATION FUNCTION
# ============================================================

evaluate_model <- function(actual, predicted, model_name) {
  
  # Capacity cannot be negative
  predicted <- pmax(predicted, 0)
  
  rmse <- sqrt(
    mean(
      (actual - predicted)^2
    )
  )
  
  mae <- mean(
    abs(
      actual - predicted
    )
  )
  
  r2_test <- 1 -
    sum(
      (actual - predicted)^2
    ) /
    sum(
      (actual - mean(actual))^2
    )
  
  tibble(
    Model = model_name,
    RMSE_MW = rmse,
    MAE_MW = mae,
    R2_test = r2_test,
    NRMSE_pct =
      100 * rmse / mean(actual),
    NMAE_pct =
      100 * mae / mean(actual)
  )
}


# Re-evaluate linear regression

lm_results_final <- evaluate_model(
  actual = test_data$upv_MW,
  predicted = lm_pred,
  model_name = "Linear Regression"
)

print(lm_results_final)

# ============================================================
# 24. GROUPED CROSS-VALIDATION FOR TRAINING DATA
# ============================================================

library(caret)
library(randomForest)

set.seed(20241003)

# Each scenario stays entirely within a CV fold
group_folds <- groupKFold(
  train_data$scenario,
  k = 5
)

train_control <- trainControl(
  method = "cv",
  index = group_folds,
  savePredictions = "final",
  verboseIter = TRUE
)

# ============================================================
# 25. RANDOM FOREST SURROGATE
# ============================================================

rf_formula <- upv_MW ~
  
  state +
  
  year_index +
  
  policy +
  
  demand_case +
  
  re_cost_case +
  
  ccs_case +
  
  nuclear_case +
  
  ng_case +
  
  transmission_case +
  
  dac_allowed +
  
  re_resource_case


rf_grid <- expand.grid(
  mtry = c(
    3,
    5,
    7,
    9
  )
)


set.seed(20241003)

rf_model <- train(
  rf_formula,
  data = train_data,
  method = "rf",
  metric = "RMSE",
  trControl = train_control,
  tuneGrid = rf_grid,
  ntree = 500,
  importance = TRUE
)


print(rf_model)

plot(rf_model)

# ============================================================
# 26. RANDOM FOREST TEST PERFORMANCE
# ============================================================

rf_pred <- predict(
  rf_model,
  newdata = test_data
)


rf_results <- evaluate_model(
  actual = test_data$upv_MW,
  predicted = rf_pred,
  model_name = "Random Forest"
)

print(rf_results)



# ============================================================
# 27. RANDOM FOREST VARIABLE IMPORTANCE
# ============================================================

rf_importance <- varImp(
  rf_model
)

print(rf_importance)

plot(
  rf_importance,
  top = 20
)

# ============================================================
# 28. XGBOOST SURROGATE
# ============================================================

library(xgboost)


xgb_grid <- expand.grid(
  
  nrounds = c(
    300,
    600
  ),
  
  max_depth = c(
    4,
    6
  ),
  
  eta = c(
    0.03,
    0.08
  ),
  
  gamma = 0,
  
  colsample_bytree = 0.8,
  
  min_child_weight = 1,
  
  subsample = 0.8
)


set.seed(20241003)

xgb_model <- train(
  rf_formula,
  data = train_data,
  method = "xgbTree",
  metric = "RMSE",
  trControl = train_control,
  tuneGrid = xgb_grid,
  verbose = FALSE
)


print(xgb_model)

plot(xgb_model)


# ============================================================
# 29. XGBOOST TEST PERFORMANCE
# ============================================================

xgb_pred <- predict(
  xgb_model,
  newdata = test_data
)


xgb_results <- evaluate_model(
  actual = test_data$upv_MW,
  predicted = xgb_pred,
  model_name = "XGBoost"
)

print(xgb_results)



# ============================================================
# 30. FINAL MODEL COMPARISON
# ============================================================

model_comparison <- bind_rows(
  lm_results_final,
  rf_results,
  xgb_results
) %>%
  
  arrange(
    RMSE_MW
  )


print(
  model_comparison
)



ggplot(
  model_comparison,
  aes(
    x = reorder(Model, RMSE_MW),
    y = RMSE_MW
  )
) +
  
  geom_col() +
  
  coord_flip() +
  
  labs(
    title = "Surrogate Model Performance on Unseen ReEDS Scenarios",
    subtitle = "Prediction of State-Level Utility-Scale PV Capacity",
    x = NULL,
    y = "Test RMSE (MW)"
  ) +
  
  theme_minimal()



# ============================================================
# 31. LOCK EXPLICIT 5-FOLD GROUPED CROSS-VALIDATION
# ============================================================

set.seed(20241003)

group_folds <- groupKFold(
  train_data$scenario,
  k = 5
)

length(group_folds)

train_control_final <- trainControl(
  method = "cv",
  number = 5,
  index = group_folds,
  savePredictions = "final",
  verboseIter = TRUE
)

# Confirm that complete scenarios stay grouped
sapply(
  group_folds,
  length
)

# ============================================================
# 32. FINAL RANDOM FOREST TUNING
# ============================================================

rf_grid_final <- expand.grid(
  mtry = c(
    7,
    9,
    11
  )
)

set.seed(20241003)

rf_model_final <- train(
  rf_formula,
  data = train_data,
  method = "rf",
  metric = "RMSE",
  trControl = train_control_final,
  tuneGrid = rf_grid_final,
  ntree = 750,
  importance = TRUE
)

print(rf_model_final)

rf_pred_final <- predict(
  rf_model_final,
  newdata = test_data
)

rf_results_final <- evaluate_model(
  actual = test_data$upv_MW,
  predicted = rf_pred_final,
  model_name = "Random Forest"
)

print(rf_results_final)



# ============================================================
# 33. FINAL XGBOOST TUNING
# ============================================================

xgb_grid_final <- expand.grid(
  
  nrounds = c(
    600,
    900,
    1200
  ),
  
  max_depth = c(
    6,
    8
  ),
  
  eta = c(
    0.05,
    0.08
  ),
  
  gamma = 0,
  
  colsample_bytree = 0.8,
  
  min_child_weight = 1,
  
  subsample = 0.8
)

set.seed(20241003)

xgb_model_final <- train(
  rf_formula,
  data = train_data,
  method = "xgbTree",
  metric = "RMSE",
  trControl = train_control_final,
  tuneGrid = xgb_grid_final,
  verbose = FALSE
)

print(xgb_model_final)

xgb_pred_final <- predict(
  xgb_model_final,
  newdata = test_data
)

xgb_results_final <- evaluate_model(
  actual = test_data$upv_MW,
  predicted = xgb_pred_final,
  model_name = "XGBoost"
)

print(xgb_results_final)



# ============================================================
# 34. FINAL MODEL COMPARISON
# ============================================================

final_model_comparison <- bind_rows(
  lm_results_final,
  rf_results_final,
  xgb_results_final
) %>%
  arrange(RMSE_MW)

print(final_model_comparison)



# ============================================================
# 35. XGBOOST TEST PREDICTION TABLE
# ============================================================

xgb_test_results <- test_data %>%
  
  select(
    scenario,
    sensitivity,
    policy,
    state,
    t,
    upv_MW
  ) %>%
  
  mutate(
    predicted_upv_MW = pmax(
      xgb_pred_final,
      0
    ),
    
    error_MW =
      predicted_upv_MW - upv_MW,
    
    absolute_error_MW =
      abs(error_MW)
  )

glimpse(xgb_test_results)



# ============================================================
# 36. ERROR BY HELD-OUT SCENARIO
# ============================================================

scenario_errors <- xgb_test_results %>%
  
  group_by(
    scenario,
    sensitivity,
    policy
  ) %>%
  
  summarise(
    
    RMSE_MW = sqrt(
      mean(error_MW^2)
    ),
    
    MAE_MW = mean(
      absolute_error_MW
    ),
    
    actual_mean_MW =
      mean(upv_MW),
    
    .groups = "drop"
  ) %>%
  
  arrange(
    desc(RMSE_MW)
  )

print(
  scenario_errors,
  n = Inf
)



# ============================================================
# 37. ERROR BY MODEL YEAR
# ============================================================

year_errors <- xgb_test_results %>%
  
  group_by(t) %>%
  
  summarise(
    
    RMSE_MW = sqrt(
      mean(error_MW^2)
    ),
    
    MAE_MW =
      mean(absolute_error_MW),
    
    .groups = "drop"
  )

print(year_errors)



# ============================================================
# 38. ERROR BY STATE
# ============================================================

state_errors <- xgb_test_results %>%
  
  group_by(state) %>%
  
  summarise(
    
    RMSE_MW = sqrt(
      mean(error_MW^2)
    ),
    
    MAE_MW =
      mean(absolute_error_MW),
    
    mean_capacity_MW =
      mean(upv_MW),
    
    .groups = "drop"
  ) %>%
  
  arrange(
    desc(RMSE_MW)
  )

print(
  state_errors,
  n = Inf
)


# ============================================================
# 39. ACTUAL VS PREDICTED
# ============================================================

ggplot(
  xgb_test_results,
  aes(
    x = upv_MW,
    y = predicted_upv_MW
  )
) +
  
  geom_point(
    alpha = 0.35
  ) +
  
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = "dashed"
  ) +
  
  labs(
    title = "XGBoost Surrogate Predictions on Held-Out ReEDS Scenarios",
    subtitle = "State-Level Utility-Scale PV Capacity",
    x = "Actual ReEDS Capacity (MW)",
    y = "Predicted Capacity (MW)"
  ) +
  
  theme_minimal()



ggplot(
  xgb_test_results,
  aes(
    x = predicted_upv_MW,
    y = error_MW
  )
) +
  
  geom_point(
    alpha = 0.35
  ) +
  
  geom_hline(
    yintercept = 0,
    linetype = "dashed"
  ) +
  
  labs(
    title = "XGBoost Prediction Residuals",
    x = "Predicted Utility-Scale PV Capacity (MW)",
    y = "Prediction Error (MW)"
  ) +
  
  theme_minimal()



# ============================================================
# 40. REPEATED SCENARIO-HOLDOUT ROBUSTNESS TEST
# ============================================================

library(xgboost)
library(tidyverse)

# ------------------------------------------------------------
# Prepare one common modeling data frame
# ------------------------------------------------------------

robust_data <- ml_data %>%
  mutate(
    year_index = (t - 2026) / 3
  )


# Make factor levels fixed across ALL observations

factor_vars <- c(
  "state",
  "policy",
  "demand_case",
  "re_cost_case",
  "ccs_case",
  "nuclear_case",
  "ng_case",
  "transmission_case",
  "dac_allowed",
  "re_resource_case"
)

for (v in factor_vars) {
  robust_data[[v]] <- factor(
    robust_data[[v]],
    levels = sort(unique(robust_data[[v]]))
  )
}


# ------------------------------------------------------------
# Build predictor matrix ONCE
# ------------------------------------------------------------

X_all <- model.matrix(
  ~ state +
    year_index +
    policy +
    demand_case +
    re_cost_case +
    ccs_case +
    nuclear_case +
    ng_case +
    transmission_case +
    dac_allowed +
    re_resource_case - 1,
  data = robust_data
)

y_all <- robust_data$upv_MW


# ------------------------------------------------------------
# Freeze final XGBoost settings
# ------------------------------------------------------------

xgb_params_fixed <- list(
  objective = "reg:squarederror",
  eta = 0.08,
  max_depth = 8,
  gamma = 0,
  colsample_bytree = 0.8,
  min_child_weight = 1,
  subsample = 0.8,
  verbosity = 0
)


# ------------------------------------------------------------
# Storage
# ------------------------------------------------------------

robustness_results <- tibble()


# ============================================================
# 20 REPEATED HOLDOUT EXPERIMENTS
# ============================================================

for (repeat_id in 1:20) {
  
  set.seed(20241003 + repeat_id)
  
  # One policy held out within EACH sensitivity family
  repeat_assignment <- tibble(
    sensitivity = sort(unique(core_scenarios$sensitivity)),
    test_policy = sample(
      core_policies,
      size = 17,
      replace = TRUE
    )
  )
  
  
  repeat_split <- core_scenarios %>%
    left_join(
      repeat_assignment,
      by = "sensitivity"
    ) %>%
    mutate(
      dataset = if_else(
        policy == test_policy,
        "test",
        "train"
      )
    )
  
  
  repeat_train_scenarios <- repeat_split %>%
    filter(dataset == "train") %>%
    pull(scenario)
  
  
  repeat_test_scenarios <- repeat_split %>%
    filter(dataset == "test") %>%
    pull(scenario)
  
  
  train_index <- which(
    robust_data$scenario %in%
      repeat_train_scenarios
  )
  
  test_index <- which(
    robust_data$scenario %in%
      repeat_test_scenarios
  )
  
  
  dtrain <- xgb.DMatrix(
    data = X_all[train_index, ],
    label = y_all[train_index]
  )
  
  
  set.seed(20241003 + repeat_id)
  
  repeat_model <- xgb.train(
    params = xgb_params_fixed,
    data = dtrain,
    nrounds = 1200,
    verbose = 0
  )
  
  
  repeat_pred <- predict(
    repeat_model,
    X_all[test_index, ]
  )
  
  repeat_pred <- pmax(
    repeat_pred,
    0
  )
  
  
  actual <- y_all[test_index]
  
  
  repeat_rmse <- sqrt(
    mean(
      (actual - repeat_pred)^2
    )
  )
  
  
  repeat_mae <- mean(
    abs(
      actual - repeat_pred
    )
  )
  
  
  repeat_r2 <- 1 -
    sum(
      (actual - repeat_pred)^2
    ) /
    sum(
      (actual - mean(actual))^2
    )
  
  
  robustness_results <- bind_rows(
    robustness_results,
    tibble(
      Repeat = repeat_id,
      RMSE_MW = repeat_rmse,
      MAE_MW = repeat_mae,
      R2_test = repeat_r2
    )
  )
  
  
  cat(
    "Finished repeat",
    repeat_id,
    "of 20\n"
  )
}

# ============================================================
# 41. ROBUSTNESS SUMMARY
# ============================================================

print(
  robustness_results,
  n = Inf
)


robustness_summary <- robustness_results %>%
  summarise(
    
    mean_RMSE_MW = mean(RMSE_MW),
    sd_RMSE_MW = sd(RMSE_MW),
    
    median_RMSE_MW = median(RMSE_MW),
    
    min_RMSE_MW = min(RMSE_MW),
    max_RMSE_MW = max(RMSE_MW),
    
    mean_MAE_MW = mean(MAE_MW),
    
    mean_R2 = mean(R2_test),
    sd_R2 = sd(R2_test),
    
    min_R2 = min(R2_test),
    max_R2 = max(R2_test)
  )

print(robustness_summary)


ggplot(
  robustness_results,
  aes(
    x = R2_test
  )
) +
  geom_histogram(
    bins = 10
  ) +
  labs(
    title = "XGBoost Robustness Across Repeated Scenario Holdouts",
    subtitle = "20 independent scenario-combination test assignments",
    x = "Out-of-Sample R²",
    y = "Number of Repeats"
  ) +
  theme_minimal()


# ============================================================
# 42. YEAR-LEVEL SCALE-ADJUSTED ERROR
# ============================================================

year_errors_scaled <- xgb_test_results %>%
  
  group_by(t) %>%
  
  summarise(
    
    mean_actual_MW =
      mean(upv_MW),
    
    RMSE_MW =
      sqrt(mean(error_MW^2)),
    
    MAE_MW =
      mean(abs(error_MW)),
    
    NRMSE_pct =
      100 *
      RMSE_MW /
      mean_actual_MW,
    
    NMAE_pct =
      100 *
      MAE_MW /
      mean_actual_MW,
    
    .groups = "drop"
  )

print(year_errors_scaled)



# ============================================================
# 43. SECOND TARGET: NET LIFECYCLE CO2e EMISSIONS
# ============================================================

# First inspect the target itself

summary(states$co2e_net_mt)

cat(
  "\nMinimum:",
  min(states$co2e_net_mt),
  "\n"
)

cat(
  "Maximum:",
  max(states$co2e_net_mt),
  "\n"
)

cat(
  "Negative observations:",
  sum(states$co2e_net_mt < 0),
  "\n"
)

cat(
  "Zero observations:",
  sum(states$co2e_net_mt == 0),
  "\n"
)



# ============================================================
# 44. VALIDATE STATE CO2e SUM AGAINST NATIONAL RESULTS
# ============================================================

state_co2e_check <- states %>%
  group_by(
    scenario,
    policy,
    t
  ) %>%
  summarise(
    state_sum_co2e_mt = sum(co2e_net_mt),
    .groups = "drop"
  )


national_co2e_check <- national %>%
  select(
    scenario,
    policy,
    t,
    national_co2e_mt = co2e_net_mt
  )


co2e_validation <- state_co2e_check %>%
  inner_join(
    national_co2e_check,
    by = c(
      "scenario",
      "policy",
      "t"
    )
  ) %>%
  mutate(
    difference_mt =
      state_sum_co2e_mt - national_co2e_mt,
    
    absolute_difference_mt =
      abs(difference_mt),
    
    relative_difference_pct =
      100 *
      absolute_difference_mt /
      pmax(abs(national_co2e_mt), 1)
  )


co2e_validation %>%
  summarise(
    comparisons = n(),
    max_absolute_difference_mt =
      max(absolute_difference_mt),
    
    mean_absolute_difference_mt =
      mean(absolute_difference_mt),
    
    max_relative_difference_pct =
      max(relative_difference_pct)
  ) %>%
  print()

# ============================================================
# 45. BUILD CO2e MACHINE-LEARNING TABLE
# ============================================================

co2e_ml_data <- ml_data %>%
  
  select(
    -upv_MW
  ) %>%
  
  left_join(
    states %>%
      select(
        scenario,
        policy,
        state,
        t,
        co2e_net_mt
      ),
    by = c(
      "scenario",
      "policy",
      "state",
      "t"
    )
  ) %>%
  
  mutate(
    co2e_net_Mt =
      co2e_net_mt / 1e6
  )


glimpse(co2e_ml_data)

summary(
  co2e_ml_data$co2e_net_Mt
)

# ============================================================
# 46. APPLY SAME SCENARIO HOLDOUT
# ============================================================

co2e_train <- co2e_ml_data %>%
  filter(
    scenario %in% train_scenarios
  )

co2e_test <- co2e_ml_data %>%
  filter(
    scenario %in% test_scenarios
  )


cat(
  "Training rows:",
  nrow(co2e_train),
  "\n"
)

cat(
  "Testing rows:",
  nrow(co2e_test),
  "\n"
)

cat(
  "Scenario overlap:",
  length(
    intersect(
      unique(co2e_train$scenario),
      unique(co2e_test$scenario)
    )
  ),
  "\n"
)



# ============================================================
# 47. PREPARE CO2e FEATURES
# ============================================================

for (v in categorical_features) {
  
  all_levels <- sort(
    unique(co2e_ml_data[[v]])
  )
  
  co2e_train[[v]] <- factor(
    co2e_train[[v]],
    levels = all_levels
  )
  
  co2e_test[[v]] <- factor(
    co2e_test[[v]],
    levels = all_levels
  )
}


co2e_train <- co2e_train %>%
  mutate(
    year_index = (t - 2026) / 3
  )


co2e_test <- co2e_test %>%
  mutate(
    year_index = (t - 2026) / 3
  )



# ============================================================
# 48. CO2e MODEL FORMULA
# ============================================================

co2e_formula <- co2e_net_Mt ~
  
  state +
  
  year_index +
  
  policy +
  
  demand_case +
  
  re_cost_case +
  
  ccs_case +
  
  nuclear_case +
  
  ng_case +
  
  transmission_case +
  
  dac_allowed +
  
  re_resource_case


# ============================================================
# 49. CO2e LINEAR BENCHMARK
# ============================================================

co2e_lm <- lm(
  co2e_formula,
  data = co2e_train
)

co2e_lm_pred <- predict(
  co2e_lm,
  newdata = co2e_test
)


co2e_lm_results <- evaluate_model(
  actual = co2e_test$co2e_net_Mt,
  predicted = co2e_lm_pred,
  model_name = "Linear Regression"
)

print(co2e_lm_results)

# ============================================================
# 50. EVALUATION FUNCTION FOR VARIABLES THAT MAY BE NEGATIVE
# ============================================================

evaluate_model_unbounded <- function(
    actual,
    predicted,
    model_name
) {
  
  rmse <- sqrt(
    mean(
      (actual - predicted)^2
    )
  )
  
  mae <- mean(
    abs(
      actual - predicted
    )
  )
  
  r2_test <- 1 -
    sum(
      (actual - predicted)^2
    ) /
    sum(
      (actual - mean(actual))^2
    )
  
  tibble(
    Model = model_name,
    RMSE = rmse,
    MAE = mae,
    R2_test = r2_test
  )
}

co2e_lm_results <- evaluate_model_unbounded(
  actual = co2e_test$co2e_net_Mt,
  predicted = co2e_lm_pred,
  model_name = "Linear Regression"
)

print(co2e_lm_results)

# ============================================================
# 51. GROUPED 5-FOLD CV FOR CO2e
# ============================================================

set.seed(20241003)

co2e_group_folds <- groupKFold(
  co2e_train$scenario,
  k = 5
)

co2e_control <- trainControl(
  method = "cv",
  number = 5,
  index = co2e_group_folds,
  savePredictions = "final",
  verboseIter = TRUE
)

length(co2e_group_folds)


# ============================================================
# 52. RANDOM FOREST CO2e SURROGATE
# ============================================================

co2e_rf_grid <- expand.grid(
  mtry = c(
    5,
    7,
    9,
    11
  )
)

set.seed(20241003)

co2e_rf_model <- train(
  co2e_formula,
  data = co2e_train,
  method = "rf",
  metric = "RMSE",
  trControl = co2e_control,
  tuneGrid = co2e_rf_grid,
  ntree = 750,
  importance = TRUE
)

print(co2e_rf_model)


# ============================================================
# 53. RANDOM FOREST CO2e TEST PERFORMANCE
# ============================================================

co2e_rf_pred <- predict(
  co2e_rf_model,
  newdata = co2e_test
)

co2e_rf_results <- evaluate_model_unbounded(
  actual = co2e_test$co2e_net_Mt,
  predicted = co2e_rf_pred,
  model_name = "Random Forest"
)

print(co2e_rf_results)


# ============================================================
# 54. XGBOOST CO2e SURROGATE
# ============================================================

co2e_xgb_grid <- expand.grid(
  
  nrounds = c(
    400,
    800,
    1200
  ),
  
  max_depth = c(
    4,
    6,
    8
  ),
  
  eta = c(
    0.03,
    0.08
  ),
  
  gamma = 0,
  
  colsample_bytree = 0.8,
  
  min_child_weight = 1,
  
  subsample = 0.8
)

set.seed(20241003)

co2e_xgb_model <- train(
  co2e_formula,
  data = co2e_train,
  method = "xgbTree",
  metric = "RMSE",
  trControl = co2e_control,
  tuneGrid = co2e_xgb_grid,
  verbose = FALSE
)

print(co2e_xgb_model)


# ============================================================
# 55. XGBOOST CO2e TEST PERFORMANCE
# ============================================================

co2e_xgb_pred <- predict(
  co2e_xgb_model,
  newdata = co2e_test
)

co2e_xgb_results <- evaluate_model_unbounded(
  actual = co2e_test$co2e_net_Mt,
  predicted = co2e_xgb_pred,
  model_name = "XGBoost"
)

print(co2e_xgb_results)


# ============================================================
# 56. CO2e FINAL MODEL COMPARISON
# ============================================================

co2e_model_comparison <- bind_rows(
  co2e_lm_results,
  co2e_rf_results,
  co2e_xgb_results
) %>%
  arrange(RMSE)

print(co2e_model_comparison)


ggplot(
  co2e_model_comparison,
  aes(
    x = reorder(Model, RMSE),
    y = RMSE
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Surrogate Model Performance for Net Lifecycle CO2e",
    subtitle = "Held-Out ReEDS Scenario Combinations",
    x = NULL,
    y = "Test RMSE (Mt CO2e)"
  ) +
  theme_minimal()

# ============================================================
# 57. XGBOOST CO2e ACTUAL VS PREDICTED
# ============================================================

co2e_test_results <- co2e_test %>%
  select(
    scenario,
    sensitivity,
    policy,
    state,
    t,
    co2e_net_Mt
  ) %>%
  mutate(
    predicted_co2e_Mt = co2e_xgb_pred,
    error_Mt =
      predicted_co2e_Mt - co2e_net_Mt,
    absolute_error_Mt =
      abs(error_Mt)
  )

ggplot(
  co2e_test_results,
  aes(
    x = co2e_net_Mt,
    y = predicted_co2e_Mt
  )
) +
  geom_point(
    alpha = 0.35
  ) +
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = "dashed"
  ) +
  labs(
    title = "XGBoost CO2e Predictions on Held-Out ReEDS Scenarios",
    x = "Actual Net Lifecycle CO2e (Mt)",
    y = "Predicted Net Lifecycle CO2e (Mt)"
  ) +
  theme_minimal()


# ============================================================
# 58. CO2e ERROR BY HELD-OUT SCENARIO
# ============================================================

co2e_scenario_errors <- co2e_test_results %>%
  group_by(
    scenario,
    sensitivity,
    policy
  ) %>%
  summarise(
    RMSE_Mt =
      sqrt(mean(error_Mt^2)),
    MAE_Mt =
      mean(absolute_error_Mt),
    mean_actual_Mt =
      mean(co2e_net_Mt),
    .groups = "drop"
  ) %>%
  arrange(
    desc(RMSE_Mt)
  )

print(
  co2e_scenario_errors,
  n = Inf
)



# ============================================================
# 59. REPEATED HOLDOUT ROBUSTNESS TEST FOR CO2e
# ============================================================

library(xgboost)
library(tidyverse)

co2e_robust_data <- co2e_ml_data %>%
  mutate(
    year_index = (t - 2026) / 3
  )

factor_vars <- c(
  "state",
  "policy",
  "demand_case",
  "re_cost_case",
  "ccs_case",
  "nuclear_case",
  "ng_case",
  "transmission_case",
  "dac_allowed",
  "re_resource_case"
)

for (v in factor_vars) {
  
  co2e_robust_data[[v]] <- factor(
    co2e_robust_data[[v]],
    levels = sort(
      unique(co2e_robust_data[[v]])
    )
  )
}


# ------------------------------------------------------------
# Build model matrix once
# ------------------------------------------------------------

X_co2e <- model.matrix(
  ~ state +
    year_index +
    policy +
    demand_case +
    re_cost_case +
    ccs_case +
    nuclear_case +
    ng_case +
    transmission_case +
    dac_allowed +
    re_resource_case - 1,
  data = co2e_robust_data
)

y_co2e <- co2e_robust_data$co2e_net_Mt


# ------------------------------------------------------------
# Freeze best CO2e XGBoost settings
# ------------------------------------------------------------

co2e_params_fixed <- list(
  
  objective = "reg:squarederror",
  
  eta = 0.08,
  
  max_depth = 6,
  
  gamma = 0,
  
  colsample_bytree = 0.8,
  
  min_child_weight = 1,
  
  subsample = 0.8,
  
  verbosity = 0
)


co2e_robustness_results <- tibble()


# ============================================================
# 20 BALANCED REPEATED HOLDOUTS
# ============================================================

for (repeat_id in 1:20) {
  
  set.seed(20242000 + repeat_id)
  
  # Keep policy representation approximately balanced
  policy_pool <- sample(
    c(
      rep("currentPolicies", 6),
      rep("Decarb_CO2e_100by2035", 6),
      rep("No_TC_Expiration", 5)
    )
  )
  
  
  repeat_assignment <- tibble(
    
    sensitivity =
      sort(
        unique(core_scenarios$sensitivity)
      ),
    
    test_policy =
      policy_pool
  )
  
  
  repeat_split <- core_scenarios %>%
    
    left_join(
      repeat_assignment,
      by = "sensitivity"
    ) %>%
    
    mutate(
      dataset = if_else(
        policy == test_policy,
        "test",
        "train"
      )
    )
  
  
  repeat_train_scenarios <- repeat_split %>%
    filter(dataset == "train") %>%
    pull(scenario)
  
  
  repeat_test_scenarios <- repeat_split %>%
    filter(dataset == "test") %>%
    pull(scenario)
  
  
  train_idx <- which(
    co2e_robust_data$scenario %in%
      repeat_train_scenarios
  )
  
  test_idx <- which(
    co2e_robust_data$scenario %in%
      repeat_test_scenarios
  )
  
  
  dtrain <- xgb.DMatrix(
    data = X_co2e[train_idx, ],
    label = y_co2e[train_idx]
  )
  
  
  set.seed(20242000 + repeat_id)
  
  repeat_model <- xgb.train(
    params = co2e_params_fixed,
    data = dtrain,
    nrounds = 1200,
    verbose = 0
  )
  
  
  predicted <- predict(
    repeat_model,
    X_co2e[test_idx, ]
  )
  
  
  actual <- y_co2e[test_idx]
  
  
  rmse <- sqrt(
    mean(
      (actual - predicted)^2
    )
  )
  
  
  mae <- mean(
    abs(
      actual - predicted
    )
  )
  
  
  r2 <- 1 -
    sum(
      (actual - predicted)^2
    ) /
    sum(
      (actual - mean(actual))^2
    )
  
  
  co2e_robustness_results <- bind_rows(
    
    co2e_robustness_results,
    
    tibble(
      Repeat = repeat_id,
      RMSE_Mt = rmse,
      MAE_Mt = mae,
      R2_test = r2
    )
  )
  
  
  cat(
    "Finished CO2e repeat",
    repeat_id,
    "of 20\n"
  )
}



# ============================================================
# 60. CO2e ROBUSTNESS SUMMARY
# ============================================================

print(
  co2e_robustness_results,
  n = Inf
)


co2e_robustness_summary <-
  co2e_robustness_results %>%
  
  summarise(
    
    mean_RMSE_Mt =
      mean(RMSE_Mt),
    
    sd_RMSE_Mt =
      sd(RMSE_Mt),
    
    median_RMSE_Mt =
      median(RMSE_Mt),
    
    min_RMSE_Mt =
      min(RMSE_Mt),
    
    max_RMSE_Mt =
      max(RMSE_Mt),
    
    mean_MAE_Mt =
      mean(MAE_Mt),
    
    mean_R2 =
      mean(R2_test),
    
    sd_R2 =
      sd(R2_test),
    
    min_R2 =
      min(R2_test),
    
    max_R2 =
      max(R2_test)
  )


print(
  co2e_robustness_summary
)


ggplot(
  co2e_robustness_results,
  aes(
    x = R2_test
  )
) +
  geom_histogram(
    bins = 10
  ) +
  labs(
    title =
      "CO2e XGBoost Robustness Across Repeated Scenario Holdouts",
    subtitle =
      "20 balanced scenario-combination test assignments",
    x = "Out-of-Sample R²",
    y = "Number of Repeats"
  ) +
  theme_minimal()


# ============================================================
# 61. BALANCED PV ROBUSTNESS USING SAME DESIGN AS CO2e
# ============================================================

pv_robust_data <- ml_data %>%
  mutate(
    year_index = (t - 2026) / 3
  )

factor_vars <- c(
  "state",
  "policy",
  "demand_case",
  "re_cost_case",
  "ccs_case",
  "nuclear_case",
  "ng_case",
  "transmission_case",
  "dac_allowed",
  "re_resource_case"
)

for (v in factor_vars) {
  
  pv_robust_data[[v]] <- factor(
    pv_robust_data[[v]],
    levels = sort(
      unique(pv_robust_data[[v]])
    )
  )
}


# ------------------------------------------------------------
# Predictor matrix
# ------------------------------------------------------------

X_pv <- model.matrix(
  
  ~ state +
    year_index +
    policy +
    demand_case +
    re_cost_case +
    ccs_case +
    nuclear_case +
    ng_case +
    transmission_case +
    dac_allowed +
    re_resource_case - 1,
  
  data = pv_robust_data
)

y_pv <- pv_robust_data$upv_MW


# ------------------------------------------------------------
# Freeze final PV XGBoost parameters
# ------------------------------------------------------------

pv_params_fixed <- list(
  
  objective = "reg:squarederror",
  
  eta = 0.08,
  
  max_depth = 8,
  
  gamma = 0,
  
  colsample_bytree = 0.8,
  
  min_child_weight = 1,
  
  subsample = 0.8,
  
  verbosity = 0
)


pv_balanced_robustness <- tibble()


# ============================================================
# SAME 20 BALANCED ASSIGNMENTS AS CO2e
# ============================================================

for (repeat_id in 1:20) {
  
  # IMPORTANT:
  # same seed rule used in CO2e robustness
  set.seed(20242000 + repeat_id)
  
  policy_pool <- sample(
    c(
      rep("currentPolicies", 6),
      rep("Decarb_CO2e_100by2035", 6),
      rep("No_TC_Expiration", 5)
    )
  )
  
  
  repeat_assignment <- tibble(
    
    sensitivity =
      sort(
        unique(core_scenarios$sensitivity)
      ),
    
    test_policy =
      policy_pool
  )
  
  
  repeat_split <- core_scenarios %>%
    
    left_join(
      repeat_assignment,
      by = "sensitivity"
    ) %>%
    
    mutate(
      dataset = if_else(
        policy == test_policy,
        "test",
        "train"
      )
    )
  
  
  repeat_train_scenarios <- repeat_split %>%
    filter(dataset == "train") %>%
    pull(scenario)
  
  
  repeat_test_scenarios <- repeat_split %>%
    filter(dataset == "test") %>%
    pull(scenario)
  
  
  train_idx <- which(
    pv_robust_data$scenario %in%
      repeat_train_scenarios
  )
  
  test_idx <- which(
    pv_robust_data$scenario %in%
      repeat_test_scenarios
  )
  
  
  dtrain <- xgb.DMatrix(
    X_pv[train_idx, ],
    label = y_pv[train_idx]
  )
  
  
  set.seed(20242000 + repeat_id)
  
  pv_repeat_model <- xgb.train(
    params = pv_params_fixed,
    data = dtrain,
    nrounds = 1200,
    verbose = 0
  )
  
  
  predicted <- predict(
    pv_repeat_model,
    X_pv[test_idx, ]
  )
  
  # PV capacity cannot be negative
  predicted <- pmax(
    predicted,
    0
  )
  
  
  actual <- y_pv[test_idx]
  
  
  rmse <- sqrt(
    mean(
      (actual - predicted)^2
    )
  )
  
  mae <- mean(
    abs(
      actual - predicted
    )
  )
  
  r2 <- 1 -
    sum(
      (actual - predicted)^2
    ) /
    sum(
      (actual - mean(actual))^2
    )
  
  
  pv_balanced_robustness <- bind_rows(
    
    pv_balanced_robustness,
    
    tibble(
      Repeat = repeat_id,
      RMSE_MW = rmse,
      MAE_MW = mae,
      R2_test = r2
    )
  )
  
  
  cat(
    "Finished balanced PV repeat",
    repeat_id,
    "of 20\n"
  )
}



# ============================================================
# 62. BALANCED PV ROBUSTNESS SUMMARY
# ============================================================

pv_balanced_summary <- pv_balanced_robustness %>%
  
  summarise(
    
    mean_RMSE_MW =
      mean(RMSE_MW),
    
    sd_RMSE_MW =
      sd(RMSE_MW),
    
    median_RMSE_MW =
      median(RMSE_MW),
    
    min_RMSE_MW =
      min(RMSE_MW),
    
    max_RMSE_MW =
      max(RMSE_MW),
    
    mean_MAE_MW =
      mean(MAE_MW),
    
    mean_R2 =
      mean(R2_test),
    
    sd_R2 =
      sd(R2_test),
    
    min_R2 =
      min(R2_test),
    
    max_R2 =
      max(R2_test)
  )

print(
  pv_balanced_summary
)



# ============================================================
# 63. ROBUSTNESS COMPARISON ACROSS BOTH TARGETS
# ============================================================

robustness_comparison <- tibble(
  
  Outcome = c(
    "Utility-scale PV capacity",
    "Net lifecycle CO2e"
  ),
  
  Mean_R2 = c(
    pv_balanced_summary$mean_R2,
    co2e_robustness_summary$mean_R2
  ),
  
  SD_R2 = c(
    pv_balanced_summary$sd_R2,
    co2e_robustness_summary$sd_R2
  ),
  
  Minimum_R2 = c(
    pv_balanced_summary$min_R2,
    co2e_robustness_summary$min_R2
  ),
  
  Maximum_R2 = c(
    pv_balanced_summary$max_R2,
    co2e_robustness_summary$max_R2
  )
)

print(robustness_comparison)



# ============================================================
# 64. SCENARIO-LEVEL PERMUTATION IMPORTANCE
# ============================================================

library(tidyverse)

scenario_features_to_test <- c(
  "policy",
  "demand_case",
  "re_cost_case",
  "ccs_case",
  "nuclear_case",
  "ng_case",
  "transmission_case",
  "dac_allowed",
  "re_resource_case"
)


# ------------------------------------------------------------
# Generic permutation importance function
# ------------------------------------------------------------

scenario_permutation_importance <- function(
    model,
    test_df,
    outcome,
    features,
    repeats = 30,
    seed = 20241003
) {
  
  actual <- test_df[[outcome]]
  
  base_pred <- predict(
    model,
    newdata = test_df
  )
  
  base_rmse <- sqrt(
    mean(
      (actual - base_pred)^2
    )
  )
  
  results <- tibble()
  
  
  for (feature in features) {
    
    delta_values <- numeric(repeats)
    
    
    for (r in seq_len(repeats)) {
      
      set.seed(
        seed +
          r +
          match(feature, features) * 1000
      )
      
      
      permuted <- test_df
      
      
      # Get one value per scenario
      scenario_map <- permuted %>%
        distinct(
          scenario,
          .data[[feature]]
        )
      
      
      # Shuffle feature across complete scenarios
      shuffled_values <- sample(
        scenario_map[[feature]]
      )
      
      
      names(shuffled_values) <-
        scenario_map$scenario
      
      
      permuted[[feature]] <-
        shuffled_values[
          permuted$scenario
        ]
      
      
      # Preserve original factor levels
      if (is.factor(test_df[[feature]])) {
        
        permuted[[feature]] <- factor(
          permuted[[feature]],
          levels = levels(
            test_df[[feature]]
          )
        )
      }
      
      
      perm_pred <- predict(
        model,
        newdata = permuted
      )
      
      
      perm_rmse <- sqrt(
        mean(
          (actual - perm_pred)^2
        )
      )
      
      
      delta_values[r] <-
        perm_rmse - base_rmse
    }
    
    
    results <- bind_rows(
      results,
      tibble(
        Feature = feature,
        Baseline_RMSE = base_rmse,
        Mean_RMSE_Increase =
          mean(delta_values),
        SD_RMSE_Increase =
          sd(delta_values),
        Percent_RMSE_Increase =
          100 *
          mean(delta_values) /
          base_rmse
      )
    )
  }
  
  
  results %>%
    arrange(
      desc(Mean_RMSE_Increase)
    )
}



# ============================================================
# 65. PV SCENARIO-ASSUMPTION IMPORTANCE
# ============================================================

pv_scenario_importance <-
  scenario_permutation_importance(
    
    model = xgb_model_final,
    
    test_df = test_data,
    
    outcome = "upv_MW",
    
    features =
      scenario_features_to_test,
    
    repeats = 30
  )


print(
  pv_scenario_importance,
  n = Inf
)


# ============================================================
# 66. CO2e SCENARIO-ASSUMPTION IMPORTANCE
# ============================================================

co2e_scenario_importance <-
  scenario_permutation_importance(
    
    model = co2e_xgb_model,
    
    test_df = co2e_test,
    
    outcome = "co2e_net_Mt",
    
    features =
      scenario_features_to_test,
    
    repeats = 30
  )


print(
  co2e_scenario_importance,
  n = Inf
)


# ============================================================
# 67. PV IMPORTANCE FIGURE
# ============================================================

ggplot(
  pv_scenario_importance,
  aes(
    x = reorder(
      Feature,
      Mean_RMSE_Increase
    ),
    y = Mean_RMSE_Increase
  )
) +
  
  geom_col() +
  
  coord_flip() +
  
  labs(
    title =
      "Scenario-Assumption Importance for PV Capacity",
    subtitle =
      "Increase in held-out RMSE after scenario-level permutation",
    x = NULL,
    y = "Increase in RMSE (MW)"
  ) +
  
  theme_minimal()



# ============================================================
# 68. CO2e IMPORTANCE FIGURE
# ============================================================

ggplot(
  co2e_scenario_importance,
  aes(
    x = reorder(
      Feature,
      Mean_RMSE_Increase
    ),
    y = Mean_RMSE_Increase
  )
) +
  
  geom_col() +
  
  coord_flip() +
  
  labs(
    title =
      "Scenario-Assumption Importance for Net Lifecycle CO2e",
    subtitle =
      "Increase in held-out RMSE after scenario-level permutation",
    x = NULL,
    y = "Increase in RMSE (Mt CO2e)"
  ) +
  
  theme_minimal()



# ============================================================
# DEFINE STATE PERMUTATION IMPORTANCE FUNCTION
# ============================================================

state_permutation_importance <- function(
    model,
    test_df,
    outcome,
    repeats = 30,
    seed = 20241003,
    nonnegative = FALSE
) {
  
  actual <- test_df[[outcome]]
  
  base_pred <- predict(
    model,
    newdata = test_df
  )
  
  if (nonnegative) {
    base_pred <- pmax(base_pred, 0)
  }
  
  base_rmse <- sqrt(
    mean(
      (actual - base_pred)^2
    )
  )
  
  increases <- numeric(repeats)
  
  
  for (r in seq_len(repeats)) {
    
    set.seed(seed + r)
    
    permuted <- test_df %>%
      
      group_by(
        scenario,
        t
      ) %>%
      
      mutate(
        state = sample(state)
      ) %>%
      
      ungroup()
    
    
    # Restore factor levels
    permuted$state <- factor(
      permuted$state,
      levels = levels(test_df$state)
    )
    
    
    pred <- predict(
      model,
      newdata = permuted
    )
    
    if (nonnegative) {
      pred <- pmax(pred, 0)
    }
    
    
    perm_rmse <- sqrt(
      mean(
        (actual - pred)^2
      )
    )
    
    
    increases[r] <-
      perm_rmse - base_rmse
  }
  
  
  tibble(
    Feature = "state",
    Baseline_RMSE = base_rmse,
    Mean_RMSE_Increase =
      mean(increases),
    SD_RMSE_Increase =
      sd(increases),
    Percent_RMSE_Increase =
      100 *
      mean(increases) /
      base_rmse
  )
}



# ============================================================
# DEFINE YEAR PERMUTATION IMPORTANCE FUNCTION
# ============================================================

year_permutation_importance <- function(
    model,
    test_df,
    outcome,
    repeats = 30,
    seed = 20241003,
    nonnegative = FALSE
) {
  
  actual <- test_df[[outcome]]
  
  base_pred <- predict(
    model,
    newdata = test_df
  )
  
  if (nonnegative) {
    base_pred <- pmax(base_pred, 0)
  }
  
  base_rmse <- sqrt(
    mean(
      (actual - base_pred)^2
    )
  )
  
  increases <- numeric(repeats)
  
  
  for (r in seq_len(repeats)) {
    
    set.seed(seed + r)
    
    permuted <- test_df %>%
      
      group_by(
        scenario,
        state
      ) %>%
      
      mutate(
        year_index =
          sample(year_index)
      ) %>%
      
      ungroup()
    
    
    pred <- predict(
      model,
      newdata = permuted
    )
    
    if (nonnegative) {
      pred <- pmax(pred, 0)
    }
    
    
    perm_rmse <- sqrt(
      mean(
        (actual - pred)^2
      )
    )
    
    
    increases[r] <-
      perm_rmse - base_rmse
  }
  
  
  tibble(
    Feature = "year",
    Baseline_RMSE = base_rmse,
    Mean_RMSE_Increase =
      mean(increases),
    SD_RMSE_Increase =
      sd(increases),
    Percent_RMSE_Increase =
      100 *
      mean(increases) /
      base_rmse
  )
}


# ============================================================
# STATE AND YEAR IMPORTANCE: PV
# ============================================================

pv_state_importance <- state_permutation_importance(
  model = xgb_model_final,
  test_df = test_data,
  outcome = "upv_MW",
  repeats = 30,
  nonnegative = TRUE
)

pv_year_importance <- year_permutation_importance(
  model = xgb_model_final,
  test_df = test_data,
  outcome = "upv_MW",
  repeats = 30,
  nonnegative = TRUE
)


# ============================================================
# STATE AND YEAR IMPORTANCE: CO2e
# ============================================================

co2e_state_importance <- state_permutation_importance(
  model = co2e_xgb_model,
  test_df = co2e_test,
  outcome = "co2e_net_Mt",
  repeats = 30,
  nonnegative = FALSE
)

co2e_year_importance <- year_permutation_importance(
  model = co2e_xgb_model,
  test_df = co2e_test,
  outcome = "co2e_net_Mt",
  repeats = 30,
  nonnegative = FALSE
)


print(pv_state_importance)
print(pv_year_importance)

print(co2e_state_importance)
print(co2e_year_importance)


# ============================================================
# 73. FINAL PAPER-READY IMPORTANCE SUMMARY
# ============================================================

pv_space_time <- bind_rows(
  pv_state_importance,
  pv_year_importance
) %>%
  mutate(
    Outcome = "Utility-scale PV capacity"
  )

co2e_space_time <- bind_rows(
  co2e_state_importance,
  co2e_year_importance
) %>%
  mutate(
    Outcome = "Net lifecycle CO2e"
  )

space_time_importance <- bind_rows(
  pv_space_time,
  co2e_space_time
) %>%
  select(
    Outcome,
    Feature,
    Baseline_RMSE,
    Mean_RMSE_Increase,
    SD_RMSE_Increase,
    Percent_RMSE_Increase
  )

print(
  space_time_importance,
  n = Inf
)


# ============================================================
# 74. FINAL PERFORMANCE TABLE
# ============================================================

final_performance_table <- tibble(
  
  Outcome = c(
    rep("Utility-scale PV capacity", 3),
    rep("Net lifecycle CO2e", 3)
  ),
  
  Model = c(
    "Linear Regression",
    "Random Forest",
    "XGBoost",
    "Linear Regression",
    "Random Forest",
    "XGBoost"
  ),
  
  RMSE = c(
    8372,
    4475,
    2994,
    12.8,
    4.77,
    2.84
  ),
  
  MAE = c(
    4656,
    2096,
    1212,
    8.40,
    2.30,
    1.43
  ),
  
  R2_test = c(
    0.838,
    0.954,
    0.979,
    0.646,
    0.951,
    0.983
  ),
  
  Unit = c(
    rep("MW", 3),
    rep("Mt CO2e", 3)
  )
)

print(final_performance_table)


# ============================================================
# 75. FINAL ROBUSTNESS TABLE
# ============================================================

final_robustness_table <- tibble(
  
  Outcome = c(
    "Utility-scale PV capacity",
    "Net lifecycle CO2e"
  ),
  
  Mean_R2 = c(
    pv_balanced_summary$mean_R2,
    co2e_robustness_summary$mean_R2
  ),
  
  SD_R2 = c(
    pv_balanced_summary$sd_R2,
    co2e_robustness_summary$sd_R2
  ),
  
  Minimum_R2 = c(
    pv_balanced_summary$min_R2,
    co2e_robustness_summary$min_R2
  ),
  
  Maximum_R2 = c(
    pv_balanced_summary$max_R2,
    co2e_robustness_summary$max_R2
  )
)

print(final_robustness_table)


# ============================================================
# 76. SAVE FINAL RESEARCH RESULTS
# ============================================================

write_csv(
  final_performance_table,
  "results/generated/final_model_performance.csv"
)

write_csv(
  final_robustness_table,
  "results/generated/final_robustness_results.csv"
)

write_csv(
  pv_scenario_importance,
  "results/generated/pv_scenario_importance.csv"
)

write_csv(
  co2e_scenario_importance,
  "results/generated/co2e_scenario_importance.csv"
)

write_csv(
  space_time_importance,
  "results/generated/space_time_importance.csv"
)

write_csv(
  scenario_errors,
  "results/generated/pv_scenario_errors.csv"
)

write_csv(
  co2e_scenario_errors,
  "results/generated/co2e_scenario_errors.csv"
)


# ============================================================
# 77. SAVE FINAL RESULTS DIRECTLY FROM MODEL OBJECTS
# ============================================================

final_performance_exact <- bind_rows(
  
  lm_results_final %>%
    transmute(
      Outcome = "Utility-scale PV capacity",
      Model,
      RMSE = RMSE_MW,
      MAE = MAE_MW,
      R2_test,
      Unit = "MW"
    ),
  
  rf_results_final %>%
    transmute(
      Outcome = "Utility-scale PV capacity",
      Model,
      RMSE = RMSE_MW,
      MAE = MAE_MW,
      R2_test,
      Unit = "MW"
    ),
  
  xgb_results_final %>%
    transmute(
      Outcome = "Utility-scale PV capacity",
      Model,
      RMSE = RMSE_MW,
      MAE = MAE_MW,
      R2_test,
      Unit = "MW"
    ),
  
  co2e_lm_results %>%
    transmute(
      Outcome = "Net lifecycle CO2e",
      Model,
      RMSE,
      MAE,
      R2_test,
      Unit = "Mt CO2e"
    ),
  
  co2e_rf_results %>%
    transmute(
      Outcome = "Net lifecycle CO2e",
      Model,
      RMSE,
      MAE,
      R2_test,
      Unit = "Mt CO2e"
    ),
  
  co2e_xgb_results %>%
    transmute(
      Outcome = "Net lifecycle CO2e",
      Model,
      RMSE,
      MAE,
      R2_test,
      Unit = "Mt CO2e"
    )
)



# ============================================================
# FIX OUTPUT FOLDER
# ============================================================

getwd()

dir.exists("results/generated")

dir.create(
  "results/generated",
  recursive = TRUE,
  showWarnings = TRUE
)

dir.exists("results/generated")

writeLines(
  "test",
  "results/generated/test.txt"
)

file.exists(
  "results/generated/test.txt"
)

file.remove(
  "results/generated/test.txt"
)

# ============================================================
# SAVE SUPPLEMENTARY TABLES
# ============================================================

write_csv(
  supp_table_s1,
  "results/generated/Supplementary_Table_S1_Core_Scenarios.csv"
)

write_csv(
  supp_table_s2,
  "results/generated/Supplementary_Table_S2_Feature_Mapping.csv"
)

write_csv(
  supp_table_s3,
  "results/generated/Supplementary_Table_S3_PV_Scenario_Errors.csv"
)

write_csv(
  supp_table_s4,
  "results/generated/Supplementary_Table_S4_CO2e_Scenario_Errors.csv"
)

write_csv(
  pv_balanced_robustness,
  "results/generated/Supplementary_Table_S5_PV_Holdouts.csv"
)

write_csv(
  co2e_robustness_results,
  "results/generated/Supplementary_Table_S6_CO2e_Holdouts.csv"
)



# ============================================================
# SAVE MODEL TUNING RESULTS
# ============================================================

supp_rf_pv <- rf_model_final$results
supp_rf_co2e <- co2e_rf_model$results

supp_xgb_pv <- xgb_model_final$results
supp_xgb_co2e <- co2e_xgb_model$results


write_csv(
  supp_rf_pv,
  "results/generated/Supplementary_Table_S7a_PV_RF_Tuning.csv"
)

write_csv(
  supp_rf_co2e,
  "results/generated/Supplementary_Table_S7b_CO2e_RF_Tuning.csv"
)

write_csv(
  supp_xgb_pv,
  "results/generated/Supplementary_Table_S8a_PV_XGB_Tuning.csv"
)

write_csv(
  supp_xgb_co2e,
  "results/generated/Supplementary_Table_S8b_CO2e_XGB_Tuning.csv"
)

list.files(
  "results/generated"
)

# ============================================================
# CREATE SUPPLEMENTARY TABLE S4
# ============================================================

supp_table_s4 <- co2e_scenario_errors %>%
  arrange(desc(RMSE_Mt))

print(
  supp_table_s4,
  n = Inf
)

write_csv(
  supp_table_s4,
  "results/generated/Supplementary_Table_S4_CO2e_Scenario_Errors.csv"
)

file.exists(
  "results/generated/Supplementary_Table_S4_CO2e_Scenario_Errors.csv"
)


# ============================================================
# SUPPLEMENTARY TABLE S5
# PV REPEATED HOLDOUT RESULTS
# ============================================================

supp_table_s5 <- pv_balanced_robustness

write_csv(
  supp_table_s5,
  "results/generated/Supplementary_Table_S5_PV_Repeated_Holdouts.csv"
)


# ============================================================
# SUPPLEMENTARY TABLE S6
# CO2e REPEATED HOLDOUT RESULTS
# ============================================================

supp_table_s6 <- co2e_robustness_results

write_csv(
  supp_table_s6,
  "results/generated/Supplementary_Table_S6_CO2e_Repeated_Holdouts.csv"
)


# ============================================================
# SUPPLEMENTARY TABLE S7
# RANDOM FOREST TUNING
# ============================================================

supp_table_s7a <- rf_model_final$results

supp_table_s7b <- co2e_rf_model$results


write_csv(
  supp_table_s7a,
  "results/generated/Supplementary_Table_S7a_PV_RF_Tuning.csv"
)

write_csv(
  supp_table_s7b,
  "results/generated/Supplementary_Table_S7b_CO2e_RF_Tuning.csv"
)


# ============================================================
# SUPPLEMENTARY TABLE S8
# XGBOOST TUNING
# ============================================================

supp_table_s8a <- xgb_model_final$results

supp_table_s8b <- co2e_xgb_model$results


write_csv(
  supp_table_s8a,
  "results/generated/Supplementary_Table_S8a_PV_XGB_Tuning.csv"
)

write_csv(
  supp_table_s8b,
  "results/generated/Supplementary_Table_S8b_CO2e_XGB_Tuning.csv"
)


# ============================================================
# SOFTWARE / SESSION INFORMATION
# ============================================================

capture.output(
  sessionInfo(),
  file =
    "results/generated/R_session_info.txt"
)

capture.output(
  citation("tidyverse"),
  file =
    "results/generated/citation_tidyverse.txt"
)

capture.output(
  citation("caret"),
  file =
    "results/generated/citation_caret.txt"
)

capture.output(
  citation("randomForest"),
  file =
    "results/generated/citation_randomForest.txt"
)

capture.output(
  citation("xgboost"),
  file =
    "results/generated/citation_xgboost.txt"
)


# ============================================================
# VERIFY FINAL RESEARCH OUTPUTS
# ============================================================

list.files(
  "results/generated"
)

cat(
  "\nNumber of files saved:",
  length(
    list.files(
      "results/generated"
    )
  ),
  "\n"
)
