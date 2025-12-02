#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#====================================================
#          FILE: splituapp.py
#       AUTHORS: superr
#   REFACTORED: 2025-12-02 (Integrated from MIO-KITCHEN)
#====================================================
"""
Wrapper for UPDATE.APP extraction using MIO-KITCHEN core utilities.
This provides backward compatibility while using the enhanced core modules.
"""

from __future__ import absolute_import
from __future__ import print_function

import sys
import os

# Add the utils directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import the actual implementation from core
from core.splituapp import *

# The core module already has __main__ functionality
# So we just need to ensure it runs when called directly
if __name__ == '__main__':
    # The core module will handle command-line arguments
    pass
