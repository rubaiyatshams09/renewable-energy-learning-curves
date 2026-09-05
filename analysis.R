# =============================================================================
# Renewable Energy Learning Curves
# Author: Rubaiyat Shams
# September 2026
#
# AI assistance:
# R code development was assisted by Anthropic's Claude.
# The code was reviewed, checked, and executed by the author.
# Analytical decisions, interpretation, and conclusions
# are the responsibility of the author.
#
# To run: set the working directory to the project root (below), then source
# this file. Data files are expected in data/, outputs are written to
# figures/ and output/.
# =============================================================================


# ---- Setup ------------------------------------------------------------------

# Run once, then leave commented out:
# install.packages(c("tidyverse", "readxl", "scales", "knitr", "gridExtra"))

library(tidyverse)
library(readxl)
library(scales)
library(knitr)
library(gridExtra)
library(grid)

# Run this script from the project root directory.

dir.create("figures", showWarnings = FALSE)
dir.create("output",  showWarnings = FALSE)

# Shared objects, defined once ------------------------------------------------

palette_tech <- c(
  "Onshore wind"    = "#1B7F79",
  "Offshore wind"   = "#2E5E8C",
  "Solar PV"        = "#E8A33D",
  "Battery storage" = "#8C4F9F",
  "Hydropower"      = "#6B7280",
  "Bioenergy"       = "#A3714F"
)

theme_report <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title            = element_text(face = "bold", size = base_size * 1.25,
                                           margin = margin(b = 4)),
      plot.subtitle         = element_text(colour = "grey35", size = base_size * 0.92,
                                           margin = margin(b = 14)),
      plot.caption          = element_text(colour = "grey55", size = base_size * 0.72,
                                           hjust = 0, margin = margin(t = 14)),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      axis.title            = element_text(colour = "grey35", size = base_size * 0.85),
      axis.text             = element_text(colour = "grey40"),
      panel.grid.minor      = element_blank(),
      panel.grid.major      = element_line(colour = "grey92", linewidth = 0.3),
      strip.text            = element_text(face = "bold", hjust = 0, size = base_size * 0.95),
      legend.position       = "top",
      legend.justification  = "left",
      legend.title          = element_blank(),
      plot.margin           = margin(16, 20, 12, 16)
    )
}

source_note <- "Source: IRENA (2026), Renewable Power Generation Costs in 2025. Analysis by R. Shams."

# Indicative cost floors. These are analytical assumptions used to test the
# behaviour of the extrapolation. They are not sourced from IRENA.
floors <- tibble(
  technology = c("Onshore wind", "Offshore wind", "Solar PV"),
  floor_tic  = c(700, 1800, 275)
)

learning_techs <- c("Solar PV", "Onshore wind", "Battery storage", "Offshore wind")


# ---- Step 1: Load the data --------------------------------------------------

capacity_raw <- read_csv("data/installed-global-renewable-energy-capacity-by-technology.csv")

cost_file <- "data/IRENA_TEC_RPGC_in_2025_data_file_2026.xlsx"

onshore_raw  <- read_excel(cost_file, sheet = "Fig 2.3",  range = "B5:R8", col_names = FALSE)
offshore_raw <- read_excel(cost_file, sheet = "Fig 4.3",  range = "B5:R8", col_names = FALSE)
solar_raw    <- read_excel(cost_file, sheet = "Fig 3.1",  range = "B5:R8", col_names = FALSE)
battery_raw  <- read_excel(cost_file, sheet = "Fig. 9.2", range = "D5:S6", col_names = FALSE)

# Battery deployment volumes are on a separate sheet, as gross annual additions
battery_vol_raw <- read_excel(cost_file, sheet = "Fig. 9.1", range = "D5:N6", col_names = FALSE)

# Two construction-led technologies, used as a contrast
hydro_raw <- read_excel(cost_file, sheet = "Fig 6.2", range = "B5:R8", col_names = FALSE)
bio_raw   <- read_excel(cost_file, sheet = "Fig 8.2", range = "B5:R8", col_names = FALSE)


# ---- Step 2: Tidy the cost data ---------------------------------------------

# IRENA sheets store years across columns. This pulls out the year row and the
# global weighted-average row.
tidy_irena <- function(raw, tech, year_row = 1, value_row = 3, first_col = 2) {
  tibble(
    technology = tech,
    year = as.numeric(unlist(raw[year_row,  first_col:ncol(raw)])),
    tic  = as.numeric(unlist(raw[value_row, first_col:ncol(raw)]))
  )
}

cost <- bind_rows(
  tidy_irena(onshore_raw,  "Onshore wind"),
  tidy_irena(offshore_raw, "Offshore wind"),
  tidy_irena(solar_raw,    "Solar PV"),
  tidy_irena(hydro_raw,    "Hydropower"),
  tidy_irena(bio_raw,      "Bioenergy"),
  # Battery sheet has no percentile rows and no label column
  tidy_irena(battery_raw,  "Battery storage", year_row = 1, value_row = 2, first_col = 1)
)


# ---- Step 3: Capacity data, then join ---------------------------------------

# Note on the volume variable: IRENA publishes installed capacity stock, defined
# as capacity installed and connected at the end of each calendar year. This is
# not cumulative deployment. See the memo Limitations section.

capacity_value_column <- names(capacity_raw)[3]

cap_lookup <- c(
  "Onshore wind"       = "Onshore wind",
  "Offshore wind"      = "Offshore wind",
  "Solar photovoltaic" = "Solar PV",
  "Hydropower"         = "Hydropower",
  "Bioenergy (total)"  = "Bioenergy"
)

capacity <- capacity_raw %>%
  rename(installed_capacity_stock_gw = all_of(capacity_value_column)) %>%
  filter(Entity %in% names(cap_lookup)) %>%
  mutate(technology = unname(cap_lookup[Entity])) %>%
  select(technology, year = Year, installed_capacity_stock_gw)

# Batteries are the exception: this is cumulative deployment, in GWh, built from
# gross annual additions. Not directly comparable with the net stock series above.
battery_cap <- tibble(
  technology = "Battery storage",
  year       = as.numeric(unlist(battery_vol_raw[1, ])),
  additions  = as.numeric(unlist(battery_vol_raw[2, ]))
) %>%
  mutate(installed_capacity_stock_gw = cumsum(additions)) %>%
  select(technology, year, installed_capacity_stock_gw)

capacity <- bind_rows(capacity, battery_cap)

df <- cost %>%
  inner_join(capacity, by = c("technology", "year")) %>%
  filter(!is.na(tic), !is.na(installed_capacity_stock_gw))

latest_year <- max(df$year)

df
df %>% count(technology)


# ---- Step 4: Fit the learning curves ----------------------------------------

fit_curve <- function(data) {
  model <- lm(log(tic) ~ log(installed_capacity_stock_gw), data = data)
  slope         <- coef(model)[2]
  standard_error <- summary(model)$coefficients[2, 2]
  # t critical value, correct for these small samples. 1.96 would understate.
  t_critical <- qt(0.975, df = model$df.residual)
  
  tibble(
    n                  = nrow(data),
    slope              = slope,
    learning_rate      = 1 - 2^slope,
    learning_rate_low  = 1 - 2^(slope + t_critical * standard_error),
    learning_rate_high = 1 - 2^(slope - t_critical * standard_error),
    r_squared          = summary(model)$r.squared
  )
}

# Unrounded. This is what the forecast uses.
results <- df %>%
  group_by(technology) %>%
  group_modify(~ fit_curve(.x)) %>%
  ungroup() %>%
  arrange(desc(learning_rate))

# Rounded. For display and the memo only.
results_display <- results %>%
  mutate(across(c(learning_rate, learning_rate_low, learning_rate_high),
                ~ round(.x * 100, 1)),
         slope     = round(slope, 4),
         r_squared = round(r_squared, 3))

results_display
write_csv(results_display, "output/learning_rates.csv")


# ---- Step 5: Charts 1 to 4 --------------------------------------------------

p1 <- df %>%
  filter(technology %in% learning_techs) %>%
  ggplot(aes(installed_capacity_stock_gw, tic, colour = technology, fill = technology)) +
  geom_smooth(method = "lm", se = TRUE, alpha = 0.12, linewidth = 0.7) +
  geom_point(size = 2.2, alpha = 0.85) +
  scale_x_log10(labels = label_number(big.mark = " ")) +
  scale_y_log10(labels = label_number(big.mark = " ")) +
  scale_colour_manual(values = palette_tech) +
  scale_fill_manual(values = palette_tech) +
  facet_wrap(~ technology, scales = "free") +
  labs(
    title = "Build costs fall as installed capacity grows",
    subtitle = "Both axes logarithmic. A straight line means a constant learning rate.",
    x = "Installed capacity stock (GW; cumulative deployment in GWh for batteries)",
    y = "Total installed cost (USD/kW; USD/kWh for batteries)",
    caption = source_note
  ) +
  theme_report() +
  theme(legend.position = "none")

ggsave("figures/01_learning_curves.png", p1, width = 9.5, height = 6.5, dpi = 300, bg = "white")


p2 <- results_display %>%
  filter(technology %in% learning_techs) %>%
  ggplot(aes(reorder(technology, learning_rate), learning_rate, fill = technology)) +
  geom_col(width = 0.55) +
  geom_errorbar(aes(ymin = learning_rate_low, ymax = learning_rate_high),
                width = 0.12, linewidth = 0.45, colour = "grey25") +
  geom_hline(yintercept = 12, linetype = "dashed", colour = "grey45", linewidth = 0.4) +
  annotate("text", x = 0.6, y = 12.6, label = "IRENA benchmark for wind",
           hjust = 0, size = 3, colour = "grey45") +
  geom_text(aes(label = paste0(learning_rate, "%")),
            hjust = -0.9, size = 3.6, fontface = "bold", colour = "grey20") +
  scale_fill_manual(values = palette_tech) +
  scale_y_continuous(limits = c(0, 40), expand = expansion(mult = c(0, 0.05))) +
  coord_flip() +
  labs(
    title = paste0("Estimated learning rates, 2010 to ", latest_year),
    subtitle = "Cost reduction per doubling of installed capacity stock. Bars show 95% confidence intervals.",
    x = NULL, y = "Learning rate (%)",
    caption = paste(source_note,
                    "IRENA benchmark refers to cost of electricity, not build cost.",
                    sep = "\n")
  ) +
  theme_report() +
  theme(legend.position = "none", panel.grid.major.y = element_blank())

ggsave("figures/02_learning_rates.png", p2, width = 8.5, height = 5, dpi = 300, bg = "white")


onshore_model <- lm(log(tic) ~ log(installed_capacity_stock_gw),
                    data = df %>% filter(technology == "Onshore wind"))

p3 <- df %>%
  filter(technology == "Onshore wind") %>%
  mutate(residual = residuals(onshore_model)) %>%
  ggplot(aes(year, residual, fill = residual > 0)) +
  geom_col(width = 0.65) +
  geom_hline(yintercept = 0, colour = "grey30", linewidth = 0.4) +
  scale_fill_manual(values = c("TRUE" = "#C0392B", "FALSE" = "#1B7F79")) +
  scale_x_continuous(breaks = seq(2010, latest_year, 3)) +
  labs(
    title = "Onshore wind: where the learning curve misses",
    subtitle = "Red means actual costs came in higher than the model predicts.",
    x = NULL, y = "Residual (log scale)",
    caption = source_note
  ) +
  theme_report() +
  theme(legend.position = "none")

ggsave("figures/03_residuals.png", p3, width = 8.5, height = 4.5, dpi = 300, bg = "white")


p4 <- df %>%
  filter(technology %in% c("Hydropower", "Bioenergy", "Onshore wind")) %>%
  ggplot(aes(installed_capacity_stock_gw, tic, colour = technology)) +
  geom_point(size = 2.2, alpha = 0.85) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.8) +
  scale_x_log10(labels = label_number(big.mark = " ")) +
  scale_y_log10(labels = label_number(big.mark = " ")) +
  scale_colour_manual(values = palette_tech) +
  labs(
    title = "The experience curve fits modular technology better than construction",
    subtitle = "Hydropower and bioenergy costs rose as installed capacity grew",
    x = "Installed capacity stock (GW)",
    y = "Total installed cost (USD/kW)",
    caption = source_note
  ) +
  theme_report()

ggsave("figures/04_contrast.png", p4, width = 8.5, height = 5.5, dpi = 300, bg = "white")


# ---- Step 6: Deployment scenarios, derived from the data --------------------

# The single judgement call in this block, named and adjustable.
# How much slower than the weakest observed period might growth get?
SLOWDOWN_FACTOR <- 0.75

growth_windows <- tibble(start = c(2010, 2015, 2020, 2023), end = latest_year)

observed_growth <- df %>%
  filter(technology %in% c("Onshore wind", "Offshore wind", "Solar PV")) %>%
  select(technology, year, installed_capacity_stock_gw) %>%
  crossing(growth_windows) %>%
  group_by(technology, start, end) %>%
  filter(year %in% c(first(start), first(end))) %>%
  summarise(
    compound_annual_growth_rate =
      (installed_capacity_stock_gw[year == max(year)] /
         installed_capacity_stock_gw[year == min(year)]) ^
      (1 / (max(year) - min(year))) - 1,
    .groups = "drop"
  )

observed_growth
write_csv(observed_growth, "output/observed_growth.csv")

scenarios <- observed_growth %>%
  group_by(technology) %>%
  summarise(
    Slow    = min(compound_annual_growth_rate) * SLOWDOWN_FACTOR,
    Central = compound_annual_growth_rate[start == 2015],
    Fast    = max(compound_annual_growth_rate),
    .groups = "drop"
  ) %>%
  pivot_longer(c(Slow, Central, Fast), names_to = "scenario", values_to = "growth")

scenarios


# ---- Step 7: Forecast -------------------------------------------------------

base_year_values <- df %>%
  filter(year == latest_year,
         technology %in% c("Onshore wind", "Offshore wind", "Solar PV")) %>%
  select(technology,
         base_capacity = installed_capacity_stock_gw,
         base_tic      = tic)

# Unrounded learning rates
rates <- results %>%
  select(technology, learning_rate, learning_rate_low, learning_rate_high)

cost_forecast <- base_year_values %>%
  left_join(scenarios, by = "technology") %>%
  left_join(rates,     by = "technology") %>%
  crossing(year = latest_year:2040) %>%
  mutate(
    installed_capacity_stock_gw = base_capacity * (1 + growth)^(year - latest_year),
    doublings = log2(installed_capacity_stock_gw / base_capacity),
    tic       = base_tic * (1 - learning_rate)^doublings,
    tic_low   = base_tic * (1 - learning_rate_high)^doublings,
    tic_high  = base_tic * (1 - learning_rate_low)^doublings
  )

cost_forecast %>%
  filter(year == 2040) %>%
  select(technology, scenario, installed_capacity_stock_gw, tic, tic_low, tic_high) %>%
  mutate(across(where(is.numeric), ~ round(.x))) %>%
  arrange(technology, scenario)


# ---- Step 8: Benchmark against IRENA's own projections ----------------------

read_irena_projection <- function(sheet, tech_label) {
  read_excel(cost_file, sheet = sheet, range = "B3:F232") %>%
    filter(Region == "Global", !is.na(Year)) %>%
    transmute(
      technology = tech_label,
      year       = as.numeric(Year),
      series     = Series,
      tic_irena  = as.numeric(`Total Installed Cost (USD/kW)`)
    )
}

# IRENA publishes forward projections for onshore wind and solar PV only.
irena_projection <- bind_rows(
  read_irena_projection("Fig 1.7", "Onshore wind"),
  read_irena_projection("Fig 1.6", "Solar PV")
)

irena_projection %>% count(technology, series)

irena_forward <- irena_projection %>% filter(series == "Refined")

comparison <- cost_forecast %>%
  filter(scenario == "Central", year <= 2035) %>%
  select(technology, year, tic_modelled = tic) %>%
  inner_join(irena_forward, by = c("technology", "year")) %>%
  mutate(gap_percent = round((tic_modelled / tic_irena - 1) * 100, 1))

comparison %>% filter(year %in% c(2030, 2035))
write_csv(comparison, "output/comparison_vs_irena.csv")


# ---- Step 9: Does the model stay within plausible cost levels? --------------

cost_forecast %>%
  filter(year %in% c(2030, 2035, 2040), scenario == "Central") %>%
  select(technology, year, tic, tic_low, tic_high) %>%
  mutate(across(where(is.numeric), ~ round(.x))) %>%
  arrange(technology, year)

floor_breach <- cost_forecast %>%
  filter(scenario == "Central") %>%
  left_join(floors, by = "technology") %>%
  filter(tic < floor_tic) %>%
  group_by(technology) %>%
  summarise(first_year_below_floor = min(year), .groups = "drop")

floor_breach
write_csv(floor_breach, "output/floor_breach.csv")


# ---- Step 10: Figures 5 and 6 -----------------------------------------------

p5 <- cost_forecast %>%
  filter(technology %in% c("Onshore wind", "Offshore wind")) %>%
  mutate(scenario = factor(scenario, levels = c("Fast", "Central", "Slow"))) %>%
  ggplot(aes(year, tic, colour = scenario, fill = scenario)) +
  geom_ribbon(aes(ymin = tic_low, ymax = tic_high), alpha = 0.10, colour = NA) +
  geom_line(linewidth = 1) +
  geom_hline(data = floors %>% filter(technology != "Solar PV"),
             aes(yintercept = floor_tic),
             linetype = "dashed", colour = "grey45", linewidth = 0.4) +
  geom_text(data = floors %>% filter(technology != "Solar PV"),
            aes(x = latest_year + 0.5, y = floor_tic, label = "assumed cost floor"),
            inherit.aes = FALSE, vjust = -0.7, hjust = 0, size = 2.9, colour = "grey45") +
  scale_colour_manual(values = c(Fast = "#2E5E8C", Central = "#1B7F79", Slow = "#E8A33D")) +
  scale_fill_manual(values   = c(Fast = "#2E5E8C", Central = "#1B7F79", Slow = "#E8A33D")) +
  scale_y_continuous(labels = label_number(big.mark = " ")) +
  facet_wrap(~ technology, scales = "free_y") +
  labs(
    title = "Projected wind build costs to 2040",
    subtitle = "Shaded bands show regression uncertainty. The dashed line is an assumed cost floor, not an IRENA estimate.",
    x = NULL, y = "Total installed cost (USD/kW)",
    caption = source_note
  ) +
  theme_report()

ggsave("figures/05_forecast.png", p5, width = 9.5, height = 5.5, dpi = 300, bg = "white")


p6 <- comparison %>%
  pivot_longer(c(tic_modelled, tic_irena), names_to = "source", values_to = "tic") %>%
  mutate(source = recode(source,
                         tic_modelled = "Learning curve model",
                         tic_irena    = "IRENA published outlook")) %>%
  ggplot(aes(year, tic, colour = source)) +
  geom_line(linewidth = 1) +
  scale_colour_manual(values = c("Learning curve model"    = "#1B7F79",
                                 "IRENA published outlook" = "#C0392B")) +
  scale_y_continuous(labels = label_number(big.mark = " ")) +
  facet_wrap(~ technology, scales = "free_y") +
  labs(
    title = "The gap widens with the forecast horizon",
    subtitle = "Central deployment scenario against IRENA's own refined projection",
    x = NULL, y = "Total installed cost (USD/kW)",
    caption = source_note
  ) +
  theme_report()

ggsave("figures/06_vs_irena.png", p6, width = 9.5, height = 5.5, dpi = 300, bg = "white")


# ---- Step 11: Forecast table, markdown and PNG ------------------------------

forecast_table <- cost_forecast %>%
  filter(year %in% c(latest_year, 2030, 2035, 2040)) %>%
  select(technology, scenario, growth, year, tic) %>%
  mutate(tic = round(tic)) %>%
  pivot_wider(names_from = year, values_from = tic) %>%
  mutate(
    scenario = factor(scenario, levels = c("Slow", "Central", "Fast")),
    growth   = paste0(round(growth * 100, 1), "%")
  ) %>%
  arrange(technology, scenario)

forecast_table
write_csv(forecast_table, "output/forecast_table.csv")

kable(forecast_table, format = "markdown",
      col.names = c("Technology", "Scenario", "Annual growth",
                    as.character(latest_year), "2030", "2035", "2040"),
      align = c("l", "l", "r", "r", "r", "r", "r"))

# PNG version, with an asterisk on any value below the assumed cost floor
table_display <- cost_forecast %>%
  filter(year %in% c(latest_year, 2030, 2035, 2040)) %>%
  left_join(floors, by = "technology") %>%
  mutate(label = ifelse(tic < floor_tic,
                        paste0(round(tic), "*"),
                        as.character(round(tic)))) %>%
  select(technology, scenario, growth, year, label) %>%
  pivot_wider(names_from = year, values_from = label) %>%
  mutate(
    scenario = factor(scenario, levels = c("Slow", "Central", "Fast")),
    growth   = paste0(round(growth * 100, 1), "%")
  ) %>%
  arrange(technology, scenario) %>%
  rename(Technology = technology, Scenario = scenario, `Annual growth` = growth)

table_theme <- ttheme_minimal(
  core    = list(fg_params = list(fontsize = 10, col = "grey20"),
                 bg_params = list(fill = c("grey96", "white"), col = NA)),
  colhead = list(fg_params = list(fontsize = 10, fontface = "bold", col = "grey10"),
                 bg_params = list(fill = "white", col = NA))
)

png("figures/07_forecast_table.png", width = 2100, height = 1350, res = 200)
grid.arrange(
  textGrob("Projected total installed cost, USD/kW",
           gp = gpar(fontsize = 13, fontface = "bold", col = "grey10")),
  tableGrob(table_display, rows = NULL, theme = table_theme),
  textGrob(paste("* falls below the assumed cost floor; model output, not forecast.",
                 source_note, sep = "\n"),
           gp = gpar(fontsize = 8, col = "grey45")),
  ncol = 1, heights = c(0.12, 0.76, 0.12)
)
dev.off()


# ---- Session info, for reproducibility --------------------------------------

writeLines(capture.output(sessionInfo()), "output/session_info.txt")

# =============================================================================
# End
# =============================================================================