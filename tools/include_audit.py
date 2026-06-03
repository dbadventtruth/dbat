#!/usr/bin/env python3
"""Audit DBAT header include hygiene.

This intentionally does not edit files. It reports structural include issues and,
optionally, checks that each header can be included by itself.
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


INCLUDE_RE = re.compile(r'^\s*#\s*include\s+([<"])([^>"]+)[>"]')


def rel(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def includes(path: Path) -> list[str]:
    result: list[str] = []
    try:
        text = path.read_text(errors="ignore")
    except OSError:
        return result
    for line in text.splitlines():
        match = INCLUDE_RE.match(line)
        if match:
            result.append(match.group(2))
    return result


def audit_structure(root: Path) -> list[str]:
    messages: list[str] = []
    headers = sorted(root.glob("src/**/*.h")) + sorted(root.glob("src/**/*.hpp"))
    sources = sorted(root.glob("src/**/*.cpp"))

    for path in headers:
        name = rel(path, root)
        if path.name == "zig_api.h":
            continue
        incs = includes(path)
        if "utils.h" in incs:
            messages.append(f"{name}: header includes utils.h")
        if path.name.endswith("_api.h") or path.name.endswith("_db.h"):
            for inc in incs:
                if inc.endswith("_impl.h"):
                    messages.append(f"{name}: public header includes implementation header {inc}")
        if path.name.endswith("_impl.h") and "consts/types.h" not in incs:
            messages.append(f"{name}: implementation header should include consts/types.h")

    for path in sources:
        name = rel(path, root)
        if "utils.h" in includes(path):
            messages.append(f"{name}: source still includes utils.h")

    return messages


def check_self_contained(root: Path, clang: str, limit: int | None) -> list[str]:
    headers = sorted(root.glob("src/**/*.h")) + sorted(root.glob("src/**/*.hpp"))
    failures: list[str] = []
    checked = 0
    for header in headers:
        if header.name == "zig_api.h":
            continue
        if limit is not None and checked >= limit:
            break
        checked += 1

        include_name = rel(header, root / "src")
        with tempfile.NamedTemporaryFile("w", suffix=".cpp", delete=False) as tmp:
            tmp.write(f'#include "{include_name}"\n')
            tmp_path = Path(tmp.name)
        try:
            cmd = [
                clang,
                "-std=gnu++23",
                "-fsyntax-only",
                "-DPATH_MAX=4096",
                "-I",
                str(root / "src"),
                "-I",
                str(root / "include"),
                str(tmp_path),
            ]
            result = subprocess.run(cmd, cwd=root, capture_output=True, text=True)
            if result.returncode != 0:
                first_error = ""
                for line in result.stderr.splitlines():
                    if "error:" in line:
                        first_error = line.strip()
                        break
                failures.append(f"{rel(header, root)}: not self-contained" + (f" ({first_error})" if first_error else ""))
        finally:
            try:
                tmp_path.unlink()
            except OSError:
                pass
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit DBAT include hygiene")
    parser.add_argument("--self-contained", action="store_true", help="compile-check each header by itself")
    parser.add_argument("--limit", type=int, default=None, help="limit self-contained checks")
    parser.add_argument("--clang", default=os.environ.get("CXX", "clang++"), help="C++ compiler for self-contained checks")
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    messages = audit_structure(root)
    if args.self_contained:
        messages.extend(check_self_contained(root, args.clang, args.limit))

    if messages:
        for message in messages:
            print(message)
        return 1
    print("include audit passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
