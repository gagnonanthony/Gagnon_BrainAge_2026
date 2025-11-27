library(optparse)
library(lcmm)
library(dplyr)
library(tidyr)
library(nnet)
library(ggplot2)

# Define command line arguments
option_list <- list(
    make_option(c("-i", "--input"), type="character", help="Input CSV file path"),
    make_option(c("-o", "--output"), type="character", help="Output directory path"),
    make_option(c("-m", "--model"), type="character", help="Model RDS file path"),
    make_option(c("-c", "--classes"), type="integer", default=1, help="Number of classes in the model"),
    make_option(c("-s", "--subject_id"), type="character", default="sid", help="Subject ID variable name"),
    make_option(c("-n", "--nproc"), type="integer", default=1, help="Number of processors to use"),
    make_option(c("-x", "--iterations"), type="integer", default=200, help="Maximum number of iterations for model fitting")
)

# Parse command line arguments
opt_parser <- OptionParser(option_list=option_list, add_help_option=TRUE)
opt <- parse_args(opt_parser)

message("Input file: ", opt$input)
message("Output directory: ", opt$output)
message("Model file: ", opt$model)

if (!dir.exists(opt$output)) {
    dir.create(opt$output, recursive = TRUE)
}

message("Loading data...")
df <- read.csv(opt$input)
model <- readRDS(opt$model)

# Data preprocessing
df <- df %>%
    mutate(age_c = as.numeric(age - median(age, na.rm = TRUE)))
df[["sid"]] <- as.numeric(as.factor(df[[opt$subject_id]]))

# Get the number of classes from the model
ng <- model$ng
opt$classes <- ng
message("Number of classes in the model: ", ng)
pos <- 10 + ((ng - 1) * 3)

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
upd_mod <- update(model)
upd_m1 <- upd_mod[[1]]
upd_m2 <- upd_mod[[2]]
upd_m3 <- upd_mod[[3]]
upd_m4 <- upd_mod[[4]]

# Predict trajectories for each univariate model.
message("Predicting trajectories...")
pred_m1 <- predictY(upd_m1, data.frame(age_c=seq(min(df$age_c), max(df$age_c), length.out=100)), var.time="age_c", draws=TRUE)
pred_m2 <- predictY(upd_m2, data.frame(age_c=seq(min(df$age_c), max(df$age_c), length.out=100)), var.time="age_c", draws=TRUE)
pred_m3 <- predictY(upd_m3, data.frame(age_c=seq(min(df$age_c), max(df$age_c), length.out=100)), var.time="age_c", draws=TRUE)
pred_m4 <- predictY(upd_m4, data.frame(age_c=seq(min(df$age_c), max(df$age_c), length.out=100)), var.time="age_c", draws=TRUE)

# Plot the trajectories.
pdf(file.path(opt$output, "trajectories.pdf"))
par(mfrow=c(2, 2))
plot(pred_m1, lwd=3, ylab="M1", xlab="Age", main="m1 Trajectories", legend.loc="topleft", shades=TRUE)
plot(pred_m2, lwd=3, ylab="M2", xlab="Age", main="m2 Trajectories", legend=NULL, shades=TRUE)
plot(pred_m3, lwd=3, ylab="M3", xlab="Age", main="m3 Trajectories", legend=NULL, shades=TRUE)
plot(pred_m4, lwd=3, ylab="M4", xlab="Age", main="m4 Trajectories", legend=NULL, shades=TRUE)
#dev.copy(png, file=file.path(opt$output, "univariate_trajectories.png"), width=1600, height=400)
#dev.off()

# Plot the predictions versus observations.
par(mfrow=c(2, 2))
plot(upd_m1, which='postprob')
plot(upd_m2, which='postprob')
plot(upd_m3, which='postprob')
plot(upd_m4, which='postprob')
#dev.copy(png, file=file.path(opt$output, "predicted_vs_observed.png"), width=1600, height=400)
#dev.off()

# Plot residuals.
#plot(upd_m1)
#plot(upd_m2)
#plot(upd_m3)
#plot(upd_m4)

# Save predicted values to CSV
pred_df <- data.frame(age=seq(min(df$age), max(df$age), length.out=100))
pred_df <- cbind(pred_df, pred_m1$pred, pred_m2$pred, pred_m3$pred, pred_m4$pred)
write.csv(pred_df, file.path(opt$output, "predicted_trajectories.csv"), row.names=FALSE)
message("Predicted trajectories saved to CSV.")
