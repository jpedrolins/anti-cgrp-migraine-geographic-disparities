#!/usr/bin/env python3
"""Validate registry data or reproduce the analysis with exact external inputs."""
from pathlib import Path
import argparse
import csv
import hashlib
import json
import shutil
import subprocess
import sys
import zipfile


def read_csv(path):
    with path.open(newline='', encoding='utf-8-sig') as handle:
        return list(csv.DictReader(handle))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--external-inputs', type=Path)
    parser.add_argument('--validate-only', action='store_true')
    parser.add_argument('--clustered', action='store_true')
    parser.add_argument('--figures', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    output = args.output.resolve()
    if output.exists():
        parser.error('Output already exists; use a new directory.')
    requirements = json.loads((root / 'EXTERNAL_INPUTS.json').read_text())
    if not args.validate_only:
        if not shutil.which('Rscript'):
            parser.error('Rscript is required for the full analysis.')
        if not args.external_inputs:
            parser.error('Full analysis requires --external-inputs. See DATA_ACCESS.md; use --validate-only to check registry counts without them.')
        for entry in requirements:
            path = args.external_inputs / entry['path']
            if not path.is_file():
                parser.error('Missing external input: ' + entry['path'])
            if hashlib.sha256(path.read_bytes()).hexdigest() != entry['sha256']:
                parser.error('External input differs from reviewed snapshot: ' + entry['path'])
    with zipfile.ZipFile(root / 'public_data_and_reference_results.zip') as archive:
        for member in archive.infolist():
            if not (output / member.filename).resolve().is_relative_to(output):
                raise ValueError('Unsafe archive path: ' + member.filename)
        output.mkdir(parents=True)
        archive.extractall(output)
    for entry in json.loads((output / 'ARCHIVE_MANIFEST.json').read_text()):
        assert hashlib.sha256((output / entry['path']).read_bytes()).hexdigest() == entry['sha256']
    trials = read_csv(output / 'trial_level_108.csv')
    pairs = read_csv(output / 'country_record_453.csv')
    universe = read_csv(output / 'source_data/who_regions.csv')
    assert len(trials) == len({r['study_id'] for r in trials}) == 108
    assert len(pairs) == len({(r['study_id'], r['country_iso3']) for r in pairs}) == 453
    assert len({r['country_iso3'] for r in pairs}) == 47
    assert len(universe) == len({r['country_iso3'] for r in universe}) == 194
    assert {r['country_iso3'] for r in pairs} <= {r['country_iso3'] for r in universe}
    assert {r['study_id'] for r in trials} - {r['study_id'] for r in pairs} == {'NCT04334408', 'NCT07655440'}
    assert {(r['study_id'], r['country_iso3']) for r in pairs if r['study_id'] == 'NCT04361721'} == {('NCT04361721', 'ITA')}
    print('Validated: 108 records; 453 unique pairs; 47 participating countries; 194-country universe.')
    if args.validate_only:
        print('Validation only: no burden-offset or socioeconomic model was run.')
        return
    for entry in requirements:
        target = output / entry['path']
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(args.external_inputs / entry['path'], target)
    for path in root.iterdir():
        if path.suffix in {'.R', '.py'} and path.name != Path(__file__).name:
            shutil.copy2(path, output / path.name)
    shutil.copytree(output / 'results', output / 'reference_results')
    tasks = [('Rscript', 'analysis.R'), ('Rscript', 'table3_covariates.R'),
             ('Rscript', 'bounding_haq_rd.R'), ('Rscript', 'pre_post_income_test.R'),
             (sys.executable, 'summarize_current.py')]
    if args.clustered:
        tasks.append((sys.executable, 'clustered_analysis.py'))
    if args.figures:
        tasks.extend(('Rscript', name) for name in [
            'figure2_vertical.R', 'figure2_global_distribution.R', 'build_figure3.R', 'build_figure_4panel.R',
            'build_supplementary_drug_figure.R', 'build_supplementary_income_forest.R', 'temporal_income.R'])
    for task in tasks:
        print('Running:', ' '.join(task), flush=True)
        subprocess.run(task, cwd=output, check=True)


if __name__ == '__main__':
    main()
