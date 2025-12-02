#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LPUnpack Tool - CLI wrapper for lpunpack module
Unpacks Android super.img (dynamic partitions) to individual partition images
"""

import sys
import os
import argparse

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.core.lpunpack import LpUnpack, FormatType
from utils.core.logging_helper import log_info, log_success, log_error

def main():
    parser = argparse.ArgumentParser(
        description='Unpack Android super.img (dynamic partitions) to individual partition images',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s super.img                    # Extract all partitions
  %(prog)s super.img -p system          # Extract only system partition
  %(prog)s super.img -o output_dir      # Extract to specific directory
        '''
    )
    
    parser.add_argument('super_image', help='Path to super.img file')
    parser.add_argument('-p', '--partition', dest='NAME', default=None,
                        help='Partition name to extract (e.g., system, vendor, product)')
    parser.add_argument('-o', '--output', dest='OUTPUT_DIR', default=None,
                        help='Output directory for extracted partitions')
    parser.add_argument('-i', '--info', action='store_true',
                        help='Show super image info without extracting')
    parser.add_argument('-j', '--json', action='store_true',
                        help='Output info in JSON format')
    
    args = parser.parse_args()
    
    # Validate super image file exists
    if not os.path.exists(args.super_image):
        log_error(f"Super image file not found: {args.super_image}")
        return 1
    
    # Set output directory to current directory if not specified
    if args.OUTPUT_DIR is None:
        args.OUTPUT_DIR = os.path.dirname(args.super_image) or '.'
    
    try:
        log_info(f"Processing super image: {args.super_image}")
        
        # Create LpUnpack instance
        lpunpack_params = {
            'SUPER_IMAGE': args.super_image,
            'OUTPUT_DIR': args.OUTPUT_DIR,
            'NAME': args.NAME,
            'SHOW_INFO': args.info or args.json,
            'SHOW_INFO_FORMAT': FormatType.JSON if args.json else FormatType.TEXT
        }
        
        lpunpack = LpUnpack(**lpunpack_params)
        
        if args.info or args.json:
            # Show info only
            lpunpack.unpack()
        else:
            # Extract partitions
            log_info(f"Extracting to: {args.OUTPUT_DIR}")
            lpunpack.unpack()
            log_success("Super image extraction completed successfully")
        
        return 0
        
    except Exception as e:
        log_error(f"Failed to process super image: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
