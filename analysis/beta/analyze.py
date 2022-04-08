# TODO: fit spline, and check center is in right place?
import gzip
import json
import numpy as np
import scipy.signal as ss
from scipy import interpolate
import matplotlib.pyplot as plt
from matplotlib import colors

def flatten(lst):
    for it in lst:
        if isinstance(it, list):
            for sub in it: yield sub
        else:
            yield it

with gzip.open('test_1649169039.json.gz', 'rb') as f:
    data = json.loads(f.read().decode('utf-8'))

# data['block'] contains general block info
for trial in data['trials']['frames']:
    # loop through frames within the trial
    xs = []
    ys = []
    ts = []
    sts = []
    for i in range(len(trial['start_state'])):
        # figure out state for each input event
        #if trial['end_state'][i] == 2:
        evts = trial['input_events'][i]
        if evts['t']: # anything at all
            if isinstance(evts['t'], list):
                xs.extend(evts['x'])
                ys.extend(evts['y'])
                ts.extend(evts['t'])
                sts.extend([trial['end_state'][i]]*len(evts['t']))
            else:
                xs.append(evts['x'])
                ys.append(evts['y'])
                ts.append(evts['t'])
                sts.append(trial['end_state'][i])
    
    xs = np.array(xs)
    ys = np.array(ys)
    ts = np.array(ts)
    ts = ts - ts[0]
    sts = np.array(sts)

s = interpolate.SmoothBivariateSpline(ts, xs, ys)
tn = np.arange(ts[0], ts[-1], 1/500) # approx 200hz
xn, yn = s(tn)

plt.plot(ts, ys, 'o')
plt.plot(tn, yn)
plt.show()
