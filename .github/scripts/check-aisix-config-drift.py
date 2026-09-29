#!/usr/bin/env python3
"""Fail when charts/aisix's `config:` block drifts from the gateway.

The gateway publishes config.reference.json — every startup-config key with
its default — at the root of api7/aisix. This compares it, at the tag of the
chart's appVersion, with the chart's `config:` block: the same keys, with the
same defaults, except the keys charts/aisix/config-policy.yaml names as set by
the chart or held in Secrets.

A release that predates config.reference.json has no tag copy; the check then
falls back to api7/aisix main and says so. CONFIG_REFERENCE_FILE points the
check at a local copy instead, for testing a gateway change before it merges.
"""
import json
import os
import sys
import urllib.error
import urllib.request

import yaml

CHART = "charts/aisix"
RAW = "https://raw.githubusercontent.com/api7/aisix/{ref}/config.reference.json"


def fetch(ref):
    try:
        with urllib.request.urlopen(RAW.format(ref=ref), timeout=30) as resp:
            return json.load(resp)
    except urllib.error.HTTPError as err:
        if err.code == 404:
            return None
        raise


def flatten(node, prefix=""):
    out = {}
    if isinstance(node, dict) and node:
        for key, value in node.items():
            out.update(flatten(value, f"{prefix}{key}."))
    else:
        out[prefix[:-1]] = node
    return out


def excluded(path, prefixes):
    return any(path == p or path.startswith(p + ".") for p in prefixes)


def main():
    with open(f"{CHART}/Chart.yaml") as f:
        app_version = yaml.safe_load(f)["appVersion"]
    with open(f"{CHART}/values.yaml") as f:
        chart_config = yaml.safe_load(f)["config"]
    with open(f"{CHART}/config-policy.yaml") as f:
        policy = yaml.safe_load(f)

    ref = f"v{app_version}"
    local = os.environ.get("CONFIG_REFERENCE_FILE")
    if local:
        ref = local
        with open(local) as f:
            reference = json.load(f)
    else:
        reference = fetch(ref)
    if reference is None:
        print(f"note: api7/aisix {ref} has no config.reference.json; comparing against main")
        ref = "main"
        reference = fetch(ref)
        if reference is None:
            sys.exit("api7/aisix main has no config.reference.json")

    skip = list(policy["owned"]) + list(policy["secrets"])
    want = {k: v for k, v in flatten(reference).items() if not excluded(k, skip)}
    have = flatten(chart_config)

    problems = []
    for path in sorted(want.keys() - have.keys()):
        problems.append(f"missing from config: {path} (gateway default {json.dumps(want[path])})")
    for path in sorted(have.keys() - want.keys()):
        problems.append(f"not a gateway setting at {ref}: {path}")
    for path in sorted(want.keys() & have.keys()):
        if want[path] != have[path]:
            problems.append(
                f"default differs: {path} is {json.dumps(have[path])} in values.yaml, "
                f"{json.dumps(want[path])} in the gateway"
            )

    if problems:
        print(f"charts/aisix config: drifted from api7/aisix {ref} config.reference.json:")
        for line in problems:
            print(f"  {line}")
        print("Mirror the gateway in values.yaml `config:`, or name the key in config-policy.yaml.")
        sys.exit(1)
    print(f"charts/aisix config: matches api7/aisix {ref} ({len(want)} keys)")


if __name__ == "__main__":
    main()
