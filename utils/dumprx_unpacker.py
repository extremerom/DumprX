#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DumprX Unpacker - Unified Python Unpacker Wrapper
Provides access to all unpacking modules from MIO-KITCHEN-SOURCE
"""

import sys
import os

# Add parent directory to path for proper imports
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)


def main():
    """Main entry point for unpacker wrapper"""
    if len(sys.argv) < 2:
        print("Usage: dumprx_unpacker.py <command> [args...]")
        print("\nCommands:")
        print("  payload      - Extract payload.bin files")
        print("  lpunpack     - Extract super.img files")
        print("  imgextract   - Extract ext4 image files")
        print("  sdat2img     - Convert system.new.dat to img")
        print("  ozipdecrypt  - Decrypt OZIP files")
        print("  ofp_qc       - Decrypt OFP (Qualcomm) files")
        print("  ofp_mtk      - Decrypt OFP (MTK) files")
        print("  opscrypto    - Decrypt OPS files")
        print("  unpac        - Unpack PAC files (SpreadTrum)")
        print("  nb0extract   - Extract NB0 files")
        print("  unkdz        - Unpack KDZ files")
        print("  undz         - Unpack DZ files")
        print("  cpio         - Unpack/repack CPIO archives")
        print("  fspatch      - Patch fs_config before unpacking")
        print("  contextpatch - Patch file_contexts before repacking")
        print("  romfs        - Unpack ROMFS files")
        print("  aml          - Unpack Amlogic V2 images")
        print("  allwinner    - Unpack Allwinner images")
        print("  qsb          - Process QSB images")
        print("  mkdtboimg    - Parse/Unpack/Repack DTBO images")
        print("  rsceutil     - Unpack/repack Rockchip resource images")
        print("  squashfs     - Handle SquashFS images")
        print("  ntpi         - Unpack NTPI images")
        sys.exit(1)
    
    command = sys.argv[1]
    
    # Remove the command from argv so the module sees its own args
    sys.argv = [sys.argv[0]] + sys.argv[2:]
    
    try:
        if command == 'payload':
            from pylib import payload_extract
            payload_extract.main()
        elif command == 'lpunpack':
            from pylib import lpunpack
            lpunpack.main()
        elif command == 'imgextract':
            from pylib import imgextractor
            # imgextractor doesn't have a main, we'll need to create a simple one
            print("imgextract: Use as a library, not a command")
            sys.exit(1)
        elif command == 'ozipdecrypt':
            from pylib import ozipdecrypt
            ozipdecrypt.main()
        elif command == 'ofp_qc':
            from pylib import ofp_qc_decrypt
            ofp_qc_decrypt.main()
        elif command == 'ofp_mtk':
            from pylib import ofp_mtk_decrypt
            ofp_mtk_decrypt.main()
        elif command == 'opscrypto':
            from pylib import opscrypto
            opscrypto.main()
        elif command == 'unpac':
            from pylib import unpac
            unpac.main()
        elif command == 'nb0extract':
            from pylib import nb0_extractor
            nb0_extractor.main()
        elif command == 'unkdz':
            from pylib import unkdz
            unkdz.main()
        elif command == 'undz':
            from pylib import undz
            undz.main()
        elif command == 'cpio':
            from pylib import cpio
            cpio.main()
        elif command == 'fspatch':
            from pylib import fspatch
            fspatch.main()
        elif command == 'contextpatch':
            from pylib import contextpatch
            contextpatch.main()
        elif command == 'romfs':
            from pylib import romfs_parse
            romfs_parse.main()
        elif command == 'aml':
            from pylib import aml_image
            aml_image.main()
        elif command == 'allwinner':
            from pylib import allwinnerimage
            allwinnerimage.main()
        elif command == 'qsb':
            from pylib import qsb_imger
            qsb_imger.main()
        elif command == 'mkdtboimg':
            from pylib import mkdtboimg
            mkdtboimg.main()
        elif command == 'rsceutil':
            from pylib import rsceutil
            rsceutil.main()
        elif command == 'squashfs':
            from pylib import squashfs
            squashfs.main()
        elif command == 'ntpi':
            from pylib import ntpi_unpacker
            ntpi_unpacker.main()
        else:
            print(f"Unknown command: {command}")
            sys.exit(1)
    except Exception as e:
        print(f"Error executing {command}: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
