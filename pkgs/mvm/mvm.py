"""Launch Claude Code (or a shell) inside a disposable munix microVM.

The current working directory is always mounted read-write. Additional
directories can be exposed with -rd (read-only) or -rw (read-write).
"""

import argparse
import os
import shlex
import subprocess
import sys
import tempfile

MUNIX = "@munix@"
MVM_LAUNCH = "@mvm_launch@"
GUEST_HOME = "/home/appvm"


def existing_dir(path):
    real = os.path.realpath(os.path.expanduser(path))
    if not os.path.isdir(real):
        raise argparse.ArgumentTypeError("not a directory: %s" % path)
    return real


def parse_args(argv):
    parser = argparse.ArgumentParser(
        prog="mvm",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=(
            "Run Claude Code inside a disposable munix microVM, isolated to the "
            "current directory.\n\n"
            "With no command, Claude is launched from a bash shell (Ctrl-Z drops "
            "you to that shell, fg resumes). Use 'mvm shell' for a debug shell. "
            "Any other arguments are passed through to claude."
        ),
        epilog="examples:\n"
        "  mvm                     run Claude in the current directory\n"
        "  mvm shell               open a debug shell in the VM\n"
        "  mvm -rw ~/data          also mount ~/data read-write\n"
        "  mvm -rd /etc/foo shell  shell with /etc/foo mounted read-only\n",
        allow_abbrev=False,
    )
    parser.add_argument(
        "-rd",
        "--ro-dir",
        metavar="DIR",
        action="append",
        default=[],
        dest="ro_dirs",
        type=existing_dir,
        help="mount DIR into the VM read-only (repeatable)",
    )
    parser.add_argument(
        "-rw",
        "--rw-dir",
        metavar="DIR",
        action="append",
        default=[],
        dest="rw_dirs",
        type=existing_dir,
        help="mount DIR into the VM read-write (repeatable)",
    )
    return parser.parse_known_args(argv)


def build_mounts(args, workdir, home):
    mounts = [
        "--no-gpu",
        "--no-wayland",
        "--no-pipewire",
        "--bind",
        workdir,
        workdir,
    ]

    # Claude login/config, read-write so token refreshes persist.
    for name in (".claude", ".claude.json"):
        src = os.path.join(home, name)
        if os.path.exists(src):
            mounts += ["--bind", src, "%s/%s" % (GUEST_HOME, name)]

    # Dev config, read-only.
    for name in (".gitconfig", ".config/git", ".ssh/known_hosts"):
        src = os.path.join(home, name)
        if os.path.exists(src):
            mounts += ["--ro-bind", src, "%s/%s" % (GUEST_HOME, name)]

    for path in args.ro_dirs:
        mounts += ["--ro-bind", path, path]
    for path in args.rw_dirs:
        mounts += ["--bind", path, path]

    # Share the host nix-daemon so nix works against the shared store.
    socket_dir = "/nix/var/nix/daemon-socket"
    if os.path.exists(os.path.join(socket_dir, "socket")):
        mounts += ["--bind", socket_dir, socket_dir]

    return mounts


def build_rc(mode, workdir, claude_args):
    lines = [
        "[ -r /etc/profile ] && . /etc/profile",
        "export HOME=%s" % GUEST_HOME,
        "cd %s" % shlex.quote(workdir),
    ]
    if mode == "shell":
        lines.append("exec zsh -l")
    else:
        run = "claude --dangerously-skip-permissions"
        if claude_args:
            run += " " + " ".join(shlex.quote(a) for a in claude_args)
        lines.append("mvm_run() { %s; }" % run)
        lines.append("source %s" % shlex.quote(MVM_LAUNCH))
    return "\n".join(lines) + "\n"


def main():
    args, rest = parse_args(sys.argv[1:])

    mode = "claude"
    claude_args = rest
    if rest and rest[0] == "shell":
        mode = "shell"
        claude_args = rest[1:]

    home = os.environ.get("HOME")
    if not home:
        sys.exit("mvm: HOME is not set")
    workdir = os.path.realpath(os.getcwd())

    mounts = build_mounts(args, workdir, home)

    fd, rc_path = tempfile.mkstemp(prefix="mvm-rc.")
    try:
        with os.fdopen(fd, "w") as handle:
            handle.write(build_rc(mode, workdir, claude_args))
        mounts += ["--ro-bind", rc_path, "%s/.mvm-rc" % GUEST_HOME]

        # Long options (--rcfile) must precede short options (-i) for bash.
        cmd = [MUNIX, *mounts, "--", "bash", "--rcfile", "%s/.mvm-rc" % GUEST_HOME, "-i"]
        return subprocess.run(cmd, check=False).returncode
    finally:
        os.unlink(rc_path)


if __name__ == "__main__":
    sys.exit(main())
