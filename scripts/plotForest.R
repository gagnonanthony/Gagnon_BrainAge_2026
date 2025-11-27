library(forestploter)
library(optparse)
library(grid)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(tidyr)
library(ggplot2)
library(showtext)
library(systemfonts)

# Define command line options
option_list <- list(
  make_option(c("-i", "--input"), type="character", default=NULL,
                help="Path to the input CSV file containing odds ratios and confidence intervals", metavar="character"),
  make_option(c("-o", "--output"), type="character", default="forest_plot.pdf",
                help="Path to the output PDF file [default= %default]", metavar="character"),
  make_option(c("-w", "--width"), type="numeric", default=12,
                help="Plot width in inches [default= %default]", metavar="numeric"),
  make_option(c("--height"), type="numeric", default=10,
                help="Plot height in inches [default= %default]", metavar="numeric"),
  make_option(c("-g", "--group"), type="character", default=NULL,
                help="Specific comparison group to plot (e.g., 'Class 1 vs Class 3'). If NULL, plots all groups", metavar="character")
)

# Parse command line arguments
opt_parser <- OptionParser(option_list=option_list, add_help_option=TRUE)
opt <- parse_args(opt_parser)

# Add custom font.
font_add("Harding", regular = "/Users/anthonygagnon/Library/Fonts/HardingTextWeb-Regular.ttf", bold = "/Users/anthonygagnon/Library/Fonts/Harding Text Web Bold Regular.ttf")
showtext_auto()  # Enable showtext for rendering
message("Harding font loaded and showtext enabled")

# Check if input file is provided
if(is.null(opt$input)){
  print_help(opt_parser)
  stop("Input file must be specified with -i or --input", call.=FALSE)
}

message("Input file: ", opt$input)
message("Output file: ", opt$output)

message("Loading data...")
df <- read.csv(opt$input, stringsAsFactors = FALSE)



# No filtering - we want both comparison groups for dual-outcome plot
if(!is.null(opt$group)){
  message("Note: Ignoring group filter - creating dual-outcome plot with both comparison groups")
}

# Ensure numeric columns are properly formatted
df$OR <- as.numeric(df$OR)
df$CI_lower <- as.numeric(df$CI_lower)
df$CI_upper <- as.numeric(df$CI_upper)
df$pval <- as.numeric(df$pval)

# Create a cleaner label column by removing "BAG_" prefix
df$label_clean <- gsub("BAG_", "", df$label)

# Create formatted p-value column
df$pval_formatted <- ifelse(df$pval < 0.001, "< 0.001", 
                           ifelse(df$pval < 0.01, sprintf("%.3f", df$pval),
                                 sprintf("%.2f", df$pval)))

# Add significance indicator
df$significant <- ifelse(df$pval < 0.05, "*", "")

# Prepare data for dual-outcome forestploter - one row per brain region
# Separate the two comparison groups
class1_data <- df[df$group == "Class E vs Class S", ] %>%
  mutate(
    region = label_clean,
    or_ci = paste0(sprintf("%.2f", OR), " (", sprintf("%.2f", CI_lower), "-", sprintf("%.2f", CI_upper), ")"),
    p_value = paste0(pval_formatted, significant)
  ) %>%
  select(region, model, or_ci, p_value, OR, CI_lower, CI_upper, pval) %>%
  pivot_wider(
    names_from = model,
    values_from = c(or_ci, p_value, OR, CI_lower, CI_upper, pval),
    names_sep = "_"
  )

class2_data <- df[df$group == "Class I vs Class S", ] %>%
  mutate(
    region = label_clean,
    or_ci = paste0(sprintf("%.2f", OR), " (", sprintf("%.2f", CI_lower), "-", sprintf("%.2f", CI_upper), ")"),
    p_value = paste0(pval_formatted, significant)
  ) %>%
  select(region, model, or_ci, p_value, OR, CI_lower, CI_upper, pval) %>%
  pivot_wider(
    names_from = model,
    values_from = c(or_ci, p_value, OR, CI_lower, CI_upper, pval),
    names_sep = "_"
  )

# Define region order for consistent display 
region_order <- c("WholeBrain", "Frontal", "Parietal", "Temporal", "Occipital", "Limbic", "Insula", "Subcortical")

# Merge both outcomes by brain region
forest_data_wide <- class1_data %>%
  full_join(class2_data, by = "region", suffix = c("_c1", "_c2")) %>%
  mutate(region = factor(region, levels = region_order)) %>%
  arrange(region)

# Create display table for dual-outcome forest plot
display_data <- forest_data_wide %>%
  mutate(
    # Create combined CI display for Class 1 vs Class 3 (bold if significant)
    class1_ci = paste(
      paste0(sprintf("%.2f", OR_Both_c1), " (", sprintf("%.2f", CI_lower_Both_c1), "-", sprintf("%.2f", CI_upper_Both_c1), ")"),
      paste0(sprintf("%.2f", OR_Female_c1), " (", sprintf("%.2f", CI_lower_Female_c1), "-", sprintf("%.2f", CI_upper_Female_c1), ")"),
      paste0(sprintf("%.2f", OR_Male_c1), " (", sprintf("%.2f", CI_lower_Male_c1), "-", sprintf("%.2f", CI_upper_Male_c1), ")"),
      sep = "\n"
    ),
    
    # Create combined CI display for Class 2 vs Class 3 (bold if significant)  
    class2_ci = paste(
      paste0(sprintf("%.2f", OR_Both_c2), " (", sprintf("%.2f", CI_lower_Both_c2), "-", sprintf("%.2f", CI_upper_Both_c2), ")"),
      paste0(sprintf("%.2f", OR_Female_c2), " (", sprintf("%.2f", CI_lower_Female_c2), "-", sprintf("%.2f", CI_upper_Female_c2), ")"),
      paste0(sprintf("%.2f", OR_Male_c2), " (", sprintf("%.2f", CI_lower_Male_c2), "-", sprintf("%.2f", CI_upper_Male_c2), ")"),
      sep = "\n"
    ),
    
    # Create combined p-value displays (asterisks for significant results)
    class1_pval = paste(
      ifelse(pval_Both_c1 < 0.05, paste0(sprintf("%.3f", pval_Both_c1), "*"), sprintf("%.3f", pval_Both_c1)),
      ifelse(pval_Female_c1 < 0.05, paste0(sprintf("%.3f", pval_Female_c1), "*"), sprintf("%.3f", pval_Female_c1)),
      ifelse(pval_Male_c1 < 0.05, paste0(sprintf("%.3f", pval_Male_c1), "*"), sprintf("%.3f", pval_Male_c1)),
      sep = "\n"
    ),
    
    class2_pval = paste(
      ifelse(pval_Both_c2 < 0.05, paste0(sprintf("%.3f", pval_Both_c2), "*"), sprintf("%.3f", pval_Both_c2)),
      ifelse(pval_Female_c2 < 0.05, paste0(sprintf("%.3f", pval_Female_c2), "*"), sprintf("%.3f", pval_Female_c2)),
      ifelse(pval_Male_c2 < 0.05, paste0(sprintf("%.3f", pval_Male_c2), "*"), sprintf("%.3f", pval_Male_c2)),
      sep = "\n"
    ),
    
    # Add blank columns for forest plots (one for each outcome)
    `Class 1 vs Class 3` = paste(rep(" ", 25), collapse = " "),
    `Class 2 vs Class 3` = paste(rep(" ", 25), collapse = " ")
  ) %>%
  select(region, class1_ci, class1_pval, `Class 1 vs Class 3`, class2_ci, class2_pval, `Class 2 vs Class 3`)

# Set column names (remove class indicators from OR/p-value columns)
colnames(display_data) <- c("Brain Region", "OR (95% CI)", "P-value", 
                           "Class E vs Class S", "OR (95% CI)", "P-value", 
                           "Class I vs Class S")

# Create lists for estimates as required by forestploter 
# For dual-outcome plots with multiple groups: interleave by group across columns
# Structure: Group 1 (Both) for both columns, Group 2 (Female) for both columns, Group 3 (Male) for both columns
est_list <- list(
  # Group 1 (Both sexes) across both outcome columns
  forest_data_wide$OR_Both_c1,     # Both sexes - Class 1 vs Class 3
  forest_data_wide$OR_Both_c2,     # Both sexes - Class 2 vs Class 3
  # Group 2 (Female) across both outcome columns  
  forest_data_wide$OR_Female_c1,   # Female - Class 1 vs Class 3
  forest_data_wide$OR_Female_c2,   # Female - Class 2 vs Class 3
  # Group 3 (Male) across both outcome columns
  forest_data_wide$OR_Male_c1,     # Male - Class 1 vs Class 3
  forest_data_wide$OR_Male_c2      # Male - Class 2 vs Class 3
)

lower_list <- list(
  # Group 1 (Both sexes) across both outcome columns
  forest_data_wide$CI_lower_Both_c1,   # Both sexes - Class 1 vs Class 3
  forest_data_wide$CI_lower_Both_c2,   # Both sexes - Class 2 vs Class 3
  # Group 2 (Female) across both outcome columns
  forest_data_wide$CI_lower_Female_c1, # Female - Class 1 vs Class 3
  forest_data_wide$CI_lower_Female_c2, # Female - Class 2 vs Class 3
  # Group 3 (Male) across both outcome columns
  forest_data_wide$CI_lower_Male_c1,   # Male - Class 1 vs Class 3
  forest_data_wide$CI_lower_Male_c2    # Male - Class 2 vs Class 3
)

upper_list <- list(
  # Group 1 (Both sexes) across both outcome columns
  forest_data_wide$CI_upper_Both_c1,   # Both sexes - Class 1 vs Class 3
  forest_data_wide$CI_upper_Both_c2,   # Both sexes - Class 2 vs Class 3
  # Group 2 (Female) across both outcome columns
  forest_data_wide$CI_upper_Female_c1, # Female - Class 1 vs Class 3
  forest_data_wide$CI_upper_Female_c2, # Female - Class 2 vs Class 3
  # Group 3 (Male) across both outcome columns
  forest_data_wide$CI_upper_Male_c1,   # Male - Class 1 vs Class 3
  forest_data_wide$CI_upper_Male_c2    # Male - Class 2 vs Class 3
)

# Set2 colormap colors
set2_colors <- c("#66c2a5", "#fc8d62", "#8da0cb")  # Both (green), Female (orange), Male (blue)

# Define theme with Harding font and Set2 colors
tm <- forest_theme(
  base_size = 11,
  base_family = "Harding",  # Use the loaded Harding font
  ci_pch = c(15, 16, 17),  # Different shapes: square, circle, triangle
  ci_col = set2_colors,    # Set2 colors for the three groups
  footnote_gp = gpar(fontsize = 9, fontfamily = "Harding"),
  legend_name = "Sex",
  legend_value = c("Both", "Female", "Male"),
  core = list(
    padding = unit(c(4, 2), "mm"),
    fg_params = list(fontfamily = "Harding")
  ),
  colhead = list(
    fg_params = list(fontface = "bold", fontfamily = "Harding")
  )
)

# Create the forest plot
message("Creating forest plot...")

p <- forest(
  data = display_data,
  est = est_list,          # List of estimates for each group (6 groups total)
  lower = lower_list,      # List of lower CIs for each group
  upper = upper_list,      # List of upper CIs for each group
  sizes = 0.8,
  ci_column = c(4, 7),     # Columns where forest plots will be displayed (Class 1, Class 2)
  ref_line = 1,
  theme = tm,
  ticks_at = c(0.8, 0.8, 1.0, 1.2, 1.4),
  arrow_lab = c("Decreased Odds", "Increased Odds"), 
  nudge_y = 0.35,
  xlim = c(0.4, 1.6),
  xlab = "Odds Ratio (95% CI)",
  footnote = "* indicates statistically significant association (p < 0.05)",
  vert_line = 1            # Add explicit reference line
)

# Save the plot
message("Saving plot to: ", opt$output)

# Determine output format based on file extension
output_ext <- tolower(as.character(tools::file_ext(opt$output)))
message("Output format detected: ", output_ext)

if(output_ext == "pdf"){
  pdf(opt$output, width = opt$width, height = opt$height)
  plot(p)
  dev.off()
} else if(output_ext == "png"){
  png(opt$output, width = opt$width * 300, height = opt$height * 300, res = 300)
  plot(p)
  dev.off()
} else if(output_ext == "svg"){
  svg(opt$output, width = opt$width, height = opt$height)
  plot(p)
  dev.off()
} else {
  # Default to PDF if extension not recognized
  pdf(paste0(tools::file_path_sans_ext(opt$output), ".pdf"), width = opt$width, height = opt$height)
  plot(p)
  dev.off()
  message("Unrecognized file extension. Saved as PDF.")
}

message("Forest plot created successfully!")

# Print summary
message("Summary:")
message("- Brain regions: ", nrow(forest_data_wide))
message("- Sex groups: Both, Female, Male")
message("- Comparisons: Class 1 vs Class 3, Class 2 vs Class 3")

# Count significant associations across all groups
sig_class1_both <- sum(forest_data_wide$pval_Both_c1 < 0.05, na.rm = TRUE)
sig_class1_female <- sum(forest_data_wide$pval_Female_c1 < 0.05, na.rm = TRUE)  
sig_class1_male <- sum(forest_data_wide$pval_Male_c1 < 0.05, na.rm = TRUE)

sig_class2_both <- sum(forest_data_wide$pval_Both_c2 < 0.05, na.rm = TRUE)
sig_class2_female <- sum(forest_data_wide$pval_Female_c2 < 0.05, na.rm = TRUE)  
sig_class2_male <- sum(forest_data_wide$pval_Male_c2 < 0.05, na.rm = TRUE)

message("- Significant associations (p < 0.05):")
message("  Class 1 vs Class 3:")
message("    - Both sexes: ", sig_class1_both)
message("    - Female: ", sig_class1_female)
message("    - Male: ", sig_class1_male)
message("  Class 2 vs Class 3:")
message("    - Both sexes: ", sig_class2_both)
message("    - Female: ", sig_class2_female)
message("    - Male: ", sig_class2_male)
message("  - Total: ", sig_class1_both + sig_class1_female + sig_class1_male + 
                         sig_class2_both + sig_class2_female + sig_class2_male)