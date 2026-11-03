#!/usr/bin/env python3
"""Mirror Flutter debug-engine artifacts into a local Maven repository.

Why: on networks where storage.googleapis.com is reachable by curl but stalls
inside the JVM, `flutter build apk` waits minutes and then fails to download
`io.flutter:<abi>_debug`. The Flutter SDK already ships the exact same engine
libraries in `bin/cache/artifacts/engine/android-<abi>/flutter.jar`, so this
script repackages them as Maven artifacts that Gradle can resolve offline.

Usage:
    python android/tools/mirror_flutter_engine.py --abls arm64
    python android/tools/mirror_flutter_engine.py            # arm64, arm, x64

The generated files live in android/local_maven/ and are git-ignored. Any
machine without the mirror simply falls back to the official host.
"""

from __future__ import annotations

import argparse
import os
import sys
import zipfile
from pathlib import Path

ABIS = {
    "arm64": ("arm64_v8a_debug", "android-arm64", "lib/arm64-v8a/libflutter.so"),
    "arm": ("armeabi_v7a_debug", "android-arm", "lib/armeabi-v7a/libflutter.so"),
    "x64": ("x86_64_debug", "android-x64", "lib/x86_64/libflutter.so"),
}

POM = """<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>io.flutter</groupId>
  <artifactId>{artifact}</artifactId>
  <version>{version}</version>
  <packaging>jar</packaging>
  <description>Flutter debug engine mirrored from the local SDK cache.</description>
</project>
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--flutter-root", default=os.environ.get("FLUTTER_ROOT", "C:/flutter"))
    parser.add_argument("--abis", nargs="+", default=list(ABIS), choices=list(ABIS))
    args = parser.parse_args()

    flutter = Path(args.flutter_root)
    stamp = flutter / "bin/cache/engine.stamp"
    if not stamp.exists():
        raise SystemExit(f"{stamp} not found — pass --flutter-root")
    engine = stamp.read_text(encoding="utf-8").strip()
    version = f"1.0.0-{engine}"
    out_root = Path(__file__).resolve().parent.parent / "local_maven"

    for abi in args.abis:
        artifact, engine_dir, lib_path = ABIS[abi]
        source = flutter / "bin/cache/artifacts/engine" / engine_dir / "flutter.jar"
        if not source.exists():
            print(f"skip {abi}: {source} missing (run `flutter precache --android`)")
            continue
        dest = out_root / "io/flutter" / artifact / version
        dest.mkdir(parents=True, exist_ok=True)
        jar = dest / f"{artifact}-{version}.jar"
        print(f"mirroring {abi} …")
        with zipfile.ZipFile(source) as zin, \
                zipfile.ZipFile(jar, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as zout:
            with zin.open(lib_path) as f:
                zout.writestr(lib_path, f.read(),
                              compress_type=zipfile.ZIP_DEFLATED, compresslevel=6)
        (dest / f"{artifact}-{version}.pom").write_text(
            POM.format(artifact=artifact, version=version), encoding="utf-8")
        print(f"  {jar} ({jar.stat().st_size / 1e6:.0f} MB)")

    print("done — android/build.gradle.kts resolves local_maven first")
    sys.exit(0)


if __name__ == "__main__":
    main()
