from pathlib import Path
import re
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from assembler import assemble
# Same code, accelerated time units; keep ten correct rounds unchanged.
values = {'TENTH': 256, 'PREP': 7680, 'LIMIT': 25600, 'RELEASE': 128, 'HOLD': 2560}
source = Path('sw/game.s').read_text()
lines=[]
for line in source.splitlines():
    match=re.search(r'# (TENTH|PREP|LIMIT|RELEASE|HOLD)_(HI|LO)',line)
    if match:
        value=values[match[1]]; high=(value+2048)//4096
        prefix=line.split('#')[0].rstrip()
        line=re.sub(r'-?\d+$',str(high if match[2]=='HI' else value-high*4096),prefix)
    lines.append(line)
Path('build/game_fast.hex').write_text(''.join(f'{w:08x}\n' for w in assemble('\n'.join(lines))))
