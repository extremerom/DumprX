#!/usr/bin/env python3
"""
Wrapper for undz functionality using MIO-KITCHEN core utilities.
This provides backward compatibility while using the enhanced core modules.
"""

import sys
import os

# Add the parent utils directory to the path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import the actual implementation from core
from core.undz import *

# The core module already has __main__ functionality
if __name__ == '__main__':
    # The core module will handle everything
    pass
