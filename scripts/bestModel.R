library(lcmm)
library(optparse)

# Define command line options
option_list <- list(
  make_option(c("-i", "--input"), type="character", default=NULL,
              help="Path to the folder containing the models", metavar="character"),
  make_option(c("-o", "--output"), type="character", default="best_model.txt",
              help="Path to the output directory [default= %default]", metavar="character")
)

# Parse command line arguments
opt_parser <- OptionParser(option_list=option_list, add_help_option=TRUE)
opt <- parse_args(opt_parser)

message("Reading models from: ", opt$input)
pos <- 1

# Create output directory if it doesn't exist
if (!dir.exists(dirname(opt$output))) {
  dir.create(dirname(opt$output), recursive = TRUE)
}

# List all model files in the input directory
model_files <- list.files(opt$input, pattern="^mm.*\\C.rds$", full.names=TRUE)

# Load all models, then use summarytable from lcmm.
models <- lapply(model_files, readRDS)

# Unpack the list of models into individual objects.
names(models) <- paste0("model", seq_along(models))
list2env(models, envir = .GlobalEnv)

# Get model summaries
model_summaries <- summarytable(models$model1, models$model2, models$model3,
                                models$model4, models$model5, models$model6,
                                models$model7, models$model8, models$model9,
                                models$model10, models$model11, models$model12,
                                models$model13, display = FALSE,
                                which = c("G", "loglik", "npm", "BIC", "%class", "SABIC", "AIC", "conv", "entropy"))

# Save table to csv file
write.csv(model_summaries,
          file = file.path(dirname(opt$output), "model_summaries.csv"),
          row.names = FALSE)

# Use the summaryplot function to visualize the BIC values
pdf(file.path(dirname(opt$output), "models_plot.pdf"))
summaryplot(models$model1, models$model2, models$model3, models$model4,
            models$model5, models$model6, models$model7, models$model8,
            models$model9, models$model10, models$model11, models$model12,
            models$model13, which=c("entropy", "loglik", "SABIC", "conv"),
            mfrow=c(2,2))

# For all models that converged, print the postprob table
converged_models <- models[sapply(models, function(m) m$conv == 1)]
for (i in seq_along(converged_models)) {
  cat(paste0("Posterior probabilities for model ", i, ":\n"))
  print(postprob(converged_models[[i]]))
  cat("\n")
}