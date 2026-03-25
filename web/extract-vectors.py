"""Extract embedding vectors from the full index for lazy-loading.

Usage: python web/extract-vectors.py <input.json> <output.json.gz>
Output: prints "version|count|raw_kb|gz_kb" to stdout.
"""
import json, hashlib, gzip, sys, os

if len(sys.argv) < 3:
    print("Usage: python extract-vectors.py <input.json> <output.json.gz>", file=sys.stderr)
    sys.exit(1)

with open(sys.argv[1], 'r') as f:
    data = json.load(f)

vectors = []
count = 0
for p in data['phrases']:
    e = p.get('embedding')
    if e:
        vectors.append(e)
        count += 1
    else:
        vectors.append(None)

raw = json.dumps({'count': count, 'vectors': vectors}, separators=(',', ':'))
version = hashlib.sha256(raw.encode()).hexdigest()[:16]
out = json.dumps({'version': version, 'count': count, 'vectors': vectors}, separators=(',', ':'))

with gzip.open(sys.argv[2], 'wt', encoding='utf-8', compresslevel=9) as f:
    f.write(out)

raw_kb = round(len(out) / 1024, 1)
gz_kb = round(os.path.getsize(sys.argv[2]) / 1024, 1)
print('%s|%d|%.1f|%.1f' % (version, count, raw_kb, gz_kb))
