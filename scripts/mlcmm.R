# Load libraries
library(lcmm)
library(dplyr)
library(tidyr)
library(nnet)
library(optparse)
library(ggplot2)

# Define command line arguments
option_list <- list(
    make_option(c("-i", "--input"), type="character", help="Input CSV file path"),
    make_option(c("-o", "--output"), type="character", help="Output directory path"),
    make_option(c("-c", "--classes"), type="integer", default=1, help="Number of classes to fit"),
    make_option(c("-r", "--repeats"), type="integer", default=50, help="Number of repetitions for grid search"),
    make_option(c("-n", "--nproc"), type="integer", default=1, help="Number of processors to use"),
    make_option(c("-x", "--iterations"), type="integer", default=200, help="Maximum number of iterations for model fitting"),
    make_option(c("-s", "--subject_id"), type="character", default="sid", help="Subject ID variable name"),
    make_option(c("-a", "--age_var"), type="character", default="age", help="Age variable name")
)

# Parse command line arguments
opt_parser <- OptionParser(option_list=option_list, add_help_option=TRUE)
opt <- parse_args(opt_parser)

message("Input file: ", opt$input)
message("Output directory: ", opt$output)
message("Num classes: ", opt$classes)

if (!dir.exists(opt$output)) {
    dir.create(opt$output, recursive = TRUE)
}

message("Loading data...")
df <- read.csv(opt$input)

# Data preprocessing
df <- df %>%
    mutate(age_c = as.numeric(age - median(age, na.rm = TRUE)))
df[["sid"]] <- as.numeric(as.factor(df[[opt$subject_id]]))

# Fit univariate first outside of loop.
message("Fitting univariate model...")
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

# First multivariate model
mm1 <- mpjlcmm(list(m_m1, m_m2, m_m3, m_m4),
                subject = "sid",
                data = df,
                ng = 1,
                posfix = 10,
                nproc = opt$nproc,
                maxiter = opt$iterations)
message("Completed model with 1 class.")
if ( !file.exists(file.path(opt$output, "mm1.rds"))) {
    saveRDS(mm1, file.path(opt$output, "mm1.rds"))
}

# Starting the loop for multiple classes.
cl = parallel::makeCluster(opt$nproc)
message("Fitting model with ", opt$classes, " classes...")
pos <- 10 + ((opt$classes - 1) * 3)
ng <- opt$classes
parallel::clusterExport(cl, c("ng", "pos"), envir=environment())

# Univariate models.
m1 <- lcmm(m1 ~ I(age_c), random = ~ I(age_c), mixture = ~ I(age_c),
            subject = "sid", data = df, ng = opt$classes,
            link = "5-quant-splines", maxiter=0, B=random(m_m1))
m2 <- lcmm(m2 ~ I(age_c), random = ~ I(age_c), mixture = ~ I(age_c),
            subject = "sid", data = df, ng = opt$classes,
            link = "5-quant-splines", maxiter=0, B=random(m_m2))
m3 <- lcmm(m3 ~ I(age_c), random = ~ I(age_c), mixture = ~ I(age_c),
            subject = "sid", data = df, ng = opt$classes,
            link = "5-quant-splines", maxiter=0, B=random(m_m3))
m4 <- lcmm(m4 ~ I(age_c), random = ~ I(age_c), mixture = ~ I(age_c),
            subject = "sid", data = df, ng = opt$classes,
            link = "5-quant-splines", maxiter=0, B=random(m_m4), posfix=pos)
    
# Multivariate model. (run only if the model does not already exist)
if ( !file.exists(file.path(opt$output, paste0("mm", opt$classes, "A.rds"))) ) {
    mm_a <- mpjlcmm(longitudinal=list(m1, m2, m3, m4),
                    subject = "sid",
                    data = df,
                    ng = opt$classes,
                    posfix=pos,
                    nproc=opt$nproc,
                    maxiter=opt$iterations)
    saveRDS(mm_a, file.path(opt$output, paste0("mm", opt$classes, "A.rds")))
    message("Completed model with ", opt$classes, " classes.")
} else {
    message("Model with ", opt$classes, " classes already exists, skipping initial fit.")
}

# Capture variables to avoid scoping issues in parallel execution
if ( ! file.exists(file.path(opt$output, paste0("mm", opt$classes, "C.rds"))) ) {
    parallel::clusterExport(cl, c("opt", "df", "m1", "m2", "m3", "m4", "mm1"), envir=environment())
    mm_c <- gridsearch(mpjlcmm(longitudinal=list(m1, m2, m3, m4),
                subject = "sid",
                data = df,
                ng = ng,
                posfix = pos,
		maxiter=opt$iterations),
                cl=cl,
                maxiter=opt$iterations,
                rep = opt$repeats,
                minit = mm1)
    saveRDS(mm_c, file.path(opt$output, paste0("mm", opt$classes, "C.rds")))
    message("Completed model with ", opt$classes, " classes.")
} else {
    message("Model with ", opt$classes, " classes already exists, skipping grid search.")
}
parallel::stopCluster(cl)

message("All models fitted and saved.")
