#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DumprX - Android Firmware Extraction Tool
Main entry point for firmware extraction and processing
"""

import sys
import os
import argparse
from pathlib import Path
from typing import Optional, List
import time

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent))

from lib import logger, utils, config

__version__ = "3.0.0"
__author__ = "DumprX Contributors"

class DumprX:
    """Main DumprX firmware extraction class"""
    
    def __init__(self, args: argparse.Namespace):
        self.args = args
        self.logger = logger.get_logger()
        self.config = config.get_config()
        
        # Paths
        self.project_dir = Path(__file__).parent.absolute()
        self.input_dir = self.project_dir / 'input'
        self.utils_dir = self.project_dir / 'utils'
        self.output_dir = self.project_dir / 'out'
        self.temp_dir = self.output_dir / 'tmp'
        
        # Firmware input
        self.firmware_input: Optional[Path] = None
        self.firmware_extension = ""
        
        # Partition list
        self.partitions = ['system', 'vendor', 'product', 'system_ext', 'odm', 'mi_ext']
        
        # Tool paths
        self.setup_tool_paths()
        
        # Statistics
        self.start_time = time.time()
        self.partitions_extracted = 0
        self.partitions_failed = 0
    
    def setup_tool_paths(self):
        """Setup paths to all extraction tools"""
        bin_dir = self.utils_dir / 'bin'
        
        self.tools = {
            # 7zip
            '7zz': self._find_tool(['7zz', '7z']),
            
            # Binaries
            'simg2img': bin_dir / 'simg2img',
            'payload-dumper-go': bin_dir / 'payload-dumper-go',
            'magiskboot': bin_dir / 'magiskboot',
            'fsck.erofs': bin_dir / 'fsck.erofs',
            'extract.erofs': bin_dir / 'extract.erofs',
            'brotli': bin_dir / 'brotli',
            'zstd': bin_dir / 'zstd',
            
            # Python tools
            'lpunpack_tool': self.utils_dir / 'lpunpack_tool.py',
            'ext4_extract': self.utils_dir / 'ext4_extract.py',
            'payload_extract': self.utils_dir / 'payload_extract_tool.py',
            'cpio_tool': self.utils_dir / 'cpio_tool.py',
            'ozip_decrypt': self.utils_dir / 'ozip_decrypt.py',
            'kdz_unpack': self.utils_dir / 'kdz_unpack.py',
            'unpac_tool': self.utils_dir / 'unpac_tool.py',
            'sdat2img': self.utils_dir / 'sdat2img.py',
            'splituapp': self.utils_dir / 'splituapp.py',
        }
    
    def _find_tool(self, tool_names: List[str]) -> Optional[str]:
        """Find tool in PATH"""
        for tool in tool_names:
            if utils.command_exists(tool):
                return tool
        return None
    
    def show_banner(self):
        """Show DumprX banner"""
        banner = f"""
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║   ██████╗ ██╗   ██╗███╗   ███╗██████╗ ██████╗ ██╗  ██╗              ║
║   ██╔══██╗██║   ██║████╗ ████║██╔══██╗██╔══██╗╚██╗██╔╝              ║
║   ██║  ██║██║   ██║██╔████╔██║██████╔╝██████╔╝ ╚███╔╝               ║
║   ██║  ██║██║   ██║██║╚██╔╝██║██╔═══╝ ██╔══██╗ ██╔██╗               ║
║   ██████╔╝╚██████╔╝██║ ╚═╝ ██║██║     ██║  ██║██╔╝ ██╗              ║
║   ╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝              ║
║                                                                       ║
║              Android Firmware Extraction Tool v{__version__}            ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
"""
        print(banner)
    
    def show_usage(self):
        """Show usage information"""
        print("""
Usage: python3 dumper.py [OPTIONS] <firmware_file_or_directory>

  Supported File Formats:
    *.zip | *.rar | *.7z | *.tar | *.tar.gz | *.tgz | *.tar.md5
    *.ozip | *.ofp | *.ops | *.kdz | ruu_*exe
    system.new.dat | system.new.dat.br | system.new.dat.zst | system.new.dat.xz
    system.new.img | system.img | system-sign.img | UPDATE.APP
    *.emmc.img | *.img.ext4 | system.bin | system-p | payload.bin
    *.nb0 | .*chunk* | *.pac | *super*.img | *system*.sin
    *romfs* | *logo*.img | resource.img (Rockchip) | *.cpio

  Options:
    --verbose, -v     Enable verbose (debug) logging
    --quiet, -q       Quiet mode (only errors)
    --dry-run         Don't actually perform operations
    --no-colors       Disable colored output
    --config FILE     Use specific configuration file
    --help, -h        Show this help message

  Examples:
    python3 dumper.py firmware.zip
    python3 dumper.py --verbose firmware_directory/
    python3 dumper.py --config custom.conf firmware.tar.gz
""")
    
    def check_dependencies(self) -> bool:
        """Check for required dependencies"""
        required = ['python3', '7zz', 'file']
        return utils.check_dependencies(*required)
    
    def validate_input(self) -> bool:
        """Validate firmware input"""
        if not self.firmware_input:
            logger.error("No firmware input provided")
            return False
        
        if not self.firmware_input.exists():
            logger.error(f"Firmware input not found: {self.firmware_input}")
            return False
        
        return True
    
    def setup_directories(self) -> bool:
        """Setup working directories"""
        logger.step("Setting up directories")
        
        # Validate project directory
        if utils.has_spaces(str(self.project_dir)):
            logger.fatal("Project directory path contains spaces. Please move to a proper location.")
            return False
        
        logger.debug(f"Project directory: {self.project_dir}")
        
        # Remove old temp directory
        if self.temp_dir.exists():
            utils.remove(self.temp_dir)
        
        # Create directories
        for directory in [self.output_dir, self.temp_dir]:
            if not utils.mkdir(directory):
                logger.error(f"Failed to create directory: {directory}")
                return False
        
        logger.debug(f"Output directory: {self.output_dir}")
        logger.debug(f"Temp directory: {self.temp_dir}")
        
        return True
    
    def run(self) -> int:
        """Main execution method"""
        try:
            # Show banner
            if not self.args.quiet:
                self.show_banner()
            
            logger.header("DumprX - Android Firmware Extraction Tool")
            
            # Check dependencies
            if not self.check_dependencies():
                return 1
            
            # Setup directories
            if not self.setup_directories():
                return 1
            
            # Validate input
            if not self.validate_input():
                return 1
            
            # Process firmware
            logger.info(f"Processing firmware: {self.firmware_input}")
            
            # TODO: Add extraction logic here
            logger.warn("Extraction logic not yet implemented - work in progress")
            
            # Calculate duration
            duration = time.time() - self.start_time
            
            logger.success(f"Processing completed in {utils.format_duration(duration)}")
            logger.info(f"Output directory: {self.output_dir}")
            
            return 0
            
        except KeyboardInterrupt:
            logger.warn("\nOperation cancelled by user")
            return 130
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            if self.args.verbose:
                import traceback
                traceback.print_exc()
            return 1

def parse_arguments() -> argparse.Namespace:
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='DumprX - Android Firmware Extraction Tool',
        add_help=False
    )
    
    parser.add_argument('firmware_input', nargs='?', help='Firmware file or directory')
    parser.add_argument('-v', '--verbose', action='store_true', help='Enable verbose logging')
    parser.add_argument('-q', '--quiet', action='store_true', help='Quiet mode (only errors)')
    parser.add_argument('--dry-run', action='store_true', help="Don't perform operations")
    parser.add_argument('--no-colors', action='store_true', help='Disable colored output')
    parser.add_argument('--config', metavar='FILE', help='Configuration file')
    parser.add_argument('-h', '--help', action='store_true', help='Show help message')
    
    args = parser.parse_args()
    
    # Configure logger based on arguments
    if args.verbose:
        os.environ['DUMPRX_VERBOSE_MODE'] = 'true'
        logger.set_level('DEBUG')
    
    if args.quiet:
        os.environ['DUMPRX_QUIET_MODE'] = 'true'
    
    if args.no_colors:
        os.environ['DUMPRX_LOG_COLORS'] = 'false'
        logger.get_logger().use_colors = False
    
    return args

def main():
    """Main entry point"""
    args = parse_arguments()
    
    # Show help if requested or no input
    if args.help or not args.firmware_input:
        dumpr = DumprX(args)
        dumpr.show_usage()
        return 0 if args.help else 1
    
    # Initialize config
    if args.config:
        config.init_config(args.config)
    else:
        config.init_config()
    
    # Create DumprX instance and run
    dumpr = DumprX(args)
    dumpr.firmware_input = Path(args.firmware_input).absolute()
    dumpr.firmware_extension = dumpr.firmware_input.suffix.lower().lstrip('.')
    
    return dumpr.run()

if __name__ == '__main__':
    sys.exit(main())
