"""Terminal tool: read a resume file and print the extracted text."""

import argparse
import sys
import time
from pathlib import Path

from app.services.resume_text import UnsupportedFile, extract_text


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract text from a resume (PDF, DOCX, JPG, PNG, WEBP).")
    parser.add_argument("file", type=Path, help="resume file to read")
    parser.add_argument("--out", type=Path, help="also save the text to this file")
    args = parser.parse_args()

    if not args.file.is_file():
        print(f"File not found: {args.file}", file=sys.stderr)
        return 1

    started = time.perf_counter()
    try:
        result = extract_text(args.file.read_bytes())
    except UnsupportedFile as exc:
        print(f"Cannot read this file: {exc}", file=sys.stderr)
        return 2
    seconds = time.perf_counter() - started

    print(f"File        : {args.file.name}")
    print(f"Type        : {result.kind}")
    print(f"Method      : {result.method}")
    print(f"Pages       : {result.pages} (OCR on {result.ocr_pages})")
    if result.ocr_confidence is not None:
        print(f"OCR score   : {result.ocr_confidence:.2f}")
    print(f"Characters  : {len(result.text)}")
    print(f"Time        : {seconds:.1f}s")
    for warning in result.warnings:
        print(f"Warning     : {warning}")
    print("-" * 60)
    print(result.text)

    if args.out:
        args.out.write_text(result.text, encoding="utf-8")
        print("-" * 60)
        print(f"Saved to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
