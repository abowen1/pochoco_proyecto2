"""Derive a simulation-only image: same program, wait 128 cycles instead of 9.375M."""
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from assembler import assemble
source = Path('sw/timer_test.s').read_text()
source = '\n'.join('    lui x2, 0' if '# WAIT_HI' in line else
                   '    addi x2, x2, 128' if '# WAIT_LO' in line else line
                   for line in source.splitlines())
Path('build/timer_test_fast.hex').write_text(''.join(f'{w:08x}\n' for w in assemble(source)))
