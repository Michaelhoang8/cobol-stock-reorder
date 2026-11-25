"""Execute the compiled COBOL program and compare an independent integer model."""
import csv
import io
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
BINARY = Path(sys.argv[1]).resolve()


def execute(text):
    with tempfile.TemporaryDirectory() as directory:
        source = Path(directory) / 'stock.txt'
        source.write_text(text, encoding='ascii')
        return subprocess.run([str(BINARY), str(source)], capture_output=True, text=True, timeout=10)


fixture = subprocess.run([str(BINARY), str(ROOT / 'fixtures/stock.txt')], capture_output=True, text=True, timeout=10)
assert fixture.returncode == 0, fixture.stderr
assert fixture.stdout == (ROOT / 'fixtures/expected.csv').read_text(encoding='ascii')

cases = [(stock, minimum, target) for stock in (0, 1, 49, 50, 51, 999999)
         for minimum, target in ((0, 0), (1, 10), (50, 100), (999999, 999999))]
text = ''.join(f'ITEM{i:<6}{stock:06}{minimum:06}{target:06}\n'
               for i, (stock, minimum, target) in enumerate(cases))
result = execute(text)
assert result.returncode == 0, result.stderr
rows = list(csv.DictReader(io.StringIO(result.stdout)))
assert len(rows) == len(cases)
for row, (stock, minimum, target) in zip(rows, cases):
    expected = target - stock if stock < minimum else 0
    assert int(row['reorder_units']) == expected
    assert row['status'] == ('ORDER' if stock < minimum else 'KEEP')
    assert row['reason'] == ''

invalid = execute('SHORT\n' + 'BAD,SKU   000001000005000010\n' +
                  '          000001000005000010\n' +
                  'BADNUM    000-01000005000010\n' +
                  'BADTARGET 000001000010000005\n')
assert invalid.returncode == 2
rejected = list(csv.DictReader(io.StringIO(invalid.stdout)))
assert [r['reason'] for r in rejected] == ['record-length', 'invalid-sku', 'blank-sku', 'non-numeric-units', 'target-below-minimum']
assert all(r['status'] == 'REJECT' and r['reorder_units'] == '0' for r in rejected)
empty = execute('')
assert empty.returncode == 0 and len(list(csv.DictReader(io.StringIO(empty.stdout)))) == 0
missing = subprocess.run([str(BINARY), str(ROOT / 'fixtures/missing-file.txt')], capture_output=True, text=True, timeout=10)
assert missing.returncode == 1
print('COBOL fixture, 24 boundary cases, 5 rejects and I/O tests passed')
