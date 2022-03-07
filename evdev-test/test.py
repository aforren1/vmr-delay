import evdev
from evdev import categorize
from pprint import pprint as pp

device = evdev.InputDevice('/dev/input/event21')
print(device)
pp(device.capabilities())

t = 0
for event in device.read_loop():
    print(1 / (event.timestamp() - t))
    t = event.timestamp()
    print(categorize(event))
