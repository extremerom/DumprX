#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Logging helper for DumprX Core modules
Provides Colors class matching the DumprX logging pattern used in sdat2img.py and splituapp.py
"""

from __future__ import absolute_import, print_function
import sys

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
    CYAN = '\033[96m'

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

def log_debug(msg, verbose=True):
    """Print debug message"""
    if verbose:
        print('{}[DEBUG]{} {}'.format(Colors.CYAN, Colors.ENDC, msg))
