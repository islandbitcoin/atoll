"""Verify the signed source builds staged for an Atoll import (read-only)."""
import json
import subprocess
from pathlib import Path


def registry_index(url):
    data = subprocess.check_output([
        "start-cli", "-r", url, "registry", "package", "index", "--format", "json"
    ])
    return json.loads(data)["packages"]


def main():
    plan = json.loads(Path(__file__).with_name("imports.json").read_text())
    indexes = {row["registry"]: None for row in plan}
    for url in indexes:
        indexes[url] = registry_index(url)
    for row in plan:
        package = row["package"]
        version = row["version"]
        release = indexes[row["registry"]][package]["versions"][version]
        archives = {}
        for hardware, asset in release["s9pks"]:
            if not asset["signatures"]:
                raise ValueError(f"Unsigned source build for {package} {version}")
            for arch in hardware["arch"]:
                if arch in archives:
                    raise ValueError(f"Ambiguous archive for {package} {version} {arch}")
                archives[arch] = asset["commitment"]
        if release["gitHash"] != row["commit"] or archives != row["archives"]:
            raise ValueError(f"Source build changed for {package} {version}")
        print(f"{package} {version} matches the reviewed source registry")


if __name__ == "__main__":
    main()
