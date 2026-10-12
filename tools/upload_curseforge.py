"""Upload the packaged addon ZIP to CurseForge using the project upload API."""
from __future__ import annotations
from pathlib import Path
import argparse
import glob
import json
import os
import re
import sys
import urllib.error
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[1]
ADDON = "InspectForEllesmereUI"
UPLOAD_URL = "https://wow.curseforge.com/api/projects/{project}/upload"
FILES_URL = "https://www.curseforge.com/api/v1/mods/{project}/files?pageIndex=0&pageSize=50"
VERSIONS_URL = "https://wow.curseforge.com/api/game/versions"
RETAIL_TYPE_ID = 1
CHANGELOG_LIMIT = 18000
# Cloudflare (error 1010) rejects the default Python-urllib signature on the upload endpoint.
USER_AGENT = "InspectForEllesmereUI-release"


def interface_versions(toc_path):
    text = Path(toc_path).read_text(encoding="utf-8-sig", errors="replace")
    match = re.search(r"^##\s*Interface:\s*(.+)$", text, re.MULTILINE)
    if not match:
        raise ValueError(f"TOC does not declare ## Interface: {toc_path}")
    values = [int(token) for token in re.split(r"[,\s]+", match.group(1).strip()) if token.isdigit()]
    if not values:
        raise ValueError(f"TOC ## Interface line has no version numbers: {toc_path}")
    return values


def interface_name(value):
    return f"{value // 10000}.{value // 100 % 100}.{value % 100}"


def resolve_game_versions(available, names):
    retail = [item for item in available if item.get("gameVersionTypeID") == RETAIL_TYPE_ID]
    chosen, missing = [], []
    for name in names:
        match = next((item for item in retail if item.get("name") == name), None)
        if match is None:
            match = next((item for item in available if item.get("name") == name), None)
        if match is None:
            missing.append(name)
        elif match["id"] not in chosen:
            chosen.append(match["id"])
    return chosen, missing


def api_get(url, token):
    request = urllib.request.Request(
        url, headers={"X-Api-Token": token, "Accept": "application/json",
                      "User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.loads(response.read().decode("utf-8"))


def already_uploaded(project, file_name):
    try:
        request = urllib.request.Request(
            FILES_URL.format(project=project),
            headers={"Accept": "application/json", "User-Agent": USER_AGENT})
        with urllib.request.urlopen(request, timeout=60) as response:
            data = json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, ValueError) as exc:
        print(f"warning: could not list existing files ({exc}); continuing", file=sys.stderr)
        return False
    files = data if isinstance(data, list) else data.get("data", [])
    return any(item.get("fileName") == file_name for item in files)


def api_upload(project, token, zip_path, metadata):
    boundary = uuid.uuid4().hex
    body = bytearray()
    body.extend(
        f'--{boundary}\r\nContent-Disposition: form-data; name="metadata"\r\n\r\n'
        f'{json.dumps(metadata, ensure_ascii=False)}\r\n'.encode("utf-8"))
    body.extend(
        f'--{boundary}\r\nContent-Disposition: form-data; name="file"; '
        f'filename="{zip_path.name}"\r\nContent-Type: application/zip\r\n\r\n'.encode("utf-8"))
    body.extend(zip_path.read_bytes())
    body.extend(f"\r\n--{boundary}--\r\n".encode("utf-8"))
    request = urllib.request.Request(
        UPLOAD_URL.format(project=project), data=bytes(body), method="POST",
        headers={"X-Api-Token": token, "Accept": "application/json", "User-Agent": USER_AGENT,
                 "Content-Type": f"multipart/form-data; boundary={boundary}"})
    with urllib.request.urlopen(request, timeout=600) as response:
        return json.loads(response.read().decode("utf-8"))


def read_changelog(path, tag):
    changelog = f"Release {tag}"
    if path:
        text = Path(path).read_text(encoding="utf-8", errors="replace").strip()
        if text:
            changelog = text
    if len(changelog) > CHANGELOG_LIMIT:
        changelog = changelog[:CHANGELOG_LIMIT].rstrip() + "\n\n... (truncated, see the GitHub release)"
    return changelog


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-id", type=int, required=True, help="CurseForge project ID")
    parser.add_argument("--zip", required=True, help="Installable addon ZIP (glob patterns allowed)")
    parser.add_argument("--tag", required=True, help="Release tag such as v2.3.4")
    parser.add_argument("--toc", default=str(ROOT / f"{ADDON}.toc"), help="TOC used for game versions")
    parser.add_argument("--changelog-file", help="Markdown changelog file to attach")
    parser.add_argument("--release-type", default="release", choices=("release", "beta", "alpha"))
    parser.add_argument("--token-env", default="CF_API_TOKEN", help="Environment variable with the API token")
    parser.add_argument("--dry-run", action="store_true", help="Print the upload metadata without uploading")
    args = parser.parse_args()

    matches = sorted(glob.glob(args.zip))
    if len(matches) != 1:
        parser.error(f"expected exactly one ZIP matching {args.zip!r}, found {len(matches)}")
    zip_path = Path(matches[0])
    if not zip_path.is_file():
        parser.error(f"not a file: {zip_path}")

    names = [interface_name(value) for value in interface_versions(args.toc)]
    changelog = read_changelog(args.changelog_file, args.tag)
    token = os.environ.get(args.token_env, "")

    if args.dry_run:
        print(f"project: {args.project_id}")
        print(f"file: {zip_path} ({zip_path.stat().st_size} bytes)")
        print(f"displayName: {args.tag}")
        print(f"releaseType: {args.release_type}")
        print(f"game versions: {', '.join(names)}")
        print(f"changelog: {len(changelog)} chars")
        if already_uploaded(args.project_id, zip_path.name):
            print(f"{zip_path.name} is already on CurseForge; a real upload would be skipped")
        else:
            print(f"{zip_path.name} is not on CurseForge yet; a real upload would proceed")
        if token:
            chosen, missing = resolve_game_versions(api_get(VERSIONS_URL, token), names)
            print(f"resolved version ids: {chosen}")
            for name in missing:
                print(f"warning: no CurseForge game version entry for {name}", file=sys.stderr)
        else:
            print(f"({args.token_env} not set; skipping game version lookup)")
        return 0

    if not token:
        parser.error(f"{args.token_env} is not set")

    if already_uploaded(args.project_id, zip_path.name):
        print(f"{zip_path.name} is already on CurseForge; skipping upload")
        return 0

    game_versions, missing = resolve_game_versions(api_get(VERSIONS_URL, token), names)
    for name in missing:
        print(f"warning: no CurseForge game version entry for {name}", file=sys.stderr)
    if not game_versions:
        raise SystemExit(f"no CurseForge game version matches {names}")

    metadata = {"changelog": changelog, "changelogType": "markdown",
                "displayName": args.tag, "releaseType": args.release_type,
                "gameVersions": game_versions}
    try:
        result = api_upload(args.project_id, token, zip_path, metadata)
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"CurseForge upload failed ({exc.code}): {detail}") from exc
    print(f"uploaded {zip_path.name} to CurseForge project {args.project_id} (file id {result.get('id')})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
