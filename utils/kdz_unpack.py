#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
KDZ Unpack Tool - CLI wrapper for unkdz module
Unpack LG KDZ firmware files
"""

import sys
import os
import argparse

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.core.unkdz import KDZFileTools
from utils.core.logging_helper import log_info, log_success, log_error

def main():
    parser = argparse.ArgumentParser(
        description='Unpack LG KDZ firmware files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s firmware.kdz                 # Extract to current directory
  %(prog)s firmware.kdz -o output_dir   # Extract to specific directory
        '''
    )
    
    parser.add_argument('kdz_file', help='Path to KDZ firmware file')
    parser.add_argument('-o', '--output', dest='output_dir', default=None,
                        help='Output directory for extracted files')
    parser.add_argument('-l', '--list', action='store_true',
                        help='List contents without extracting')
    
    args = parser.parse_args()
    
    # Validate KDZ file exists
    if not os.path.exists(args.kdz_file):
        log_error(f"KDZ file not found: {args.kdz_file}")
        return 1
    
    # Set output directory if not specified
    if args.output_dir is None:
        base_name = os.path.basename(args.kdz_file)
        if base_name.lower().endswith('.kdz'):
            dir_name = base_name[:-4]
        else:
            dir_name = base_name
        args.output_dir = os.path.join(os.path.dirname(args.kdz_file) or '.', dir_name)
    
    try:
        log_info(f"Processing KDZ file: {args.kdz_file}")
        
        if args.list:
            log_info("Listing KDZ contents...")
            # KDZFileTools doesn't have a list method, so we'll just show the file info
            kdz_tool = KDZFileTools(args.kdz_file)
            log_info(f"KDZ file: {args.kdz_file}")
            log_info(f"Size: {os.path.getsize(args.kdz_file)} bytes")
        else:
            log_info(f"Extracting to: {args.output_dir}")
            os.makedirs(args.output_dir, exist_ok=True)
            
            # Extract KDZ file
            kdz_tool = KDZFileTools(args.kdz_file)
            kdz_tool.extract(args.output_dir)
            
            log_success(f"KDZ extraction completed to: {args.output_dir}")
        
        return 0
        
    except Exception as e:
        log_error(f"Failed to process KDZ file: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
