#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DumprX UNPACK Module
Integrated from MIO-KITCHEN-SOURCE for advanced firmware unpacking capabilities
"""

# Core unpacking functionality
from .lpunpack import (
    SparseImage as LpSparseImage,
    LpUnpackError,
)

from .unpac import (
    unpac,
    MODE as UnpacMode,
)

from .cpio import (
    extract as cpio_extract,
    repack as cpio_repack,
    CpioMagicFormat,
)

from .ext4 import (
    Volume as Ext4Volume,
    Inode as Ext4Inode,
)

from .sparse_img import (
    SparseImage,
)

from .imgextractor import (
    Extractor,
)

# Payload extraction
from .payload_extract import (
    extract_partitions_from_payload,
    init_payload_info,
)

# Decryption/Special formats
from .ozipdecrypt import (
    main as decrypt_ozip,
)

from .opscrypto import (
    main as decrypt_ops,
)

# Utility functions
from .utils import (
    call,
    Sdat2img,
)

__all__ = [
    # Core
    'LpSparseImage',
    'LpUnpackError',
    'unpac',
    'UnpacMode',
    'cpio_extract',
    'cpio_repack',
    'CpioMagicFormat',
    'Ext4Volume',
    'Ext4Inode',
    'SparseImage',
    'Extractor',
    # Payload
    'extract_partitions_from_payload',
    'init_payload_info',
    # Decryption
    'decrypt_ozip',
    'decrypt_ops',
    # Utils
    'call',
    'Sdat2img',
]
