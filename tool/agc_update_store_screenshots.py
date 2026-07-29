#!/usr/bin/env python3
"""Replace a numbered AppGallery screenshot for selected locales via AGC API."""

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path

import requests

scripts_root = os.environ.get("HARMONY_AGC_PUBLISH_SCRIPTS")
if not scripts_root:
    raise SystemExit(
        "Set HARMONY_AGC_PUBLISH_SCRIPTS to the harmony-agc-publish scripts directory."
    )
SKILL_SCRIPTS = Path(scripts_root)
sys.path.insert(0, str(SKILL_SCRIPTS))

from _agc_common import APP_FILE_INFO_URL, APP_INFO_URL, UPLOAD_URL_ENDPOINT, bootstrap


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def upload(path: Path, app_id: str, headers: dict) -> str:
    checksum = sha256(path)
    params = {
        "appId": app_id,
        "fileName": path.name,
        "sha256": checksum,
        "contentLength": str(path.stat().st_size),
        "fileType": "APP",
    }
    response = requests.get(UPLOAD_URL_ENDPOINT, params=params, headers=headers, timeout=30)
    response.raise_for_status()
    info = response.json().get("urlInfo") or {}
    object_id = info.get("objectId")
    if not info.get("url") or not object_id:
        raise RuntimeError("AGC did not return an upload URL and object ID")
    upload_headers = dict(info.get("headers") or {})
    upload_headers.setdefault("Content-Type", "image/png")
    upload_headers["Content-Length"] = str(path.stat().st_size)
    with path.open("rb") as file:
        response = requests.request(info.get("method", "PUT"), info["url"], data=file, headers=upload_headers, timeout=300)
    if response.status_code not in (200, 201, 204):
        raise RuntimeError(f"OBS upload failed: HTTP {response.status_code} {response.text[:400]}")

    response = requests.put(
        APP_FILE_INFO_URL,
        params={"appId": app_id},
        headers=headers,
        json={"objectId": object_id, "fileType": "APP", "files": [{"objectId": object_id, "fileName": path.name, "sha256": checksum, "contentLength": str(path.stat().st_size), "fileType": "APP"}]},
        timeout=30,
    )
    response.raise_for_status()
    result = response.json()
    if (result.get("ret") or {}).get("code") not in (None, 0):
        raise RuntimeError(f"AGC did not register the screenshot: {result.get('ret')}")
    return object_id


def object_url(object_id: str) -> str:
    # AGC resolves registered media by object ID when app-info is updated.
    return object_id


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("image", type=Path)
    parser.add_argument("project_root", type=Path)
    parser.add_argument("--index", type=int, default=3, help="zero-based screenshot position")
    parser.add_argument("--langs", nargs="+", default=["en-US", "ja-JP"])
    args = parser.parse_args()
    image = args.image.resolve()
    if not image.is_file() or image.suffix.lower() != ".png":
        raise SystemExit("Image must be an existing PNG file")

    app_id, _client_id, _secret, _token, headers = bootstrap(str(args.project_root.resolve()))
    object_id = upload(image, app_id, headers)
    response = requests.get(APP_INFO_URL, params={"appId": app_id, "lang": "zh-CN"}, headers=headers, timeout=30)
    response.raise_for_status()
    app_info = response.json().get("appInfo")
    if not app_info:
        raise RuntimeError("AGC app-info response has no appInfo")

    changed = []
    for language in app_info.get("languages") or []:
        if language.get("lang") not in args.langs:
            continue
        materials = language.get("deviceMaterials") or []
        if not materials or len(materials[0].get("screenShots") or []) <= args.index:
            raise RuntimeError(f"{language.get('lang')} does not have screenshot index {args.index}")
        materials[0]["screenShots"][args.index] = object_url(object_id)
        changed.append(language.get("lang"))
    if set(changed) != set(args.langs):
        raise RuntimeError(f"Requested locales not updated: {args.langs}; changed: {changed}")

    response = requests.put(APP_INFO_URL, params={"appId": app_id}, headers=headers, json=app_info, timeout=30)
    response.raise_for_status()
    result = response.json()
    if (result.get("ret") or {}).get("code") not in (None, 0):
        raise RuntimeError(f"AGC app-info update failed: {result.get('ret')}")
    print(json.dumps({"updatedLanguages": changed, "screenshotIndex": args.index, "objectId": object_id}, ensure_ascii=False))


if __name__ == "__main__":
    main()
