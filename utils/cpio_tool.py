#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
CPIO Tool - CLI wrapper for cpio module
Pack and unpack CPIO archives (used in ramdisks)
"""

import sys
import os
import argparse

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.core.cpio import CpioArchive
from utils.core.logging_helper import log_info, log_success, log_error

def main():
    parser = argparse.ArgumentParser(
        description='Pack and unpack CPIO archives (used in ramdisks)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s -x ramdisk.cpio              # Extract ramdisk.cpio
  %(prog)s -x ramdisk.cpio -o output    # Extract to specific directory
  %(prog)s -c ramdisk_dir -o new.cpio   # Create CPIO from directory
        '''
    )
    
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-x', '--extract', dest='extract_file', metavar='FILE',
                       help='Extract CPIO archive')
    group.add_argument('-c', '--create', dest='create_dir', metavar='DIR',
                       help='Create CPIO archive from directory')
    
    parser.add_argument('-o', '--output', dest='output', default=None,
                        help='Output file/directory')
    
    args = parser.parse_args()
    
    try:
        if args.extract_file:
            # Extract mode
            if not os.path.exists(args.extract_file):
                log_error(f"CPIO file not found: {args.extract_file}")
                return 1
            
            output_dir = args.output or os.path.splitext(args.extract_file)[0]
            log_info(f"Extracting CPIO: {args.extract_file} -> {output_dir}")
            
            os.makedirs(output_dir, exist_ok=True)
            
            with open(args.extract_file, 'rb') as f:
                archive = CpioArchive()
                archive.load(f)
                archive.extract(output_dir)
            
            log_success(f"CPIO extraction completed to: {output_dir}")
            
        elif args.create_dir:
            # Create mode
            if not os.path.isdir(args.create_dir):
                log_error(f"Directory not found: {args.create_dir}")
                return 1
            
            output_file = args.output or f"{args.create_dir}.cpio"
            log_info(f"Creating CPIO: {args.create_dir} -> {output_file}")
            
            archive = CpioArchive()
            archive.create(args.create_dir)
            
            with open(output_file, 'wb') as f:
                archive.save(f)
            
            log_success(f"CPIO archive created: {output_file}")
        
        return 0
        
    except Exception as e:
        log_error(f"CPIO operation failed: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
