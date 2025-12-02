#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PAC Extractor Wrapper
Wrapper around the MIO-KITCHEN unpac module for SPRD PAC file extraction
Maintains compatibility with existing dumper.sh calls
"""

import sys
import os

# Add parent directory to path to import unpack module
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../..'))

from unpack import unpac, UnpacMode

def main():
    if len(sys.argv) < 3:
        print("Usage: pacExtractor.py <pac_file> <output_dir>")
        sys.exit(1)
    
    pac_file = sys.argv[1]
    output_dir = sys.argv[2]
    
    if not os.path.exists(pac_file):
        print(f"Error: PAC file not found: {pac_file}")
        sys.exit(1)
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir, exist_ok=True)
    
    try:
        print(f"Extracting PAC file: {pac_file}")
        print(f"Output directory: {output_dir}")
        unpac(pac_file, output_dir, UnpacMode.EXTRACT)
        print("PAC extraction completed successfully")
    except Exception as e:
        print(f"Error extracting PAC file: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
