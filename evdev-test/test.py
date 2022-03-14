import sys
import evdev
from evdev import categorize, ecodes
from pprint import pprint as pp

devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
dev = None
for device in devices:
    print(device.path, device.name, device.phys)
    if all([x in device.name for x in ['Wacom', 'Pen']]):
        dev = device

if dev is None:
    sys.exit(1)


device = evdev.InputDevice(dev.path)
print(device)
pp(device.capabilities())

t = 0
n_evts = 0
# notes
# seems like +/- 5 units of noise when still, but might be location-dependent?
# more events might be delivered when moving?
# when still, only y axis reports (& it's noisy?), x is quiet
for event in device.read_loop():
    if event.type == 0: # sync event
        t1 = event.timestamp()
        #print(f'{n_evts} events, dt = {t1 - t}')
        print('')
        n_evts = 0
        t = t1
    else:
        #print((event))
        if event.type == ecodes.EV_ABS and event.code in [ecodes.ABS_X, ecodes.ABS_Y]:
            #print(1/(event.timestamp() - t), event.code, event.value)
            print(event.value)
            pass
            n_evts += 1
    
    
    # print((t1 - t))
    # if t1 != t:
    #     t = t1
    # print(categorize(event))
