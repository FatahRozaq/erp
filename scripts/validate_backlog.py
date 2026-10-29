#!/usr/bin/env python3
"""Validate R-01 planning coverage and dependency links; no runtime tests."""
from collections import Counter
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs/roadmap'
REQUIREMENT = r'(?:FR|BR|NFR|US|AC)-[A-Z0-9]+-?\d*'
SLICE = r'(?:R|B|F|M|P2|P3|E|Z)-\d{2}\.\d+'
WEIGHTS = {'S': (2, 3), 'M': (4, 6), 'L': (7, 10)}


def main():
    failures = []
    backlog = (DOCS / 'implementation-backlog.md').read_text()
    trace = (DOCS / 'requirement-traceability.md').read_text()
    prd = (ROOT / 'docs/enterprise-erp-prd.md').read_text()
    orders = (DOCS / 'ai-work-orders.md').read_text()
    required = set(re.findall(r'^\| ((?:FR|BR|NFR|US)-[A-Z0-9-]+)', prd, re.M))
    required.update(re.findall(r'AC-[A-Z]+-\d+', prd))
    order_ids = re.findall(r'^- \[[ x]\] \*\*([A-Z0-9]+-\d{2}) —', orders, re.M)
    profiles = re.findall(r'^## ([A-Z0-9]+-\d{2})\n(.*?)(?=^## |\Z)', backlog, re.M | re.S)
    rows = {}
    for wo, section in profiles:
        for field in ('**Owner delivery:**', '**Reviewer acceptance:**', '**Sumber:**',
                      '[FSD/aturan]', 'Kontrak ', '[event producer/consumer]', '[data]', '[UX/operator]', '[QA]'):
            if field not in section:
                failures.append(f'{wo}: missing {field}')
        for line in section.splitlines():
            if not re.match(r'^\| \*\*'+SLICE, line):
                continue
            cells = [c.strip() for c in line.split('|')[1:-1]]
            if len(cells) != 5:
                failures.append(f'{wo}: invalid row width')
                continue
            ident = re.match(r'\*\*('+SLICE+r') —', cells[0]).group(1)
            if ident in rows or ident.rsplit('.', 1)[0] != wo:
                failures.append(f'{ident}: duplicate or wrong parent')
            reqs = set(re.findall(REQUIREMENT, cells[1]))
            deps = re.findall(SLICE, cells[2])
            size, status = cells[3].split(' / ')
            rows[ident] = {'reqs': reqs, 'deps': deps, 'size': size, 'status': status}
            if not reqs or reqs-required:
                failures.append(f'{ident}: invalid requirements {reqs-required}')
            if size not in WEIGHTS or status not in ('DONE', 'READY', 'PLANNED', 'NEEDS_SPEC'):
                failures.append(f'{ident}: invalid size/status')
            if '**Risiko:**' not in cells[4] or len(cells[4]) < 60:
                failures.append(f'{ident}: missing acceptance/risk')
            if status == 'NEEDS_SPEC' and not re.search(r'GAP-\d+', cells[4]):
                failures.append(f'{ident}: missing gap')
    if len(set(order_ids)) != len(order_ids) or set(order_ids) != {w for w, _ in profiles}:
        failures.append('Work order coverage differs from checklist')
    covered = set().union(*(r['reqs'] for r in rows.values()))
    if covered != required:
        failures.append(f'PRD coverage missing={required-covered}, extra={covered-required}')
    reverse = {}
    for line in trace.splitlines():
        if re.match(r'^\| '+REQUIREMENT+r' \|', line):
            q = line.split('|')[1].strip()
            if q in reverse:
                failures.append(f'{q}: duplicate trace row')
            reverse[q] = set(re.findall(SLICE, line))
    if set(reverse) != required:
        failures.append('Reverse trace coverage differs from PRD')
    for q in required:
        if reverse.get(q) != {i for i, r in rows.items() if q in r['reqs']}:
            failures.append(f'{q}: reverse trace differs from backlog')
    for ident, row in rows.items():
        for dep in row['deps']:
            if dep not in rows:
                failures.append(f'{ident}: missing dependency {dep}')
        if row['status'] in ('READY', 'DONE'):
            if any(rows.get(d, {}).get('status') != 'DONE' for d in row['deps']):
                failures.append(f'{ident}: unfinished prerequisite for READY/DONE')
    visiting, solved = set(), {}

    def path_to(ident):
        if ident in solved:
            return solved[ident]
        if ident in visiting:
            raise ValueError(f'Dependency cycle at {ident}')
        visiting.add(ident)
        candidates = [path_to(d) for d in rows[ident]['deps'] if d in rows]
        base, path = max(candidates, default=(0, []), key=lambda x: x[0])
        solved[ident] = (base + sum(WEIGHTS[rows[ident]['size']])/2, path + [ident])
        visiting.remove(ident)
        return solved[ident]

    try:
        for ident in rows:
            path_to(ident)
    except (ValueError, KeyError) as exc:
        failures.append(str(exc))
    checked_links = 0
    for name in ('implementation-backlog.md', 'requirement-traceability.md', 'r-01-audit.md'):
        source = DOCS / name
        if not source.exists():
            failures.append(f'Missing {name}')
            continue
        for target in re.findall(r'(?<!!)\[[^\]]+\]\(([^)]+)\)', source.read_text()):
            if target.startswith(('https:', 'http:', 'mailto:')):
                continue
            file, _, anchor = target.partition('#')
            dest = (source.parent / file).resolve() if file else source
            checked_links += 1
            if not dest.exists():
                failures.append(f'{name}: missing {target}')
            elif anchor and dest.suffix == '.md':
                headings = re.findall(r'^#{1,6} (.+)$', dest.read_text(), re.M)
                slugs = {re.sub(r'[^\w\- ]', '', h.lower()).replace(' ', '-') for h in headings}
                if anchor not in slugs:
                    failures.append(f'{name}: missing anchor {target}')
    counts = Counter(q.split('-')[0] for q in required)
    print(f'Work orders: {len(order_ids)}; slices: {len(rows)}; requirement IDs: {len(required)} {dict(sorted(counts.items()))}')
    print(f'Local links checked: {checked_links}; NEEDS_SPEC: {sum(r["status"] == "NEEDS_SPEC" for r in rows.values())}')
    if solved and not failures:
        _, critical = max(solved.values(), key=lambda x: x[0])
        chain = []
        for ident in critical:
            wo = ident.rsplit('.', 1)[0]
            if not chain or chain[-1] != wo:
                chain.append(wo)
        print('Longest dependency chain by midpoint effort (not calendar CPM): ' + ' -> '.join(chain))
        total = tuple(sum(WEIGHTS[r['size']][i] for r in rows.values()) for i in (0, 1))
        print(f'Estimated total effort: {total[0]}–{total[1]} person-days; excludes external waiting and conditional split re-estimation')
    print('PASS: planning references/coverage/DAG only; runtime not tested.' if not failures else '\n'.join(failures))
    return bool(failures)


if __name__ == '__main__':
    raise SystemExit(main())
