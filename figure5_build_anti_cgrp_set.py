#!/usr/bin/env python3
"""Anti-CGRP record sets for Figure 5, as country-trial pairs, at three stages
of the PRISMA flow:
  pre_dedup_167   all 167 records identified, before deduplication (a trial
                  registered twice contributes twice);
  post_dedup_132  the 132 records retained after deduplication, before
                  full-record eligibility assessment (Figure 5 main set);
  eligible_108    the 108 eligible trials (the primary 453 pairs).

Countries are read from the registry records of the 5 August 2026 snapshot:
ClinicalTrials.gov location countries, or the ICTRP "Countries" field. A jRCT
record without a listed country is Japan (the convention of the primary
dataset). Only the 194 WHO Member States are kept. Applied to the 108 included
records, the same rule must reproduce the 453 primary pairs exactly.

Usage:
  python3 -I figure5_build_anti_cgrp_set.py <harmonized.json> <dedup_complete.json> \
      <final_screening_source_snapshot.csv> <data_dir> <out.csv>
  harmonized.json: harmonized_registry_records.json (167 records, before deduplication)
  dedup_complete.json: deduplicated_registry_records_complete.json (134 records)
  final_screening_source_snapshot.csv: final full-record screening (132 records)
  data_dir: extracted public_data_and_reference_results.zip
"""
import csv, json, re, sys, unicodedata, collections

pre_json, dedup_json, screening_csv, data_dir, out_csv = sys.argv[1:6]

ref = {r['ISO3']: r for r in csv.DictReader(open(f'{data_dir}/results/country_expected_oe_all_scenarios.csv'))
       if r['scenario'] == 'Point'}
assert len(ref) == 194

def norm(x):
    x = unicodedata.normalize('NFKD', x).encode('ascii', 'ignore').decode()
    return re.sub(r'\s+', ' ', re.sub(r"[’'`]", '', x)).strip().lower()

name2iso = {norm(r['Country']): k for k, r in ref.items()}
alias = {'united states': 'USA', 'russia': 'RUS', 'russian federation': 'RUS', 'south korea': 'KOR',
         'korea, republic of': 'KOR', 'turkey (turkiye)': 'TUR', 'turkey': 'TUR', 'czech republic': 'CZE',
         'united kingdom': 'GBR', 'vietnam': 'VNM', 'netherlands': 'NLD', 'iran (islamic republic of)': 'IRN', 'iran': 'IRN'}
nonmember = {'taiwan', 'puerto rico', 'hong kong', 'macau', 'macao', 'kosovo', 'palestine'}

def iso(name):
    k = norm(name)
    if k in name2iso: return name2iso[k]
    if k in alias: return alias[k]
    if k in nonmember: return None
    sys.exit(f'Unmatched country name: {name!r}')

def countries(rec):
    raw = rec['raw']
    if rec['source'] == 'ClinicalTrials.gov':
        names = raw.get('contactsLocations.locations[].country') or []
    else:
        names = [x for x in (raw.get('Countries') or '').split(';') if x.strip()]
        if not names and rec['registry_id'].startswith('JPRN-'):
            names = ['Japan']
    return sorted({i for i in map(iso, names) if i})

records = json.load(open(dedup_json))['records']
screen = {r['trial_id']: r for r in csv.DictReader(open(screening_csv, encoding='utf-8'))}
assert len(screen) == 132
# The two records removed as duplicates in Rayyan (PRISMA: n = 2).
rayyan_dups = {'EUCTR2020-004509-30-ES', 'EUCTR2020-000661-16-DK'}
kept = [r for r in records if r['registry_id'] not in rayyan_dups]
assert len(records) == 134 and len(kept) == 132
assert {r['registry_id'] for r in kept} == set(screen), 'record set differs from the screening snapshot'

pairs = [(r['registry_id'], c) for r in kept for c in countries(r)]
assert len(pairs) == len(set(pairs))

primary = {(r['study_id'], r['country_iso3']) for r in csv.DictReader(open(f'{data_dir}/country_record_453.csv'))}
included = {k for k, r in screen.items() if r['final_decision'] == 'include'}
assert len(included) == 108
got = {p for p in pairs if p[0] in included}
assert got == primary, f'rule does not reproduce the 453 primary pairs: {sorted(got ^ primary)}'

pre = json.load(open(pre_json))['records']
assert len(pre) == 167
pre_pairs = [(r['record_key'], r['registry_id'], c) for r in pre for c in countries(r)]
assert len(pre_pairs) == len({(k, c) for k, _, c in pre_pairs})

rows = [('pre_dedup_167', k, s, c, '', '') for k, s, c in pre_pairs]
rows += [('post_dedup_132', s, s, c, screen[s]['final_decision'], screen[s]['final_exclusion_code']) for s, c in pairs]
rows += [('eligible_108', s, s, c, 'include', '') for s, c in pairs if s in included]
with open(out_csv, 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['set', 'record_key', 'study_id', 'country_iso3', 'income_fy2019', 'final_decision', 'final_exclusion_code'])
    for st, k, s, c, dec, code in sorted(rows):
        w.writerow([st, k, s, c, ref[c]['income'], dec, code])

for st in ['pre_dedup_167', 'post_dedup_132', 'eligible_108']:
    sub = [r for r in rows if r[0] == st]
    cnt = collections.Counter(ref[r[3]]['income'] for r in sub)
    print(f'{st}: {len({r[1] for r in sub})} records with pairs, {len(sub)} pairs;', dict(cnt))
