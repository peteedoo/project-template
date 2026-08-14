#!/usr/bin/env python3
"""Sync skills from starred GitHub repositories.

Behavior:
1) Fetch starred repositories (user-scoped if token provided, public stars otherwise).
2) Evaluate each repository for library growth potential.
3) Import all discovered skill folders (directories containing SKILL.md) from recommended repos.
4) Persist a snapshot and write markdown/json reports.
"""

from __future__ import annotations

import json
import os
import shutil
import sys
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from subprocess import CalledProcessError, run
from typing import Any
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
SNAPSHOT_PATH = ROOT / ".agents" / "state" / "starred-snapshot.json"
REPORT_JSON_PATH = ROOT / ".agents" / "reports" / "star-evaluations.json"
REPORT_MD_PATH = ROOT / ".agents" / "reports" / "star-evaluations.md"
IMPORTED_ROOT = ROOT / ".agents" / "skills" / "imported"
ATTRIBUTIONS_PATH = IMPORTED_ROOT / "ATTRIBUTIONS.generated.md"

PERMISSIVE_LICENSES = {
    "mit",
    "apache-2.0",
    "bsd-2-clause",
    "bsd-3-clause",
    "isc",
    "mpl-2.0",
    "unlicense",
}


@dataclass
class RepoEval:
    full_name: str
    html_url: str
    description: str
    stargazers_count: int
    language: str
    license_spdx: str
    default_branch: str
    skill_paths: list[str]
    score: int
    recommendation: str
    rationale: list[str]
    is_new_star: bool


def getenv_int(name: str, default: int) -> int:
    raw = os.getenv(name)
    if not raw:
        return default
    try:
        return int(raw)
    except ValueError:
        return default


def request_json(url: str, *, token: str | None = None, accept: str = "application/vnd.github+json") -> Any:
    headers = {
        "Accept": accept,
        "User-Agent": "project-template-star-sync",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = Request(url, headers=headers)
    with urlopen(req) as resp:
        payload = resp.read().decode("utf-8")
    return json.loads(payload)


def fetch_starred_repos(
    username: str | None,
    token: str | None,
    max_repos: int,
    use_authenticated_user: bool,
) -> list[dict[str, Any]]:
    repos: list[dict[str, Any]] = []
    page = 1
    per_page = min(100, max_repos)

    if token and use_authenticated_user:
        endpoint = "https://api.github.com/user/starred"
    else:
        if not username:
            raise ValueError("STARRED_GITHUB_USERNAME is required unless STAR_SYNC_USE_AUTHENTICATED_USER=true.")
        endpoint = f"https://api.github.com/users/{username}/starred"

    while len(repos) < max_repos:
        query = urlencode({"per_page": per_page, "page": page})
        url = f"{endpoint}?{query}"
        batch = request_json(url, token=token)
        if not batch:
            break
        repos.extend(batch)
        if len(batch) < per_page:
            break
        page += 1

    return repos[:max_repos]


def load_previous_snapshot() -> set[str]:
    if not SNAPSHOT_PATH.exists():
        return set()
    data = json.loads(SNAPSHOT_PATH.read_text(encoding="utf-8"))
    return {entry["full_name"] for entry in data.get("repos", [])}


def save_snapshot(repos: list[dict[str, Any]]) -> None:
    SNAPSHOT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "repos": [{"full_name": repo["full_name"]} for repo in repos],
    }
    SNAPSHOT_PATH.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def fetch_repo_tree(repo: dict[str, Any], token: str | None) -> list[dict[str, Any]]:
    owner = repo["owner"]["login"]
    name = repo["name"]
    branch = repo["default_branch"]
    url = f"https://api.github.com/repos/{owner}/{name}/git/trees/{branch}?recursive=1"
    try:
        data = request_json(url, token=token)
    except HTTPError as exc:
        print(f"warning: failed tree lookup for {owner}/{name}: {exc}", file=sys.stderr)
        return []
    return data.get("tree", [])


def extract_skill_paths(tree: list[dict[str, Any]]) -> list[str]:
    paths: list[str] = []
    for item in tree:
        path = item.get("path", "")
        if item.get("type") != "blob":
            continue
        if path.endswith("/SKILL.md") or path == "SKILL.md":
            paths.append(path)
    return sorted(paths)


def compute_score(repo: dict[str, Any], skill_paths: list[str]) -> tuple[int, list[str]]:
    score = 0
    rationale: list[str] = []

    if skill_paths:
        score += 50
        rationale.append(f"Contains {len(skill_paths)} SKILL.md file(s).")
    else:
        rationale.append("No SKILL.md files discovered.")

    stars = int(repo.get("stargazers_count", 0))
    if stars >= 500:
        score += 20
        rationale.append("Strong social proof (500+ stars).")
    elif stars >= 100:
        score += 12
        rationale.append("Moderate social proof (100+ stars).")
    elif stars >= 20:
        score += 6
        rationale.append("Some social proof (20+ stars).")

    spdx = (repo.get("license") or {}).get("spdx_id") or ""
    if spdx.lower() in PERMISSIVE_LICENSES:
        score += 20
        rationale.append(f"Permissive license ({spdx}).")
    elif spdx and spdx != "NOASSERTION":
        rationale.append(f"Non-permissive or unclear license ({spdx}).")
    else:
        rationale.append("No license metadata found.")

    text_fields = " ".join(
        [
            repo.get("name", ""),
            repo.get("description") or "",
            repo.get("homepage") or "",
        ]
    ).lower()
    keyword_hits = sum(1 for kw in ("skill", "agent", "cursor", "claude", "codex") if kw in text_fields)
    if keyword_hits >= 2:
        score += 10
        rationale.append("Repository metadata aligns with agent-skill domain.")
    elif keyword_hits == 1:
        score += 5
        rationale.append("Repository metadata partially aligns with agent-skill domain.")

    return min(100, score), rationale


def recommendation(score: int, skill_paths: list[str], license_spdx: str) -> str:
    if not skill_paths:
        return "skip-no-skills"
    if license_spdx.lower() not in PERMISSIVE_LICENSES:
        return "review-license"
    if score >= 70:
        return "import-now"
    if score >= 50:
        return "import-with-review"
    return "defer"


def run_git_clone(url: str, directory: Path) -> None:
    try:
        run(
            ["git", "clone", "--depth=1", url, str(directory)],
            check=True,
            capture_output=True,
            text=True,
        )
    except CalledProcessError as exc:
        print(f"warning: clone failed for {url}: {exc.stderr}", file=sys.stderr)
        raise


def normalize_relative_skill_dir(skill_path: str) -> str:
    skill_dir = str(Path(skill_path).parent)
    if "/skills/" in skill_dir:
        return skill_dir.split("/skills/", 1)[1]
    if skill_dir.startswith("skills/"):
        return skill_dir.split("skills/", 1)[1]
    return Path(skill_dir).name


def copy_skill_dirs(repo_slug: str, checkout_dir: Path, skill_paths: list[str]) -> list[str]:
    copied: list[str] = []
    dest_repo_root = IMPORTED_ROOT / repo_slug
    if dest_repo_root.exists():
        shutil.rmtree(dest_repo_root)
    for skill_path in skill_paths:
        src_parent = Path(skill_path).parent
        if str(src_parent) == ".":
            # Root-level SKILL.md: do not mirror the entire repository.
            # Import only the root skill contract and common companion folders.
            dest_dir = dest_repo_root / "root-skill"
            if dest_dir.exists():
                shutil.rmtree(dest_dir)
            dest_dir.mkdir(parents=True, exist_ok=True)

            root_skill = checkout_dir / "SKILL.md"
            if root_skill.exists():
                shutil.copy2(root_skill, dest_dir / "SKILL.md")

            for aux_name in ("references", "scripts", "assets"):
                aux_src = checkout_dir / aux_name
                if aux_src.exists() and aux_src.is_dir():
                    shutil.copytree(
                        aux_src,
                        dest_dir / aux_name,
                        ignore=shutil.ignore_patterns(".git", ".git/*"),
                    )
        else:
            src_dir = checkout_dir / src_parent
            rel_dir = normalize_relative_skill_dir(skill_path)
            dest_dir = dest_repo_root / rel_dir
            if dest_dir.exists():
                shutil.rmtree(dest_dir)
            dest_dir.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(
                src_dir,
                dest_dir,
                ignore=shutil.ignore_patterns(".git", ".git/*"),
            )
        copied.append(str(dest_dir.relative_to(ROOT)))
    return copied


def sanitize_repo_slug(full_name: str) -> str:
    return full_name.lower().replace("/", "--")


def write_reports(evals: list[RepoEval], copied_skills: dict[str, list[str]]) -> None:
    REPORT_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    json_payload = {
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "evaluations": [
            {
                "full_name": e.full_name,
                "html_url": e.html_url,
                "description": e.description,
                "stargazers_count": e.stargazers_count,
                "language": e.language,
                "license_spdx": e.license_spdx,
                "skill_paths": e.skill_paths,
                "score": e.score,
                "recommendation": e.recommendation,
                "rationale": e.rationale,
                "is_new_star": e.is_new_star,
                "copied_skill_dirs": copied_skills.get(e.full_name, []),
            }
            for e in evals
        ],
    }
    REPORT_JSON_PATH.write_text(json.dumps(json_payload, indent=2) + "\n", encoding="utf-8")

    new_items = [e for e in evals if e.is_new_star]
    lines = [
        "# Star Skill Evaluation Report",
        "",
        f"Generated: {datetime.now(timezone.utc).isoformat()}",
        "",
        f"- Total starred repos scanned: {len(evals)}",
        f"- New stars since last snapshot: {len(new_items)}",
        f"- Repos imported this run: {sum(1 for v in copied_skills.values() if v)}",
        "",
        "## New stars",
        "",
        "| Repo | Score | Recommendation | Skills | Imported |",
        "| --- | ---: | --- | ---: | --- |",
    ]
    for e in sorted(new_items, key=lambda x: x.score, reverse=True):
        imported = "yes" if copied_skills.get(e.full_name) else "no"
        lines.append(
            f"| [{e.full_name}]({e.html_url}) | {e.score} | {e.recommendation} | {len(e.skill_paths)} | {imported} |"
        )

    lines.extend(
        [
            "",
            "## Imported repositories (this run)",
            "",
        ]
    )
    if not copied_skills:
        lines.append("- None")
    else:
        for repo_name, paths in copied_skills.items():
            lines.append(f"- `{repo_name}`")
            for path in paths:
                lines.append(f"  - `{path}`")

    REPORT_MD_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_generated_attributions(evals: list[RepoEval], copied_skills: dict[str, list[str]]) -> None:
    IMPORTED_ROOT.mkdir(parents=True, exist_ok=True)
    lines = [
        "# Generated Attributions for Imported Skills",
        "",
        "This file is generated by `scripts/sync_starred_skills.py`.",
        "",
    ]
    imported_evals = [e for e in evals if copied_skills.get(e.full_name)]
    if not imported_evals:
        lines.append("No imported sources in this run.")
    else:
        for e in sorted(imported_evals, key=lambda x: x.full_name):
            lines.extend(
                [
                    f"## {e.full_name}",
                    "",
                    f"- Source: {e.html_url}",
                    f"- License: {e.license_spdx or 'Unknown'}",
                    "- Imported skill directories:",
                ]
            )
            for p in copied_skills[e.full_name]:
                lines.append(f"  - `{p}`")
            lines.append("")

    ATTRIBUTIONS_PATH.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


def main() -> int:
    username = os.getenv("STARRED_GITHUB_USERNAME", "").strip() or None
    token = os.getenv("GH_STARS_TOKEN", "").strip() or None
    use_authenticated_user = os.getenv("STAR_SYNC_USE_AUTHENTICATED_USER", "false").lower() == "true"
    max_repos = getenv_int("STAR_SYNC_MAX_REPOS", 200)

    previous = load_previous_snapshot()
    repos = fetch_starred_repos(username, token, max_repos, use_authenticated_user)
    if not repos:
        print("No starred repos found; nothing to sync.")
        save_snapshot([])
        return 0

    evaluations: list[RepoEval] = []
    copied_skills: dict[str, list[str]] = {}

    for repo in repos:
        tree = fetch_repo_tree(repo, token)
        skill_paths = extract_skill_paths(tree)
        score, rationale = compute_score(repo, skill_paths)
        spdx = ((repo.get("license") or {}).get("spdx_id") or "").strip()
        rec = recommendation(score, skill_paths, spdx)
        full_name = repo["full_name"]
        evaluations.append(
            RepoEval(
                full_name=full_name,
                html_url=repo["html_url"],
                description=repo.get("description") or "",
                stargazers_count=int(repo.get("stargazers_count", 0)),
                language=repo.get("language") or "",
                license_spdx=spdx,
                default_branch=repo.get("default_branch") or "main",
                skill_paths=skill_paths,
                score=score,
                recommendation=rec,
                rationale=rationale,
                is_new_star=full_name not in previous,
            )
        )

    IMPORTED_ROOT.mkdir(parents=True, exist_ok=True)

    # Import all skills for recommended repos.
    for e in evaluations:
        if e.recommendation not in {"import-now", "import-with-review"}:
            continue
        if not e.skill_paths:
            continue
        repo_slug = sanitize_repo_slug(e.full_name)
        clone_url = f"https://github.com/{e.full_name}.git"
        with tempfile.TemporaryDirectory(prefix=f"star-sync-{repo_slug}-") as tmp:
            checkout = Path(tmp) / "repo"
            try:
                run_git_clone(clone_url, checkout)
                copied = copy_skill_dirs(repo_slug, checkout, e.skill_paths)
                copied_skills[e.full_name] = copied
            except CalledProcessError:
                continue

    save_snapshot(repos)
    write_reports(evaluations, copied_skills)
    write_generated_attributions(evaluations, copied_skills)

    imported_count = sum(len(v) for v in copied_skills.values())
    print(f"Scanned repos: {len(repos)}")
    print(f"Imported skill directories: {imported_count}")
    print(f"Report: {REPORT_MD_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
