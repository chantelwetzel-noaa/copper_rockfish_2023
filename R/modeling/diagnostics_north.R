#######################################################################################################
# Copper Rockfish: North of Pt. Conception
# Run profiles, retrospectives, and jitters
#######################################################################################################

library(r4ss)
# Locatedi in the pfmc-assessments organization repo
# pak::pkg_install("pfmc-assessments/nwfscDiag")
#library(nwfscDiag)
devtools::load_all("C:/Users/Chantel.Wetzel/Documents/GitHub/nwfscDiag")
library(dplyr)

# Specify the directory
user <- Sys.getenv("USERNAME")
if( grepl("Chantel", user) ){
  user_dir <- "C:/Assessments/2023/copper_rockfish_2023"
} else {
  # Fill in Melissa's document directory below
  user_dir <- "C:/Assessments/2023/copper_rockfish_2023"
}

model_dir <- file.path(user_dir, "models", "nca")
# Specify why model you would like to profile, retro, and/or jitter
base_name <- "10.0_north_post_star_base"

# Specify the parameters and the space to profile
get = get_settings_profile(
   parameters =  c( "NatM_uniform_Fem_GP_1", "SR_BH_steep", "SR_LN(R0)"),
   low =  c(0.05, 0.30, -0.5),
   high = c(0.12,  0.95,  1.0),
   step_size = c(0.005,  0.05, 0.10),
   param_space = c('real', 'real', 'relative'),
   use_prior_like = c(1,  1, 0))

# This specifies to run ALL the diagnostics, if you want to do only some of them revise the "run" input line
model_settings = get_settings(
  settings = list(
  base_name = base_name,
  btarg = -1, 
  minbthresh = -1,
  profile_details = get,
  run = c("profile", "retro", "jitter"),
  retro_yrs = -1:-5,
  jitter_fraction = 0.10,
  Njitter = 100))

# Run line
run_diagnostics(mydir = model_dir, model_settings = model_settings)


library(ss3diags)
base_name <- "9.8_selex_fix"
model <- SS_output(file.path(model_dir, base_name))

# Runs Test
dir.create(file.path(model_dir, base_name, "runs_test"))
ss3diags::SSplotRunstest(
  model, 
  plotdir = file.path(model_dir, base_name, "runs_test"),
  print = TRUE)
sspar(mfrow = c(3, 2), plot.cex = 0.8)
ss3diags::SSplotRunstest(
  model,
  add = TRUE,
  verbose = FALSE,
  plotdir = file.path(model_dir, base_name, "runs_test"),
  print = TRUE)

sspar(mfrow = c(1, 1), plot.cex = 0.8)
SSplotJABBAres(model, add = TRUE, subplot = 'len')

load(file.path(model_dir, paste0(base_model,"_retro"), "retro_output.Rdata"))
sspar(mfrow = c(3, 2), plot.cex = 0.8)
SSplotHCxval(
  retroSummary, 
  add = TRUE, 
  verbose = F, 
  ylimAdj = 1.3, 
  legendcex = 0.7)

sspar(mfrow = c(1, 1), plot.cex = 0.7)
mvln = SSdeltaMVLN(model, run = "SMA")
sspar(mfrow = c(3, 2), plot.cex = 0.7)
SSplotEnsemble(mvln$kb, ylabs = mvln$labels, add = T, verbose = F)



