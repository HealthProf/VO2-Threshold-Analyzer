# Run with ctrl+shift+enter
#clear environment
rm(list=ls())
# Load necessary libraries
library(dplyr) 
library(ggplot2)
library(segmented)
library(grid)
library(gridExtra)
library(gtable)

# Function to get validated string input with a maximum number of attempts
get_string_input <- function(prompt_text, max_attempts = 3) {
  attempts <- 0
  repeat {
    input <- readline(prompt = prompt_text)
    if (nzchar(input)) {
      return(input)
    } else {
      attempts <- attempts + 1
      cat("Input cannot be empty. Please try again.\n")
      if (attempts >= max_attempts) {
        stop("Maximum attempts reached. Exiting the script.")
      }
    }
  }
}

# Function to get validated numeric input with a maximum number of attempts
get_numeric_input <- function(prompt_text, type = "numeric", max_attempts = 3) {
  attempts <- 0
  repeat {
    input <- readline(prompt = prompt_text)
    if (type == "integer") {
      value <- suppressWarnings(as.integer(input))
    } else {
      value <- suppressWarnings(as.numeric(input))
    }
    if (!is.na(value)) {
      return(value)
    } else {
      attempts <- attempts + 1
      cat("Invalid input. Please enter a valid number.\n")
      if (attempts >= max_attempts) {
        stop("Maximum attempts reached. Exiting the script.")
      }
    }
  }
}

# Ensure the script is run in an interactive session
if (!interactive()) {
  stop("This script must be run in an interactive R session.")
}

# Load the data from the provided CSV file
file_path <- "Test VO2.csv"

# Check if the file exists
if (!file.exists(file_path)) {
  stop(paste("The file", file_path, "does not exist in the working directory."))
}

# Read the first 3 rows as headers and combine them
headers <- read.csv(file_path, nrows = 3, header = FALSE, stringsAsFactors = FALSE)
combined_header <- paste(headers[1, ], headers[2, ], headers[3, ], sep = " ")
# Read the data starting from the 5th row
df <- read.csv(file_path, skip = 4, header = FALSE)

# Assign meaningful column names
colnames(df) <- c(
  "TIME_min_", "VO2_STPD_L_min_", "VO2_kg_STPD_ml_kg_m_", "METS_", 
  "VCO2_STPD_L_min_", "VE_BTPS_L_min_", "RER_", "RR_BPM_", 
  "Vt_BTPS_L_", "FEO2_percent_", "FECO2_percent_", "HR_bpm_", 
  "LOAD_PROG_W_", "BIKE_MEAS_W_", "AcKcal_Kcal_", 
  "CHO_percent_", "CHO_g_min", "FAT_percent_", "FAT_g_min"
)

# Prompt user for athlete information with validation
athlete_name <- get_string_input("Enter athlete's name: ")
height_in <- get_numeric_input("Enter athlete's height (in inches): ")
weight_lb <- get_numeric_input("Enter athlete's weight (in lbs): ")
age <- get_numeric_input("Enter athlete's age: ", type = "integer")
sport <- get_string_input("Enter athlete's sport: ")
date_of_test <- get_string_input("Enter date of the test (YYYY-MM-DD): ")

# Convert weight to kilograms
weight_kg <- weight_lb * 0.453592

# Prompt user for test details with validation
num_stages <- get_numeric_input("Enter the number of stages completed in the test: ", type = "integer")
stage_time <- get_numeric_input("Enter the time per stage (in minutes): ")

# Create empty vector to store power input for each stage
power_stages <- numeric(num_stages)

# Prompt user to enter power for each stage with validation
for (i in 1:num_stages) {
  prompt_text <- paste("Enter the power (in Watts) for stage", i, ": ")
  power_stages[i] <- get_numeric_input(prompt_text)
}

# Create a summary table for each stage
summary_table <- data.frame(
  Stage = 1:num_stages,
  Power = power_stages,
  Avg_Heart_Rate = numeric(num_stages),
  Avg_CHO = numeric(num_stages),
  Avg_FAT = numeric(num_stages),
  W_per_kg = numeric(num_stages)
)

# Iterate over each stage to calculate summary metrics
for (i in 1:num_stages) {
  start_time <- (i - 1) * stage_time
  end_time <- start_time + stage_time
  
  # Filter rows corresponding to the current stage time range
  stage_data <- df %>% filter(TIME_min_ >= start_time & TIME_min_ < end_time)
  
  if (nrow(stage_data) == 0) {
    warning(paste("No data found for Stage", i, ". Skipping calculations for this stage."))
    next
  }
  
  # Calculate average heart rate for the last four rows of the stage
  heart_rate_values <- tail(stage_data$HR_bpm_, 4)
  summary_table$Avg_Heart_Rate[i] <- mean(heart_rate_values, na.rm = TRUE)
  
  # Calculate average CHO for the last four rows of the stage
  cho_values <- tail(stage_data$CHO_g_min, 4)
  summary_table$Avg_CHO[i] <- mean(cho_values, na.rm = TRUE)
  
  # Calculate average FAT for the last four rows of the stage
  fat_values <- tail(stage_data$FAT_g_min, 4)
  summary_table$Avg_FAT[i] <- mean(fat_values, na.rm = TRUE)
  
  # Calculate W/kg for each stage
  summary_table$W_per_kg[i] <- summary_table$Power[i] / weight_kg
}

# Display the summary table
cat("\nSummary Table:\n")
print(summary_table)

# Calculate Ve/VCO2 and Ve/VO2
df <- df %>%
  mutate(
    Ve_VO2 = VE_BTPS_L_min_ / VO2_STPD_L_min_,
    Ve_VCO2 = VE_BTPS_L_min_ / VCO2_STPD_L_min_
  )

# Calculate inflection point (VT1) between two linear models for VO2 vs. VCO2
# Fit two linear models to the data
mean_VO2 <- mean(df$VO2_STPD_L_min_, na.rm = TRUE)
fit1 <- lm(VCO2_STPD_L_min_ ~ VO2_STPD_L_min_, data = df, subset = VO2_STPD_L_min_ <= mean_VO2)
fit2 <- lm(VCO2_STPD_L_min_ ~ VO2_STPD_L_min_, data = df, subset = VO2_STPD_L_min_ > mean_VO2)

# Find intersection point between the two lines
coef1 <- coef(fit1)
coef2 <- coef(fit2)

# Calculate x-coordinate of intersection
x_intersect <- (coef2[1] - coef1[1]) / (coef1[2] - coef2[2])

# Calculate y-coordinate of intersection
y_intersect <- coef1[1] + coef1[2] * x_intersect

# Store the coordinates of the crossing point as VT1_VO2_VCO2
VT1_VO2_VCO2 <- c(x_intersect, y_intersect)

# Print the VT1 coordinates
cat(sprintf("\nVT1 (VO2, VCO2): %.2f, %.2f\n", VT1_VO2_VCO2[1], VT1_VO2_VCO2[2]))

# Calculate inflection point (VT2) between two linear models for VCO2 vs. VE
# Fit two linear models to the data
mean_VCO2 <- mean(df$VCO2_STPD_L_min_, na.rm = TRUE)
fit3 <- lm(VE_BTPS_L_min_ ~ VCO2_STPD_L_min_, data = df, subset = VCO2_STPD_L_min_ <= mean_VCO2)
fit4 <- lm(VE_BTPS_L_min_ ~ VCO2_STPD_L_min_, data = df, subset = VCO2_STPD_L_min_ > mean_VCO2)

# Find intersection point between the two lines
coef3 <- coef(fit3)
coef4 <- coef(fit4)

# Calculate x-coordinate of intersection
x_intersect_vco2_ve <- (coef4[1] - coef3[1]) / (coef3[2] - coef4[2])

# Calculate y-coordinate of intersection
y_intersect_vco2_ve <- coef3[1] + coef3[2] * x_intersect_vco2_ve

# Store the coordinates of the crossing point as VT2_VCO2_VE
VT2_VCO2_VE <- c(x_intersect_vco2_ve, y_intersect_vco2_ve)

# Print the VT2 coordinates
cat(sprintf("VT2 (VCO2, VE): %.2f, %.2f\n", VT2_VCO2_VE[1], VT2_VCO2_VE[2]))

# Calculate inflection point (VT3) for VO2 vs. Ve/VO2 between three linear models
# Fit three linear models to the data
quantiles_VO2 <- quantile(df$VO2_STPD_L_min_, probs = c(0.33, 0.66), na.rm = TRUE)
fit5 <- lm(Ve_VO2 ~ VO2_STPD_L_min_, data = df, subset = VO2_STPD_L_min_ <= quantiles_VO2[1])
fit6 <- lm(Ve_VO2 ~ VO2_STPD_L_min_, data = df, subset = VO2_STPD_L_min_ > quantiles_VO2[1] & 
             VO2_STPD_L_min_ <= quantiles_VO2[2])
fit7 <- lm(Ve_VO2 ~ VO2_STPD_L_min_, data = df, subset = VO2_STPD_L_min_ > quantiles_VO2[2])

# Find intersection point between the first and second lines
coef5 <- coef(fit5)
coef6 <- coef(fit6)

x_intersect_vo2_vevo2 <- (coef6[1] - coef5[1]) / (coef5[2] - coef6[2])
y_intersect_vo2_vevo2 <- coef5[1] + coef5[2] * x_intersect_vo2_vevo2

# Find intersection point between the second and third lines
coef7 <- coef(fit7)

x_intersect_vo2_vevo2_2 <- (coef7[1] - coef6[1]) / (coef6[2] - coef7[2])
y_intersect_vo2_vevo2_2 <- coef6[1] + coef6[2] * x_intersect_vo2_vevo2_2

# Store the coordinates of the crossing point as VT3_VO2_VEVO2
VT3_VO2_VEVO2 <- c(x_intersect_vo2_vevo2_2, y_intersect_vo2_vevo2_2)

# Print the VT3 coordinates
cat(sprintf("VT3 (VO2, Ve/VO2): %.2f, %.2f\n", VT3_VO2_VEVO2[1], VT3_VO2_VEVO2[2]))

# Calculate inflection point (VT4) for VO2 vs. Ve/VCO2 between three linear models
# Fit three linear models to the data
quantiles_VO2_vco2 <- quantile(df$VO2_STPD_L_min_, probs = c(0.33, 0.66), na.rm = TRUE)
fit8 <- lm(Ve_VCO2 ~ VO2_STPD_L_min_, data = df, subset = VO2_STPD_L_min_ <= quantiles_VO2_vco2[1])
fit9 <- lm(Ve_VCO2 ~ VO2_STPD_L_min_, data = df, subset = VO2_STPD_L_min_ > quantiles_VO2_vco2[1] & 
             VO2_STPD_L_min_ <= quantiles_VO2_vco2[2])
fit10 <- lm(Ve_VCO2 ~ VO2_STPD_L_min_, data = df, subset = VO2_STPD_L_min_ > quantiles_VO2_vco2[2])

# Find intersection point between the first and second lines
coef8 <- coef(fit8)
coef9 <- coef(fit9)

x_intersect_vo2_vevco2 <- (coef9[1] - coef8[1]) / (coef8[2] - coef9[2])
y_intersect_vo2_vevco2 <- coef8[1] + coef8[2] * x_intersect_vo2_vevco2

# Find intersection point between the second and third lines
coef10 <- coef(fit10)

x_intersect_vo2_vevco2_2 <- (coef10[1] - coef9[1]) / (coef9[2] - coef10[2])
y_intersect_vo2_vevco2_2 <- coef9[1] + coef9[2] * x_intersect_vo2_vevco2_2

# Store the coordinates of the crossing point as VT4_VO2_VEVCO2
VT4_VO2_VEVCO2 <- c(x_intersect_vo2_vevco2_2, y_intersect_vo2_vevco2_2)

# Print the VT4 coordinates
cat(sprintf("VT4 (VO2, Ve/VCO2): %.2f, %.2f\n", VT4_VO2_VEVCO2[1], VT4_VO2_VEVCO2[2]))

# Create a table containing the calculated VT1 and VT2 points
vt_table <- data.frame(
  VT_Point = c("VT1 (VO2 vs VCO2)", "VT2 (VCO2 vs VE)", 
               "VT1 (VO2 vs Ve/VO2)", "VT2 (VO2 vs Ve/VCO2)"),
  VO2 = c(round(VT1_VO2_VCO2[1], 2), round(VT2_VCO2_VE[1], 2), 
          round(VT3_VO2_VEVO2[1], 2), round(VT4_VO2_VEVCO2[1], 2)),
  VCO2_VE_or_Ve_VCO2 = c(round(VT1_VO2_VCO2[2], 2), round(VT2_VCO2_VE[2], 2),
                         round(VT3_VO2_VEVO2[2], 2), round(VT4_VO2_VEVCO2[2], 2)),
  stringsAsFactors = FALSE
)

# Modify vt_table to remove column headers for columns 2 and 3
colnames(vt_table)[2:3] <- c("", "")

# Display the VT table
cat("\nVT Table:\n")
print(vt_table)

# Generate all required plots and assign them to variables

# Plot 1: Power vs. Heart Rate
plot1 <- ggplot(summary_table, aes(x = Power, y = Avg_Heart_Rate)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  labs(title = "Power vs. Heart Rate", x = "Power (Watts)", y = "Average Heart Rate (bpm)") +
  theme_minimal()

# Plot 2: Power vs. FAT
plot2 <- ggplot(summary_table, aes(x = Power, y = Avg_FAT)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  labs(title = "Power vs. FAT", x = "Power (Watts)", y = "Average FAT (g/min)") +
  theme_minimal()

# Plot 3: Power vs. CHO
plot3 <- ggplot(summary_table, aes(x = Power, y = Avg_CHO)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  labs(title = "Power vs. CHO", x = "Power (Watts)", y = "Average CHO (g/min)") +
  theme_minimal()

# Plot 4: W/kg vs. FAT and CHO
plot4 <- ggplot(summary_table, aes(x = W_per_kg)) +
  geom_line(aes(y = Avg_FAT, color = "FAT"), size = 1.5) +
  geom_point(aes(y = Avg_FAT, color = "FAT"), size = 3) +
  geom_line(aes(y = Avg_CHO, color = "CHO"), size = 1.5) +
  geom_point(aes(y = Avg_CHO, color = "CHO"), size = 3) +
  labs(title = "W/kg vs. FAT and CHO", x = "W/kg", y = "FAT and CHO") +
  scale_y_continuous(
    name = "FAT (g/min)",
    sec.axis = sec_axis(~ ., name = "CHO (g/min)")
  ) +
  theme_minimal() +
  scale_color_manual(values = c("FAT" = "blue", "CHO" = "red")) +
  theme(legend.title = element_blank())

# Plot 5: Time vs. VO2
plot5 <- ggplot(df, aes(x = TIME_min_, y = VO2_STPD_L_min_)) + 
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  labs(title = "Time vs. VO2", x = "Time (min)", y = "VO2 (L/min)") +
  theme_minimal()

# Plot 6: Time vs. VO2/kg
plot6 <- ggplot(df, aes(x = TIME_min_, y = VO2_kg_STPD_ml_kg_m_)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  labs(title = "Time vs. VO2/kg", x = "Time (min)", y = "VO2/kg (ml/kg/min)") +
  theme_minimal()

# Plot 7: Time vs. HR
plot7 <- ggplot(df, aes(x = TIME_min_, y = HR_bpm_)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  labs(title = "Time vs. Heart Rate", x = "Time (min)", y = "Heart Rate (bpm)") +
  theme_minimal()

# Plot 8: Time vs. VE
plot8 <- ggplot(df, aes(x = TIME_min_, y = VE_BTPS_L_min_)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  labs(title = "Time vs. VE", x = "Time (min)", y = "VE (L/min)") +
  theme_minimal()

# Plot 9: VO2 vs. VCO2
plot9 <- ggplot(df, aes(x = VO2_STPD_L_min_, y = VCO2_STPD_L_min_)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  labs(title = "VO2 vs. VCO2", x = "VO2 (L/min)", y = "VCO2 (L/min)") +
  theme_minimal()

# Plot 10: VO2 vs. Ve/VO2 with inflection point
plot10 <- ggplot(df, aes(x = VO2_STPD_L_min_, y = Ve_VO2)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  geom_vline(xintercept = VT3_VO2_VEVO2[1], linetype = "dotted", color = "black", size = 1) +
  labs(title = "VO2 vs Ve/VO2", x = "VO2 (L/min)", y = "Ve/VO2") +
  theme_minimal()

# Plot 11: VCO2 vs. VE with inflection point
plot11 <- ggplot(df, aes(x = VCO2_STPD_L_min_, y = VE_BTPS_L_min_)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  geom_vline(xintercept = VT2_VCO2_VE[1], linetype = "dotted", color = "black", size = 1) +
  labs(title = "VCO2 vs VE", x = "VCO2 (L/min)", y = "VE (L/min)") +
  theme_minimal()

# Plot 12: VO2 vs. Ve/VCO2 with inflection point
plot12 <- ggplot(df, aes(x = VO2_STPD_L_min_, y = Ve_VCO2)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  geom_vline(xintercept = VT4_VO2_VEVCO2[1], linetype = "dotted", color = "black", size = 1) +
  labs(title = "VO2 vs Ve/VCO2", x = "VO2 (L/min)", y = "Ve/VCO2") +
  theme_minimal()

# Plot 13: Time vs. RR
plot13 <- ggplot(df, aes(x = TIME_min_, y = RR_BPM_)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  labs(title = "Time vs. RR", x = "Time (min)", y = "RR (BPM)") +
  theme_minimal()

# Plot 14: Time vs. RER
plot14 <- ggplot(df, aes(x = TIME_min_, y = RER_)) +
  geom_line(size = 1.5) +
  geom_point(size = 3) +
  labs(title = "Time vs. RER", x = "Time (min)", y = "RER") +
  theme_minimal()

# Plot 15: VO2 vs VCO2 with inflection lines
plot15 <- ggplot(df, aes(x = VO2_STPD_L_min_, y = VCO2_STPD_L_min_)) +
  geom_point(size = 3) +
  geom_abline(intercept = coef1[1], slope = coef1[2], color = "blue", linetype = "dashed", size = 1) +
  geom_abline(intercept = coef2[1], slope = coef2[2], color = "red", linetype = "dashed", size = 1) +
  geom_vline(xintercept = VT1_VO2_VCO2[1], linetype = "dotted", color = "black", size = 1) +
  labs(title = "VO2 vs VCO2 with Inflection Point", x = "VO2 (L/min)", y = "VCO2 (L/min)") +
  theme_minimal()

# Plot 16: VCO2 vs VE with inflection lines
plot16 <- ggplot(df, aes(x = VCO2_STPD_L_min_, y = VE_BTPS_L_min_)) +
  geom_point(size = 3) +
  geom_abline(intercept = coef3[1], slope = coef3[2], color = "blue", linetype = "dashed", size = 1) +
  geom_abline(intercept = coef4[1], slope = coef4[2], color = "red", linetype = "dashed", size = 1) +
  geom_vline(xintercept = VT2_VCO2_VE[1], linetype = "dotted", color = "black", size = 1) +
  labs(title = "VCO2 vs VE with Inflection Point", x = "VCO2 (L/min)", y = "VE (L/min)") +
  theme_minimal()

# Plot 17a: VO2 vs Ve/VO2 with inflection lines
plot17a <- ggplot(df, aes(x = VO2_STPD_L_min_, y = Ve_VO2)) +
  geom_point(size = 3) +
  geom_abline(intercept = coef5[1], slope = coef5[2], color = "blue", linetype = "dashed", size = 1) +
  geom_abline(intercept = coef6[1], slope = coef6[2], color = "green", linetype = "dashed", size = 1) +
  geom_abline(intercept = coef7[1], slope = coef7[2], color = "red", linetype = "dashed", size = 1) +
  geom_vline(xintercept = VT3_VO2_VEVO2[1], linetype = "dotted", color = "black", size = 1) +
  labs(title = "VO2 vs Ve/VO2 with Inflection Point", x = "VO2 (L/min)", y = "Ve/VO2") +
  theme_minimal()

# Plot 17b: VO2 vs Ve/VCO2 with inflection lines
plot17b <- ggplot(df, aes(x = VO2_STPD_L_min_, y = Ve_VCO2)) +
  geom_point(size = 3) +
  geom_abline(intercept = coef8[1], slope = coef8[2], color = "blue", linetype = "dashed", size = 1) +
  geom_abline(intercept = coef9[1], slope = coef9[2], color = "green", linetype = "dashed", size = 1) +
  geom_abline(intercept = coef10[1], slope = coef10[2], color = "red", linetype = "dashed", size = 1) +
  geom_vline(xintercept = VT4_VO2_VEVCO2[1], linetype = "dotted", color = "black", size = 1) +
  labs(title = "VO2 vs Ve/VCO2 with Inflection Point", x = "VO2 (L/min)", y = "Ve/VCO2") +
  theme_minimal()

# Create a list of plots in the desired order
plots_list <- list(
  plot1,    # Plot 1
  plot2,    # Plot 2
  plot3,    # Plot 3
  plot4,    # Plot 4
  plot5,    # Plot 5
  plot6,    # Plot 6
  plot7,    # Plot 7
  plot8,    # Plot 8
  plot9,    # Plot 9
  plot15,   # Plot 15
  plot10,   # Plot 10
  plot17a,  # Plot 17a
  plot11,   # Plot 11
  plot16,   # Plot 16
  plot12,   # Plot 12
  plot17b,  # Plot 17b
  plot13,   # Plot 13
  plot14    # Plot 14
)

# Open a PDF device to save the report
pdf("Athlete_Report.pdf", width = 11, height = 8.5)

# Function to add the first page with Athlete Information, Summary Table, and VT Table
add_first_page <- function(athlete_info_df, summary_table_df, vt_table_df) {
  grid.newpage()
  
  # Title
  title <- "Athlete Information and Test Summary"
  grid.text(title, x = 0.5, y = 0.95, gp = gpar(fontsize = 20, fontface = "bold"))
  
  # Athlete Information Table
  athlete_info_grob <- tableGrob(athlete_info_df, rows = NULL,
                                 theme = ttheme_default(
                                   core = list(fg_params = list(fontsize = 12)),
                                   colhead = list(fg_params = list(fontsize = 12, fontface = "bold"))
                                 ))
  
  # Summary Table
  summary_table_grob <- tableGrob(summary_table_df, rows = NULL,
                                  theme = ttheme_default(
                                    core = list(fg_params = list(fontsize = 10)),
                                    colhead = list(fg_params = list(fontsize = 10, fontface = "bold"))
                                  ))
  
  # VT Table (with only first column header)
  vt_table_modified <- vt_table_df
  colnames(vt_table_modified)[2:3] <- c("", "")
  vt_table_grob <- tableGrob(vt_table_modified, rows = NULL,
                             theme = ttheme_default(
                               core = list(fg_params = list(fontsize = 10)),
                               colhead = list(fg_params = list(fontsize = 10, fontface = "bold"))
                             ))
  
  # Arrange tables vertically with spacing
  combined <- arrangeGrob(
    athlete_info_grob,
    summary_table_grob,
    vt_table_grob,
    ncol = 1,
    heights = unit(c(2, 3, 2), "inches"),
    padding = unit(0.5, "line")
  )
  
  # Draw combined grob
  grid.draw(combined)
}

# Create Athlete Information Data Frame
athlete_info_df <- data.frame(
  Parameter = c("Name", "Height (in)", "Weight (lbs)", "Age", "Sport", "Date of Test"),
  Value = c(athlete_name, height_in, weight_lb, age, sport, date_of_test),
  stringsAsFactors = FALSE
)

# Add first page with Athlete Information, Summary Table, and VT Table
add_first_page(athlete_info_df, summary_table, vt_table)

# Function to add a plot on a new page
add_plot_page <- function(plot) {
  grid.newpage()
  print(plot, newpage = FALSE)
}

# Add all plots in the specified order starting from the second page
for (plot in plots_list) {
  add_plot_page(plot)
}

# Close the PDF device
dev.off()

# Notify the user
cat("PDF report 'Athlete_Report.pdf' has been created successfully.\n")
