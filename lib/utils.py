#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DumprX Utilities Library
Common utility functions used across the dumper scripts
"""

import os
import sys
import shutil
import hashlib
import subprocess
import re
from pathlib import Path
from typing import Optional, List, Union
from lib import logger

def command_exists(command: str) -> bool:
    """Check if a command exists in PATH"""
    return shutil.which(command) is not None

def check_dependencies(*commands: str) -> bool:
    """Verify required commands are available"""
    missing_deps = []
    for cmd in commands:
        if not command_exists(cmd):
            missing_deps.append(cmd)
    
    if missing_deps:
        logger.error(f"Missing required dependencies: {', '.join(missing_deps)}")
        logger.info("Please run setup.sh to install dependencies")
        return False
    return True

def sanitize_filename(filename: str) -> str:
    """Sanitize filename (remove special characters, spaces)"""
    # Remove or replace problematic characters
    sanitized = re.sub(r'[^a-zA-Z0-9._-]', '_', filename)
    return sanitized

def human_filesize(file_path: Union[str, Path]) -> str:
    """Get file size in human-readable format"""
    try:
        size = os.path.getsize(file_path)
    except (OSError, IOError):
        return "N/A"
    
    if size < 1024:
        return f"{size}B"
    elif size < 1048576:  # 1024 * 1024
        return f"{size // 1024}KB"
    elif size < 1073741824:  # 1024 * 1024 * 1024
        return f"{size // 1048576}MB"
    else:
        return f"{size // 1073741824}GB"

def calculate_checksum(file_path: Union[str, Path], algorithm: str = 'sha256') -> Optional[str]:
    """Calculate file checksum"""
    if not os.path.isfile(file_path):
        logger.error(f"File not found: {file_path}")
        return None
    
    try:
        if algorithm == 'md5':
            hasher = hashlib.md5()
        elif algorithm == 'sha1':
            hasher = hashlib.sha1()
        elif algorithm == 'sha256':
            hasher = hashlib.sha256()
        else:
            logger.error(f"Unsupported hash algorithm: {algorithm}")
            return None
        
        with open(file_path, 'rb') as f:
            for chunk in iter(lambda: f.read(8192), b''):
                hasher.update(chunk)
        
        return hasher.hexdigest()
    except (OSError, IOError) as e:
        logger.error(f"Error calculating checksum: {e}")
        return None

def has_spaces(path: str) -> bool:
    """Check if path contains spaces"""
    return ' ' in path

def mkdir(directory: Union[str, Path]) -> bool:
    """Create directory if it doesn't exist"""
    try:
        os.makedirs(directory, exist_ok=True)
        return True
    except (OSError, IOError) as e:
        logger.error(f"Failed to create directory {directory}: {e}")
        return False

def remove(path: Union[str, Path]) -> bool:
    """Remove file or directory"""
    try:
        if os.path.isfile(path):
            os.remove(path)
        elif os.path.isdir(path):
            shutil.rmtree(path)
        return True
    except (OSError, IOError) as e:
        logger.debug(f"Failed to remove {path}: {e}")
        return False

def copy(src: Union[str, Path], dst: Union[str, Path]) -> bool:
    """Copy file or directory"""
    try:
        if os.path.isfile(src):
            shutil.copy2(src, dst)
        elif os.path.isdir(src):
            shutil.copytree(src, dst, dirs_exist_ok=True)
        return True
    except (OSError, IOError) as e:
        logger.error(f"Failed to copy {src} to {dst}: {e}")
        return False

def move(src: Union[str, Path], dst: Union[str, Path]) -> bool:
    """Move file or directory"""
    try:
        shutil.move(src, dst)
        return True
    except (OSError, IOError) as e:
        logger.error(f"Failed to move {src} to {dst}: {e}")
        return False

def run_command(cmd: List[str], check: bool = True, capture_output: bool = False, 
                timeout: Optional[int] = None, cwd: Optional[str] = None) -> subprocess.CompletedProcess:
    """Run a command and return the result"""
    try:
        result = subprocess.run(
            cmd,
            check=check,
            capture_output=capture_output,
            text=True,
            timeout=timeout,
            cwd=cwd
        )
        return result
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed: {' '.join(cmd)}")
        logger.error(f"Return code: {e.returncode}")
        if e.stderr:
            logger.error(f"Error output: {e.stderr}")
        raise
    except subprocess.TimeoutExpired as e:
        logger.error(f"Command timed out after {timeout}s: {' '.join(cmd)}")
        raise
    except FileNotFoundError:
        logger.error(f"Command not found: {cmd[0]}")
        raise

def is_archive(file_path: Union[str, Path]) -> bool:
    """Check if file is an archive based on extension"""
    archive_extensions = {'.zip', '.rar', '.7z', '.tar', '.tar.gz', '.tgz', 
                         '.tar.bz2', '.tbz2', '.tar.xz', '.txz', '.gz', '.bz2', '.xz'}
    ext = Path(file_path).suffix.lower()
    # Check for double extensions like .tar.gz
    if ext in {'.gz', '.bz2', '.xz'}:
        stem = Path(file_path).stem
        if stem.endswith('.tar'):
            return True
    return ext in archive_extensions

def is_image_file(file_path: Union[str, Path]) -> bool:
    """Check if file is an image file based on extension"""
    image_extensions = {'.img', '.raw', '.bin', '.ext4', '.erofs', '.sin', '.pac'}
    ext = Path(file_path).suffix.lower()
    return ext in image_extensions

def get_cpu_count() -> int:
    """Get number of CPU cores"""
    try:
        return os.cpu_count() or 1
    except:
        return 1

def find_files(directory: Union[str, Path], pattern: str = '*', 
               recursive: bool = True) -> List[Path]:
    """Find files matching pattern in directory"""
    path = Path(directory)
    if not path.exists():
        return []
    
    if recursive:
        return list(path.rglob(pattern))
    else:
        return list(path.glob(pattern))

def get_file_type(file_path: Union[str, Path]) -> str:
    """Get file type using 'file' command"""
    try:
        result = subprocess.run(
            ['file', '-b', str(file_path)],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "Unknown"

def extract_archive(archive_path: Union[str, Path], output_dir: Union[str, Path],
                   tool: str = '7zz') -> bool:
    """Extract archive using specified tool"""
    try:
        if not os.path.exists(archive_path):
            logger.error(f"Archive not found: {archive_path}")
            return False
        
        mkdir(output_dir)
        
        if tool == '7zz' and command_exists('7zz'):
            cmd = ['7zz', 'x', '-y', str(archive_path), f'-o{output_dir}']
        elif tool == 'unzip' and command_exists('unzip'):
            cmd = ['unzip', '-q', str(archive_path), '-d', str(output_dir)]
        elif tool == 'tar' and command_exists('tar'):
            cmd = ['tar', '-xf', str(archive_path), '-C', str(output_dir)]
        else:
            logger.error(f"Extraction tool not available: {tool}")
            return False
        
        result = run_command(cmd, check=False, capture_output=True)
        return result.returncode == 0
    except Exception as e:
        logger.error(f"Failed to extract archive: {e}")
        return False

def is_root() -> bool:
    """Check if running as root"""
    return os.geteuid() == 0 if hasattr(os, 'geteuid') else False

def get_terminal_width() -> int:
    """Get terminal width"""
    try:
        return shutil.get_terminal_size().columns
    except:
        return 80

def prompt_yes_no(question: str, default: bool = False) -> bool:
    """Prompt user for yes/no answer"""
    if default:
        prompt = f"{question} [Y/n]: "
    else:
        prompt = f"{question} [y/N]: "
    
    while True:
        response = input(prompt).strip().lower()
        if not response:
            return default
        if response in ('y', 'yes'):
            return True
        if response in ('n', 'no'):
            return False
        print("Please answer 'y' or 'n'")

def format_duration(seconds: float) -> str:
    """Format duration in human-readable format"""
    if seconds < 60:
        return f"{seconds:.1f}s"
    elif seconds < 3600:
        minutes = int(seconds // 60)
        secs = seconds % 60
        return f"{minutes}m {secs:.0f}s"
    else:
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        secs = seconds % 60
        return f"{hours}h {minutes}m {secs:.0f}s"
