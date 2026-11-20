#!/usr/bin/env python3
"""Figure 1: PRISMA 2020 flow diagram (identification of studies via registers).

Layout: PRISMA 2020 template colours (header #FFC000, phase labels #9CC2E5), Arial,
thin black boxes, boxes of a row drawn at the same height. Screening is a single
full-record stage, so the template's "records screened" and "reports sought"
boxes are replaced by one "full registry records assessed" box (footnote).

The counts come from figures/figure1/Figure_1_PRISMA_counts.csv. Before drawing,
the script checks them:
  * internal arithmetic (167 = 109 + 58; 35 = 19 + 14 + 2; 132 = 167 - 35;
    24 = sum of reasons; 108 = 132 - 24);
  * against the public package: CURRENT_RELEASE.json, trial_level_108.csv and
    Supplementary Table S2 (24 exclusions, count per reason);
  * optionally (--restricted DIR), against the restricted registry processing
    files: harmonized_registry_records.json (109 + 58), automatic_exact_nct_matches.csv
    (19), manual_review_decisions_final.csv (14 duplicates) and
    deduplicated_registry_records_complete.json (134 = 167 - 19 - 14).
It stops on any mismatch.

Usage:
  python3 -I figure1_prisma.py <data_dir> figures/figure1 [--restricted <processed_dir>]
  data_dir: extracted public_data_and_reference_results.zip
Outputs: Figure_1_PRISMA_2020.svg, .png (3600 px wide) and .pdf (from the same
SVG with librsvg through R's rsvg package), and Figure_1_PRISMA_2020_validation.json.
"""
import csv, datetime, hashlib, html, json, subprocess, sys
from pathlib import Path

args = sys.argv[1:]
restricted = None
if "--restricted" in args:
    i = args.index("--restricted")
    restricted = Path(args[i + 1])
    del args[i:i + 2]
data_dir, out_dir = Path(args[0]), Path(args[1])
repo = Path(__file__).resolve().parent
rows = list(csv.DictReader(open(out_dir / "Figure_1_PRISMA_counts.csv", encoding="utf-8")))
get = lambda item: [r for r in rows if r["item"] == item]
one = lambda item: int(get(item)[0]["n"])
src = {r["label"]: int(r["n"]) for r in get("source")}
dups = [(r["label"], int(r["n"])) for r in get("duplicate_type")]
reasons = [(r["label"], int(r["n"]), r["s2_reason"]) for r in get("reason")]
N = dict(ctg=src["ClinicalTrials.gov"], ictrp=src["WHO ICTRP"], total=one("total"), dup=one("duplicates"),
         assessed=one("assessed"), excluded=one("excluded"), included=one("included"), reports=one("reports"))

# ── checks ──
release = json.load(open(repo / "CURRENT_RELEASE.json"))
trials = list(csv.DictReader(open(data_dir / "trial_level_108.csv", encoding="utf-8")))
s2 = list(csv.DictReader(open(data_dir / "results/native_document_tables/supplement_table_02.csv", encoding="utf-8")))
ids = {t["study_id"] for t in trials}
checks = {
    "total = ClinicalTrials.gov + WHO ICTRP": N["total"] == N["ctg"] + N["ictrp"],
    "duplicates = sum of duplicate types": N["dup"] == sum(n for _, n in dups),
    "assessed = total - duplicates": N["assessed"] == N["total"] - N["dup"],
    "excluded = sum of reasons": N["excluded"] == sum(n for _, n, _ in reasons),
    "included = assessed - excluded": N["included"] == N["assessed"] - N["excluded"] == N["reports"],
    "duplicates = CURRENT_RELEASE.json": N["dup"] == release["duplicates_removed"],
    "excluded = CURRENT_RELEASE.json": N["excluded"] == release["excluded_records"],
    "included = CURRENT_RELEASE.json": N["included"] == release["records"],
    "included = trial_level_108.csv (unique)": N["included"] == len(trials) == len(ids),
    "excluded = Supplementary Table S2 rows": N["excluded"] == len(s2),
    "each reason = Supplementary Table S2 count": all(sum(r["Reason for exclusion"] == lab for r in s2) == n for _, n, lab in reasons),
    "S2 reasons all mapped": {r["Reason for exclusion"] for r in s2} == {lab for _, _, lab in reasons},
    "included and excluded are disjoint": not (ids & {r["Registry identifier"] for r in s2}),
}
if restricted:
    harm = json.load(open(restricted / "harmonized_registry_records.json"))
    recs = harm["records"] if isinstance(harm, dict) else harm
    dedup = json.load(open(restricted / "deduplicated_registry_records_complete.json"))
    drecs = dedup["records"] if isinstance(dedup, dict) else dedup
    auto = list(csv.DictReader(open(restricted / "automatic_exact_nct_matches.csv", encoding="utf-8")))
    manual = list(csv.DictReader(open(restricted / "manual_review_decisions_final.csv", encoding="utf-8")))
    checks.update({
        "ClinicalTrials.gov = harmonized records": N["ctg"] == sum(r["source"] == "ClinicalTrials.gov" for r in recs),
        "WHO ICTRP = harmonized records": N["ictrp"] == sum(r["source"] == "ICTRP" for r in recs),
        "automated exact NCT matches = automatic_exact_nct_matches.csv": dups[0][1] == len(auto),
        "manual duplicates = manual review decisions": dups[1][1] == sum(r["decision"] == "duplicate" for r in manual),
        "deduplicated records = total - automated - manual": len(drecs) == N["total"] - dups[0][1] - dups[1][1],
    })
for k, ok in checks.items():
    print(("ok   " if ok else "FAIL ") + k)
if not all(checks.values()):
    sys.exit("stopped: counts do not match the sources")

# ── drawing ──
HEADER_FILL, PHASE_FILL, FONT = "#FFC000", "#9CC2E5", "Arial, Helvetica, sans-serif"
W, LH, PAD, FS, GAP = 900, 18, 12, 13.5, 34
xL, wL, xR, wR = 90, 300, 450, 430
e, parts = html.escape, []


def box(x, y, w, h, lines, center):
    parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#fff" stroke="#000" stroke-width="1"/>')
    top = y + (h - LH * len(lines)) / 2 + LH * 0.74
    for i, (t, indent) in enumerate(lines):
        ty = top + LH * i
        parts.append(f'<text x="{x + w / 2}" y="{ty:.1f}" text-anchor="middle" font-size="{FS}">{e(t)}</text>' if center else
                     f'<text x="{x + PAD + indent}" y="{ty:.1f}" font-size="{FS}">{e(t)}</text>')


def arrow(x1, y1, x2, y2):
    parts.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#000" stroke-width="1.2" marker-end="url(#ah)"/>')


def pair(y, left, right, left_center=True):
    h = 2 * PAD + LH * max(len(left), len(right))
    box(xL, y, wL, h, left, left_center)
    box(xR, y, wR, h, right, False)
    arrow(xL + wL, y + h / 2, xR - 1, y + h / 2)
    return h


def phase(label, y0, y1):
    parts.append(f'<rect x="20" y="{y0}" width="46" height="{y1 - y0}" rx="8" fill="{PHASE_FILL}"/>'
                 f'<text transform="translate(48,{(y0 + y1) / 2}) rotate(-90)" text-anchor="middle" font-size="14" font-weight="bold">{e(label)}</text>')


L = lambda *t: [(x, 0) for x in t]
I = lambda *t: [(x, 16) for x in t]
y = 74
h = pair(y, L("Records identified from:") + I(f"ClinicalTrials.gov (n = {N['ctg']})", f"WHO ICTRP (n = {N['ictrp']})")
         + L(f"Total records identified (n = {N['total']})"),
         L(f"Duplicate records removed (n = {N['dup']})") + I(*[f"{l} (n = {n})" for l, n in dups]), left_center=False)
phase("Identification", y, y + h)
arrow(xL + wL / 2, y + h, xL + wL / 2, y + h + GAP - 1)
y += h + GAP
h = pair(y, L("Full registry records assessed", "for eligibility", f"(n = {N['assessed']})"),
         L(f"Full registry records excluded (n = {N['excluded']})") + I(*[f"{l} (n = {n})" for l, n, _ in reasons]))
phase("Full-record screening", y, y + h)
arrow(xL + wL / 2, y + h, xL + wL / 2, y + h + GAP - 1)
y += h + GAP
h = 2 * PAD + LH * 4
box(xL, y, wL, h, L("Studies included in review", f"(n = {N['included']})",
                    "Registry records of included studies", f"(n = {N['reports']})"), True)
phase("Included", y, y + h)
y += h + 30
for t, col in [("All potentially eligible records were assessed using the complete registry entry; "
                "no preliminary title/abstract screening stage was performed.", "#000"),
               ("Source: Adapted from Page MJ, et al. BMJ. 2021;372:n71. doi:10.1136/bmj.n71.", "#333")]:
    parts.append(f'<text x="20" y="{y}" font-size="11.5" fill="{col}">{e(t)}</text>')
    y += 19
H = round(y + 8)
svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="{FONT}">'
       '<defs><marker id="ah" markerWidth="10" markerHeight="10" refX="9" refY="5" orient="auto" markerUnits="userSpaceOnUse">'
       '<path d="M0,0 L10,5 L0,10 z" fill="#000"/></marker></defs><rect width="100%" height="100%" fill="#fff"/>'
       f'<rect x="20" y="16" width="{xR + wR - 20}" height="40" rx="8" fill="{HEADER_FILL}"/>'
       f'<text x="{(20 + xR + wR) / 2}" y="42" text-anchor="middle" font-size="15.5" font-weight="bold">Identification of studies via registers</text>'
       f'{"".join(parts)}</svg>')

out_dir.mkdir(parents=True, exist_ok=True)
stem = out_dir / "Figure_1_PRISMA_2020"
Path(f"{stem}.svg").write_text(svg, encoding="utf-8")
r = subprocess.run(["Rscript", "-e", f'rsvg::rsvg_png("{stem}.svg", "{stem}.png", width=3600); rsvg::rsvg_pdf("{stem}.svg", "{stem}.pdf")'],
                   capture_output=True, text=True)
if r.returncode:
    sys.exit("rsvg failed: " + r.stderr)
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
json.dump({"figure": "Figure 1", "generated": datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z"),
           "counts": "figures/figure1/Figure_1_PRISMA_counts.csv",
           "restricted_registry_checks": bool(restricted),
           "checks": {k: bool(v) for k, v in checks.items()},
           "input_sha256": {"Figure_1_PRISMA_counts.csv": sha(out_dir / "Figure_1_PRISMA_counts.csv"),
                            "trial_level_108.csv": sha(data_dir / "trial_level_108.csv"),
                            "supplement_table_02.csv": sha(data_dir / "results/native_document_tables/supplement_table_02.csv")},
           "output_sha256": {f"Figure_1_PRISMA_2020.{x}": sha(f"{stem}.{x}") for x in ("svg", "png", "pdf")}},
          open(out_dir / "Figure_1_PRISMA_2020_validation.json", "w"), indent=2)
print(f"written: {stem}.svg / .png / .pdf and validation JSON")
