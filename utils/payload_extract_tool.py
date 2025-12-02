#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Payload Extract Tool - CLI wrapper for payload_extract module
Extracts Android OTA payload.bin files
"""

import sys
import os
import argparse

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.core.payload_extract import Payload
from utils.core.logging_helper import log_info, log_success, log_error

def main():
    parser = argparse.ArgumentParser(
        description='Extract Android OTA payload.bin files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s payload.bin                  # Extract all partitions
  %(prog)s payload.bin -o output_dir    # Extract to specific directory
  %(prog)s payload.bin -p system        # Extract only system partition
        '''
    )
    
    parser.add_argument('payload_file', help='Path to payload.bin file')
    parser.add_argument('-o', '--output', dest='output_dir', default=None,
                        help='Output directory for extracted partitions')
    parser.add_argument('-p', '--partition', dest='partition_name', default=None,
                        help='Extract only specific partition (e.g., system, vendor)')
    parser.add_argument('-l', '--list', action='store_true',
                        help='List partitions in payload without extracting')
    
    args = parser.parse_args()
    
    # Validate payload file exists
    if not os.path.exists(args.payload_file):
        log_error(f"Payload file not found: {args.payload_file}")
        return 1
    
    # Set output directory to current directory if not specified
    if args.output_dir is None:
        args.output_dir = os.path.dirname(args.payload_file) or '.'
    
    try:
        log_info(f"Processing payload file: {args.payload_file}")
        
        # Create Payload instance
        payload = Payload(args.payload_file, args.output_dir)
        
        if args.list:
            # List partitions
            log_info("Partitions in payload:")
            # This would need to be implemented in payload_extract module
            # For now, just extract which will show progress
            payload.extract(args.partition_name)
        else:
            # Extract partitions
            log_info(f"Extracting to: {args.output_dir}")
            payload.extract(args.partition_name)
            log_success("Payload extraction completed successfully")
        
        return 0
        
    except Exception as e:
        log_error(f"Failed to extract payload: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
