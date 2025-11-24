#!/usr/bin/env python
# -*- coding: utf-8 -*-

# splituapp for Python2/3 by SuperR. @XDA
#
# For extracting img files from UPDATE.APP
#
# Based on the app_structure file in split_updata.pl by McSpoon
# REFACTORED: 2025-11-24 (Enhanced logging and error handling)

from __future__ import absolute_import
from __future__ import print_function

import os
import re
import sys
import string
import struct
from subprocess import check_output

# ANSI color codes for better output
class Colors:
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    CYAN = '\033[96m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def log_info(msg):
    """Print info message"""
    print('{}[INFO]{} {}'.format(Colors.CYAN, Colors.ENDC, msg))

def log_success(msg):
    """Print success message"""
    print('{}[SUCCESS]{} {}'.format(Colors.OKGREEN, Colors.ENDC, msg))

def log_error(msg):
    """Print error message"""
    print('{}[ERROR]{} {}'.format(Colors.FAIL, Colors.ENDC, msg), file=sys.stderr)

def log_warning(msg):
    """Print warning message"""
    print('{}[WARNING]{} {}'.format(Colors.WARNING, Colors.ENDC, msg))

def format_size(size_bytes):
    """Format bytes to human readable string"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0:
            return "{:.2f} {}".format(size_bytes, unit)
        size_bytes /= 1024.0
    return "{:.2f} TB".format(size_bytes)

def extract(source, flist, verbose=False):
    """Extract img files from UPDATE.APP"""
    
    def cmd(command):
        try:
            test1 = check_output(command)
            test1 = test1.strip().decode()
        except Exception as e:
            if verbose:
                log_warning('Command failed: {}'.format(e))
            test1 = ''
        return test1

    # Validate input file
    if not os.path.exists(source):
        log_error('UPDATE.APP file not found: {}'.format(source))
        return 1
    
    file_size = os.path.getsize(source)
    log_info('Processing UPDATE.APP ({})'.format(format_size(file_size)))

    bytenum = 4
    outdir = 'output'
    img_files = []
    extracted_count = 0

    # Create output directory
    try:
        os.makedirs(outdir)
        log_info('Created output directory: {}'.format(outdir))
    except OSError:
        if verbose:
            log_info('Output directory already exists')
        pass

    py2 = None
    if int(''.join(str(i) for i in sys.version_info[0:2])) < 30:
        py2 = 1

    try:
        with open(source, 'rb') as f:
            file_pos = 0
            while True:
                i = f.read(bytenum)
                file_pos = f.tell()

                if not i:
                    break
                elif i != b'\x55\xAA\x5A\xA5':
                    continue

                headersize = f.read(bytenum)
                headersize = list(struct.unpack('<L', headersize))[0]
                f.seek(16, 1)
                filesize = f.read(bytenum)
                filesize = list(struct.unpack('<L', filesize))[0]
                f.seek(32, 1)
                filename = f.read(16)

                try:
                    filename = str(filename.decode())
                    filename = ''.join(f for f in filename if f in string.printable).lower()
                except Exception as e:
                    if verbose:
                        log_warning('Failed to decode filename at position {}'.format(file_pos))
                    filename = ''

                f.seek(22, 1)
                crcdata = f.read(headersize - 98)

                if not flist or filename in flist:
                    if filename in img_files:
                        filename = filename + '_2'

                    log_info('Extracting: {}.img ({})'.format(filename, format_size(filesize)))

                    chunk = 10240
                    output_path = os.path.join(outdir, filename + '.img')

                    try:
                        # Check if file exists and create unique name if needed
                        if os.path.exists(output_path):
                            i = 1
                            while os.path.exists(os.path.join(outdir, '{}_{}.img'.format(filename, i))):
                                i += 1
                            output_path = os.path.join(outdir, '{}_{}.img'.format(filename, i))
                            log_warning('File exists, using: {}'.format(os.path.basename(output_path)))

                        # Extract the file
                        bytes_written = 0
                        with open(output_path, 'wb') as o:
                            while filesize > 0:
                                if chunk > filesize:
                                    chunk = filesize

                                o.write(f.read(chunk))
                                filesize -= chunk
                                bytes_written += chunk

                                # Show progress for large files
                                if verbose and bytes_written % (1024 * 1024 * 10) == 0:
                                    print('.', end='', flush=True)
                        
                        if verbose and bytes_written > 1024 * 1024:
                            print()  # New line after progress dots

                        log_success('Extracted: {}'.format(os.path.basename(output_path)))
                        extracted_count += 1

                    except Exception as e:
                        log_error('Failed to create {}.img: {}'.format(filename, e))
                        return 1

                    img_files.append(filename)

                    # CRC validation (Linux only)
                    if os.name != 'nt' and os.path.isfile('crc'):
                        if verbose:
                            log_info('Calculating CRC for {}.img'.format(filename))

                        crcval = []
                        if py2:
                            for i in crcdata:
                                crcval.append('%02X' % ord(i))
                        else:
                            for i in crcdata:
                                crcval.append('%02X' % i)

                        crcval = ''.join(crcval)
                        crcact = cmd(['./crc', output_path])

                        if crcval != crcact:
                            log_error('CRC mismatch for {}.img'.format(filename))
                            if verbose:
                                log_error('Expected: {}, Got: {}'.format(crcval, crcact))
                            return 1
                        elif verbose:
                            log_success('CRC verified for {}.img'.format(filename))
                else:
                    f.seek(filesize, 1)

                xbytes = bytenum - f.tell() % bytenum
                if xbytes < bytenum:
                    f.seek(xbytes, 1)

    except IOError as e:
        log_error('Failed to read UPDATE.APP: {}'.format(e))
        return 1
    except KeyboardInterrupt:
        log_error('Extraction cancelled by user')
        return 1

    print()
    log_success('Extraction complete! Extracted {} file(s)'.format(extracted_count))
    return 0

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(
        description="Split UPDATE.APP file into img files",
        epilog="Created by SuperR @XDA"
    )
    parser.add_argument("-f", "--filename", required=True,
                       help="Path to UPDATE.APP file")
    parser.add_argument("-l", "--list", nargs="*", metavar=('img1', 'img2'),
                       help="List of specific img files to extract (default: all)")
    parser.add_argument("-v", "--verbose", action="store_true",
                       help="Enable verbose output with detailed information")
    
    args = parser.parse_args()

    try:
        exit_code = extract(args.filename, args.list, args.verbose)
        sys.exit(exit_code)
    except Exception as e:
        log_error('Unexpected error: {}'.format(e))
        sys.exit(1)
