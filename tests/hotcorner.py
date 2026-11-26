#!/usr/bin/env python3
"""Checks for the rice-hotcorner helpers that need no desktop: a file name taken twice in one second, and the
Hyprland config swap. Runs anywhere and in CI on every push."""
import importlib.machinery
import importlib.util
import os
import tempfile

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
loader = importlib.machinery.SourceFileLoader("hotcorner", os.path.join(root, "bin", "rice-hotcorner"))
spec = importlib.util.spec_from_loader("hotcorner", loader)
hc = importlib.util.module_from_spec(spec)
loader.exec_module(hc)

tmp = tempfile.mkdtemp()

# two shots in one second: the second name is kept, not written over the first
first = os.path.join(tmp, "Screenshot.png")
open(first, "w").close()
assert hc.unique(first) == os.path.join(tmp, "Screenshot-2.png")
open(os.path.join(tmp, "Screenshot-2.png"), "w").close()
assert hc.unique(first) == os.path.join(tmp, "Screenshot-3.png")
free = os.path.join(tmp, "other.png")
assert hc.unique(free) == free
print("ok 1 - a taken name gets -2, a free one is kept")

# the hot corner line goes and the config is swapped in, never cut short
h = os.path.join(tmp, "hyprland.lua")
with open(h, "w") as f:
    f.write('general { }\nrequire("rice-hotcorner")\nbind = "x"\n')
hc.HLUA = h
hc.BLUR_LUA = os.path.join(tmp, "rice-hotcorner.lua")
hc.q = lambda *a: None
hc.apply_blur()
with open(h) as f:
    text = f.read()
assert 'require("rice-hotcorner")' not in text
assert "bind = " in text and text.startswith("general")
assert not os.path.exists(h + ".tmp")
print("ok 2 - the config keeps the rest and leaves no .tmp")