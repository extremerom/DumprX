#!/usr/bin/env python3
"""
Payload Dumper - Extract Android OTA Payload Images
Wrapper for payload extraction from MIO-KITCHEN core
"""

import sys
import os

# Add the utils directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import the payload_extract module - it has its own __main__ handling
if __name__ == '__main__':
    from core import payload_extract
    # The module will handle command line arguments
