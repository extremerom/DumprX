#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OZIP Decrypt Tool - CLI wrapper for ozipdecrypt module
Decrypt OPPO/Realme OZIP encrypted firmware files
"""

import sys
import os
import argparse

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.core.ozipdecrypt import ozipdecrypt
from utils.core.logging_helper import log_info, log_success, log_error

def main():
    parser = argparse.ArgumentParser(
        description='Decrypt OPPO/Realme OZIP encrypted firmware files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s firmware.ozip                # Decrypt to firmware.zip
  %(prog)s firmware.ozip -o output.zip  # Decrypt to specific file
        '''
    )
    
    parser.add_argument('ozip_file', help='Path to OZIP encrypted file')
    parser.add_argument('-o', '--output', dest='output_file', default=None,
                        help='Output decrypted ZIP file')
    
    args = parser.parse_args()
    
    # Validate OZIP file exists
    if not os.path.exists(args.ozip_file):
        log_error(f"OZIP file not found: {args.ozip_file}")
        return 1
    
    # Set output file name if not specified
    if args.output_file is None:
        base_name = os.path.basename(args.ozip_file)
        if base_name.lower().endswith('.ozip'):
            output_name = base_name[:-5] + '.zip'
        else:
            output_name = base_name + '.zip'
        args.output_file = os.path.join(os.path.dirname(args.ozip_file) or '.', output_name)
    
    try:
        log_info(f"Decrypting OZIP file: {args.ozip_file}")
        log_info(f"Output file: {args.output_file}")
        
        # Decrypt OZIP file
        ozipdecrypt(args.ozip_file, args.output_file)
        
        log_success(f"OZIP decryption completed: {args.output_file}")
        return 0
        
    except Exception as e:
        log_error(f"Failed to decrypt OZIP: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
