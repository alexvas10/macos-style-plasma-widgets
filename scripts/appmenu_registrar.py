#!/usr/bin/env python3
"""
com.canonical.AppMenu.Registrar service

Qt6 apps (KDE, Firefox, etc.) watch for this service to appear on the session bus.
When it appears, they export their dbusmenu and register via RegisterWindow().
On Wayland, they also push the service/path to KWin via org_kde_kwin_appmenu,
which then populates ApplicationMenuServiceName in Plasma's TasksModel.
"""

import signal
import sys
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

BUSNAME = "com.canonical.AppMenu.Registrar"
OBJECT_PATH = "/com/canonical/AppMenu/Registrar"
INTERFACE = "com.canonical.AppMenu.Registrar"


class AppMenuRegistrar(dbus.service.Object):
    def __init__(self, bus):
        super().__init__(bus, OBJECT_PATH)
        self._menus = {}  # windowId → (senderBusName, objectPath)
        self._bus = bus
        print("AppMenu Registrar started", flush=True)

    @dbus.service.method(INTERFACE,
                         in_signature="uo", out_signature="",
                         sender_keyword="sender")
    def RegisterWindow(self, window_id, menu_object_path, sender=None):
        self._menus[int(window_id)] = (str(sender), str(menu_object_path))
        print(f"RegisterWindow: winId={window_id} sender={sender} path={menu_object_path}", flush=True)

    @dbus.service.method(INTERFACE,
                         in_signature="u", out_signature="")
    def UnregisterWindow(self, window_id):
        self._menus.pop(int(window_id), None)
        print(f"UnregisterWindow: winId={window_id}", flush=True)

    @dbus.service.method(INTERFACE,
                         in_signature="u", out_signature="so")
    def GetMenuForWindow(self, window_id):
        entry = self._menus.get(int(window_id))
        if entry:
            return entry
        return ("", dbus.ObjectPath("/"))


def main():
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()

    try:
        name = dbus.service.BusName(BUSNAME, bus,
                                    allow_replacement=False,
                                    replace_existing=False)
    except dbus.exceptions.NameExistsException:
        print(f"ERROR: {BUSNAME} is already registered. Another registrar is running.", flush=True)
        sys.exit(1)

    registrar = AppMenuRegistrar(bus)

    loop = GLib.MainLoop()
    signal.signal(signal.SIGTERM, lambda *_: loop.quit())
    signal.signal(signal.SIGINT, lambda *_: loop.quit())
    loop.run()


if __name__ == "__main__":
    main()
