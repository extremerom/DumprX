#!/usr/bin/env python3
"""
UNPAC - Unpack SPRD (Spreadtrum) PAC firmware files
Wrapper for unpac functionality from MIO-KITCHEN core
"""

import sys
import os

# Add the utils directory to the path  
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

if __name__ == '__main__':
    # The core unpac module has __main__ code, so we run it as a module
    import runpy
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'core'))
    runpy.run_module('unpac', run_name='__main__', alter_sys=True)
