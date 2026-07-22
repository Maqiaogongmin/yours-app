#!/usr/bin/env python3
"""Tap the center of an Android UI node by one of its semantic labels."""

from __future__ import annotations

import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: android_tap_semantics.py SERIAL LABEL [LABEL ...]", file=sys.stderr)
        return 64
    serial, *labels = sys.argv[1:]
    for attempt in range(15):
        subprocess.run(
            ["adb", "-s", serial, "shell", "uiautomator", "dump", "/sdcard/yours-window.xml"],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        xml = subprocess.check_output(
            ["adb", "-s", serial, "exec-out", "cat", "/sdcard/yours-window.xml"]
        )
        root = ET.fromstring(xml)
        for node in root.iter("node"):
            description = node.attrib.get("content-desc", "")
            text = node.attrib.get("text", "")
            if description not in labels and text not in labels:
                continue
            match = re.fullmatch(
                r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", node.attrib["bounds"]
            )
            if match is None:
                continue
            left, top, right, bottom = map(int, match.groups())
            subprocess.run(
                [
                    "adb",
                    "-s",
                    serial,
                    "shell",
                    "input",
                    "tap",
                    str((left + right) // 2),
                    str((top + bottom) // 2),
                ],
                check=True,
            )
            return 0
        if attempt < 14:
            time.sleep(1)
    print(f"none of the labels are visible: {', '.join(labels)}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
