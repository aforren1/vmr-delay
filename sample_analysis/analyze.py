
import gzip
import json

with gzip.open('test_1648845108.json.gz', 'rb') as f:
    data = json.loads(f.read().decode('utf-8'))

# data['block'] contains general block info