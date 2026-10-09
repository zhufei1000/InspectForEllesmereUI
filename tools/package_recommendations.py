"""Build the installable addon ZIP using the version declared in its TOC."""
from pathlib import Path
import argparse
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ADDON = "InspectForEllesmereUI"
VERSION = r"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)"


def build(tag=None):
    toc = ROOT / f"{ADDON}.toc"
    match = re.search(rf"^## Version:\s*v?({VERSION})\s*$",
                      toc.read_text(encoding="utf-8-sig"), re.MULTILINE)
    if not match:
        raise ValueError("TOC must declare a three-part version such as v2.3.0")
    version = match.group(1)
    if tag is not None and tag != f"v{version}":
        raise ValueError(f"Release tag {tag!r} does not match TOC version v{version}")
    files = list(ROOT.glob("*.lua")) + [toc, ROOT / "LICENSE"]
    for folder in ("libs", "locales", "texture", "GearData"):
        files.extend(p for p in (ROOT / folder).rglob("*") if p.is_file())
    out = ROOT / "dist"
    out.mkdir(exist_ok=True)
    path = out / f"{ADDON}_{version}.zip"
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as archive:
        for file in sorted(files):
            archive.write(file, Path(ADDON) / file.relative_to(ROOT))
    return path


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", help="Require the release tag to match the TOC version")
    args = parser.parse_args()
    print(build(args.tag))
