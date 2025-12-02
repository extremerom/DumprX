#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
UNPAC Tool - CLI wrapper for unpac module
Unpack SPRD PAC firmware files
"""

import sys
import os
import argparse

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.core.unpac import unpack as unpac_unpack
from utils.core.logging_helper import log_info, log_success, log_error

def main():
    parser = argparse.ArgumentParser(
        description='Unpack SPRD PAC firmware files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s firmware.pac                 # Extract to current directory
  %(prog)s firmware.pac -o output_dir   # Extract to specific directory
        '''
    )
    
    parser.add_argument('pac_file', help='Path to PAC firmware file')
    parser.add_argument('-o', '--output', dest='output_dir', default=None,
                        help='Output directory for extracted files')
    
    args = parser.parse_args()
    
    # Validate PAC file exists
    if not os.path.exists(args.pac_file):
        log_error(f"PAC file not found: {args.pac_file}")
        return 1
    
    # Set output directory if not specified
    if args.output_dir is None:
        base_name = os.path.basename(args.pac_file)
        if base_name.lower().endswith('.pac'):
            dir_name = base_name[:-4]
        else:
            dir_name = base_name
        args.output_dir = os.path.join(os.path.dirname(args.pac_file) or '.', dir_name)
    
    try:
        log_info(f"Unpacking PAC file: {args.pac_file}")
        log_info(f"Output directory: {args.output_dir}")
        
        os.makedirs(args.output_dir, exist_ok=True)
        
        # Unpack PAC file
        unpac_unpack(args.pac_file, args.output_dir)
        
        log_success(f"PAC extraction completed to: {args.output_dir}")
        return 0
        
    except Exception as e:
        log_error(f"Failed to unpack PAC file: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
