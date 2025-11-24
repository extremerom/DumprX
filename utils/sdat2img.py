#!/usr/bin/env python
# -*- coding: utf-8 -*-
#====================================================
#          FILE: sdat2img.py
#       AUTHORS: xpirt - luxi78 - howellzhu
#          DATE: 2018-10-27 10:33:21 CEST
#   REFACTORED: 2025-11-24 (Enhanced logging and error handling)
#====================================================

from __future__ import absolute_import
from __future__ import print_function

import sys
import os
import errno
import argparse

# ANSI color codes for better output
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def log_info(msg, verbose=True):
    """Print info message"""
    if verbose:
        print('{}[INFO]{} {}'.format(Colors.OKCYAN, Colors.ENDC, msg))

def log_success(msg):
    """Print success message"""
    print('{}[SUCCESS]{} {}'.format(Colors.OKGREEN, Colors.ENDC, msg))

def log_error(msg):
    """Print error message"""
    print('{}[ERROR]{} {}'.format(Colors.FAIL, Colors.ENDC, msg), file=sys.stderr)

def log_warning(msg):
    """Print warning message"""
    print('{}[WARNING]{} {}'.format(Colors.WARNING, Colors.ENDC, msg))

def log_progress(current, total, prefix='Progress'):
    """Display progress bar"""
    bar_length = 50
    filled_length = int(bar_length * current // total)
    bar = '█' * filled_length + '-' * (bar_length - filled_length)
    percent = 100 * (current / float(total))
    print('\r{}: |{}| {:.1f}% ({}/{})'.format(prefix, bar, percent, current, total), end='\r')
    if current == total:
        print()

def main(TRANSFER_LIST_FILE, NEW_DATA_FILE, OUTPUT_IMAGE_FILE, verbose=True, quiet=False):
    __version__ = '1.3'

    if sys.hexversion < 0x02070000:
        log_error("Python 2.7 or newer is required.")
        try:
            input = raw_input
        except NameError:
            pass
        input('Press ENTER to exit...')
        sys.exit(1)

    if not quiet:
        print('{}sdat2img - version: {}{}\n'.format(Colors.BOLD, __version__, Colors.ENDC))

    # Validate input files
    if not os.path.exists(TRANSFER_LIST_FILE):
        log_error('Transfer list file not found: {}'.format(TRANSFER_LIST_FILE))
        sys.exit(1)
    
    if not os.path.exists(NEW_DATA_FILE):
        log_error('New data file not found: {}'.format(NEW_DATA_FILE))
        sys.exit(1)

    def rangeset(src):
        src_set = src.split(',')
        try:
            num_set = [int(item) for item in src_set]
        except ValueError as e:
            log_error('Invalid rangeset data: {}'.format(src))
            sys.exit(1)
            
        if len(num_set) != num_set[0] + 1:
            log_error('Error on parsing following data to rangeset:\n{}'.format(src))
            sys.exit(1)

        return tuple([(num_set[i], num_set[i+1]) for i in range(1, len(num_set), 2)])

    def parse_transfer_list_file(path):
        try:
            with open(TRANSFER_LIST_FILE, 'r') as trans_list:
                # First line in transfer list is the version number
                version = int(trans_list.readline())

                # Second line in transfer list is the total number of blocks we expect to write
                new_blocks = int(trans_list.readline())

                if version >= 2:
                    # Third line is how many stash entries are needed simultaneously
                    trans_list.readline()
                    # Fourth line is the maximum number of blocks that will be stashed simultaneously
                    trans_list.readline()

                # Subsequent lines are all individual transfer commands
                commands = []
                for line in trans_list:
                    line = line.split(' ')
                    cmd = line[0]
                    if cmd in ['erase', 'new', 'zero']:
                        commands.append([cmd, rangeset(line[1])])
                    else:
                        # Skip lines starting with numbers, they are not commands anyway
                        if not cmd[0].isdigit():
                            log_warning('Skipping invalid command: "{}"'.format(cmd))

                return version, new_blocks, commands
        except IOError as e:
            log_error('Failed to read transfer list: {}'.format(e))
            sys.exit(1)
        except ValueError as e:
            log_error('Invalid transfer list format: {}'.format(e))
            sys.exit(1)

    BLOCK_SIZE = 4096
    
    log_info('Parsing transfer list...', verbose)
    version, new_blocks, commands = parse_transfer_list_file(TRANSFER_LIST_FILE)

    # Detect Android version
    version_names = {
        1: 'Android Lollipop 5.0',
        2: 'Android Lollipop 5.1',
        3: 'Android Marshmallow 6.x',
        4: 'Android Nougat 7.x / Oreo 8.x / Pie 9.x / Q 10.x+'
    }
    
    detected_version = version_names.get(version, 'Unknown Android version')
    log_info('Detected: {}'.format(detected_version), verbose)
    log_info('Total blocks to process: {}'.format(new_blocks), verbose)

    # Don't clobber existing files to avoid accidental data loss
    if os.path.exists(OUTPUT_IMAGE_FILE):
        log_warning('Output file already exists: {}'.format(OUTPUT_IMAGE_FILE))
        log_error('Remove it, rename it, or choose a different file name.')
        sys.exit(errno.EEXIST)

    try:
        output_img = open(OUTPUT_IMAGE_FILE, 'wb')
        new_data_file = open(NEW_DATA_FILE, 'rb')
    except IOError as e:
        log_error('Failed to open file: {}'.format(e))
        sys.exit(1)

    all_block_sets = [i for command in commands for i in command[1]]
    max_file_size = max(pair[1] for pair in all_block_sets) * BLOCK_SIZE

    log_info('Output image size: {:.2f} MB'.format(max_file_size / (1024 * 1024)), verbose)
    
    total_blocks_processed = 0
    total_blocks_to_process = sum(command[1][0][1] - command[1][0][0] for command in commands if command[0] == 'new')

    for command in commands:
        if command[0] == 'new':
            for block in command[1]:
                begin = block[0]
                end = block[1]
                block_count = end - begin
                
                if verbose:
                    log_info('Copying {} blocks into position {}...'.format(block_count, begin), verbose)

                # Position output file
                output_img.seek(begin * BLOCK_SIZE)
                
                # Copy one block at a time with progress
                while block_count > 0:
                    output_img.write(new_data_file.read(BLOCK_SIZE))
                    block_count -= 1
                    total_blocks_processed += 1
                    
                    if not quiet and not verbose:
                        log_progress(total_blocks_processed, total_blocks_to_process, 'Converting')
        else:
            if verbose:
                log_info('Skipping command: {}'.format(command[0]), verbose)

    # Make file larger if necessary
    if output_img.tell() < max_file_size:
        output_img.truncate(max_file_size)

    output_img.close()
    new_data_file.close()
    
    log_success('Conversion complete!')
    log_info('Output image: {}'.format(os.path.realpath(OUTPUT_IMAGE_FILE)), True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Convert Android sparse data (sdat) to image file',
        epilog='Visit XDA thread for more information.'
    )
    parser.add_argument('transfer_list', help='Transfer list file')
    parser.add_argument('new_data_file', help='System new dat file')
    parser.add_argument('output_image', nargs='?', default='system.img',
                       help='Output system image (default: system.img)')
    parser.add_argument('-v', '--verbose', action='store_true',
                       help='Enable verbose output')
    parser.add_argument('-q', '--quiet', action='store_true',
                       help='Quiet mode (minimal output)')
    
    args = parser.parse_args()
    
    # Set verbosity
    verbose = args.verbose
    quiet = args.quiet
    
    if quiet:
        verbose = False
    
    try:
        main(args.transfer_list, args.new_data_file, args.output_image, verbose, quiet)
    except KeyboardInterrupt:
        log_error('\nOperation cancelled by user')
        sys.exit(1)
    except Exception as e:
        log_error('Unexpected error: {}'.format(e))
        sys.exit(1)
