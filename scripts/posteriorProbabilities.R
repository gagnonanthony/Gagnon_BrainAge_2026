library(lcmm)
library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
library(optparse)

# Define command line options
option_list <- list(
  make_option(c("-i", "--input"), type="character", default=NULL,
              help="Path to the input dataset used to fit the model", metavar="character"),
  make_option(c("-o", "--output"), type="character", default="posteriorProbabilities.csv",
              help="Path to the output file [default= %default]", metavar="character"),
  make_option(c("-m", "--model"), type="character", default=NULL,
              help="Path to the fitted model RDS file", metavar="character"),
  make_option(c("-s", "--subject_id"), type="character", default="sid",
              help="Subject ID variable name [default= %default]", metavar="character"),
  make_option(c("-n", "--nproc"), type="integer", default=1,
              help="Number of processors to use [default= %default]", metavar="integer"),
  make_option(c("-x", "--iterations"), type="integer", default=200,
              help="Maximum number of iterations for model fitting [default= %default]", metavar="integer")
)

# Parse command line arguments
opt_parser <- OptionParser(option_list=option_list, add_help_option=TRUE)
opt <- parse_args(opt_parser)

message("Input file: ", opt$input)
message("Output directory: ", opt$output)
message("Model file: ", opt$model)

message("Loading data...")
df <- read.csv(opt$input)
model <- readRDS(opt$model)

# Get the number of classes from the model
ng <- model$ng
message("Number of classes in the model: ", ng)
pos <- 10 + ((ng - 1) * 3)

# Perform data preprocessing.
df <- df %>%
    mutate(age_c = as.numeric(age - median(age, na.rm = TRUE)))
df[[opt$subject_id]] <- as.numeric(as.factor(df[[opt$subject_id]]))

# Update the univariate models with the model outputs.
message("Updating models...")
m_m1 <- lcmm(m1 ~ I(age_c), random = ~ I(age_c),
            subject = "sid", data = df, ng = 1,
            link = "5-quant-splines", nproc=opt$nproc, maxiter=opt$iterations)
m_m2 <- lcmm(m2 ~ I(age_c), random = ~ I(age_c),
            subject = "sid", data = df, ng = 1,
            link = "5-quant-splines", nproc=opt$nproc, maxiter=opt$iterations)
m_m3 <- lcmm(m3 ~ I(age_c), random = ~ I(age_c),
            subject = "sid", data = df, ng = 1,
            link = "5-quant-splines", nproc=opt$nproc, maxiter=opt$iterations)
m_m4 <- lcmm(m4 ~ I(age_c), random = ~ I(age_c),
            subject = "sid", data = df, ng = 1, posfix=10,
            link = "5-quant-splines", nproc=opt$nproc, maxiter=opt$iterations)
m1 <- lcmm(m1 ~ I(age_c), random = ~ I(age_c), mixture = ~ I(age_c),
            subject = "sid", data = df, ng = ng,
            link = "5-quant-splines", maxiter=0, B=random(m_m1))
m2 <- lcmm(m2 ~ I(age_c), random = ~ I(age_c), mixture = ~ I(age_c),
            subject = "sid", data = df, ng = ng,
            link = "5-quant-splines", maxiter=0, B=random(m_m2))
m3 <- lcmm(m3 ~ I(age_c), random = ~ I(age_c), mixture = ~ I(age_c),
            subject = "sid", data = df, ng = ng,
            link = "5-quant-splines", maxiter=0, B=random(m_m3))
m4 <- lcmm(m4 ~ I(age_c), random = ~ I(age_c), mixture = ~ I(age_c),
            subject = "sid", data = df, ng = ng,
            link = "5-quant-splines", maxiter=0, B=random(m_m4), posfix=pos)

# Get posterior probabilities for each subject.
postProbs <- predictClass(model, newdata = df, subject = opt$subject_id)

# Save to CSV file.
write.csv(postProbs, file = opt$output, row.names = FALSE)
message("Posterior probabilities saved to: ", opt$output)