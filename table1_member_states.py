#!/usr/bin/env python3
"""WHO Member States per Table 1 Panel B subgroup.

For each subgroup of Table 1 Panel B, counts the distinct WHO Member States
with at least one country-trial participation, from the 453 primary pairs.
Antibody categories overlap (a trial evaluating several antibodies counts in
each), as in the table. The script stops unless its participation and
high-income counts equal the published Panel B values listed below.

Usage:
  python3 -I table1_member_states.py <data_dir> <out.csv>
  data_dir: extracted public_data_and_reference_results.zip
"""
import csv, sys, collections

data_dir, out_csv = sys.argv[1:3]
rows = list(csv.DictReader(open(f'{data_dir}/country_record_453.csv')))
assert len(rows) == 453

# (column, value in the data, label in Table 1) in table order.
groups = [
    ('Study phase', 'phase', [('Phase 1', '1'), ('Phase 2', '2'), ('Phase 2/3', '2/3'), ('Phase 3', '3'),
                              ('Phase 4', '4'), ('Not applicable', 'Not applicable'), ('Not reported', 'Not reported')]),
    ('Sponsor type', 'sponsor', [('Industry', 'Industry'), ('Non-industry', 'Non-industry'),
                                 ('Unclear/not reported', 'Unclear/not reported')]),
    ('Recruitment status', 'recruitment_status', [
        ('Completed', 'Completed'), ('Recruiting', 'Recruiting'), ('Active, not recruiting', 'Active, not recruiting'),
        ('Not yet recruiting', 'Not yet recruiting'), ('Terminated', 'Terminated'), ('Withdrawn', 'Withdrawn'),
        ('Suspended', 'Suspended'), ('Unknown/not reported', 'Unknown/not reported')]),
    ('FDA approval period', 'fda_period', [('Before approval', 'Before approval'), ('On/after approval', 'On/after approval'),
                                           ('Missing or insufficient precision', 'Missing or insufficient precision')]),
    ('Anti-CGRP antibody', 'agents', [('erenumab', 'erenumab'), ('fremanezumab', 'fremanezumab'),
                                      ('galcanezumab', 'galcanezumab'), ('eptinezumab', 'eptinezumab'),
                                      ('Not specified', 'Not specified')]),
]
# Published Table 1 Panel B values: (participations, high-income participations).
published = {
    '1': (15, 14), '2': (38, 37), '2/3': (2, 2), '3': (301, 247), '4': (89, 84), 'Not applicable': (7, 7),
    'Not reported': (1, 1), 'Industry': (426, 367), 'Non-industry': (20, 20), 'Unclear/not reported': (7, 5),
    'Completed': (361, 317), 'Recruiting': (41, 30), 'Active, not recruiting': (37, 31), 'Not yet recruiting': (0, 0),
    'Terminated': (4, 4), 'Withdrawn': (2, 2), 'Suspended': (0, 0), 'Unknown/not reported': (8, 8),
    'Before approval': (193, 172), 'On/after approval': (260, 220), 'Missing or insufficient precision': (0, 0),
    'erenumab': (180, 158), 'fremanezumab': (98, 92), 'galcanezumab': (78, 68), 'eptinezumab': (105, 82),
    'Not specified': (1, 1),
}

def values(r, col):
    return {v.strip() for v in r[col].split(';')} if col == 'agents' else {r[col]}

out = []
for heading, col, cats in groups:
    for value, label in cats:
        z = [r for r in rows if value in values(r, col)]
        got = (len(z), sum(r['income'] == 'HIC' for r in z))
        assert got == published[label], (label, got, published[label])
        out.append((heading, label, len({r['country_iso3'] for r in z}), len(z)))

with open(out_csv, 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['group', 'subgroup', 'who_member_states', 'participations'])
    w.writerows(out)
total = len({r['country_iso3'] for r in rows})
print(f'{len(out)} subgroups; {total} WHO Member States overall')
for g, l, m, n in out: print(f'{g} | {l}: {m} Member States, {n} participations')
