#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
EXT4 Extract Tool - CLI wrapper for ext4/imgextractor modules
Extracts files from EXT4 partition images
"""

import sys
import os
import argparse

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from utils.core.imgextractor import Extractor
from utils.core.logging_helper import log_info, log_success, log_error

def main():
    parser = argparse.ArgumentParser(
        description='Extract files from EXT4 partition images',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  %(prog)s system.img                   # Extract to ./system directory
  %(prog)s system.img -o output_dir     # Extract to specific directory
        '''
    )
    
    parser.add_argument('image_file', help='Path to EXT4 image file (e.g., system.img)')
    parser.add_argument('-o', '--output', dest='output_dir', default=None,
                        help='Output directory for extracted files')
    
    args = parser.parse_args()
    
    # Validate image file exists
    if not os.path.exists(args.image_file):
        log_error(f"Image file not found: {args.image_file}")
        return 1
    
    # Set output directory based on image filename if not specified
    if args.output_dir is None:
        base_name = os.path.basename(args.image_file)
        if base_name.endswith('.img'):
            partition_name = base_name[:-4]  # Remove .img extension
        else:
            partition_name = base_name
        args.output_dir = os.path.join(os.path.dirname(args.image_file) or '.', partition_name)
    
    try:
        log_info(f"Extracting EXT4 image: {args.image_file}")
        log_info(f"Output directory: {args.output_dir}")
        
        # Create output directory if it doesn't exist
        os.makedirs(args.output_dir, exist_ok=True)
        
        # Create Extractor instance
        extractor = Extractor()
        extractor.FileName = os.path.basename(args.image_file)
        extractor.OUTPUT_IMAGE_FILE = args.image_file
        extractor.EXTRACT_DIR = args.output_dir
        
        # Extract the image
        extractor.main()
        
        log_success(f"EXT4 extraction completed successfully to: {args.output_dir}")
        return 0
        
    except Exception as e:
        log_error(f"Failed to extract EXT4 image: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
