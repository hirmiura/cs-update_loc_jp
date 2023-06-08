#!/usr/bin/env -S python3
# SPDX-License-Identifier: MIT
# Copyright 2023 hirmiura (https://github.com/hirmiura)
#
# ルーズJSONをピュアJSONに変換する

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import json5

ENC = "utf-8"


def pargs():
    parser = argparse.ArgumentParser(description="ルーズJSONをピュアJSONに変換する")
    parser.add_argument(
        dest="files",
        nargs="+",
        help="ファイル",
    )
    parser.add_argument("--version", action="version", version="%(prog)s 0.1.0")
    args = parser.parse_args()
    return args


def main() -> None:
    args = pargs()
    for f in args.files:
        print(f"読み込み中: {f}", file=sys.stderr)
        t_sta = time.perf_counter()
        path = Path(f)
        text = path.read_text(encoding=ENC)
        if path.name == "mansus.json":
            text = text.replace(
                r"""ingredientforgef:"Last night in the Mansus I visited the Malleary, from whose fires one does not emerge unchanged. The Forge's light fell upon me and my heart boiled and when I woke my blood burnt within me so that I had to shed it in a cup before it overwhelmed me
and lo, ten drops of it were not blood, exactly, unless it be the Blood of the Sun. Perhaps I found the cup and the blood is not mine. The Forge sears memory.",""",  # noqa: E501
                r"""ingredientforgef:"Last night in the Mansus I visited the Malleary, from whose fires one does not emerge unchanged. The Forge's light fell upon me and my heart boiled and when I woke my blood burnt within me so that I had to shed it in a cup before it overwhelmed me and lo, ten drops of it were not blood, exactly, unless it be the Blood of the Sun. Perhaps I found the cup and the blood is not mine. The Forge sears memory.",""",  # noqa: E501
                1,
            )
        elif path.name == "versionnews.json":
            # 生の改行でエラー&使わないのでスキップ
            continue
        js = json5.loads(text, encoding=ENC)
        t_dlt = time.perf_counter() - t_sta
        print(f"  {t_dlt}秒", file=sys.stderr)
        json.dump(js, sys.stdout, ensure_ascii=False, indent=4)


if __name__ == "__main__":
    main()
