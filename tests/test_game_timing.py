"""Keep real FPGA time constants consistent with the hardware clock divider."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]

class GameTimingTests(unittest.TestCase):
    def test_real_clock_constants(self):
        values = {}
        for line in (ROOT/'sw/game.s').read_text().splitlines():
            tag = re.search(r'# (TENTH|PREP|LIMIT|RELEASE|HOLD)_(HI|LO)', line)
            if tag:
                immediate = int(re.search(r'(-?\d+)\s*$', line.split('#')[0])[1])
                values[tag[1]+'_'+tag[2]] = immediate
        hz = 25_000_000 // 8
        for name, expected in {'TENTH':hz//10,'PREP':3*hz,'LIMIT':10*hz,
                               'RELEASE':hz//50,'HOLD':hz}.items():
            with self.subTest(name=name):
                self.assertEqual((values[name+'_HI'] << 12) + values[name+'_LO'],expected)
        rtl=(ROOT/'rtl/pochoco_soc.v').read_text()
        self.assertIn('reg [2:0] clock_divider = 0;',rtl)
        self.assertIn('assign clk = clock_divider[2];',rtl)

if __name__ == '__main__':
    unittest.main()
