#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Utility functions for DumprX core modules
Adapted from MIO-KITCHEN-SOURCE
"""

from __future__ import absolute_import, print_function
import os
import sys
from utils.core.lpunpack import SparseImage  # Use the SparseImage from lpunpack.py
from utils.core.logging_helper import log_info, log_success, log_error, log_warning

def simg2img(path):
    """
    Convert Sparse image to Raw Image
    :param path: Path to sparse image file
    :return: None (modifies file in-place)
    """
    try:
        with open(path, 'rb') as fd:
            sparse_img = SparseImage(fd)
            if sparse_img.check():
                log_info('Sparse image detected.')
                log_info('Converting to raw image...')
                unsparse_file = sparse_img.unsparse()
                log_success('Sparse conversion complete')
                
                # Replace original file with unsparsed version
                if os.path.exists(unsparse_file):
                    os.remove(path)
                    os.rename(unsparse_file, path)
            else:
                log_info(f"{path} is not sparse. Skipping conversion.")
    except Exception as e:
        log_error(f"Error converting sparse image: {e}")
        raise
