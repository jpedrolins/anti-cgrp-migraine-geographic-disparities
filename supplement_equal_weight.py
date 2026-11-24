#!/usr/bin/env python3
"""Supplementary Table S13: primary participations versus equal trial weight.

In the primary analysis each country-trial pair counts once, so a trial that
recruited in several countries weighs more than a single-country trial. In the
equal-trial-weight sensitivity each trial contributes a total weight of 1,
split equally among its countries (1/k per country). Shares by World Bank
income group (FY2019) and WHO region are compared with the primary shares.
The 106 trials with geography contribute 106.00 in total.

The script stops unless the primary counts equal the published ones (453
pairs; income groups 392/42/19/0; regions 101/297/46/7/2/0) and the weights
sum to 106.

Usage:
  python3 -I supplement_equal_weight.py <data_dir> <out.csv>
  data_dir: extracted public_data_and_reference_results.zip
"""
import csv, sys, collections

data_dir, out_csv = sys.argv[1:3]
rows = list(csv.DictReader(open(f'{data_dir}/country_record_453.csv', encoding='utf-8')))
assert len(rows) == 453
k = collections.Counter(r['study_id'] for r in rows)
assert len(k) == 106
for r in rows:
    r['w'] = 1 / k[r['study_id']]

income = [('High income', 'HIC'), ('Upper-middle income', 'UMIC'), ('Lower-middle income', 'LMIC'),
          ('Low income', 'LIC'), ('Unclassified', None)]
regions = ['Americas', 'Europe', 'Western Pacific', 'South-East Asia', 'Eastern Mediterranean', 'Africa']
known = {'HIC', 'UMIC', 'LMIC', 'LIC'}

def block(label, keyfun, cats):
    out = []
    n = collections.Counter(); w = collections.Counter()
    for r in rows:
        c = keyfun(r); n[c] += 1; w[c] += r['w']
    tn, tw = sum(n.values()), sum(w.values())
    assert tn == 453 and abs(tw - 106) < 1e-9
    out.append([label, '', '', ''])
    for name, key in cats:
        pn, pw = 100 * n[key] / tn, 100 * w[key] / tw
        out.append([name, f'{n[key]} ({pn:.1f})', f'{w[key]:.2f} ({pw:.1f})', (f'{pw - pn:+.1f}'.replace('-', '−') if round(pw - pn, 1) else '0.0')])
    out.append(['Total', f'{tn} (100.0)', f'{tw:.2f} (100.0)', '—'])
    return out, n

inc_rows, n_inc = block('World Bank income group', lambda r: r['income'] if r['income'] in known else None, income)
assert [n_inc[k_] for k_ in ('HIC', 'UMIC', 'LMIC', 'LIC')] == [392, 42, 19, 0]
reg_rows, n_reg = block('WHO region', lambda r: r['who_region'], [(x, x) for x in regions])
assert [n_reg[x] for x in regions] == [101, 297, 46, 7, 2, 0]

with open(out_csv, 'w', newline='', encoding='utf-8-sig') as f:
    wr = csv.writer(f)
    wr.writerow(['Group', 'Primary, n (%)', 'Equal trial weight, sum (%)', 'Difference, pp'])
    wr.writerows(inc_rows)
    # as in the manuscript, the first region row carries the block label
    for i, r in enumerate(reg_rows[1:-1]):
        wr.writerow([f'WHO region: {r[0]}' if i == 0 else r[0]] + r[1:])
    wr.writerow(reg_rows[-1])
print('wrote', out_csv)
