###################################################################################
#
#        Copper rockfish 2023
#   NWFSC WCGBT survey data processing
#
#############################################################################################

devtools::load_all("C:/Users/Chantel.Wetzel/Documents/GitHub/nwfscSurvey")
#library(nwfscSurvey)

library(here)
library(dplyr)

dir_main <- file.path(here(), "data", "wcgbt")

#=====================================================================
# Pull all available data
#=====================================================================

# catch = pull_catch(
#     dir = dir_main, 
#     common_name = "copper rockfish",
#     survey = "NWFSC.Combo",
#     convert  = TRUE)
#bio = pull_bio(
#   dir = dir_main, 
#   common_name = "copper rockfish",
#   survey = "NWFSC.Combo",
#   convert = TRUE)
# bio_samps = pull_biological_samples(
#     dir = dir, 
#     common_name = "copper rockfish",
#     survey = "NWFSC.Combo")

load(file.path(dir_main, "catch_copper rockfish_NWFSC.Combo_2023-02-11.rdata"))
catch_orig <- x
load(file.path(dir_main, "bio_copper rockfish_NWFSC.Combo_2023-04-03.rdata"))
bio_orig <- x

#=====================================================================
# Thread in the newly released ages
#=====================================================================
# new_ages <- read.csv(file.path(dir_main, "NWFSC_Combo_2004-2022_COPP_AgeData_20230309.csv"))
# # There is a duplicate record in these data 102185136
# duplicate <- new_ages[new_ages$Barcode == "102185136", ]
# sub_ages <- new_ages[new_ages$Barcode != "102185136", ]
# sub_ages <- rbind(sub_ages, duplicate[1,])
# sub_ages <- sub_ages[, c("Year", "Barcode", "Age")]
# sub_ages$Barcode <- as.character(sub_ages$Barcode)
# colnames(sub_ages) <- c("Year", "Otosag_id", "Read_Age")
# 
# find = which(sub_ages$Otosag_id %in% bio_orig$Otosag_id)
# length(find)
# hist(sub_ages[-find, 'Read_Age'])
# sum(!is.na(bio_orig$Age))
# 
# bio_orig <- dplyr::left_join(bio_orig, sub_ages[find,])
# replace <- which(!is.na(bio_orig$Read_Age))
# bio_orig$Age[replace] <- bio_orig$Read_Age[replace]
# bio_orig$Age_years[replace] <- bio_orig$Read_Age[replace]
# sum(!is.na(bio_orig$Age))
# sum(!is.na(bio_orig$Age_years))
# 
# save(bio_orig, file = file.path(dir_main, "bio_2003-2004_w_ages.rdata"))

#=====================================================================
# Do some summaries for data available for both areas 
#=====================================================================
catch_orig <- catch_orig[catch_orig$Latitude_dd < 42, ]
bio_orig <- bio_orig[bio_orig$Latitude_dd < 42, ]

catch_orig$area <- 'north'
catch_orig[catch_orig$Latitude_dd < 34.47, 'area'] <- 'south'

bio_orig$area <- 'north'
bio_orig[bio_orig$Latitude_dd < 34.47, 'area'] <- 'south'

save(bio_orig, file = file.path(dir_main, "wcgbt_ages_with_area.rdata"))

n_obs <- bio_orig %>%
  group_by(area, Year) %>%
  summarise(
    length_samples = length(Length_cm),
    age_samples = sum(!is.na(Age))
  )

n_tows <- catch_orig %>%
  group_by(area, Year) %>%
  summarise(
    positive_tows = sum(total_catch_numbers > 0)
  )

remove <- which(n_tows$Year == 2011)
n_tows <- n_tows[-remove[1], ]

out <- cbind(n_tows, n_obs[, c("length_samples", "age_samples")])
colnames(out) <- c("Area", "Year", "Positive Tows", "Length Samples", "Read Ages")
write.csv(out, row.names = FALSE, file = file.path(dir_main, "forSS", "wcgbt_positive_tows_and_bio_samples.csv"))

#=====================================================================
# Table of available and aged otoliths - melissa
#=====================================================================

copp_otoliths_table <- bio_orig %>%
  filter(!is.na(Otosag_id)) %>%
  group_by(area, Year) %>%
   summarise(avail.oto.cnt = n())
  
copp_age_table <- bio_orig %>%
  filter(!is.na(Age)) %>%
  group_by(area, Year) %>%
  summarise(
    oto.aged = n())

copp_age_summary <- inner_join(copp_otoliths_table,copp_age_table)
write.csv(copp_age_summary,"copper_age_summary.csv")

#=====================================================================
# Split the data by assessment area 
#=====================================================================
area = "south"
#area = "north"

catch <- catch_orig[catch_orig$area == area, ]
bio <- bio_orig[bio_orig$area == area, ]

dir = file.path(dir_main, area)

#=====================================================================
# Process the data in the selected area 
#=====================================================================

# Observations range between 59 - 183 m 
# South - one  observation > 400 m, North - one observation at 359 m
# Peak observations between 75 - 105 m
# hist(catch[catch$cpue_kg_per_ha_der >0, "Depth_m"], breaks = 30)

# Existing SA file only allows splits at 75, 100, 125, 155, 183
strata = CreateStrataDF.fn(names=c("All Depths"), 
                           depths.shallow = c(55),
                           depths.deep    = c(183),
                           lats.south     = c(32.5),
                           lats.north     = c(42.0))

if( area == "south") {
  strata = CreateStrataDF.fn(names=c("All Depths"), 
                           depths.shallow = c(55),
                           depths.deep    = c(183),
                           lats.south     = c(32.5),
                           lats.north     = c(34.5))
} 
if( area == "north") {
strata = CreateStrataDF.fn(names=c("All Depths"), 
                           depths.shallow = c(55),
                           depths.deep    = c(183),
                           lats.south     = c(34.5),
                           lats.north     = c(42.0))
}
num_strata = CheckStrata.fn(dir = dir,  
							dat = catch, 
							strat.df = strata)

file.rename(file.path(dir, "forSS", "strata_observations.csv"),
            file.path(dir, "forSS", paste0(area, "_strata_observations.csv")))

# Calculate the design based index
biomass = Biomass.fn(
    dir = dir, 
    dat = catch,  
    strat.df = strata) 

file.rename(file.path(dir,  "forSS", "design_based_indices.csv"),
            file.path(dir,  "forSS", paste0(area, "_design_based_indices.csv")))

# Plot the biomass index
PlotBio.fn(
  dir = dir, 
  dat = biomass)

#=====================================================================
# Visualize the data
#=====================================================================

plot_bio_patterns(
  dir = dir, 
  bio = bio, 
  col_name = "Length_cm")

temp <- catch[catch$Depth_m < 200, ] %>%
  dplyr::mutate(new = factor(
    cpue_kg_km2 <= 0,
    levels = c(FALSE, TRUE),
    labels = c("Present", "Absent")
  ))

# Plot depth bins (10 m) by presence/absence with default colors
plot_proportion(
  data = temp,
  column_factor = new,
  column_bin = Depth_m,
  width = 10,
  boundary = 0,
  bar_width = "equal"
)
ggplot2::ggsave(filename = file.path(dir, "plots", "proportion_by_depth.png"))

# In the south there are two observations > 150 m of one fish
# at 182.7 and another at 407.8. The last one is suspect. That 
# tow is 183 on 10-20-2008. The nearest previous tow with copper
# occurred the day before in tow 179 at 77 meters.
plot_proportion(
  data = bio[bio$Depth_m < 150, ] %>%
    dplyr::mutate(Sex = codify_sex(Sex)),
  column_factor = Sex,
  column_bin = Depth_m,
  width = 10,
  boundary = 0,
  bar_width = "equal"
)
ggplot2::ggsave(filename = file.path(dir, "plots", "sex_by_depth.png"))


# Look at where copper are observed by location
plot(catch$Longitude_dd, catch$Latitude_dd, pch = 16, 
    col = 'grey', xlab = "Longitude", ylab = "Latitude")
pos = which(catch$cpue_kg_km2 > 0)
points(catch$Longitude_dd[pos], catch$Latitude_dd[pos], pch = 16, col = 'red')
legend('topright', bty = 'n', legend = c("All Tows", "Positive Tows"),
    col = c('grey', 'red'), pch = c(16, 16))
ggplot2::ggsave(filename = file.path(dir, "plots", paste0('postive_copper_tows_', area, '.png')))

plot_age_length_sampling(
   data = bio,
   xlim = c(0, 60),
   ylim = c(0, 0.25),
   dir = dir)

#=====================================================================
# Calculate the numbers of lengths and ages by year
#=====================================================================

samples <- bio %>%
  filter(Depth_m < 183) %>%
  group_by(Year) %>%
  reframe(
    n_lengths = n(),
    n_ages = sum(!is.na(Age))
  )

pos_tows <- catch %>% 
  filter(Depth_m < 183) %>%
  group_by(Year) %>%
  reframe(
    total_tows = length(total_catch_numbers),
    pos_tow = sum(total_catch_numbers > 0),
    n = sum(total_catch_numbers),
    weight = sum(total_catch_wt_kg)
  )

out <- left_join(pos_tows, samples, by = "Year")
out[is.na(out)] <- 0
colnames(out) <- c("Year", "Tows", "Positive Tows", "Numbers", "Weight (kg)", "Lengths", "Ages")
write.csv(out, file = file.path(dir, "forSS", "wcgbt_samples_by_year.csv"), row.names = FALSE)

#=====================================================================
# Calculate length compositions
#=====================================================================
len_bin = seq(10, 54, 2)

# Calculate the effN
# Using the others group which is 2.43 unique samples / tow
# The shelf and slope rockfish in contrast have a value of 2.38

# Process the sexed and unsexed fish separately 
n = GetN.fn(
    dat = bio, 
    type = "length", 
    species = "others")

# Process the sexed and unsexed fish separately 
n = GetN.fn(
    dat = bio[bio$Sex %in% c("F", "M"), ], 
    type = "length", 
    species = "others")

sexed_length_comps <- SurveyLFs.fn(
  dir = dir, 
	datL = bio[bio$Sex %in% c("F", "M"), ],
  datTows = catch,  
  strat.df = strata,
  lgthBins = len_bin, 
  month = 7, 
  fleet = NA, 
  sex = 3,
  nSamps = n)

plot_comps(
  dir = dir, 
  add_save_name = "sexed",
  data = sexed_length_comps)

# Check for greater than one observation per year
table(bio[bio$Sex == "U", "Year"])

n = GetN.fn(
    dat = bio[bio$Sex == "U", ], 
    type = "length", 
    species = "others")

unsexed_length_comps <- SurveyLFs.fn(
    dir = dir, 
    datL = bio[bio$Sex == "U", ],
    datTows = catch,  
    strat.df = strata,
    lgthBins = len_bin, 
    month = 7, fleet = 10, 
    sex = 0,
    nSamps = n)

plot_comps(dir = dir, 
    add_save_name = "unsexed",
    data = unsexed_length_comps)

PlotFreqData.fn(dir = dir,
	dat = sexed_length_comps, 
    inch = 0.10,
    main = paste0("NWFSC WCGBTS - ", area, " - Sexed Fish "))

PlotSexRatio.fn(dir = dir, 
    dat = bio, data.type = "length")

# Unexpanded length data
tmp <- bio[, !colnames(bio) %in% c("Ageing_lab")]
lens <-  UnexpandedLFs.fn(
  datL = tmp, 
  lgthBins = len_bin,
  partition = 0, 
  ageErr = 1,
  fleet = "wcgbt", 
  month = 7)
write.csv(lens$sexed, 
          file = file.path(dir, "forSS", "wcgbt_lengths_sexed_unexpanded.csv"),
          row.names = FALSE)
write.csv(lens$unsexed, 
          file = file.path(dir,"forSS", "wcgbt_lengths_unsexed_unexpanded.csv"),
          row.names = FALSE)

#=====================================================================
# Calculate age compositions
#=====================================================================
age_bin = 0:50

# There is only one unsexed fish that has been aged
n <- GetN.fn(
    dat = bio, 
    type = "age", 
    species = "others")

# Marginals
age_comps <- SurveyAFs.fn(
    dir = dir, 
    datA = bio,
    datTows = catch,  
    strat.df = strata,
    ageBins = age_bin, 
    sex = 3, 
    month = 7, 
    fleet = NA, 
    nSamps = n)

plot_comps(dir = dir, 
    data = age_comps)

# Conditional-age-at-length
caal <- SurveyAgeAtLen.fn(
    dir = dir, 
    ageErr = 1, 
    datAL = bio, 
    datTows = catch, 
    strat.df = strata, 
    lgthBins = len_bin, 
    ageBins = age_bin)


# Condense to a single year
caal = bio
caal$Year = 9999
caal_catch = catch
caal_catch$Year = 9999
SurveyAgeAtLen.fn(dir = dir, 
    datAL = caal, 
    datTows = caal_catch, 
    strat.df = strata, 
    lgthBins = len_bin, 
    ageBins = age_bin)

PlotVarLengthAtAge.fn(
    dir = dir, 
    dat = bio)

#=============================================================
# Estimate index for copper south of pt. conceptions
#=============================================================

library(sdmTMB)
devtools::load_all("C:/Users/Chantel.Wetzel/Documents/GitHub/indexwc")

southern_BC <- 49.0
southern_WA <- 46.0
southern_OR <- 42.0
southern_CA <- 32.0

setwd("C:/Users/Chantel.Wetzel/Documents/GitHub/indexwc")
usethis::use_data(
  southern_BC, southern_WA, southern_OR, southern_CA,
  internal = TRUE,
  overwrite = TRUE
)

dir <- file.path(here(), "data", "survey_indices", "wcgbt")
setwd(dir)

load(file.path(dir_main, "catch_copper rockfish_NWFSC.Combo_2023-02-11.rdata"))
catch_orig <- x
data <- catch_orig[catch_orig$Latitude_dd < 34.5, ]

run(data, family = sdmTMB::delta_lognormal())
run(data, family = sdmTMB::delta_lognormal_mix())
