{
  writers,
  python3Packages,
}:

writers.writePython3Bin "sunshine-display" {
  libraries = [ python3Packages.pygobject3 ];
  flakeIgnore = [
    "E402" # gi.require_version has to run before the gi.repository import
    "E501"
  ];
} (builtins.readFile ./sunshine-display.py)
