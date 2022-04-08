library(RcppSimdJson)
library(data.table)
library(signal)
library(ggplot2)
source('clean_trial.r')

rad2deg <- function(rad) {(rad * 180) / (pi)}
deg2rad <- function(deg) {(deg * pi) / (180)}

# https://stackoverflow.com/a/30887154/2690232
signed_diff_angle <- function(a, b) {
  d <- abs(a - b) %% 360
  r <- ifelse(d > 180, 360 - d, d)
  sgn <- ifelse((a - b >= 0 && a - b <= 180) || (a - b <= -180 && a - b >= -360), 1, -1)
  r * sgn
}

data_files <- list.files('../data', glob2rx('msl*.json.gz'), full.names=TRUE)

dat <- list()

for (i in 1:length(data_files)) {
    raw_dat <- fload(data_files[i], max_simplify_lvl='vector')
    # skip if warmup (I suppose this begs for the on-demand interface)
    if (raw_dat[['block']][['block_type']] != 'r') {
        next
    }
    dat[[i]] <- clean_block(raw_dat[['block']], raw_dat[['trials']])
}

dat <- rbindlist(dat)

# for each person, calculate baseline-corrected err
dat_cyc <- list()
ids <- unique(dat[['id']])
for (i in 1:length(ids)) {
    # take subset
    tmp <- dat[id==ids[i]]
    # correct baseline
    bs <- tmp[label=='BASELINE_1', mean(diff_angle)]
    tmp[, diff_angle := diff_angle - bs]
    eventual_angle <- tmp[label=='PERTURBATION', manipulation_angle[1]]
    dat_cyc[[i]] <- tmp[, .(id = id[1], group = group[1],
                            label = label[1], manipulation_angle = manipulation_angle[1],
                            eventual_angle = eventual_angle,
                            dang = mean(diff_angle)), by = (seq(nrow(tmp)) - 1) %/% 5]
}

dat_cyc <- rbindlist(dat_cyc)
dat_cyc[, mega_label := paste0('id: ', id, ' group: ', group, ' clamp angle: ', eventual_angle)]
dat_cyc[, dang := dang * ifelse(eventual_angle > 0, -1, 1)]
#labels <- dat_cyc[label=='PERTURBATION', .SD[1], by=id]

ggplot(dat_cyc, aes(x=seq, y = dang, colour=label)) +
  geom_hline(yintercept = 0, linetype='longdash') +
  geom_point(size=2) +
  labs(x = 'Cycle (5 trials)', y = 'Baseline-corrected error (deg)') +
  theme_bw() + 
  facet_wrap(~mega_label)
