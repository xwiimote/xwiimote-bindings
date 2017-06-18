#!/usr/bin/env python

from __future__ import print_function
import xwiimote
import select
import errno

def print_wiimotes(wiimotes):
    print("+--------------------------------------------+")
    print("| %-40s %i |" % (xwiimote.iface.get_name(xwiimote.IFACE_CORE), len(wiimotes['all'])))
    print("+--------------------------------------------+")
    for devtype, devlist in wiimotes.items():
        if devtype != 'all':
            print("| %-40s %i |" % (xwiimote.iface.get_name(devtype), len(devlist)))
    print("+--------------------------------------------+")

def read_monitor(mon, wiimotes):
    newmotes = []
    wiimote_path = mon.poll()
    while wiimote_path is not None:
        try:
            dev = xwiimote.iface(wiimote_path)
            wiimotes['all'].append(dev)
            news = open_subdevices(dev, wiimotes)
            newmotes.append(dev)
        except IOError as eo:
            print("Fail on creating the wiimote (", eo, ")")
        wiimote_path = mon.poll()
    return newmotes

def remove_device(wiimotes, dev):
    for devtype, devlist in wiimotes.items():
        if dev in devlist:
            devlist.remove(dev)
    print_wiimotes(wiimotes)

def open_subdevices(dev, wiimotes):
    news = False
    for devtype, devlist in wiimotes.items():
        if devtype != 'all':
            news = open_subdevice(dev, devlist, devtype) or news
    return news

def open_subdevice(dev, currents, ext):
    # already opened
    if((dev.opened() & ext) == ext):
        return False

    # device not already opened, but in the list
    if dev in currents:
        if((dev.available() & ext) == ext):
            # nothing changed
            return False
        else:
            # this is a removal
            currents.remove(dev)
            return True

    # device not available
    if((dev.available() & ext) == 0):
        return False

    try:
        dev.open(ext)
        currents.append(dev)
        return True
    except IOError:
        print("Ooops, unable to open the device")

    return False

#
p = select.poll()

# watched wiimotes
wiimotes = {'all':[], xwiimote.IFACE_CLASSIC_CONTROLLER:[], xwiimote.IFACE_DRUMS:[], xwiimote.IFACE_GUITAR:[]}

try:
    mon = xwiimote.monitor(True, False)
    newmotes = read_monitor(mon, wiimotes)
    for dev in newmotes:
        p.register(dev.get_fd(), select.POLLIN)
    print_wiimotes(wiimotes)
except SystemError as e:
    print("ooops, cannot create monitor (", e, ")")
    exit(1)

# register devices
mon_fd = mon.get_fd(False)
p.register(mon_fd, select.POLLIN)

revt = xwiimote.event()
try:
    while True:
        polls = p.poll()
        for fd, evt in polls:

            # monitor
            if fd == mon_fd:
                newmotes = read_monitor(mon, wiimotes)
                for dev in newmotes:
                    p.register(dev.get_fd(), select.POLLIN)
                    if len(newmotes) > 0:
                        print_wiimotes(wiimotes)

            # wiimotes
            else:
                for dev in wiimotes['all']:
                    if fd == dev.get_fd():
                        try:
                            dev.dispatch(revt)

                            # special actions
                            if revt.type == xwiimote.EVENT_WATCH:
                                if(open_subdevices(dev, wiimotes)):
                                    print_wiimotes(wiimotes)
                            elif revt.type == xwiimote.EVENT_GONE:
                                p.unregister(dev.get_fd())
                                remove_device(wiimotes, dev)
                            else:
                                # normal actions
                                if revt.type == xwiimote.EVENT_CLASSIC_CONTROLLER_KEY:
                                    (code, state) = revt.get_key()
                                    if state == True:
                                        if code == xwiimote.KEY_PLUS:
                                            print("plus")
                                        elif code == xwiimote.KEY_MINUS:
                                            print("minus")
                        except IOError as e:
                            if e.errno != errno.EAGAIN:
                                print(e)
                                p.unregister(dev.get_fd())
                                remove_device(wiimotes, dev)
except KeyboardInterrupt:
    print("exiting...")

# cleaning
for dev in wiimotes['all']:
    p.unregister(dev.get_fd())
    remove_device(wiimotes, dev)
p.unregister(mon_fd)
exit(0)
