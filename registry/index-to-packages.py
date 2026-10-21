#!/usr/bin/env python3
"""Transform `start-cli registry package index` (stdin JSON) into docs/packages.json.

Usage: start-cli ... registry package index | UMBREL_IDS="id1 id2" index-to-packages.py <out.json>
"""
import json, os, re, sys

def version_key(value):
    """StartOS numeric version, SemVer prerelease, then package revision."""
    match = re.fullmatch(r'(\d+(?:\.\d+)*)(?:-([A-Za-z0-9.-]+))?:(\d+)', value)
    if not match:
        raise ValueError('invalid registry version: ' + value)
    core = tuple(map(int, match[1].split('.')))
    core += (0,) * max(0, 3 - len(core))
    pre = tuple((0, int(part)) if part.isdigit() else (1, part)
                for part in (match[2] or '').split('.'))
    return core, match[2] is None, pre, int(match[3])


raw = sys.stdin.read()
i = raw.find("{")
if i < 0:
    sys.exit("could not read registry index (empty/unsigned?)")
d = json.loads(raw[i:])

cat_names = {k: (v.get("name") or k) for k, v in d.get("categories", {}).items()}
umbrel = set(os.environ.get("UMBREL_IDS", "").split())

pkgs = []
for pid, p in d.get("packages", {}).items():
    versions = p.get("versions", {})
    if not versions:
        continue
    ver = max(versions, key=version_key)
    v = versions[ver]
    short = (v.get("description", {}) or {}).get("short", {}) or {}
    pkgs.append({
        "id": pid,
        "name": v.get("title", pid),
        "description": short.get("en_US", ""),
        "version": ver,
        "categories": p.get("categories", []),
        "icon": v.get("icon"),
        "site": v.get("marketingUrl"),                            # landing page (null -> page falls back to README)
        "source": v.get("packageRepo") or v.get("upstreamRepo"),  # repo / README
        "platforms": ["start9"] + (["umbrel"] if pid in umbrel else []),
    })

pkgs.sort(key=lambda x: x["name"].lower())
out = {"categories": cat_names, "packages": pkgs}
with open(sys.argv[1], "w") as f:
    f.write(json.dumps(out, indent=2) + "\n")
print(f"==> wrote {len(pkgs)} packages to {sys.argv[1]}")
