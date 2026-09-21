"""Switch the GNOME display mode for the duration of a Sunshine session.

``apply`` picks the display mode that matches the streaming client's aspect
ratio (Moonlight reports its resolution in ``SUNSHINE_CLIENT_WIDTH`` and
``SUNSHINE_CLIENT_HEIGHT``) and applies it as a *temporary* mutter
configuration, so a crashed session never leaves it persisted.  ``revert``
restores the configuration that was active when ``apply`` ran.

Failures are reported on stderr but exit 0 unless ``--strict`` is given: a
display that cannot be reconfigured must not abort the stream.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
import syslog
from dataclasses import dataclass
from pathlib import Path

import gi

gi.require_version("Gio", "2.0")

from gi.repository import Gio, GLib

BUS_NAME = "org.gnome.Mutter.DisplayConfig"
OBJECT_PATH = "/org/gnome/Mutter/DisplayConfig"
METHOD_TEMPORARY = 1
TRANSFORM_NORMAL = 0
APPLY_TYPE = "(uua(iiduba(ssa{sv}))a{sv})"
# Logical rows to aim for when picking a scale, i.e. "1200p worth of desktop".
TARGET_LOGICAL_HEIGHT = 1200


def log(message: str) -> None:
    """Report to stderr and to the journal.

    Sunshine discards prep-cmd output, so the journal is the only place where
    the resolution a client asked for can be read back after a session.
    """
    print(f"sunshine-display: {message}", file=sys.stderr)
    syslog.openlog("sunshine-display", syslog.LOG_PID, syslog.LOG_USER)
    syslog.syslog(syslog.LOG_INFO, message)


@dataclass(frozen=True)
class Mode:
    """One monitor mode as reported by mutter."""

    id: str
    width: int
    height: int
    refresh: float
    scales: tuple[float, ...]
    variable_refresh: bool

    @property
    def aspect(self) -> float:
        return self.width / self.height


@dataclass(frozen=True)
class Logical:
    """One logical monitor of a mutter configuration."""

    x: int
    y: int
    scale: float
    transform: int
    primary: bool
    connectors: tuple[str, ...]
    mode_ids: tuple[str, ...]


@dataclass(frozen=True)
class State:
    """Snapshot of mutter's current display configuration."""

    serial: int
    layout_mode: int | None
    modes: dict[str, tuple[Mode, ...]]
    logicals: tuple[Logical, ...]
    current_mode: dict[str, str]


def proxy() -> Gio.DBusProxy:
    return Gio.DBusProxy.new_for_bus_sync(
        Gio.BusType.SESSION,
        Gio.DBusProxyFlags.NONE,
        None,
        BUS_NAME,
        OBJECT_PATH,
        BUS_NAME,
        None,
    )


def read_state(bus: Gio.DBusProxy) -> State:
    """Read mutter's current configuration."""
    serial, monitors, logicals, props = bus.call_sync(
        "GetCurrentState", None, Gio.DBusCallFlags.NO_AUTO_START, -1, None
    ).unpack()

    modes: dict[str, tuple[Mode, ...]] = {}
    current: dict[str, str] = {}
    for (connector, _vendor, _product, _serial), mode_list, _mprops in monitors:
        parsed = []
        for mode_id, width, height, refresh, _pref, scales, mprops in mode_list:
            parsed.append(
                Mode(
                    id=mode_id,
                    width=width,
                    height=height,
                    refresh=refresh,
                    scales=tuple(scales),
                    variable_refresh=mprops.get("refresh-rate-mode") == "variable",
                )
            )
            if mprops.get("is-current"):
                current[connector] = mode_id
        modes[connector] = tuple(parsed)

    parsed_logicals = tuple(
        Logical(
            x=x,
            y=y,
            scale=scale,
            transform=transform,
            primary=primary,
            connectors=tuple(spec[0] for spec in specs),
            mode_ids=tuple(current.get(spec[0], "") for spec in specs),
        )
        for x, y, scale, transform, primary, specs, _lprops in logicals
    )
    return State(
        serial=serial,
        layout_mode=props.get("layout-mode")
        if props.get("supports-changing-layout-mode")
        else None,
        modes=modes,
        logicals=parsed_logicals,
        current_mode=current,
    )


def pick_mode(modes: tuple[Mode, ...], width: int, height: int, fps: float, aspect: float) -> Mode:
    """Pick the mode that best serves a client of ``width`` x ``height``.

    ``aspect`` wins over everything: a wrong aspect ratio is either black bars
    or, with Moonlight set to stretch, distorted geometry, while a size
    mismatch only costs sharpness because Sunshine rescales the captured image.
    """

    def key(mode: Mode) -> tuple:
        return (
            round(abs(mode.aspect - aspect), 4),
            0 if (mode.width >= width and mode.height >= height) else 1,
            abs(mode.width * mode.height - width * height),
            1 if mode.variable_refresh else 0,
            -mode.refresh if fps <= 0 else abs(mode.refresh - fps),
        )

    return min(modes, key=key)


def pick_scale(mode: Mode, requested: str) -> float:
    """Resolve ``--scale``; ``auto`` keeps the desktop around 1200 logical rows."""
    if requested != "auto":
        wanted = float(requested)
        return min(mode.scales, key=lambda s: abs(s - wanted))
    integral = [s for s in mode.scales if math.isclose(s, round(s))] or list(mode.scales)
    return min(integral, key=lambda s: abs(mode.height / s - TARGET_LOGICAL_HEIGHT))


def logical_size(entry: Logical, mode: Mode, layout_mode: int | None) -> tuple[int, int]:
    width, height = mode.width, mode.height
    if entry.transform in (1, 3, 5, 7):
        width, height = height, width
    if layout_mode != 2:  # physical layout mode positions monitors in device pixels
        width, height = round(width / entry.scale), round(height / entry.scale)
    return width, height


def to_variant(state: State, entries: list[Logical]) -> GLib.Variant:
    props: dict[str, GLib.Variant] = {}
    if state.layout_mode is not None:
        props["layout-mode"] = GLib.Variant("u", state.layout_mode)
    payload = [
        (
            entry.x,
            entry.y,
            entry.scale,
            entry.transform,
            entry.primary,
            [
                (connector, mode_id, {})
                for connector, mode_id in zip(entry.connectors, entry.mode_ids)
            ],
        )
        for entry in entries
    ]
    return GLib.Variant(APPLY_TYPE, (state.serial, METHOD_TEMPORARY, payload, props))


def apply_config(bus: Gio.DBusProxy, state: State, entries: list[Logical]) -> None:
    bus.call_sync(
        "ApplyMonitorsConfig",
        to_variant(state, entries),
        Gio.DBusCallFlags.NO_AUTO_START,
        -1,
        None,
    )


def repack(state: State, entries: list[Logical]) -> list[Logical]:
    """Lay monitors out left to right so a resized monitor cannot overlap."""
    if len(entries) < 2:
        return [Logical(**{**entry.__dict__, "x": 0, "y": 0}) for entry in entries]
    packed: list[Logical] = []
    cursor = 0
    for entry in sorted(entries, key=lambda e: e.x):
        packed.append(Logical(**{**entry.__dict__, "x": cursor, "y": 0}))
        mode = next(m for m in state.modes[entry.connectors[0]] if m.id == entry.mode_ids[0])
        cursor += logical_size(entry, mode, state.layout_mode)[0]
    return packed


def state_path() -> Path:
    runtime = os.environ.get("XDG_RUNTIME_DIR") or f"/tmp/sunshine-display-{os.getuid()}"
    Path(runtime).mkdir(parents=True, exist_ok=True)
    return Path(runtime) / "sunshine-display.json"


def parse_aspect(spec: str) -> float:
    """Parse a ``W:H`` aspect ratio lock."""
    width, height = (int(part) for part in spec.split(":", 1))
    return width / height


def target_connector(state: State, requested: str | None) -> str:
    if requested:
        return requested
    for entry in state.logicals:
        if entry.primary and entry.connectors:
            return entry.connectors[0]
    return next(iter(state.modes))


def do_apply(args: argparse.Namespace) -> None:
    bus = proxy()
    state = read_state(bus)
    connector = target_connector(state, args.connector)
    width = int(os.environ.get("SUNSHINE_CLIENT_WIDTH") or 0) or args.width
    height = int(os.environ.get("SUNSHINE_CLIENT_HEIGHT") or 0) or args.height
    fps = float(os.environ.get("SUNSHINE_CLIENT_FPS") or 0)

    aspect = parse_aspect(args.aspect) if args.aspect else width / height
    requested = os.environ.get("SUNSHINE_CLIENT_WIDTH") is not None
    log(
        f"client {'requested' if requested else 'default'} "
        f"{width}x{height}@{fps:g}, aspect lock {aspect:.4f}"
    )
    mode = pick_mode(state.modes[connector], width, height, fps, aspect)
    scale = pick_scale(mode, args.scale)

    path = state_path()
    if not path.exists():
        path.write_text(
            json.dumps(
                {
                    "layout_mode": state.layout_mode,
                    "logicals": [entry.__dict__ for entry in state.logicals],
                }
            )
        )

    entries = [
        entry
        if connector not in entry.connectors
        else Logical(
            x=entry.x,
            y=entry.y,
            scale=scale,
            transform=TRANSFORM_NORMAL,
            primary=True,
            connectors=entry.connectors,
            mode_ids=tuple(
                mode.id if name == connector else current
                for name, current in zip(entry.connectors, entry.mode_ids)
            ),
        )
        for entry in state.logicals
    ]
    apply_config(bus, state, repack(state, entries))
    log(f"{connector} -> {mode.id} scale {scale}")


def do_revert(_args: argparse.Namespace) -> None:
    path = state_path()
    if not path.exists():
        log("nothing to revert")
        return
    saved = json.loads(path.read_text())
    bus = proxy()
    state = read_state(bus)
    entries = [
        Logical(
            x=entry["x"],
            y=entry["y"],
            scale=entry["scale"],
            transform=entry["transform"],
            primary=entry["primary"],
            connectors=tuple(entry["connectors"]),
            mode_ids=tuple(entry["mode_ids"]),
        )
        for entry in saved["logicals"]
    ]
    restored = State(
        serial=state.serial,
        layout_mode=saved["layout_mode"],
        modes=state.modes,
        logicals=state.logicals,
        current_mode=state.current_mode,
    )
    apply_config(bus, restored, entries)
    path.unlink()
    log("restored previous display configuration")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strict", action="store_true", help="exit non-zero on failure")
    sub = parser.add_subparsers(dest="command", required=True)

    apply_parser = sub.add_parser("apply", help="switch to the client's resolution")
    apply_parser.add_argument("--connector", help="output to reconfigure (default: primary)")
    apply_parser.add_argument("--width", type=int, default=3392, help="fallback client width")
    apply_parser.add_argument("--height", type=int, default=2400, help="fallback client height")
    apply_parser.add_argument("--scale", default="auto", help="'auto' or a scale factor")
    apply_parser.add_argument(
        "--aspect",
        help="lock the host aspect ratio, e.g. 106:75; default follows the client",
    )
    apply_parser.set_defaults(func=do_apply)

    revert_parser = sub.add_parser("revert", help="restore the previous configuration")
    revert_parser.set_defaults(func=do_revert)

    args = parser.parse_args()
    try:
        args.func(args)
    except (GLib.Error, OSError, ValueError, KeyError, StopIteration) as error:
        log(f"{args.command} failed: {error}")
        return 1 if args.strict else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
