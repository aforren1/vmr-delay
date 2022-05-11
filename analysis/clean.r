library(RcppSimdJson)
library(data.table)
library(ggplot2)
source('clean_trial.r')

# msl000296 accidentally reused?
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
    print(data_files[i])
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
dat_cyc[, dang := dang * -sign(eventual_angle)]
#labels <- dat_cyc[label=='PERTURBATION', .SD[1], by=id]

ggplot(dat_cyc, aes(x=seq, y = dang, colour=label)) +
  geom_hline(yintercept = 0, linetype='longdash') +
  geom_point(size=2) +
  labs(x = 'Cycle (5 trials)', y = 'Baseline-corrected error (deg)') +
  theme_bw() + 
  facet_wrap(~mega_label, ncol=2) +
  ylim(c(-20,20))


foo <- dat_cyc[, .(mn = mean(dang)), by=c('seq', 'group', 'label')]
# mean aftereffect per person (baseline subtracted)
# 
baseline <- dat[label=='BASELINE_1', .(bs = mean(diff_angle)), by=id]
angs <- dat[label == 'PERTURBATION', .(ang = manipulation_angle[1]), by=id]

after <- dat[label=='WASHOUT']

after <- after[baseline, on = .(id)]
after[, bs_corrected_angle := diff_angle - bs]
after <- after[angs, on = .(id)]
after[, bs_corrected_angle := bs_corrected_angle * -sign(ang)]
after[, group := factor(group)]
after[, c('bs') := NULL]

after_summ <- after[, .(mean_bs_corrected_angle = mean(bs_corrected_angle), group=group[1], ang=ang[1]), by = id]

##
avg_foo <- dat

avg_foo <- avg_foo[baseline, on = .(id)]
avg_foo[, bs_corrected_angle := diff_angle - bs]
avg_foo[, c('bs', 'online_feedback', 'endpoint_feedback', 'manipulation_type', 'target_dist') := NULL]
avg_foo <- avg_foo[angs, on = .(id)]
avg_foo[, bs_corrected_angle := bs_corrected_angle * -sign(ang)]
avg_foo[, group := factor(group)]

avg_foo <- avg_foo[abs(bs_corrected_angle) < 60]

avg_bar <- avg_foo[, .(mn_bs_corrected_angle = mean(bs_corrected_angle), label = label[1]), by = c('trial', 'group')]

ggplot(avg_bar, aes(x = trial, y = mn_bs_corrected_angle, colour=label)) + 
  geom_point() +
  geom_line() +
  facet_wrap(~group)
# fwrite( after_summ, 'aftereffect_summary.csv')

# g1 = 0.5 sec delay
# g2 = variable delay
# g3 = 0.1 sec delay
# g4 = 0.3 sec delay


