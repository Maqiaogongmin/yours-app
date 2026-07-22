#!/usr/bin/env python3

"""Remove debug-only plugins from Flutter's generated release registrant."""

from pathlib import Path


REGISTRANT = Path(
    "android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
)
DEBUG_ONLY_PLUGINS = ("dev.flutter.plugins.integration_test.IntegrationTestPlugin",)


def main() -> None:
    if not REGISTRANT.exists():
        raise SystemExit(
            f"Missing {REGISTRANT}; run `flutter pub get` before preparing a release."
        )

    lines = REGISTRANT.read_text(encoding="utf-8").splitlines(keepends=True)
    output: list[str] = []
    index = 0
    removed = 0

    while index < len(lines):
        if lines[index].strip() != "try {":
            output.append(lines[index])
            index += 1
            continue

        block = [lines[index]]
        index += 1
        while index < len(lines):
            block.append(lines[index])
            index += 1
            if block[-1] == "    }\n":
                break

        if any(plugin in line for plugin in DEBUG_ONLY_PLUGINS for line in block):
            removed += 1
        else:
            output.extend(block)

    REGISTRANT.write_text("".join(output), encoding="utf-8")
    print(f"Prepared Android release registrant; removed {removed} debug-only plugin(s).")


if __name__ == "__main__":
    main()
