#!/usr/bin/env python3
"""
UNPAC - Unpack SPRD (Spreadtrum) PAC firmware files
Wrapper for unpac functionality from MIO-KITCHEN core
"""

import sys
import os

# Add the utils directory to the path  
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import the unpac module
from core import unpac

if __name__ == '__main__':
    # The module will handle command line arguments
    pass
