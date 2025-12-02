#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DumprX Logging Library
Provides comprehensive logging functionality with multiple levels,
colored output, timestamps, and file logging support
"""

import sys
import os
from datetime import datetime
from typing import Optional
from enum import IntEnum

class LogLevel(IntEnum):
    """Log level enumeration"""
    DEBUG = 0
    INFO = 1
    SUCCESS = 2
    WARN = 3
    ERROR = 4
    FATAL = 5

class Colors:
    """ANSI color codes for terminal output"""
    RESET = '\033[0m'
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[0;33m'
    BLUE = '\033[0;34m'
    MAGENTA = '\033[0;35m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    DIM = '\033[2m'

class Logger:
    """Main logger class for DumprX"""
    
    def __init__(self):
        self.log_level = LogLevel.INFO
        self.log_file: Optional[str] = None
        self.use_colors = True
        self.use_timestamp = True
        self.quiet_mode = False
        self.verbose_mode = False
        
        # Initialize from environment variables
        self._init_from_env()
    
    def _init_from_env(self):
        """Initialize logger from environment variables"""
        # Log level
        level_str = os.getenv('DUMPRX_LOG_LEVEL', 'INFO').upper()
        self.set_level(level_str)
        
        # Log file
        log_file = os.getenv('DUMPRX_LOG_FILE', '')
        if log_file:
            self.set_log_file(log_file)
        
        # Colors
        self.use_colors = os.getenv('DUMPRX_LOG_COLORS', 'true').lower() == 'true'
        
        # Timestamp
        self.use_timestamp = os.getenv('DUMPRX_LOG_TIMESTAMP', 'true').lower() == 'true'
        
        # Quiet/Verbose modes
        self.quiet_mode = os.getenv('DUMPRX_QUIET_MODE', 'false').lower() == 'true'
        self.verbose_mode = os.getenv('DUMPRX_VERBOSE_MODE', 'false').lower() == 'true'
        
        if self.verbose_mode:
            self.set_level('DEBUG')
    
    def set_level(self, level: str):
        """Set log level from string"""
        level_map = {
            'DEBUG': LogLevel.DEBUG,
            'INFO': LogLevel.INFO,
            'SUCCESS': LogLevel.SUCCESS,
            'WARN': LogLevel.WARN,
            'ERROR': LogLevel.ERROR,
            'FATAL': LogLevel.FATAL
        }
        self.log_level = level_map.get(level.upper(), LogLevel.INFO)
    
    def set_log_file(self, log_file: str):
        """Set log file path"""
        try:
            log_dir = os.path.dirname(log_file)
            if log_dir:
                os.makedirs(log_dir, exist_ok=True)
            # Test if writable
            with open(log_file, 'a') as f:
                pass
            self.log_file = log_file
        except (OSError, IOError) as e:
            print(f"Warning: Cannot write to log file: {log_file}: {e}", file=sys.stderr)
            self.log_file = None
    
    def _get_timestamp(self) -> str:
        """Get formatted timestamp"""
        if self.use_timestamp:
            return datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        return ''
    
    def _format_message(self, level_name: str, message: str, color: str = '') -> str:
        """Format log message with optional color and timestamp"""
        timestamp = self._get_timestamp()
        
        if self.use_colors and color and sys.stdout.isatty():
            if timestamp:
                formatted = f"{color}[{level_name}]{Colors.RESET} {Colors.DIM}{timestamp}{Colors.RESET} {message}"
            else:
                formatted = f"{color}[{level_name}]{Colors.RESET} {message}"
        else:
            if timestamp:
                formatted = f"[{level_name}] {timestamp} {message}"
            else:
                formatted = f"[{level_name}] {message}"
        
        return formatted
    
    def _log(self, level: LogLevel, level_name: str, message: str, color: str = '', file=sys.stdout):
        """Core logging function"""
        if self.quiet_mode and level < LogLevel.ERROR:
            return
        
        if level < self.log_level:
            return
        
        formatted = self._format_message(level_name, message, color)
        print(formatted, file=file)
        
        # Write to log file (without colors)
        if self.log_file:
            try:
                with open(self.log_file, 'a') as f:
                    timestamp = self._get_timestamp()
                    if timestamp:
                        log_line = f"[{level_name}] {timestamp} {message}\n"
                    else:
                        log_line = f"[{level_name}] {message}\n"
                    f.write(log_line)
            except (OSError, IOError):
                pass  # Silently fail on log file write errors
    
    def debug(self, message: str):
        """Log debug message"""
        self._log(LogLevel.DEBUG, 'DEBUG', message, Colors.CYAN)
    
    def info(self, message: str):
        """Log info message"""
        self._log(LogLevel.INFO, 'INFO', message, Colors.BLUE)
    
    def success(self, message: str):
        """Log success message"""
        self._log(LogLevel.SUCCESS, 'SUCCESS', message, Colors.GREEN)
    
    def warn(self, message: str):
        """Log warning message"""
        self._log(LogLevel.WARN, 'WARN', message, Colors.YELLOW)
    
    def error(self, message: str):
        """Log error message"""
        self._log(LogLevel.ERROR, 'ERROR', message, Colors.RED, file=sys.stderr)
    
    def fatal(self, message: str):
        """Log fatal message and exit"""
        self._log(LogLevel.FATAL, 'FATAL', message, Colors.RED + Colors.BOLD, file=sys.stderr)
        sys.exit(1)
    
    def step(self, message: str):
        """Log step header (always visible)"""
        if not self.quiet_mode:
            formatted = f"\n{Colors.BOLD}{Colors.MAGENTA}{'=' * 70}{Colors.RESET}\n"
            formatted += f"{Colors.BOLD}{Colors.MAGENTA}▶ {message}{Colors.RESET}\n"
            formatted += f"{Colors.BOLD}{Colors.MAGENTA}{'=' * 70}{Colors.RESET}"
            print(formatted)
            
            if self.log_file:
                try:
                    with open(self.log_file, 'a') as f:
                        f.write(f"\n{'=' * 70}\n")
                        f.write(f"▶ {message}\n")
                        f.write(f"{'=' * 70}\n")
                except (OSError, IOError):
                    pass
    
    def header(self, message: str):
        """Log header (always visible)"""
        if not self.quiet_mode:
            formatted = f"\n{Colors.BOLD}{Colors.CYAN}{'*' * 70}{Colors.RESET}\n"
            formatted += f"{Colors.BOLD}{Colors.CYAN}{message.center(70)}{Colors.RESET}\n"
            formatted += f"{Colors.BOLD}{Colors.CYAN}{'*' * 70}{Colors.RESET}\n"
            print(formatted)
            
            if self.log_file:
                try:
                    with open(self.log_file, 'a') as f:
                        f.write(f"\n{'*' * 70}\n")
                        f.write(f"{message.center(70)}\n")
                        f.write(f"{'*' * 70}\n")
                except (OSError, IOError):
                    pass

# Global logger instance
_logger = Logger()

# Convenience functions
def debug(message: str):
    """Log debug message"""
    _logger.debug(message)

def info(message: str):
    """Log info message"""
    _logger.info(message)

def success(message: str):
    """Log success message"""
    _logger.success(message)

def warn(message: str):
    """Log warning message"""
    _logger.warn(message)

def error(message: str):
    """Log error message"""
    _logger.error(message)

def fatal(message: str):
    """Log fatal message and exit"""
    _logger.fatal(message)

def step(message: str):
    """Log step header"""
    _logger.step(message)

def header(message: str):
    """Log header"""
    _logger.header(message)

def set_level(level: str):
    """Set log level"""
    _logger.set_level(level)

def set_log_file(log_file: str):
    """Set log file"""
    _logger.set_log_file(log_file)

def get_logger() -> Logger:
    """Get the global logger instance"""
    return _logger
