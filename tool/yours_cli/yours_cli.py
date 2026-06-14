#!/usr/bin/env python3
"""Local-first CLI for Yours.

This tool is intentionally conservative: it validates JSON plans, checks the
custom exercise library, and only writes to the local SQLite database after the
plan is structurally safe.
"""

from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
import time
from pathlib import Path
from typing import Any


APP_DB_NAME = "local_training.sqlite"
EXERCISE_DB_NAME = "custom_exercises.sqlite"
SYNC_PENDING = "pending"
VAULT_FORMAT = "yours-vault"
PLAN_FORMAT = "yours-plan"
EXERCISE_FORMAT = "yours-exercise"


class CliError(Exception):
    def __init__(self, message: str, *, code: str = "error", details: Any = None):
        super().__init__(message)
        self.message = message
        self.code = code
        self.details = details


def normalize_key(value: str) -> str:
    return " ".join(
        "".join(ch.lower() if ch.isalnum() else " " for ch in value.strip()).split()
    )


def now_ts() -> int:
    return int(time.time())


def latest_file_named(name: str) -> Path | None:
    roots = [
        Path.home() / "Library/Developer/CoreSimulator/Devices",
        Path.cwd(),
    ]
    matches: list[Path] = []
    for root in roots:
        if root.exists():
            matches.extend(root.rglob(name))
    if not matches:
        return None
    return max(matches, key=lambda path: path.stat().st_mtime)


def resolve_db_path(explicit: str | None, name: str) -> Path:
    if explicit:
        path = Path(explicit).expanduser()
        if not path.exists():
            raise CliError(f"数据库不存在：{path}", code="db_not_found")
        return path

    env_name = "YOURS_LOCAL_DB" if name == APP_DB_NAME else "YOURS_EXERCISE_DB"
    env_value = os.environ.get(env_name)
    if env_value:
        path = Path(env_value).expanduser()
        if not path.exists():
            raise CliError(f"{env_name} 指向的数据库不存在：{path}", code="db_not_found")
        return path

    path = latest_file_named(name)
    if path is None:
        raise CliError(f"没有找到 {name}。请先启动模拟器 App，或用 --db 指定路径。", code="db_not_found")
    return path


def connect(path: Path) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    return conn


def emit(data: Any, *, as_json: bool) -> None:
    if as_json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
        return
    if isinstance(data, str):
        print(data)
        return
    print(json.dumps(data, ensure_ascii=False, indent=2))


def load_plan(path: str) -> dict[str, Any]:
    try:
        with Path(path).expanduser().open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except FileNotFoundError as exc:
        raise CliError(f"计划文件不存在：{path}", code="file_not_found") from exc
    except json.JSONDecodeError as exc:
        raise CliError(f"计划 JSON 格式错误：{exc}", code="invalid_json") from exc
    if not isinstance(data, dict):
        raise CliError("计划文件顶层必须是 JSON object。", code="invalid_plan")
    return data


def load_json_object(path: str, label: str) -> dict[str, Any]:
    try:
        with Path(path).expanduser().open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except FileNotFoundError as exc:
        raise CliError(f"{label} 文件不存在：{path}", code="file_not_found") from exc
    except json.JSONDecodeError as exc:
        raise CliError(f"{label} JSON 格式错误：{exc}", code="invalid_json") from exc
    if not isinstance(data, dict):
        raise CliError(f"{label} 顶层必须是 JSON object。", code="invalid_json")
    return data


def parse_positive_int(value: Any, field: str, *, default: int | None = None) -> int:
    if value is None and default is not None:
        return default
    if isinstance(value, bool):
        raise CliError(f"{field} 必须是正整数。", code="invalid_plan")
    try:
        parsed = int(value)
    except (TypeError, ValueError) as exc:
        raise CliError(f"{field} 必须是正整数。", code="invalid_plan") from exc
    if parsed <= 0:
        raise CliError(f"{field} 必须大于 0。", code="invalid_plan")
    return parsed


def parse_optional_float(value: Any, field: str) -> float | None:
    if value in (None, ""):
        return None
    try:
        return float(value)
    except (TypeError, ValueError) as exc:
        raise CliError(f"{field} 必须是数字。", code="invalid_plan") from exc


def parse_reps_with_note(value: Any, field: str) -> tuple[int, str | None]:
    if isinstance(value, str):
        stripped = value.strip()
        if "-" in stripped or "～" in stripped or "~" in stripped:
            normalized = stripped.replace("～", "-").replace("~", "-")
            first = normalized.split("-", 1)[0].strip()
            return parse_positive_int(first, field), f"次数范围：{stripped}"
    return parse_positive_int(value, field, default=8), None


def parse_optional_int(value: Any, field: str) -> int | None:
    if value in (None, ""):
        return None
    if isinstance(value, bool):
        raise CliError(f"{field} 必须是整数。", code="invalid_plan")
    try:
        return int(value)
    except (TypeError, ValueError) as exc:
        raise CliError(f"{field} 必须是整数。", code="invalid_plan") from exc


def action_note(action_data: dict[str, Any], reps_note: str | None) -> str:
    parts: list[str] = []
    if reps_note:
        parts.append(reps_note)

    for key in ("rir", "RIR"):
        if action_data.get(key) not in (None, ""):
            parts.append(f"RIR：{action_data[key]}")
            break

    raw_note = action_data.get("note") or action_data.get("notes") or action_data.get("备注")
    if raw_note not in (None, ""):
        parts.append(f"备注：{str(raw_note).strip()}")

    return "；".join(parts)


def normalize_plan(data: dict[str, Any]) -> dict[str, Any]:
    name = str(data.get("name", "")).strip()
    if not name:
        raise CliError("计划缺少 name。", code="invalid_plan")
    weeks = data.get("weeks")
    if not isinstance(weeks, list) or not weeks:
        raise CliError("计划缺少 weeks，或 weeks 不是数组。", code="invalid_plan")

    normalized_weeks: list[dict[str, Any]] = []
    for week_index, week_data in enumerate(weeks, start=1):
        if not isinstance(week_data, dict):
            raise CliError(f"第 {week_index} 个 week 必须是 object。", code="invalid_plan")
        week = parse_positive_int(week_data.get("week"), f"weeks[{week_index}].week", default=week_index)
        days = week_data.get("days")
        if not isinstance(days, list) or not days:
            raise CliError(f"第 {week} 周缺少 days。", code="invalid_plan")

        normalized_days: list[dict[str, Any]] = []
        for day_index, day_data in enumerate(days, start=1):
            if not isinstance(day_data, dict):
                raise CliError(f"第 {week} 周第 {day_index} 个 day 必须是 object。", code="invalid_plan")
            day = parse_positive_int(day_data.get("day"), f"week {week} day", default=day_index)
            day_name = str(day_data.get("name") or f"D{day}").strip()
            actions = day_data.get("actions", [])
            if not isinstance(actions, list):
                raise CliError(f"第 {week} 周 D{day} 的 actions 必须是数组。", code="invalid_plan")

            normalized_actions: list[dict[str, Any]] = []
            for action_index, action_data in enumerate(actions, start=1):
                if not isinstance(action_data, dict):
                    raise CliError(
                        f"第 {week} 周 D{day} 第 {action_index} 个动作必须是 object。",
                        code="invalid_plan",
                    )
                exercise = str(action_data.get("exercise") or action_data.get("name") or "").strip()
                if not exercise:
                    raise CliError(
                        f"第 {week} 周 D{day} 第 {action_index} 个动作缺少 exercise。",
                        code="invalid_plan",
                    )
                sets = parse_positive_int(action_data.get("sets"), f"{exercise}.sets", default=3)
                reps, reps_note = parse_reps_with_note(action_data.get("reps"), f"{exercise}.reps")
                weight = parse_optional_float(action_data.get("weight"), f"{exercise}.weight")
                rest_seconds = parse_optional_int(
                    action_data.get("restSeconds")
                    or action_data.get("rest_seconds")
                    or action_data.get("rest")
                    or action_data.get("休息"),
                    f"{exercise}.restSeconds",
                )
                note = action_note(action_data, reps_note)
                normalized_actions.append(
                    {
                        "exercise": exercise,
                        "sets": sets,
                        "reps": reps,
                        "weight": weight,
                        "restSeconds": rest_seconds,
                        "note": note,
                    }
                )

            normalized_days.append(
                {
                    "day": day,
                    "name": day_name,
                    "actions": normalized_actions,
                }
            )

        normalized_weeks.append({"week": week, "days": normalized_days})

    total_weeks = (
        parse_positive_int(data.get("totalWeeks"), "totalWeeks")
        if data.get("totalWeeks") is not None
        else max(week["week"] for week in normalized_weeks)
    )
    days_per_week = (
        parse_positive_int(data.get("daysPerWeek"), "daysPerWeek")
        if data.get("daysPerWeek") is not None
        else max(day["day"] for week in normalized_weeks for day in week["days"])
    )

    return {
        "name": name,
        "totalWeeks": total_weeks,
        "daysPerWeek": days_per_week,
        "weeks": normalized_weeks,
    }


def exercise_keys(exercise_db: Path) -> set[str]:
    with connect(exercise_db) as conn:
        rows = conn.execute(
            """
            select chinese_name, english_name
            from custom_exercises
            where deleted = 0
            """
        ).fetchall()
    keys: set[str] = set()
    for row in rows:
        for value in (row["chinese_name"], row["english_name"]):
            if value:
                keys.add(normalize_key(value))
    return keys


def missing_exercises(plan: dict[str, Any], exercise_db: Path) -> list[str]:
    known = exercise_keys(exercise_db)
    missing: list[str] = []
    seen: set[str] = set()
    for week in plan["weeks"]:
        for day in week["days"]:
            for action in day["actions"]:
                exercise = action["exercise"]
                key = normalize_key(exercise)
                if key not in known and key not in seen:
                    missing.append(exercise)
                    seen.add(key)
    return missing


def normalize_exercise_operations(data: dict[str, Any]) -> list[dict[str, Any]]:
    raw_items = data.get("exercises")
    if raw_items is None:
        raw_items = [data]
    if not isinstance(raw_items, list):
        raise CliError("动作 JSON 的 exercises 必须是数组。", code="invalid_exercise")

    operations: list[dict[str, Any]] = []
    for index, item in enumerate(raw_items, start=1):
        if not isinstance(item, dict):
            raise CliError(f"第 {index} 个动作必须是 object。", code="invalid_exercise")
        action = str(item.get("action") or "upsert").strip().lower()
        if action not in {"upsert", "delete"}:
            raise CliError(f"第 {index} 个动作 action 只支持 upsert/delete。", code="invalid_exercise")
        name = str(item.get("chineseName") or item.get("name") or "").strip()
        match_name = str(item.get("matchName") or item.get("oldName") or "").strip()
        english_name = str(item.get("englishName") or "").strip()
        if action == "delete" and not any([item.get("id"), name, match_name, english_name]):
            raise CliError(f"第 {index} 个删除动作缺少 id/name/matchName。", code="invalid_exercise")
        if action == "upsert" and not name:
            raise CliError(f"第 {index} 个动作缺少 name。", code="invalid_exercise")
        operations.append(
            {
                "id": int(item["id"]) if item.get("id") not in (None, "") else None,
                "action": action,
                "matchName": match_name,
                "chineseName": name,
                "englishName": english_name,
                "category1": str(item.get("category1") or item.get("bodyPart") or "").strip(),
                "category2": str(item.get("category2") or item.get("equipment") or "").strip(),
                "primaryMuscles": str(item.get("primaryMuscles") or "").strip(),
                "description": str(item.get("description") or "").strip(),
                "imagePaths": item.get("imagePaths") if isinstance(item.get("imagePaths"), list) else [],
            }
        )
    return operations


def exercise_summary(operations: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "operations": len(operations),
        "upserts": len([item for item in operations if item["action"] == "upsert"]),
        "deletes": len([item for item in operations if item["action"] == "delete"]),
        "names": [
            item.get("chineseName") or item.get("matchName") or str(item.get("id"))
            for item in operations
        ],
    }


def plan_summary(plan: dict[str, Any]) -> dict[str, Any]:
    days = sum(len(week["days"]) for week in plan["weeks"])
    actions = sum(len(day["actions"]) for week in plan["weeks"] for day in week["days"])
    sets = sum(
        action["sets"]
        for week in plan["weeks"]
        for day in week["days"]
        for action in day["actions"]
    )
    return {
        "name": plan["name"],
        "weeks": len(plan["weeks"]),
        "days": days,
        "actions": actions,
        "targetSets": sets,
    }


def slugify(value: str, *, fallback: str = "untitled") -> str:
    chars: list[str] = []
    previous_dash = False
    for ch in value.strip().lower():
        if ch.isalnum() or "\u4e00" <= ch <= "\u9fff":
            chars.append(ch)
            previous_dash = False
        elif not previous_dash:
            chars.append("-")
            previous_dash = True
    slug = "".join(chars).strip("-")
    return slug or fallback


def iso_from_db_time(value: Any) -> str | None:
    if value in (None, ""):
        return None
    try:
        number = float(value)
    except (TypeError, ValueError):
        return str(value)
    if number > 10_000_000_000:
        number = number / 1000
    return time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime(number))


def safe_json_loads(value: str, fallback: Any) -> Any:
    try:
        return json.loads(value)
    except (TypeError, json.JSONDecodeError):
        return fallback


def plan_from_db(conn: sqlite3.Connection, routine: sqlite3.Row) -> dict[str, Any]:
    days = conn.execute(
        """
        select id, week, day, name, actions_json
        from local_training_days
        where routine_id = ?
        order by week, day
        """,
        (routine["id"],),
    ).fetchall()
    slot_rows = conn.execute(
        """
        select d.id as day_id, s."order" as action_order, e.exercise_name,
               e.target_sets, e.target_reps, e.target_weight
        from local_training_days d
        join local_slots s on s.day_id = d.id
        join local_slot_entries e on e.slot_id = s.id
        where d.routine_id = ?
        order by d.week, d.day, s."order"
        """,
        (routine["id"],),
    ).fetchall()
    slot_targets: dict[tuple[int, int], sqlite3.Row] = {
        (int(row["day_id"]), int(row["action_order"])): row for row in slot_rows
    }
    weeks: dict[int, list[dict[str, Any]]] = {}
    for day in days:
        actions = safe_json_loads(day["actions_json"], [])
        normalized_actions: list[dict[str, Any]] = []
        for index, action in enumerate(actions if isinstance(actions, list) else []):
            if isinstance(action, str):
                action_data: dict[str, Any] = {"name": action}
            elif isinstance(action, dict):
                action_data = dict(action)
            else:
                continue
            slot = slot_targets.get((int(day["id"]), index))
            exercise = slot["exercise_name"] if slot else action_data.get("name", "未命名动作")
            normalized_actions.append(
                {
                    "exercise": exercise,
                    "sets": int(slot["target_sets"] if slot else action_data.get("targetSets", 3)),
                    "reps": int(slot["target_reps"] if slot else action_data.get("targetReps", 8)),
                    "weight": (
                        float(slot["target_weight"])
                        if slot and slot["target_weight"] is not None
                        else action_data.get("targetWeight")
                    ),
                    "restSeconds": action_data.get("targetRestSeconds"),
                    "note": action_data.get("note", ""),
                }
            )
        weeks.setdefault(int(day["week"]), []).append(
            {
                "id": day["id"],
                "day": day["day"],
                "name": day["name"],
                "actions": normalized_actions,
            }
        )
    return {
        "format": PLAN_FORMAT,
        "formatVersion": 1,
        "id": routine["id"],
        "name": routine["name"],
        "totalWeeks": routine["total_weeks"],
        "daysPerWeek": routine["days_per_week"],
        "syncStatus": routine["sync_status"],
        "weeks": [{"week": week, "days": days} for week, days in sorted(weeks.items())],
    }


def export_vault(db_path: Path, exercise_db: Path, out_dir: Path) -> dict[str, Any]:
    out_dir.mkdir(parents=True, exist_ok=True)
    for name in ("plans", "logs", "exercises", "inbox", "reports"):
        (out_dir / name).mkdir(parents=True, exist_ok=True)

    plan_count = 0
    workout_count = 0
    exercise_count = 0
    with connect(db_path) as conn:
        routines = conn.execute(
            """
            select id, name, total_weeks, days_per_week, sync_status
            from local_routines
            where deleted = 0
            order by updated_at desc
            """
        ).fetchall()
        for routine in routines:
            plan = plan_from_db(conn, routine)
            path = (
                out_dir
                / "plans"
                / f"{slugify(routine['name'], fallback='plan')}-{routine['id']}.plan.json"
            )
            path.write_text(json.dumps(plan, ensure_ascii=False, indent=2), encoding="utf-8")
            plan_count += 1

        routines_by_id = {int(row["id"]): row["name"] for row in routines}
        days_by_id = {
            int(row["id"]): row["name"]
            for row in conn.execute("select id, name from local_training_days").fetchall()
        }
        sessions = conn.execute(
            """
            select id, routine_id, day_id, started_at, ended_at, note
            from local_workout_sessions
            order by started_at
            """
        ).fetchall()
        for session in sessions:
            logs = conn.execute(
                """
                select id, exercise_name, set_index, weight, reps, rir, duration_seconds, created_at
                from local_workout_logs
                where session_id = ?
                order by created_at, set_index
                """,
                (session["id"],),
            ).fetchall()
            if not logs:
                continue
            started_iso = iso_from_db_time(session["started_at"]) or "unknown"
            date_part = started_iso[:10] if len(started_iso) >= 10 else "unknown-date"
            year = date_part[:4] if len(date_part) >= 4 else "unknown"
            month = date_part[5:7] if len(date_part) >= 7 else "unknown"
            log_dir = out_dir / "logs" / year / month
            log_dir.mkdir(parents=True, exist_ok=True)
            payload = {
                "format": "yours-workout",
                "formatVersion": 1,
                "id": session["id"],
                "routineId": session["routine_id"],
                "routineName": routines_by_id.get(int(session["routine_id"]), ""),
                "dayId": session["day_id"],
                "dayName": days_by_id.get(int(session["day_id"])) if session["day_id"] else "",
                "startedAt": started_iso,
                "endedAt": iso_from_db_time(session["ended_at"]),
                "note": session["note"] or "",
                "incomplete": "未完成训练计划" in (session["note"] or ""),
                "logs": [
                    {
                        "id": log["id"],
                        "exercise": log["exercise_name"],
                        "setIndex": log["set_index"],
                        "weight": log["weight"],
                        "reps": log["reps"],
                        "rir": log["rir"],
                        "durationSeconds": log["duration_seconds"],
                        "createdAt": iso_from_db_time(log["created_at"]),
                    }
                    for log in logs
                ],
            }
            path = out_dir / "logs" / year / month / f"{date_part}-session-{session['id']}.workout.json"
            path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
            workout_count += 1

    with connect(exercise_db) as conn:
        exercises = conn.execute(
            """
            select id, remote_id, chinese_name, english_name, body_part, equipment,
                   primary_muscles, description, image_paths_json, is_custom,
                   sync_status, deleted, created_at, updated_at
            from custom_exercises
            order by body_part, chinese_name
            """
        ).fetchall()
        payload = {
            "format": "yours-custom-exercises",
            "formatVersion": 1,
            "exercises": [
                {
                    "id": row["id"],
                    "remoteId": row["remote_id"],
                    "chineseName": row["chinese_name"],
                    "englishName": row["english_name"],
                    "bodyPart": row["body_part"],
                    "equipment": row["equipment"],
                    "primaryMuscles": row["primary_muscles"],
                    "description": row["description"],
                    "imagePaths": safe_json_loads(row["image_paths_json"], []),
                    "isCustom": bool(row["is_custom"]),
                    "syncStatus": row["sync_status"],
                    "deleted": bool(row["deleted"]),
                    "createdAt": iso_from_db_time(row["created_at"]),
                    "updatedAt": iso_from_db_time(row["updated_at"]),
                }
                for row in exercises
            ],
        }
        exercise_count = sum(1 for row in exercises if not bool(row["deleted"]))
        (out_dir / "exercises" / "custom-exercises.json").write_text(
            json.dumps(payload, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    exported_at = time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime())
    manifest = {
        "format": VAULT_FORMAT,
        "formatVersion": 1,
        "appName": "Yours",
        "exportedAt": exported_at,
        "contains": {
            "plans": plan_count,
            "workouts": workout_count,
            "customExercises": exercise_count,
            "reports": True,
        },
        "directories": {
            "plans": "plans",
            "logs": "logs",
            "exercises": "exercises",
            "inbox": "inbox",
            "reports": "reports",
        },
    }
    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return {
        "ok": True,
        "vault": str(out_dir),
        "manifest": str(out_dir / "manifest.json"),
        "plans": plan_count,
        "workouts": workout_count,
        "customExercises": exercise_count,
    }


def inspect_vault(path: Path) -> dict[str, Any]:
    if not path.exists():
        raise CliError(f"Yours Vault 不存在：{path}", code="vault_not_found")
    manifest_path = path / "manifest.json"
    manifest = None
    if manifest_path.exists():
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise CliError(f"manifest.json 格式错误：{exc}", code="invalid_manifest") from exc
    plans = sorted((path / "plans").glob("*.plan.json")) if (path / "plans").exists() else []
    workouts = sorted(path.glob("logs/**/*.workout.json")) if (path / "logs").exists() else []
    inbox = sorted((path / "inbox").glob("*.plan.json")) if (path / "inbox").exists() else []
    inbox_exercises = (
        sorted((path / "inbox").glob("*.exercise.json")) if (path / "inbox").exists() else []
    )
    exercises_file = path / "exercises" / "custom-exercises.json"
    exercise_count = 0
    if exercises_file.exists():
        try:
            data = json.loads(exercises_file.read_text(encoding="utf-8"))
            if isinstance(data, dict) and isinstance(data.get("exercises"), list):
                exercise_count = len([item for item in data["exercises"] if not item.get("deleted")])
        except json.JSONDecodeError as exc:
            raise CliError(f"custom-exercises.json 格式错误：{exc}", code="invalid_exercises") from exc
    return {
        "ok": True,
        "vault": str(path),
        "format": manifest.get("format") if isinstance(manifest, dict) else None,
        "formatVersion": manifest.get("formatVersion") if isinstance(manifest, dict) else None,
        "plans": len(plans),
        "workouts": len(workouts),
        "customExercises": exercise_count,
        "inboxPlans": len(inbox),
        "inboxExercises": len(inbox_exercises),
    }


def archive_inbox_file(file: Path, folder_name: str = "imported") -> Path:
    destination_dir = file.parent / folder_name
    destination_dir.mkdir(parents=True, exist_ok=True)
    destination = destination_dir / file.name
    if destination.exists():
        destination = destination_dir / f"{int(time.time())}-{file.name}"
    file.rename(destination)
    return destination


def insert_sync_queue(conn: sqlite3.Connection, entity_type: str, entity_id: int, action: str) -> None:
    ts = now_ts()
    conn.execute(
        """
        insert into local_sync_queue
        (entity_type, entity_id, action, payload, status, attempts, created_at, updated_at)
        values (?, ?, ?, '{}', ?, 0, ?, ?)
        """,
        (entity_type, entity_id, action, SYNC_PENDING, ts, ts),
    )


def find_exercise(conn: sqlite3.Connection, operation: dict[str, Any]) -> sqlite3.Row | None:
    if operation.get("id") is not None:
        row = conn.execute(
            "select * from custom_exercises where id = ? and deleted = 0",
            (operation["id"],),
        ).fetchone()
        if row is not None:
            return row

    names = {
        normalize_key(value)
        for value in (
            operation.get("matchName"),
            operation.get("chineseName"),
            operation.get("englishName"),
        )
        if isinstance(value, str) and value.strip()
    }
    if not names:
        return None
    rows = conn.execute(
        "select * from custom_exercises where deleted = 0",
    ).fetchall()
    for row in rows:
        row_keys = {
            normalize_key(row["chinese_name"] or ""),
            normalize_key(row["english_name"] or ""),
        }
        if names & row_keys:
            return row
    return None


def import_exercise_operations(
    operations: list[dict[str, Any]],
    exercise_db: Path,
    *,
    app_db: Path | None = None,
    dry_run: bool = False,
) -> dict[str, Any]:
    ts = now_ts()
    results: list[dict[str, Any]] = []
    with connect(exercise_db) as conn:
        conn.execute("begin")
        try:
            for operation in operations:
                existing = find_exercise(conn, operation)
                if operation["action"] == "delete":
                    if existing is None:
                        results.append(
                            {
                                "action": "delete",
                                "changed": False,
                                "reason": "not_found",
                                "name": operation.get("chineseName") or operation.get("matchName"),
                            }
                        )
                        continue
                    results.append(
                        {
                            "action": "delete",
                            "changed": True,
                            "id": existing["id"],
                            "name": existing["chinese_name"],
                        }
                    )
                    if not dry_run:
                        conn.execute(
                            """
                            update custom_exercises
                            set deleted = 1, sync_status = ?, updated_at = ?
                            where id = ?
                            """,
                            (SYNC_PENDING, ts, existing["id"]),
                        )
                    continue

                english_name = operation["englishName"] or (existing["english_name"] if existing else "")
                category1 = operation["category1"] or (existing["body_part"] if existing else "")
                category2 = operation["category2"] or (existing["equipment"] if existing else "")
                primary_muscles = operation["primaryMuscles"] or (
                    existing["primary_muscles"] if existing else ""
                )
                description = operation["description"] or (existing["description"] if existing else "")
                image_paths = operation["imagePaths"] or (
                    safe_json_loads(existing["image_paths_json"], []) if existing else []
                )
                payload = (
                    operation["chineseName"],
                    english_name,
                    category1,
                    category2,
                    primary_muscles,
                    description,
                    json.dumps(image_paths, ensure_ascii=False),
                    1,
                    SYNC_PENDING,
                    0,
                    ts,
                )
                if existing is None:
                    results.append(
                        {
                            "action": "create",
                            "changed": True,
                            "name": operation["chineseName"],
                        }
                    )
                    if not dry_run:
                        cursor = conn.execute(
                            """
                            insert into custom_exercises
                            (
                              remote_id, chinese_name, english_name, body_part, equipment,
                              primary_muscles, description, image_paths_json, is_custom,
                              sync_status, deleted, created_at, updated_at
                            )
                            values (null, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                            """,
                            (*payload, ts),
                        )
                        results[-1]["id"] = int(cursor.lastrowid)
                    continue

                results.append(
                    {
                        "action": "update",
                        "changed": True,
                        "id": existing["id"],
                        "oldName": existing["chinese_name"],
                        "name": operation["chineseName"],
                    }
                )
                if not dry_run:
                    conn.execute(
                        """
                        update custom_exercises
                        set chinese_name = ?, english_name = ?, body_part = ?, equipment = ?,
                            primary_muscles = ?, description = ?, image_paths_json = ?,
                            is_custom = ?, sync_status = ?, deleted = ?, updated_at = ?
                        where id = ?
                        """,
                        (*payload, existing["id"]),
                    )
            if dry_run:
                conn.rollback()
            else:
                conn.commit()
        except Exception:
            conn.rollback()
            raise

    if not dry_run and app_db is not None:
        with connect(app_db) as app_conn:
            for result in results:
                if result.get("changed") and result.get("id") is not None:
                    action = "delete" if result["action"] == "delete" else result["action"]
                    insert_sync_queue(app_conn, "custom_exercise", int(result["id"]), action)
            app_conn.commit()

    return {
        "dryRun": dry_run,
        "changedCount": len([item for item in results if item.get("changed")]),
        "results": results,
    }


def import_plan(plan: dict[str, Any], db_path: Path, *, replace: bool) -> dict[str, Any]:
    total_weeks = int(plan.get("totalWeeks") or max(week["week"] for week in plan["weeks"]))
    days_per_week = int(
        plan.get("daysPerWeek")
        or max(day["day"] for week in plan["weeks"] for day in week["days"])
    )
    ts = now_ts()
    with connect(db_path) as conn:
        conn.execute("begin")
        try:
            replaced_ids: list[int] = []
            if replace:
                rows = conn.execute(
                    "select id from local_routines where deleted = 0 and name = ?",
                    (plan["name"],),
                ).fetchall()
                replaced_ids = [int(row["id"]) for row in rows]
                for routine_id in replaced_ids:
                    conn.execute(
                        """
                        update local_routines
                        set deleted = 1, sync_status = ?, updated_at = ?
                        where id = ?
                        """,
                        (SYNC_PENDING, ts, routine_id),
                    )
                    insert_sync_queue(conn, "routine", routine_id, "delete")

            cursor = conn.execute(
                """
                insert into local_routines
                (remote_id, name, total_weeks, days_per_week, sync_status, deleted, created_at, updated_at)
                values (null, ?, ?, ?, ?, 0, ?, ?)
                """,
                (plan["name"], total_weeks, days_per_week, SYNC_PENDING, ts, ts),
            )
            routine_id = int(cursor.lastrowid)

            day_count = 0
            action_count = 0
            for week in plan["weeks"]:
                for day in week["days"]:
                    actions_json = json.dumps(
                        [
                            {
                                "name": action["exercise"],
                                "targetSets": action["sets"],
                                "targetReps": action["reps"],
                                "targetWeight": action["weight"],
                                "targetRestSeconds": action["restSeconds"],
                                "note": action["note"],
                            }
                            for action in day["actions"]
                        ],
                        ensure_ascii=False,
                    )
                    cursor = conn.execute(
                        """
                        insert into local_training_days
                        (remote_id, routine_id, week, day, name, actions_json, sync_status, updated_at)
                        values (null, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        (
                            routine_id,
                            week["week"],
                            day["day"],
                            day["name"],
                            actions_json,
                            SYNC_PENDING,
                            ts,
                        ),
                    )
                    day_id = int(cursor.lastrowid)
                    day_count += 1

                    for order, action in enumerate(day["actions"]):
                        cursor = conn.execute(
                            """
                            insert into local_slots
                            (remote_id, day_id, "order", sync_status)
                            values (null, ?, ?, ?)
                            """,
                            (day_id, order, SYNC_PENDING),
                        )
                        slot_id = int(cursor.lastrowid)
                        conn.execute(
                            """
                            insert into local_slot_entries
                            (
                              remote_id, slot_id, exercise_name, exercise_id,
                              target_sets, target_reps, target_weight, sync_status
                            )
                            values (null, ?, ?, null, ?, ?, ?, ?)
                            """,
                            (
                                slot_id,
                                action["exercise"],
                                action["sets"],
                                action["reps"],
                                action["weight"],
                                SYNC_PENDING,
                            ),
                        )
                        action_count += 1

            insert_sync_queue(conn, "routine", routine_id, "create")
            conn.commit()
        except Exception:
            conn.rollback()
            raise

    return {
        "imported": True,
        "routineId": routine_id,
        "replacedRoutineIds": replaced_ids,
        "days": day_count,
        "actions": action_count,
    }


def cmd_doctor(args: argparse.Namespace) -> dict[str, Any]:
    app_db = None
    exercise_db = None
    app_ok = False
    exercise_ok = False
    errors: list[str] = []
    try:
        app_db = resolve_db_path(args.db, APP_DB_NAME)
        app_ok = True
    except CliError as exc:
        errors.append(exc.message)
    try:
        exercise_db = resolve_db_path(args.exercise_db, EXERCISE_DB_NAME)
        exercise_ok = True
    except CliError as exc:
        errors.append(exc.message)
    return {
        "ok": app_ok and exercise_ok,
        "appDb": str(app_db) if app_db else None,
        "exerciseDb": str(exercise_db) if exercise_db else None,
        "authRequired": False,
        "mode": "local-simulator",
        "errors": errors,
    }


def cmd_exercise_list(args: argparse.Namespace) -> dict[str, Any]:
    exercise_db = resolve_db_path(args.exercise_db, EXERCISE_DB_NAME)
    sql = """
        select id, chinese_name, english_name, body_part, equipment, primary_muscles
        from custom_exercises
        where deleted = 0
    """
    params: list[Any] = []
    if args.body_part:
        sql += " and body_part = ?"
        params.append(args.body_part)
    sql += " order by body_part, chinese_name limit ?"
    params.append(args.limit)
    with connect(exercise_db) as conn:
        rows = conn.execute(sql, params).fetchall()
    return {
        "count": len(rows),
        "exercises": [dict(row) for row in rows],
    }


def cmd_plan_list(args: argparse.Namespace) -> dict[str, Any]:
    db_path = resolve_db_path(args.db, APP_DB_NAME)
    with connect(db_path) as conn:
        rows = conn.execute(
            """
            select id, name, total_weeks, days_per_week, sync_status, deleted, updated_at
            from local_routines
            where deleted = 0
            order by updated_at desc
            limit ?
            """,
            (args.limit,),
        ).fetchall()
    return {"count": len(rows), "plans": [dict(row) for row in rows]}


def cmd_plan_validate(args: argparse.Namespace) -> dict[str, Any]:
    exercise_db = resolve_db_path(args.exercise_db, EXERCISE_DB_NAME)
    plan = normalize_plan(load_plan(args.file))
    missing = missing_exercises(plan, exercise_db)
    return {
        "ok": not missing,
        "summary": plan_summary(plan),
        "missingExercises": missing,
    }


def cmd_plan_import(args: argparse.Namespace) -> dict[str, Any]:
    db_path = resolve_db_path(args.db, APP_DB_NAME)
    exercise_db = resolve_db_path(args.exercise_db, EXERCISE_DB_NAME)
    plan = normalize_plan(load_plan(args.file))
    missing = missing_exercises(plan, exercise_db)
    if missing and not args.allow_missing_exercises:
        raise CliError(
            "计划中有动作不在自定义动作库，已阻止写入。",
            code="missing_exercises",
            details={"missingExercises": missing},
        )
    if args.dry_run:
        return {
            "imported": False,
            "dryRun": True,
            "summary": plan_summary(plan),
            "missingExercises": missing,
            "db": str(db_path),
        }
    result = import_plan(plan, db_path, replace=args.replace)
    result["summary"] = plan_summary(plan)
    result["missingExercises"] = missing
    result["db"] = str(db_path)
    return result


def cmd_vault_export(args: argparse.Namespace) -> dict[str, Any]:
    db_path = resolve_db_path(args.db, APP_DB_NAME)
    exercise_db = resolve_db_path(args.exercise_db, EXERCISE_DB_NAME)
    return export_vault(db_path, exercise_db, Path(args.out).expanduser())


def cmd_vault_inspect(args: argparse.Namespace) -> dict[str, Any]:
    return inspect_vault(Path(args.path).expanduser())


def cmd_vault_validate_plan(args: argparse.Namespace) -> dict[str, Any]:
    exercise_db = resolve_db_path(args.exercise_db, EXERCISE_DB_NAME)
    plan = normalize_plan(load_plan(args.file))
    missing = missing_exercises(plan, exercise_db)
    return {
        "ok": not missing,
        "summary": plan_summary(plan),
        "missingExercises": missing,
        "file": str(Path(args.file).expanduser()),
    }


def cmd_vault_validate_exercise(args: argparse.Namespace) -> dict[str, Any]:
    operations = normalize_exercise_operations(load_json_object(args.file, "动作"))
    return {
        "ok": True,
        "summary": exercise_summary(operations),
        "file": str(Path(args.file).expanduser()),
    }


def cmd_exercise_import(args: argparse.Namespace) -> dict[str, Any]:
    db_path = resolve_db_path(args.db, APP_DB_NAME)
    exercise_db = resolve_db_path(args.exercise_db, EXERCISE_DB_NAME)
    operations = normalize_exercise_operations(load_json_object(args.file, "动作"))
    result = import_exercise_operations(
        operations,
        exercise_db,
        app_db=db_path,
        dry_run=args.dry_run,
    )
    result["summary"] = exercise_summary(operations)
    result["exerciseDb"] = str(exercise_db)
    return result


def cmd_vault_import_inbox(args: argparse.Namespace) -> dict[str, Any]:
    db_path = resolve_db_path(args.db, APP_DB_NAME)
    exercise_db = resolve_db_path(args.exercise_db, EXERCISE_DB_NAME)
    vault = Path(args.path).expanduser()
    inbox = vault / "inbox"
    if not inbox.exists():
        raise CliError(f"没有找到 inbox 目录：{inbox}", code="inbox_not_found")
    exercise_files = sorted(inbox.glob("*.exercise.json"))
    plan_files = sorted(inbox.glob("*.plan.json"))
    imported: list[dict[str, Any]] = []
    blocked: list[dict[str, Any]] = []
    exercise_imported: list[dict[str, Any]] = []
    pending_exercise_names: set[str] = set()
    for file in exercise_files:
        operations = normalize_exercise_operations(load_json_object(str(file), "动作"))
        pending_exercise_names.update(
            normalize_key(item["chineseName"])
            for item in operations
            if item["action"] == "upsert" and item.get("chineseName")
        )
        result = import_exercise_operations(
            operations,
            exercise_db,
            app_db=db_path,
            dry_run=args.dry_run,
        )
        result["file"] = str(file)
        result["summary"] = exercise_summary(operations)
        if not args.dry_run:
            archived = archive_inbox_file(file)
            result["archivedTo"] = str(archived)
        exercise_imported.append(result)

    for file in plan_files:
        plan = normalize_plan(load_plan(str(file)))
        missing = [
            name
            for name in missing_exercises(plan, exercise_db)
            if normalize_key(name) not in pending_exercise_names
        ]
        if missing and not args.allow_missing_exercises:
            blocked.append({"file": str(file), "missingExercises": missing})
            continue
        if args.dry_run:
            imported.append(
                {
                    "file": str(file),
                    "dryRun": True,
                    "summary": plan_summary(plan),
                    "missingExercises": missing,
                }
            )
            continue
        result = import_plan(plan, db_path, replace=args.replace)
        archived = archive_inbox_file(file)
        result["file"] = str(file)
        result["archivedTo"] = str(archived)
        result["summary"] = plan_summary(plan)
        result["missingExercises"] = missing
        imported.append(result)
    return {
        "ok": not blocked,
        "vault": str(vault),
        "dryRun": args.dry_run,
        "importedCount": len(imported) if not args.dry_run else 0,
        "importedExerciseCount": sum(item.get("changedCount", 0) for item in exercise_imported)
        if not args.dry_run
        else 0,
        "checkedCount": len(plan_files) + len(exercise_files),
        "checkedPlanCount": len(plan_files),
        "checkedExerciseCount": len(exercise_files),
        "importedExercises": exercise_imported,
        "imported": imported,
        "blocked": blocked,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="yours-cli",
        description="AI-friendly local CLI for Yours.",
    )
    parser.add_argument("--json", action="store_true", help="输出稳定 JSON。")
    parser.add_argument("--db", help="指定 local_training.sqlite 路径。")
    parser.add_argument("--exercise-db", help="指定 custom_exercises.sqlite 路径。")

    subparsers = parser.add_subparsers(dest="command", required=True)
    doctor = subparsers.add_parser("doctor", help="检查本地数据库和运行模式。")
    doctor.set_defaults(func=cmd_doctor)

    exercise = subparsers.add_parser("exercise", help="动作库命令。")
    exercise_sub = exercise.add_subparsers(dest="exercise_command", required=True)
    exercise_list = exercise_sub.add_parser("list", help="列出自定义动作库。")
    exercise_list.add_argument("--body-part", help="按部位/分类筛选，例如 有氧。")
    exercise_list.add_argument("--limit", type=int, default=200)
    exercise_list.set_defaults(func=cmd_exercise_list)

    exercise_import = exercise_sub.add_parser("import", help="导入动作 JSON 到本地动作库。")
    exercise_import.add_argument("file")
    exercise_import.add_argument("--dry-run", action="store_true", help="只预览，不写数据库。")
    exercise_import.set_defaults(func=cmd_exercise_import)

    plan = subparsers.add_parser("plan", help="训练计划命令。")
    plan_sub = plan.add_subparsers(dest="plan_command", required=True)
    plan_list = plan_sub.add_parser("list", help="列出本地训练计划。")
    plan_list.add_argument("--limit", type=int, default=50)
    plan_list.set_defaults(func=cmd_plan_list)

    plan_validate = plan_sub.add_parser("validate", help="校验训练计划 JSON。")
    plan_validate.add_argument("file")
    plan_validate.set_defaults(func=cmd_plan_validate)

    plan_import = plan_sub.add_parser("import", help="导入训练计划 JSON 到本地数据库。")
    plan_import.add_argument("file")
    plan_import.add_argument("--dry-run", action="store_true", help="只预览，不写数据库。")
    plan_import.add_argument("--replace", action="store_true", help="同名计划存在时，标记旧计划删除后新建。")
    plan_import.add_argument(
        "--allow-missing-exercises",
        action="store_true",
        help="允许导入动作库暂未收录的动作。不推荐，除非你明确要先导入再补动作。",
    )
    plan_import.set_defaults(func=cmd_plan_import)

    vault = subparsers.add_parser("vault", help="Yours Vault 开放文件夹命令。")
    vault_sub = vault.add_subparsers(dest="vault_command", required=True)

    vault_export = vault_sub.add_parser("export", help="导出 Yours Vault 文件夹。")
    vault_export.add_argument("--out", required=True, help="导出目录，例如 ~/YoursVault。")
    vault_export.set_defaults(func=cmd_vault_export)

    vault_inspect = vault_sub.add_parser("inspect", help="检查 Yours Vault 内容。")
    vault_inspect.add_argument("path", help="Yours Vault 目录。")
    vault_inspect.set_defaults(func=cmd_vault_inspect)

    vault_validate = vault_sub.add_parser("validate-plan", help="校验 inbox 计划 JSON。")
    vault_validate.add_argument("file")
    vault_validate.set_defaults(func=cmd_vault_validate_plan)

    vault_validate_exercise = vault_sub.add_parser("validate-exercise", help="校验 inbox 动作 JSON。")
    vault_validate_exercise.add_argument("file")
    vault_validate_exercise.set_defaults(func=cmd_vault_validate_exercise)

    vault_import = vault_sub.add_parser("import-inbox", help="导入 Yours Vault/inbox 中的动作和计划。")
    vault_import.add_argument("path", help="Yours Vault 目录。")
    vault_import.add_argument("--dry-run", action="store_true", help="只校验和预览，不写数据库。")
    vault_import.add_argument("--replace", action="store_true", help="同名计划存在时，标记旧计划删除后新建。")
    vault_import.add_argument(
        "--allow-missing-exercises",
        action="store_true",
        help="允许导入动作库暂未收录的动作。不推荐。",
    )
    vault_import.set_defaults(func=cmd_vault_import_inbox)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        result = args.func(args)
        emit(result, as_json=args.json)
        return 0
    except CliError as exc:
        payload = {"ok": False, "error": {"code": exc.code, "message": exc.message}}
        if exc.details is not None:
            payload["error"]["details"] = exc.details
        if args.json:
            emit(payload, as_json=True)
        else:
            print(f"错误：{exc.message}", file=sys.stderr)
            if exc.details is not None:
                print(json.dumps(exc.details, ensure_ascii=False, indent=2), file=sys.stderr)
        return 1
    except sqlite3.OperationalError as exc:
        message = str(exc)
        hint = None
        if "readonly database" in message:
            hint = "当前进程没有写入数据库权限。开发环境下请确认命令有模拟器目录写权限。"
        payload = {
            "ok": False,
            "error": {
                "code": "sqlite_error",
                "message": message,
                "hint": hint,
            },
        }
        if args.json:
            emit(payload, as_json=True)
        else:
            print(f"SQLite 错误：{message}", file=sys.stderr)
            if hint:
                print(hint, file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
