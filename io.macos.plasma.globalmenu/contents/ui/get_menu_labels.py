#!/usr/bin/env python3
"""
Interact with a com.canonical.dbusmenu D-Bus service.

Usage:
  get_menu_labels.py pid <pid>
      → {"service":"...","path":"..."} for the window whose process is <pid>,
        or {} if no dbusmenu is found.

  get_menu_labels.py <service> <path>
      → JSON array of top-level menu items: [{"id":N,"label":"File"}, ...]

  get_menu_labels.py <service> <path> children <id>
      → JSON array of children of item <id>

  get_menu_labels.py <service> <path> activate <id>
      → sends a clicked event to item <id>, prints "ok"
"""
import sys, json, dbus

def get_layout(iface, item_id, depth):
    _, layout = iface.GetLayout(item_id, depth,
        ["label", "visible", "enabled", "type", "children-display", "icon-name"])
    return layout

def parse_items(children):
    items = []
    for child in children:
        child_id, props, grandchildren = child
        label   = str(props.get("label", ""))
        visible = bool(props.get("visible", True))
        typ     = str(props.get("type", "standard"))
        enabled = bool(props.get("enabled", True))
        if not visible:
            continue
        if typ == "separator":
            items.append({"id": int(child_id), "label": "", "type": "separator",
                          "has_submenu": False, "enabled": True})
            continue
        if not label or label == "Label Empty":
            continue
        clean = label.replace("_", "")
        has_sub = str(props.get("children-display", "")) == "submenu"
        items.append({"id": int(child_id), "label": clean,
                      "type": "standard", "has_submenu": has_sub, "enabled": enabled})
    return items

try:
    bus = dbus.SessionBus()

    # ── PID-based service discovery ──────────────────────────────────────────
    if sys.argv[1] == "pid":
        target_pid = int(sys.argv[2])
        daemon     = bus.get_object("org.freedesktop.DBus", "/org/freedesktop/DBus")
        daemon_if  = dbus.Interface(daemon, "org.freedesktop.DBus")
        all_names  = daemon_if.ListNames()

        # Static paths to probe first (browsers, Electron, GTK apps)
        STATIC_PROBE_PATHS = [
            "/com/canonical/menu/1",
            "/com/canonical/menu/2",
            "/com/canonical/menu/3",
            "/com/canonical/menu/0",
            "/com/canonical/menu/4",
            "/com/canonical/menu/5",
        ]

        def probe_dbusmenu(name, path):
            try:
                obj   = bus.get_object(name, path, introspect=False)
                iface = dbus.Interface(obj, "com.canonical.dbusmenu")
                iface.GetLayout(0, 0, dbus.Array([], signature='s'))
                return True
            except Exception:
                return False

        for name in all_names:
            if name.startswith(":"):
                continue
            try:
                if int(daemon_if.GetConnectionUnixProcessID(name)) != target_pid:
                    continue
            except Exception:
                continue

            # Try static paths first
            for path in STATIC_PROBE_PATHS:
                if probe_dbusmenu(name, path):
                    print(json.dumps({"service": str(name), "path": path}))
                    sys.exit(0)

            # For KDE Qt apps: introspect /MenuBar to find window-specific subpaths
            # (e.g. /MenuBar/2 for a window with index 2)
            try:
                mb_obj = bus.get_object(name, "/MenuBar")
                mb_xml = mb_obj.Introspect(dbus_interface="org.freedesktop.DBus.Introspectable")
                import re as _re
                for child in _re.findall(r'<node name="([^"]+)"', mb_xml):
                    path = "/MenuBar/" + child
                    if probe_dbusmenu(name, path):
                        print(json.dumps({"service": str(name), "path": path}))
                        sys.exit(0)
            except Exception:
                pass

        print("{}")
        sys.exit(0)

    # ── Standard service + path modes ────────────────────────────────────────
    service = sys.argv[1]
    path    = sys.argv[2]
    mode    = sys.argv[3] if len(sys.argv) > 3 else "toplevel"
    arg     = int(sys.argv[4]) if len(sys.argv) > 4 else 0

    obj   = bus.get_object(service, path, introspect=False)
    iface = dbus.Interface(obj, "com.canonical.dbusmenu")

    if mode == "toplevel":
        _id, _props, children = get_layout(iface, 0, 1)
        print(json.dumps(parse_items(children)))

    elif mode == "children":
        _id, _props, children = get_layout(iface, arg, 1)
        print(json.dumps(parse_items(children)))

    elif mode == "close":
        try:
            iface.Event(dbus.Int32(arg), "closed",
                        dbus.Int32(0, variant_level=1), dbus.UInt32(0))
        except Exception:
            pass
        print("ok")

    elif mode == "activate":
        iface.Event(dbus.Int32(arg), "clicked",
                    dbus.Int32(0, variant_level=1), dbus.UInt32(0))
        print("ok")

except Exception as e:
    print("[]")
    print(str(e), file=sys.stderr)
