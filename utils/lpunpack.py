#!/usr/bin/env python3
"""
lpunpack - Unpack Android Super/Dynamic Partition Images
Wrapper for lpunpack functionality from MIO-KITCHEN core
"""

import sys
import os
import argparse

# Add the utils directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import lpunpack functions
from core.lpunpack import unpack, get_info

def main():
    """Command-line interface for lpunpack"""
    parser = argparse.ArgumentParser(
        description='Unpack Android super/dynamic partition images',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument('SUPER_IMAGE', help='Path to super image file')
    parser.add_argument('OUTPUT_DIR', nargs='?', help='Output directory for extracted partitions')
    parser.add_argument('-p', '--partition', dest='NAME', action='append', 
                        help='Extract specific partition(s)')
    parser.add_argument('-S', '--slot', type=int, dest='SLOT', help='Slot number')
    parser.add_argument('--show-info', dest='SHOW_INFO', action='store_true',
                        help='Show partition info without extracting')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.SUPER_IMAGE):
        print(f'Error: Super image not found: {args.SUPER_IMAGE}', file=sys.stderr)
        return 1
    
    try:
        if args.SHOW_INFO:
            # Show info only
            info = get_info(args.SUPER_IMAGE)
            print(info)
        elif args.OUTPUT_DIR:
            # Extract partitions
            unpack(args.SUPER_IMAGE, args.OUTPUT_DIR, args.NAME)
            print(f'Successfully extracted partitions to {args.OUTPUT_DIR}')
        else:
            print('Error: Either --show-info or OUTPUT_DIR must be specified', file=sys.stderr)
            return 1
        
        return 0
    except Exception as e:
        print(f'Error: {e}', file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
