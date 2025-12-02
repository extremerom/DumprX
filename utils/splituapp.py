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
import argparse

# Add the utils directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import the actual implementation from core
from core.splituapp import extract_update_app, get_parts

def main():
    """Command-line interface for splituapp"""
    parser = argparse.ArgumentParser(
        description='Extract partitions from Huawei UPDATE.APP files',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('-f', '--file', dest='source', required=True,
                        help='UPDATE.APP file to extract')
    parser.add_argument('-l', '--list', dest='partitions', nargs='+',
                        help='List of partitions to extract (space-separated)')
    parser.add_argument('-o', '--output', dest='output_dir', default='output',
                        help='Output directory (default: output)')
    
    args = parser.parse_args()
    
    if not os.path.isfile(args.source):
        print(f'Error: File not found: {args.source}', file=sys.stderr)
        return 1
    
    try:
        # Create output directory
        os.makedirs(args.output_dir, exist_ok=True)
        
        # Extract partitions
        if args.partitions:
            print(f'Extracting partitions: {", ".join(args.partitions)}')
            extract_update_app(args.source, args.output_dir, args.partitions)
        else:
            print('Extracting all partitions')
            extract_update_app(args.source, args.output_dir)
        
        return 0
    except Exception as e:
        print(f'Error during extraction: {e}', file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
