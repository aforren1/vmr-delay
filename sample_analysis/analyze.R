library(RcppSimdJson)

dat <- fload('test_1648845108.json.gz', max_simplify_lvl='vector')
# dat$block has blockwise settings,
# dat$trial has individual trial info
# dat$tgt is the original tgt (which is probably totally subsumed by $block & $trial...)

# there's a lot of metadata in $block that you probably won't need,
# but at least a few things (id, rot_or_clamp, state_names, trial_labels, ...)

