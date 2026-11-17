#!/usr/bin/env python3
"""Reuse the reviewed whole-record permutation and wild-bootstrap routines."""
import ast
import hashlib
import json
from itertools import combinations
from pathlib import Path
import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent
W = ROOT
ORIGINAL = ROOT / 'source/clustered_original_analysis.py'
CFG = {'seed': 20261029, 'resamples': 99999, 'batch_size': 2000, 'alpha': .05}
RNG = np.random.default_rng(CFG['seed'])
income_levels = ['HIC', 'UMIC', 'LMIC', 'LIC']
trials = pd.read_csv(W / 'trial_level_108.csv').set_index('study_id')
pairs = pd.read_csv(W / 'country_record_453.csv')
assert len(trials) == 108 and len(pairs) == 453 and trials.index.is_unique
profiles = pd.crosstab(pairs.study_id, pairs.income).reindex(index=trials.index, columns=income_levels, fill_value=0)
records = trials.copy()
for level in income_levels:
    records[level] = profiles[level]
records['participations'] = profiles.sum(axis=1)
phase_map = {'Phase 1':'Phases 1-2', 'Phase 2':'Phases 1-2', 'Phase 2/3':'Phase 2/3',
             'Phase 3':'Phase 3', 'Phase 4':'Phase 4', 'Not applicable':'Not applicable',
             'Not reported':'Not reported', 'Unresolved':'Unresolved phase'}
records['phase_group'] = records.phase_harmonized.map(phase_map)
assert records.phase_group.notna().all()
records['sponsor_group'] = records.sponsor_group_analysis
records['scope_group'] = records.participations.map(lambda n: 'No eligible country' if n == 0 else
                                                   'Single-country' if n == 1 else 'Multicountry')

# Compile exactly the named functions from the prior audited implementation.
source = ORIGINAL.read_text(encoding='utf8')
tree = ast.parse(source)
names = {'pearson_distance', 'cluster_permutation', 'scope_wild_cluster', 'holm'}
selected = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name in names]
assert {n.name for n in selected} == names
exec(compile(ast.Module(body=selected, type_ignores=[]), str(ORIGINAL), 'exec'), globals())

phase = ['Phases 1-2','Phase 3','Phase 4']
sponsor = ['Industry','Non-industry','Unclear/not reported']
tests = [cluster_permutation(records,'phase_group',phase,'Study phase'),
         cluster_permutation(records,'sponsor_group',sponsor,'Lead sponsor type'),
         scope_wild_cluster(records)]
pairwise = []
for test, variable, levels in zip(tests[:2],['phase_group','sponsor_group'],[phase,sponsor]):
    if test['p'] < CFG['alpha']:
        current = [cluster_permutation(records,variable,list(pair),test['stratum']) for pair in combinations(levels,2)]
        for item, adjusted in zip(current,holm([item['p'] for item in current])):
            item['p_holm_within_stratum'] = float(adjusted)
        pairwise.extend(current)

strata = [('Study phase','phase_group', phase + ['Phase 2/3','Not applicable','Not reported','Unresolved phase']),
          ('Lead sponsor type','sponsor_group',sponsor),
          ('Geographic scope','scope_group',['Single-country','Multicountry','No eligible country'])]
rows=[]
for title, variable, levels in strata:
    for level in levels:
        z=records[records[variable].eq(level)]
        if len(z)==0: continue
        total=int(z.participations.sum())
        row={'Stratum':title,'Subgroup':level,'Records, n':len(z), 'Participations, n':total}
        for income in income_levels:
            number=int(z[income].sum())
            row[income+', n (%)']=f'{number} ({100*number/total:.1f})' if total else 'Not applicable'
        row['Global P']=(next(t['p'] for t in tests if t['stratum']==title)
                         if not any(x['Stratum']==title for x in rows) else '')
        rows.append(row)
    assert sum(x['Records, n'] for x in rows if x['Stratum']==title)==108
    assert sum(x['Participations, n'] for x in rows if x['Stratum']==title)==453
pd.DataFrame(rows).to_csv(W/'results/stratified_income_candidate.csv',index=False)
out={'global':tests, 'pairwise':pairwise, 'seed':CFG['seed'], 'resamples':CFG['resamples'],
     'source_sha256':hashlib.sha256(ORIGINAL.read_bytes()).hexdigest(),
     'note':'Source functions are reused unchanged; the record is included by manual adjudication with registry conflict.'}
(W/'results/clustered_tests_candidate.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps(out,indent=2))
