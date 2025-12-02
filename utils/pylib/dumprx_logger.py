#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DumprX Python Logging Adapter
Provides consistent logging interface for Python modules matching DumprX shell logging
"""

import sys
import os
from datetime import datetime
from enum import IntEnum


class LogLevel(IntEnum):
    """Log levels matching DumprX shell logger"""
    DEBUG = 0
    INFO = 1
    SUCCESS = 2
    WARN = 3
    ERROR = 4
    FATAL = 5


class Colors:
    """ANSI color codes"""
    RESET = '\033[0m'
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[0;33m'
    BLUE = '\033[0;34m'
    MAGENTA = '\033[0;35m'
    CYAN = '\033[0;36m'
    BOLD = '\033[1m'
    DIM = '\033[2m'


class DumprXLogger:
    """Logging class matching DumprX shell logger functionality"""
    
    def __init__(self, name=None):
        self.name = name or 'DumprX'
        self.level = LogLevel.INFO
        self.use_colors = os.getenv('DUMPRX_LOG_COLORS', 'true').lower() == 'true'
        self.use_timestamp = os.getenv('DUMPRX_LOG_TIMESTAMP', 'true').lower() == 'true'
        self.quiet_mode = os.getenv('DUMPRX_QUIET_MODE', 'false').lower() == 'true'
        self.verbose_mode = os.getenv('DUMPRX_VERBOSE_MODE', 'false').lower() == 'true'
        
        if self.verbose_mode:
            self.level = LogLevel.DEBUG
        
        # Get log level from environment
        env_level = os.getenv('DUMPRX_LOG_LEVEL', 'INFO').upper()
        if env_level in ['DEBUG', 'INFO', 'SUCCESS', 'WARN', 'ERROR', 'FATAL']:
            self.level = LogLevel[env_level]
    
    def _format_message(self, level_name, symbol, message):
        """Format log message with timestamp and level"""
        parts = []
        
        if self.use_timestamp:
            timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            parts.append(f'[{timestamp}]')
        
        parts.append(f'[{level_name}]')
        
        if symbol:
            parts.append(symbol)
        
        parts.append(str(message))
        
        return ' '.join(parts)
    
    def _log(self, level, level_name, color, symbol, message):
        """Core logging function"""
        if level < self.level:
            return
        
        # Skip console in quiet mode except for errors
        if self.quiet_mode and level < LogLevel.ERROR:
            return
        
        formatted = self._format_message(level_name, symbol, message)
        
        # Apply color if enabled
        if self.use_colors and color:
            formatted = f'{color}{formatted}{Colors.RESET}'
        
        # Write to stderr for errors, stdout for everything else
        stream = sys.stderr if level >= LogLevel.ERROR else sys.stdout
        print(formatted, file=stream, flush=True)
    
    def debug(self, message):
        """Log debug message"""
        self._log(LogLevel.DEBUG, 'DEBUG', Colors.DIM, '🔍', message)
    
    def info(self, message):
        """Log info message"""
        self._log(LogLevel.INFO, 'INFO', Colors.CYAN, 'ℹ️', message)
    
    def success(self, message):
        """Log success message"""
        self._log(LogLevel.SUCCESS, 'SUCCESS', Colors.GREEN, '✓', message)
    
    def warn(self, message):
        """Log warning message"""
        self._log(LogLevel.WARN, 'WARN', Colors.YELLOW, '⚠️', message)
    
    def error(self, message):
        """Log error message"""
        self._log(LogLevel.ERROR, 'ERROR', Colors.RED, '✗', message)
    
    def fatal(self, message):
        """Log fatal error and exit"""
        self._log(LogLevel.FATAL, 'FATAL', Colors.RED + Colors.BOLD, '💀', message)
        sys.exit(1)
    
    def step(self, message):
        """Log step message (like log_step in shell)"""
        self._log(LogLevel.INFO, 'STEP', Colors.BLUE + Colors.BOLD, '▶', message)
    
    def progress(self, current, total, prefix='Progress'):
        """Display progress"""
        if self.quiet_mode:
            return
        
        bar_length = 50
        filled_length = int(bar_length * current // total)
        bar = '█' * filled_length + '░' * (bar_length - filled_length)
        percent = 100 * (current / float(total))
        
        msg = f'{prefix}: |{bar}| {percent:.1f}% ({current}/{total})'
        
        if self.use_colors:
            msg = f'{Colors.CYAN}{msg}{Colors.RESET}'
        
        print(f'\r{msg}', end='', flush=True, file=sys.stdout)
        
        if current >= total:
            print()  # New line when complete


# Global logger instance
logger = DumprXLogger()


# Convenience functions
def debug(msg):
    logger.debug(msg)


def info(msg):
    logger.info(msg)


def success(msg):
    logger.success(msg)


def warn(msg):
    logger.warn(msg)


def error(msg):
    logger.error(msg)


def fatal(msg):
    logger.fatal(msg)


def step(msg):
    logger.step(msg)


def progress(current, total, prefix='Progress'):
    logger.progress(current, total, prefix)
