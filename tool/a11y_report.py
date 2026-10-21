#!/usr/bin/env python3
"""The accessibility checks as a PR comment.

    flutter test --reporter json <files> > a11y.jsonl ; tool/a11y_report.py a11y.jsonl > report.md

Reads the JSON reporter's event stream and writes a Markdown table: one row
per test, passed or failed, and for a failure the first lines of its message
(the guideline's own wording: which node, what size, what contrast), so the
reason is on the PR without opening the logs. Exits 1 if any test failed.
"""
import json
import sys


def failure_reason(prints, errors):
    """The 'Expected / Actual / Which' block of the first failed expectation,
    without its stack; else the error event's text."""
    for msg in prints:
        lines = msg.splitlines()
        start = next((i for i, l in enumerate(lines) if l.startswith('Expected:')), None)
        if start is None:
            continue
        block = []
        for l in lines[start:]:
            if l.startswith('When the exception was thrown') or l.startswith('#'):
                break
            if l.strip():
                block.append(l.strip())
        return cell(block)
    msg = '\n'.join(errors)
    return cell([l.strip() for l in msg.splitlines() if l.strip()])


def cell(lines):
    """Lines as one table cell: angle brackets escaped (a table swallows what
    looks like a tag), pipes escaped, line breaks kept."""
    text = '<br>'.join(l.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;') for l in lines)
    return text[:800].replace('|', '\\|')


def main(path):
    tests, errors, results, groups, prints = {}, {}, {}, {}, {}
    for line in open(path, encoding='utf-8'):
        line = line.strip()
        if not line.startswith('{'):
            continue
        ev = json.loads(line)
        t = ev.get('type')
        if t == 'group':
            g = ev['group']
            groups[g['id']] = g
        elif t == 'testStart':
            tests[ev['test']['id']] = ev['test']
        elif t == 'error':
            errors.setdefault(ev['testID'], []).append(ev.get('error', ''))
        elif t == 'print':
            # A failed expectation is printed by the test framework before the
            # error event, and the print is where the guideline's own words
            # are ("expected tap target size of at least …, but found …").
            prints.setdefault(ev['testID'], []).append(ev.get('message', ''))
        elif t == 'testDone':
            results[ev['testID']] = ev
    rows, failed = [], 0
    for tid, test in tests.items():
        done = results.get(tid)
        if done is None or done.get('hidden'):
            continue
        name = test['name']
        if name.startswith('loading '):
            continue
        ok = done.get('result') == 'success'
        if not ok:
            failed += 1
        reason = ''
        if not ok:
            reason = failure_reason(prints.get(tid, []), errors.get(tid, []))
        # root_url is the test file for a test declared through a helper
        # (testWidgets); url would be the helper's own file.
        suite = (test.get('root_url') or test.get('url') or '').rsplit('/', 1)[-1]
        rows.append(f"| {'✅' if ok else '❌'} | {name} | `{suite}` | {reason} |")
    total = len(rows)
    head = (f'### {"❌" if failed else "✅"} Accessibility checks: '
            f'{total - failed} of {total} passed\n\n'
            '| | Check | Suite | Why it failed |\n|---|---|---|---|')
    print(head)
    print('\n'.join(rows))
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
