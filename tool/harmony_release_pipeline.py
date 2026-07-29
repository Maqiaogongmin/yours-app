#!/usr/bin/env python3
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parents[1]
OHOS = ROOT / "ohos"
ARTIFACTS = Path(
    os.environ.get(
        "YOURS_HARMONY_ARTIFACTS",
        str(ROOT / ".harmony-release-artifacts"),
    )
)
FLUTTER_OH = Path(
    os.environ.get(
        "FLUTTER_OH_HOME",
        str(Path.home() / "Developer/flutter-oh/flutter_oh_3_41_9"),
    )
) / "bin"
DEVECO_SDK = Path(
    os.environ.get("DEVECO_SDK_HOME", "/Applications/DevEco-Studio.app/Contents/sdk")
)
SIGN_ENV = Path(
    os.environ.get(
        "YOURS_HARMONY_SIGN_ENV",
        str(Path.home() / ".config/yours/harmonyos-release.env"),
    )
)
SIGN_ROOT = Path(
    os.environ.get(
        "YOURS_HARMONY_SIGN_ROOT",
        str(Path.home() / ".config/yours/harmonyos-signing"),
    )
)


def run(args: list[str], cwd: Path, env: Optional[dict[str, str]] = None) -> None:
    print(f"$ {' '.join(args)}")
    merged_env = os.environ.copy()
    if env:
        merged_env.update(env)
    subprocess.run(args, cwd=cwd, env=merged_env, check=True)


def output(args: list[str], cwd: Path) -> str:
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def read_version() -> tuple[str, str]:
    pubspec = (ROOT / "pubspec.yaml").read_text()
    match = re.search(r"^version:\s*([0-9A-Za-z.\-]+)\+([0-9]+)\s*$", pubspec, re.M)
    if not match:
        raise SystemExit("Cannot parse pubspec.yaml version.")
    return match.group(1), match.group(2)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def ensure_clean_tree(allow_dirty: bool) -> None:
    status = output(["git", "status", "--short"], ROOT)
    if status and not allow_dirty:
        raise SystemExit(
            "Git worktree is dirty. Commit or stash first, or rerun with --allow-dirty."
        )


def harmony_env() -> dict[str, str]:
    return {
        "FLUTTER_GIT_URL": "https://atomgit.com/openharmony-tpc/flutter_flutter.git",
        "PATH": f"{FLUTTER_OH}:{os.environ.get('PATH', '')}",
        "DEVECO_SDK_HOME": str(DEVECO_SDK),
        "PUB_CACHE": str(ROOT / ".dart_tool/pub-cache-ohos"),
    }


def read_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        values[key] = value
    return values


def signing_config_text() -> str:
    values = read_env_file(SIGN_ENV)
    return f'''"signingConfigs": [
      {{
        "name": "default",
        "type": "HarmonyOS",
        "material": {{
          "storeFile": "{SIGN_ROOT / 'yours-release.p12'}",
          "storePassword": "{values['STORE_PASSWORD_ENC']}",
          "keyAlias": "{values['KEY_ALIAS']}",
          "keyPassword": "{values['KEY_PASSWORD_ENC']}",
          "signAlg": "SHA256withECDSA",
          "profile": "{SIGN_ROOT / 'yours-release.p7b'}",
          "certpath": "{SIGN_ROOT / 'yours-release.cer'}"
        }}
      }}
    ]'''


def inject_release_signing() -> str:
    profile = OHOS / "build-profile.json5"
    original = profile.read_text()
    if '"signingConfigs": []' not in original:
        raise SystemExit(
            "ohos/build-profile.json5 signingConfigs is not empty; refusing to overwrite it."
        )
    profile.write_text(original.replace('"signingConfigs": []', signing_config_text()))
    return original


def restore_build_profile(original: str) -> None:
    (OHOS / "build-profile.json5").write_text(original)


def snapshot_file(path: Path) -> Optional[bytes]:
    if not path.exists():
        return None
    return path.read_bytes()


def restore_file(path: Path, snapshot: Optional[bytes]) -> None:
    if snapshot is None:
        if path.exists():
            path.unlink()
        return
    path.write_bytes(snapshot)


def build_release_app(skip_build: bool) -> Path:
    if not skip_build:
        env = harmony_env()
        pubspec_lock = ROOT / "pubspec.lock"
        pubspec_lock_snapshot = snapshot_file(pubspec_lock)
        try:
            run(["make", "harmony-flutter-pub-get"], ROOT, env)
            run(["make", "harmony-flutter-patch-deps"], ROOT, env)
            original_profile = inject_release_signing()
            try:
                run(
                    [
                        "flutter",
                        "build",
                        "app",
                        "--release",
                        "--build-name",
                        read_version()[0],
                        "--build-number",
                        read_version()[1],
                    ],
                    ROOT,
                    env,
                )
            finally:
                restore_build_profile(original_profile)
        finally:
            restore_file(pubspec_lock, pubspec_lock_snapshot)

    app = OHOS / "build/outputs/default/ohos-default-signed.app"
    if not app.exists():
        raise SystemExit(f"Signed APP was not produced: {app}")
    return app


def archive(app: Path, note: str) -> Path:
    version_name, version_code = read_version()
    git_sha = output(["git", "rev-parse", "--short", "HEAD"], ROOT)
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    release_dir = ARTIFACTS / "releases" / f"{version_name}+{version_code}" / timestamp
    release_dir.mkdir(parents=True, exist_ok=True)

    final_name = f"yours-harmonyos-{version_name}-{version_code}-{git_sha}-release.app"
    final_app = release_dir / final_name
    shutil.copy2(app, final_app)
    app_hash = sha256(final_app)
    (final_app.with_suffix(final_app.suffix + ".sha256")).write_text(
        f"{app_hash}  {final_app.name}\n"
    )

    metadata = {
        "platform": "HarmonyOS",
        "artifactType": "APP",
        "versionName": version_name,
        "versionCode": int(version_code),
        "gitSha": git_sha,
        "sourceRoot": str(ROOT),
        "sourceApp": str(app),
        "artifact": str(final_app),
        "sha256": app_hash,
        "builtAt": time.strftime("%Y-%m-%d %H:%M:%S %z"),
        "note": note,
        "agcAction": "none",
    }
    (release_dir / "metadata.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2)
    )
    latest = ARTIFACTS / "LATEST_LOCAL_RELEASE.json"
    latest.write_text(json.dumps(metadata, ensure_ascii=False, indent=2))
    print(f"Archived release APP: {final_app}")
    print(f"SHA-256: {app_hash}")
    return final_app


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Build and archive the HarmonyOS release APP. Does not upload to AGC."
    )
    parser.add_argument("--allow-dirty", action="store_true")
    parser.add_argument("--skip-build", action="store_true")
    parser.add_argument("--note", default="")
    args = parser.parse_args()

    ensure_clean_tree(args.allow_dirty)
    app = build_release_app(args.skip_build)
    archive(app, args.note)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
