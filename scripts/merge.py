# -*- coding: utf-8 -*-
# scripts/merge.py
import argparse, sys, re
from pathlib import Path
from pypdf import PdfWriter, PdfReader

def natural_key(s: str):
    return [int(t) if t.isdigit() else t for t in re.split(r'(\d+)', s)]

def unique_keep_order(paths):
    seen = set(); out = []
    for p in paths:
        rp = Path(p).resolve()
        if rp not in seen:
            out.append(rp); seen.add(rp)
    return out

def is_merged_pdf(p: Path) -> bool:
    # exclude merged*.pdf (case-insensitive)
    return re.fullmatch(r"merged.*\.pdf", p.name, flags=re.IGNORECASE) is not None

def main():
    ap = argparse.ArgumentParser(description="Merge PDFs (name ascending).")
    ap.add_argument("--dir", default=None, help="(optional) base directory")
    ap.add_argument("--files", nargs="*", help="explicit list of PDFs (same folder)")
    ap.add_argument("--out", default="merged.pdf", help="output file name or path")
    ap.add_argument("--recursive", action="store_true", help="(unused here)")
    ap.add_argument("--dry-run", action="store_true", help="print order only")
    args = ap.parse_args()

    files = []
    out_path = None

    if args.files:
        files = unique_keep_order(args.files)
        files = [Path(p).resolve() for p in files
                 if Path(p).exists() and Path(p).suffix.lower()==".pdf"]
        # exclude merged*.pdf just in case
        files = [p for p in files if not is_merged_pdf(p)]
        if not files:
            print("no PDFs found (--files)", file=sys.stderr); return 1

        parents = {p.parent for p in files}
        if len(parents) != 1:
            print("files must be from the same folder", file=sys.stderr); return 2

        base_dir = next(iter(parents))
        out_path = Path(args.out)
        out_path = (base_dir / out_path) if not out_path.is_absolute() else out_path
        files.sort(key=lambda p: natural_key(p.name))

    elif args.dir:
        base_dir = Path(str(args.dir).rstrip("\\/ \t\"'")).resolve()
        out_path = (base_dir / args.out).resolve()
        files = [p for p in base_dir.glob("*.pdf") if p.is_file()]
        files = [p.resolve() for p in files
                 if p.resolve()!=out_path and not is_merged_pdf(p)]
        files.sort(key=lambda p: natural_key(p.name))
    else:
        print("use --files or --dir", file=sys.stderr); return 3

    if not files:
        print("no PDFs to merge", file=sys.stderr); return 1

    print("order:")
    for p in files:
        print(" -", p.name)

    if args.dry_run:
        return 0

    writer = PdfWriter()
    appended = 0
    for p in files:
        try:
            r = PdfReader(str(p))
            if getattr(r, "is_encrypted", False):
                try:
                    r.decrypt(b"")
                except Exception:
                    print(f"[SKIP] encrypted: {p.name}", file=sys.stderr)
                    continue
            for page in r.pages:
                writer.add_page(page)
            appended += 1
        except Exception as e:
            print(f"[SKIP] read failed: {p.name} ({e})", file=sys.stderr)

    if appended == 0:
        print("nothing merged", file=sys.stderr); return 2

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "wb") as f:
        writer.write(f)

    print(f"\nOK: {out_path} ({appended} files)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
