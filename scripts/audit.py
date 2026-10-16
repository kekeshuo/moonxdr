"""Conservative physical source inventory; no tests/examples/generated code counted."""
from pathlib import Path
import json
ROOT = Path(__file__).resolve().parents[1]
rows = []
for p in sorted(ROOT.glob('*.mbt')):
    if p.name.endswith(('_test.mbt', '_wbtest.mbt')):
        continue
    lines = p.read_text(encoding='utf-8-sig').splitlines()
    rows.append({'file': p.name, 'physical': len(lines),
                 'nonblank_noncomment': sum(bool(s.strip()) and not s.lstrip().startswith('//') for s in lines)})
result = {'production_files': len(rows), 'production_physical_lines': sum(r['physical'] for r in rows),
          'nonblank_noncomment_lines': sum(r['nonblank_noncomment'] for r in rows),
          'excluded': ['tests', 'generated reference vectors', 'examples', 'interfaces', 'scripts', 'documentation'],
          'files': rows}
print(json.dumps(result, indent=2))
assert result['nonblank_noncomment_lines'] >= 1500
