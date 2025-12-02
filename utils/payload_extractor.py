#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Payload Extractor Wrapper for DumprX
Wrapper around MIO-KITCHEN-SOURCE payload_extract.py
"""

import sys
import os

# Add pylib to path
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'pylib'))

import argparse
from pylib.payload_extract import Extractor


def main():
    parser = argparse.ArgumentParser(description='Extract Android OTA payload.bin')
    parser.add_argument('payload', help='payload.bin file or directory containing it')
    parser.add_argument('-o', '--output', default='.', help='Output directory (default: current directory)')
    parser.add_argument('-p', '--partitions', nargs='+', help='Specific partitions to extract (optional)')
    parser.add_argument('-w', '--workers', type=int, default=os.cpu_count() or 4, help='Number of worker threads')
    
    args = parser.parse_args()
    
    # Find payload.bin if directory is given
    payload_file = args.payload
    if os.path.isdir(args.payload):
        payload_file = os.path.join(args.payload, 'payload.bin')
        if not os.path.isfile(payload_file):
            print(f"Error: payload.bin not found in {args.payload}")
            sys.exit(1)
    
    if not os.path.isfile(payload_file):
        print(f"Error: {payload_file} not found")
        sys.exit(1)
    
    # Create output directory if it doesn't exist
    os.makedirs(args.output, exist_ok=True)
    
    print(f"Extracting {payload_file} to {args.output}")
    print(f"Using {args.workers} worker threads")
    
    try:
        extractor = Extractor(
            payload_file,
            args.output,
            partitions=args.partitions,
            max_workers=args.workers
        )
        extractor.extract()
        print("Extraction completed successfully")
    except Exception as e:
        print(f"Error during extraction: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
