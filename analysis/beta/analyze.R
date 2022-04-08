library(RcppSimdJson)
library(data.table)
library(signal)
library(ggplot2)

rad2deg <- function(rad) {(rad * 180) / (pi)}
deg2rad <- function(deg) {(deg * pi) / (180)}

# https://stackoverflow.com/a/30887154/2690232
signed_diff_angle <- function(a, b) {
  d <- abs(a - b) %% 360
  r <- ifelse(d > 180, 360 - d, d)
  sgn <- ifelse((a - b >= 0 && a - b <= 180) || (a - b <= -180 && a - b >= -360), 1, -1)
  r * sgn
}

raw_dat <- fload('adf_1649270675.json.gz', max_simplify_lvl='vector')
# raw_dat$block has blockwise settings,
# raw_dat$trial has individual trial info

# there's a lot of metadata in $block that you probably won't need,
# but at least a few things (id, rot_or_clamp, state_names, trial_labels, ...)

# add some arrays for later
trials <- raw_dat[['trials']]
lt <- length(trials[['delay']])
z <- rep(0, lt)
trials$rt <- z
trials$target_angle <- z
trials$reach_angle <- z
trials$diff_angle <- z
trials$target_dist <- z
trials$trial <- z
for (i in 1:lt) {
  # for each trial, compute reaction time/initial movement angle
  # 
  #foo <- rbindlist(raw_dat$trials$frames[i])
  #print(nrow(foo[missed_frame_deadline==1]))
  trial <- trials$frames[[i]]
  evts <- list()
  for (j in 1:length(trial[['end_state']])) {
    # loop through frames, assigning state & such
    evt = trial[['input_events']][[j]]
    if (!is.null(evt[['t']])) {
      tmp <- as.data.table(evt)
      tmp[, state := trial[['end_state']][j]]
      evts[[j]] <- tmp
    }
  }
  
  evts <- rbindlist(evts)

  # find the trial start time
  idx <- which(trial[['end_state']] - trial[['start_state']] == 1)[1]
  start_time <- trial[['vbl_time']][idx]
  evts[, distance := sqrt(x^2 + y^2)]
  evts[, t := t - start_time]
  evts[, dt := t - shift(t)]
  evts[, dx := x - shift(x)]
  evts[, dy := y - shift(y)]
  evts[, speed := sqrt((dx/dt)^2 + (dy/dt)^2)]
  # if you wanted to peek at individual trials, this is the point at which to do so
  
  # compute RT and MT on relevant part of trial
  subevt <- evts[state==2]
  # RT: diff between moving[['vbl_time']][1] and moved 1cm from start
  # MT: from https://www.biorxiv.org/content/10.1101/2020.09.14.297143v4.full.pdf
  # heading angle was defined by two imaginary lines, one from the start position to the target and the other from the start position to the hand position at maximum movement velocity
  #
  idx <- which(subevt[, distance] > 10)[1]
  rt <- subevt[idx, t]
  fastest <- which.max(subevt[, speed])[1]
  # hand angle at fastest time
  ang <- rad2deg(do.call(atan2, subevt[fastest, c('y', 'x')]))
  # target angle
  targ <- trial[['target']][[j]]
  t_ang <- rad2deg(atan2(targ$y, targ$x))
  diff_ang <- signed_diff_angle(ang, t_ang)
  trials$rt[i] <- rt
  trials$target_angle[i] <- t_ang
  trials$target_dist[i] <- sqrt(targ$x^2 + targ$y^2)
  trials$reach_angle[i] <- ang
  trials$diff_angle[i] <- diff_ang
  trials$trial[i] <- i
}

trials$frames <- NULL
trials$target <- NULL

dat <- as.data.table(trials)

dat_cyc <- dat[, .(label = mean(label), dang = mean(diff_angle)), by = c('id', (seq(nrow(dat)) - 1) %/% 5)]
baseline_correct <- mean(dat[label==2, diff_angle])
dat_cyc[, dang := dang - baseline_correct]
dat_cyc[, lab2 := raw_dat$block$trial_labels[label+1]]

ggplot(dat_cyc, aes(x=seq, y = dang, colour=lab2)) +
  geom_hline(yintercept = 0, linetype='longdash') +
  geom_point(size=2) +
  labs(x = 'Cycle (5 trials)', y = 'Baseline-corrected error (deg)', title = '-7.5° clamp, variable delays') +
  theme_bw()

trial <- trials$frames[[30]]
foo <- data.table(dur = trial$frame_comp_dur, st = trial$end_state)
foo[, t := 1:.N]
ggplot(foo, aes(x = t, y = dur, colour=factor(st))) + geom_point() + geom_line()
