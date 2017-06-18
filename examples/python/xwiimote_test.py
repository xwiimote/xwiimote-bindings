#!/usr/bin/env python

# test with
# sudo LD_LIBRARY_PATH=<prefix>/lib PYTHONPATH=<prefix>/lib/python2.7/site-packages python ./examples/python/xwiimote_test.py

from __future__ import print_function
import errno
from time import sleep
from select import poll, POLLIN
from inspect import getmembers
import xwiimote

# display a constant
print("=== " + xwiimote.NAME_CORE + " ===")

# list wiimotes and remember the first one
try:
    mon = xwiimote.monitor(True, True)
    print("mon fd", mon.get_fd(False))
    ent = mon.poll()
    firstwiimote = ent
    while ent is not None:
        print("Found device: " + ent)
        ent = mon.poll()
except SystemError as e:
    print("ooops, cannot create monitor (", e, ")")

# continue only if there is a wiimote
if firstwiimote is None:
    print("No wiimote to read")
    exit(0)

# create a new iface
try:
    dev = xwiimote.iface(firstwiimote)
except IOError as e:
    print("ooops,", e)
    exit(1)

# display some information and open the iface
try:
    print("syspath:" + dev.get_syspath())
    fd = dev.get_fd()
    print("fd:", fd)
    print("opened mask:", dev.opened())
    dev.open(dev.available() | xwiimote.IFACE_WRITABLE)
    print("opened mask:", dev.opened())

    dev.set_led(1, True)
    if dev.get_devtype() != "balanceboard":
        dev.rumble(True)
        sleep(1/4.0)
        dev.rumble(False)
        dev.set_led(2, dev.get_led(3))
        dev.set_led(3, dev.get_led(4))
        dev.set_led(4, dev.get_led(4) == False)
    print("capacity:",  dev.get_battery(), "%")
    print("devtype:",   dev.get_devtype())
    print("extension:", dev.get_extension())

except SystemError as e:
    print("ooops", e)
    exit(1)

dev.set_mp_normalization(10, 20, 30, 40)
x, y, z, factor = dev.get_mp_normalization()
print("mp", x, y, z, factor)

# read some values
p = poll()
p.register(fd, POLLIN)
evt = xwiimote.event()
n = 0
while n < 2:
    p.poll()
    try:
        dev.dispatch(evt)
        if evt.type == xwiimote.EVENT_KEY:
            code, state = evt.get_key()
            print("Key:", code, ", State:", state)
            n+=1
        elif evt.type == xwiimote.EVENT_GONE:
            print("Gone")
            n = 2
        elif evt.type == xwiimote.EVENT_WATCH:
            print("Watch")
        elif evt.type == xwiimote.EVENT_CLASSIC_CONTROLLER_KEY:
            code, state = evt.get_key()
            print("Classical controller key:", code, state)
            tv_sec, tv_usec = evt.get_time()
            print(tv_sec, tv_usec)
            evt.set_key(xwiimote.KEY_HOME, 1)
            code, state = evt.get_key()
            print("Classical controller key:", code, state)
            evt.set_time(0, 0)
            tv_sec, tv_usec = evt.get_time()
            print(tv_sec, tv_usec)
        elif evt.type == xwiimote.EVENT_CLASSIC_CONTROLLER_MOVE:
            x, y, z = evt.get_abs(0)
            print("Classical controller move 1:", x, y)
            evt.set_abs(0, 1, 2, 3)
            x, y, z = evt.get_abs(0)
            print("Classical controller move 1:", x, y)
            x, y, z = evt.get_abs(1)
            print("Classical controller move 2:", x, y)
        elif evt.type == xwiimote.EVENT_IR:
            for i in [0, 1, 2, 3]:
                if evt.ir_is_valid(i):
                    x, y, z = evt.get_abs(i)
                    print("IR", i, x, y, z)
        elif evt.type == xwiimote.EVENT_BALANCE_BOARD:
            tr, _, _ = evt.get_abs(0)
            br, _, _ = evt.get_abs(1)
            tl, _, _ = evt.get_abs(2)
            bl, _, _ = evt.get_abs(3)
            tot = tl + tr + bl + br
            # Top Left, Top Right, Bottom Left, Bottom Right
            print("Balance board: {:5d} {:5d}".format(tl, tr))
            print("Sum:    {:5d}  {:5d} {:5d}".format(tot, bl, br))
        elif evt.type == xwiimote.EVENT_BALANCE_BOARD_KEY:
            _, state = evt.get_key()
            print("Balance board button state {}".format(state))
        else:
            if evt.type != xwiimote.EVENT_ACCEL:
                print("type:", evt.type)
    except IOError as e:
        if e.errno != errno.EAGAIN:
            print("Bad")

exit(0)
