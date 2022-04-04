library(RcppSimdJson)
library(data.table)
library(signal)
library(ggplot2)

dat <- fload('test_1648845108.json.gz', max_simplify_lvl='vector')
# dat$block has blockwise settings,
# dat$trial has individual trial info
# dat$tgt is the original tgt (which is probably totally subsumed by $block & $trial...)

# there's a lot of metadata in $block that you probably won't need,
# but at least a few things (id, rot_or_clamp, state_names, trial_labels, ...)

for (i in 1:length(dat[['trials']])) {
  # for each trial, compute reaction time/initial movement angle
  # 
  #foo <- rbindlist(dat$trials$frames[i])
  #print(nrow(foo[missed_frame_deadline==1]))
  mv <- rbindlist(dat$trials$frames[[i]]$input_events)
  # for now, use pre-interpolated cursor position
  trial <- dat$trials$frames[[i]]
  trial[['input_events']] <- NULL
  trial <- as.data.table(trial)
  cur <- rbindlist(trial[['cursor']])
  tar <- rbindlist(trial[['target']])
  trial[, c('cursor.x', 'cursor.y', 'cursor.vis') := cur]
  trial[, c('target.x', 'target.y', 'target.vis') := tar]
  trial[['cursor']] <- NULL
  trial[['target']] <- NULL
  trial[['ep_feedback']] <- NULL
  moving <- trial[end_state==2]
  # RT: diff between moving[['vbl_time']][1] and moved 1cm from start
  # MT: from https://www.biorxiv.org/content/10.1101/2020.09.14.297143v4.full.pdf
  # heading angle was defined by two imaginary lines, one from the start position to the target and the other from the start position to the hand position at maximum movement velocity
  #
  
}