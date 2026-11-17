#!/usr/bin/env python3
"""Independent reconciliation and descriptive outputs for the candidate release."""
import csv
import json
import math
import statistics
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent
WORK = ROOT

def read(path):
    with path.open(newline='', encoding='utf-8-sig') as f:
        return list(csv.DictReader(f))

def save(path, rows):
    with path.open('w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)

trials = read(WORK / 'trial_level_108.csv')
pairs = read(WORK / 'country_record_453.csv')
old = read(ROOT / 'source/prior_country_record452.csv')
countries = read(WORK / 'results/country_expected_oe_all_scenarios.csv')
countries = [r for r in countries if r['scenario'] == 'Point']
assert len(trials) == len({r['study_id'] for r in trials}) == 108
assert len(pairs) == len({(r['study_id'], r['country_iso3']) for r in pairs}) == 453
new_set = {(r['study_id'], r['country_iso3']) for r in pairs}
old_set = {(r['study_id'], r['country_iso3']) for r in old}
assert new_set - old_set == {('NCT04361721', 'ITA')} and not old_set - new_set
assert all(p['study_id'] in {r['study_id'] for r in trials} for p in pairs)
assert len(countries) == 194
counts = Counter(p['country_iso3'] for p in pairs)
assert all(int(r['observed']) == counts[r['ISO3']] for r in countries)
assert math.isclose(sum(float(r['expected']) for r in countries), 453, rel_tol=1e-12)
assert len(counts) == 47 and counts['ITA'] == 24
no_country = sorted({t['study_id'] for t in trials} - {p['study_id'] for p in pairs})
assert no_country == ['NCT04334408', 'NCT07655440']

by_study = defaultdict(list)
for p in pairs: by_study[p['study_id']].append(p)
for t in trials:
    assert int(t['participations']) == len(by_study[t['study_id']])
income = Counter(p['income'] for p in pairs)
region = Counter(p['who_region'] for p in pairs)
years = [int(t['start_date_harmonized'][:4]) for t in trials if t['start_date_harmonized']]
geographic_scope = Counter('No eligible country' if len(by_study[t['study_id']]) == 0 else
                           'Single-country' if len(by_study[t['study_id']]) == 1 else 'Multicountry'
                           for t in trials)
def quantile_type7(values, p):
    values = sorted(values)
    position = (len(values) - 1) * p
    low = int(position)
    return values[low] + (values[min(low + 1, len(values) - 1)] - values[low]) * (position - low)

summary = {'trials': len(trials), 'with_country': len(trials) - len(no_country),
           'no_eligible_country': no_country, 'country_record_pairs': len(pairs),
           'countries': len(counts), 'income': dict(income), 'who_region': dict(region),
           'phase': dict(Counter(t['phase_harmonized'] for t in trials)),
           'sponsor_type': dict(Counter(t['sponsor_group_analysis'] for t in trials)),
           'scope': dict(geographic_scope), 'status': dict(Counter(t['status_harmonized'] for t in trials)),
           'year': {'min': min(years), 'max': max(years), 'median': statistics.median(years),
                    'quartiles_type7': [quantile_type7(years, .25), quantile_type7(years, .75)]},
           'antibodies': {drug: sum(drug in t['agent_analysis'].split('; ') for t in trials)
                          for drug in ['erenumab','fremanezumab','galcanezumab','eptinezumab']},
           'fda_period': dict(Counter(t['fda_period'] for t in trials))}
observed = sorted(int(c['observed']) for c in countries)
total = sum(observed)
summary['concentration'] = {'gini': 2*sum(i*v for i,v in enumerate(observed, 1))/(len(observed)*total)-(len(observed)+1)/len(observed),
                            'hhi': sum((v/total)**2 for v in observed),
                            'top5_share': sum(observed[-5:])/total,
                            'top10_share': sum(observed[-10:])/total}
(WORK/'results/cohort_summary.json').write_text(json.dumps(summary, indent=2)+'\n')

# Country ranking is based on unrounded values; zero is not a missing value.
ranked = sorted(countries, key=lambda c: (-float(c['oe']),c['ISO3']))
for i, row in enumerate(ranked, 1): row['oe_rank_descending'] = i
save(WORK/'results/supplementary_country_level_all_194.csv', ranked)

grouped = []
for name, field, options in [
        ('Phase', 'phase_harmonized', ['Phase 1','Phase 2','Phase 2/3','Phase 3','Phase 4','Not applicable','Not reported']),
        ('Sponsor type', 'sponsor_group_analysis', ['Industry','Non-industry','Unclear/not reported']),
        ('FDA period', 'fda_period', ['Before approval','On/after approval','Missing or insufficient precision'])]:
    for option in options:
        matched = [t for t in trials if t[field] == option]
        sample = [p for t in matched for p in by_study[t['study_id']]]
        row = {'dimension':name,'subgroup':option,'records':len(matched),'participations':len(sample)}
        for label in ['HIC','UMIC','LMIC','LIC']:
            n = sum(p['income'] == label for p in sample)
            row[label+'_n'] = n
            row[label+'_pct'] = 100*n/len(sample) if sample else ''
        grouped.append(row)
    assert sum(g['records'] for g in grouped if g['dimension'] == name) == 108, name
    assert sum(g['participations'] for g in grouped if g['dimension'] == name) == 453, name
save(WORK/'results/subgroup_descriptive.csv', grouped)
print(json.dumps(summary,indent=2))
