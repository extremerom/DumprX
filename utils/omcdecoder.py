#!/usr/bin/env python3
"""
OMC Decoder Module for DumprX
Decrypts XML files from Samsung optics partition using the OMCDecoder binary
"""

import os
import sys
import subprocess
import glob


class OMCDecoder:
    """
    Handler for Samsung OMC (OEM Multi-CSC) XML file decryption.
    Uses the omcdecoder binary to decrypt XML files from the optics partition.
    """
    
    def __init__(self, binary_path=None, logger=None):
        """
        Initialize the OMCDecoder.
        
        Args:
            binary_path: Path to the omcdecoder binary (optional)
            logger: Logger instance for logging (optional)
        """
        self.logger = logger
        
        # Determine binary path
        if binary_path and os.path.exists(binary_path):
            self.omcdecoder_bin = binary_path
        else:
            # Try to find the binary in common locations
            script_dir = os.path.dirname(os.path.abspath(__file__))
            possible_paths = [
                os.path.join(script_dir, 'bin', 'omcdecoder'),
                os.path.join(script_dir, 'OMCDecoder', 'omcdecoder'),
                'omcdecoder'  # Try PATH
            ]
            
            self.omcdecoder_bin = None
            for path in possible_paths:
                if os.path.exists(path) and os.access(path, os.X_OK):
                    self.omcdecoder_bin = path
                    break
            
            if not self.omcdecoder_bin:
                # Try which command
                try:
                    result = subprocess.run(['which', 'omcdecoder'], 
                                         capture_output=True, text=True, check=False)
                    if result.returncode == 0 and result.stdout.strip():
                        self.omcdecoder_bin = result.stdout.strip()
                except Exception as e:
                    # Could not locate omcdecoder in PATH, will fall through to error below
                    self._log_debug(f"Exception occurred while running 'which omcdecoder': {e}")
        
        if not self.omcdecoder_bin:
            raise FileNotFoundError(
                "omcdecoder binary not found. Please ensure it is built and available."
            )
        
        self._log_info(f"OMCDecoder initialized with binary: {self.omcdecoder_bin}")
    
    def _log_info(self, message):
        """Log info message"""
        if self.logger:
            self.logger.info(message)
        else:
            print(f"[INFO] {message}")
    
    def _log_warn(self, message):
        """Log warning message"""
        if self.logger:
            self.logger.warning(message)
        else:
            print(f"[WARN] {message}")
    
    def _log_error(self, message):
        """Log error message"""
        if self.logger:
            self.logger.error(message)
        else:
            print(f"[ERROR] {message}", file=sys.stderr)
    
    def _log_debug(self, message):
        """Log debug message"""
        if self.logger:
            self.logger.debug(message)
    
    def decode_file(self, input_file, output_file=None, in_place=False):
        """
        Decode a single OMC XML file.
        
        Args:
            input_file: Path to encrypted XML file
            output_file: Path to save decrypted XML (optional if in_place=True)
            in_place: If True, save output to input file
            
        Returns:
            bool: True if successful, False otherwise
        """
        if not os.path.exists(input_file):
            self._log_error(f"Input file not found: {input_file}")
            return False
        
        try:
            cmd = [self.omcdecoder_bin, '-d']
            
            if in_place:
                cmd.extend(['-i', input_file])
            else:
                if not output_file:
                    # Generate output filename
                    base = os.path.splitext(input_file)[0]
                    output_file = f"{base}_decrypted.xml"
                cmd.extend([input_file, output_file])
            
            self._log_debug(f"Running: {' '.join(cmd)}")
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=False
            )
            
            if result.returncode == 0:
                target = input_file if in_place else output_file
                self._log_info(f"Successfully decoded: {input_file} -> {target}")
                return True
            else:
                self._log_error(f"Failed to decode {input_file}")
                if result.stderr:
                    self._log_error(f"Error: {result.stderr}")
                return False
                
        except Exception as e:
            self._log_error(f"Exception while decoding {input_file}: {str(e)}")
            return False
    
    def find_xml_files(self, directory):
        """
        Find all XML files in a directory recursively.
        
        Args:
            directory: Directory to search
            
        Returns:
            list: List of XML file paths
        """
        xml_files = []
        
        if not os.path.exists(directory):
            self._log_warn(f"Directory not found: {directory}")
            return xml_files
        
        # Search for XML files
        for pattern in ['**/*.xml', '**/*.XML']:
            xml_files.extend(glob.glob(
                os.path.join(directory, pattern),
                recursive=True
            ))
        
        # Remove duplicates and sort
        xml_files = sorted(list(set(xml_files)))
        
        self._log_info(f"Found {len(xml_files)} XML file(s) in {directory}")
        return xml_files
    
    def decode_directory(self, directory, in_place=True, recursive=True):
        """
        Decode all XML files in a directory.
        
        Args:
            directory: Directory containing XML files
            in_place: If True, overwrite original files with decoded versions
            recursive: If True, search recursively
            
        Returns:
            tuple: (success_count, total_count)
        """
        xml_files = self.find_xml_files(directory)
        
        if not xml_files:
            self._log_warn(f"No XML files found in {directory}")
            return (0, 0)
        
        success_count = 0
        total_count = len(xml_files)
        
        self._log_info(f"Decoding {total_count} XML file(s)...")
        
        for xml_file in xml_files:
            if self.decode_file(xml_file, in_place=in_place):
                success_count += 1
        
        self._log_info(f"Decoded {success_count}/{total_count} XML file(s)")
        return (success_count, total_count)
    
    def process_optics_partition(self, optics_dir):
        """
        Process the optics partition to decode all XML files.
        
        Args:
            optics_dir: Path to extracted optics partition directory
            
        Returns:
            bool: True if processing was successful, False otherwise
        """
        if not os.path.exists(optics_dir):
            self._log_error(f"Optics directory not found: {optics_dir}")
            return False
        
        if not os.path.isdir(optics_dir):
            self._log_error(f"Optics path is not a directory: {optics_dir}")
            return False
        
        self._log_info(f"Processing optics partition: {optics_dir}")
        
        # Decode all XML files in the optics directory
        success, total = self.decode_directory(optics_dir, in_place=True)
        
        if total == 0:
            self._log_warn("No XML files found in optics partition")
            return True  # Not an error, just no files to decode
        
        if success == 0:
            self._log_error("Failed to decode any XML files")
            return False
        
        self._log_info(f"Successfully processed optics partition: {success}/{total} files decoded")
        return True


def main():
    """
    Main function for standalone usage.
    """
    import argparse
    
    parser = argparse.ArgumentParser(
        description='OMC Decoder - Decrypt Samsung optics partition XML files'
    )
    parser.add_argument(
        'input',
        help='Input XML file or directory containing XML files'
    )
    parser.add_argument(
        'output',
        nargs='?',
        help='Output file (for single file decoding)'
    )
    parser.add_argument(
        '-i', '--in-place',
        action='store_true',
        help='Overwrite input file(s) with decoded version(s)'
    )
    parser.add_argument(
        '-b', '--binary',
        help='Path to omcdecoder binary'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Verbose output'
    )
    
    args = parser.parse_args()
    
    try:
        decoder = OMCDecoder(binary_path=args.binary)
        
        if os.path.isfile(args.input):
            # Single file
            success = decoder.decode_file(
                args.input,
                args.output,
                in_place=args.in_place
            )
            sys.exit(0 if success else 1)
        elif os.path.isdir(args.input):
            # Directory
            success, total = decoder.decode_directory(
                args.input,
                in_place=args.in_place
            )
            sys.exit(0 if success > 0 else 1)
        else:
            print(f"Error: {args.input} is neither a file nor a directory", file=sys.stderr)
            sys.exit(1)
            
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
