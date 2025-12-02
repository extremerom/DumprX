#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#====================================================
#          FILE: sdat2img.py
#       AUTHORS: xpirt - luxi78 - howellzhu
#   REFACTORED: 2025-12-02 (Integrated from MIO-KITCHEN)
#====================================================
"""
Wrapper for sdat2img functionality using MIO-KITCHEN core utilities.
This provides backward compatibility while using the enhanced core modules.
"""

from __future__ import absolute_import
from __future__ import print_function

import sys
import os
import argparse

# Add the utils directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from core.utils import sdat2img as core_sdat2img

def main():
    """Main function for sdat2img conversion"""
    parser = argparse.ArgumentParser(description='Convert Android sparse data (DAT) to raw image (IMG)')
    parser.add_argument('transfer_list', help='Transfer list file (system.transfer.list)')
    parser.add_argument('new_dat', help='New DAT file (system.new.dat)')
    parser.add_argument('output', help='Output IMG file (system.img)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Enable verbose output')
    
    args = parser.parse_args()
    
    # Check if files exist
    if not os.path.isfile(args.transfer_list):
        print(f'Error: Transfer list file not found: {args.transfer_list}', file=sys.stderr)
        return 1
    
    if not os.path.isfile(args.new_dat):
        print(f'Error: DAT file not found: {args.new_dat}', file=sys.stderr)
        return 1
    
    try:
        # Call the core function from MIO-KITCHEN utils
        print(f'Converting {args.new_dat} to {args.output}...')
        core_sdat2img(args.transfer_list, args.new_dat, args.output)
        print(f'Successfully converted to {args.output}')
        return 0
    except Exception as e:
        print(f'Error during conversion: {e}', file=sys.stderr)
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
