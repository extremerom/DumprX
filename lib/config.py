#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
DumprX Configuration Library
Handles configuration file reading and management
"""

import os
import configparser
from pathlib import Path
from typing import Optional, Dict, Any
from lib import logger

class Config:
    """Configuration manager for DumprX"""
    
    def __init__(self, config_file: Optional[str] = None):
        self.config = configparser.ConfigParser()
        self.config_file = config_file
        
        # Default configuration
        self.defaults = {
            'general': {
                'verbose': 'false',
                'quiet': 'false',
                'no_colors': 'false',
                'dry_run': 'false',
            },
            'paths': {
                'input_dir': 'input',
                'output_dir': 'out',
                'temp_dir': 'out/tmp',
                'utils_dir': 'utils',
            },
            'extraction': {
                'partitions': 'system vendor product system_ext odm mi_ext',
                'extract_boot': 'true',
                'extract_dtbo': 'true',
                'extract_vbmeta': 'true',
            },
            'logging': {
                'log_level': 'INFO',
                'log_file': '',
                'log_timestamp': 'true',
                'log_colors': 'true',
            },
        }
        
        # Load defaults
        for section, options in self.defaults.items():
            if not self.config.has_section(section):
                self.config.add_section(section)
            for key, value in options.items():
                self.config.set(section, key, value)
        
        # Load from file if provided
        if config_file:
            self.load(config_file)
    
    def load(self, config_file: str) -> bool:
        """Load configuration from file"""
        try:
            if not os.path.exists(config_file):
                logger.warn(f"Config file not found: {config_file}")
                return False
            
            self.config.read(config_file)
            self.config_file = config_file
            logger.debug(f"Loaded configuration from {config_file}")
            return True
        except Exception as e:
            logger.error(f"Failed to load config file: {e}")
            return False
    
    def save(self, config_file: Optional[str] = None) -> bool:
        """Save configuration to file"""
        target_file = config_file or self.config_file
        if not target_file:
            logger.error("No config file specified")
            return False
        
        try:
            config_dir = os.path.dirname(target_file)
            if config_dir:
                os.makedirs(config_dir, exist_ok=True)
            
            with open(target_file, 'w') as f:
                self.config.write(f)
            
            logger.debug(f"Saved configuration to {target_file}")
            return True
        except Exception as e:
            logger.error(f"Failed to save config file: {e}")
            return False
    
    def get(self, section: str, option: str, fallback: Any = None) -> str:
        """Get configuration value"""
        try:
            return self.config.get(section, option, fallback=fallback)
        except (configparser.NoSectionError, configparser.NoOptionError):
            return fallback
    
    def get_bool(self, section: str, option: str, fallback: bool = False) -> bool:
        """Get boolean configuration value"""
        try:
            value = self.config.get(section, option)
            return value.lower() in ('true', 'yes', '1', 'on')
        except (configparser.NoSectionError, configparser.NoOptionError):
            return fallback
    
    def get_int(self, section: str, option: str, fallback: int = 0) -> int:
        """Get integer configuration value"""
        try:
            return self.config.getint(section, option)
        except (configparser.NoSectionError, configparser.NoOptionError, ValueError):
            return fallback
    
    def set(self, section: str, option: str, value: Any):
        """Set configuration value"""
        if not self.config.has_section(section):
            self.config.add_section(section)
        self.config.set(section, option, str(value))
    
    def get_all(self, section: str) -> Dict[str, str]:
        """Get all options in a section"""
        try:
            return dict(self.config.items(section))
        except configparser.NoSectionError:
            return {}

# Global config instance
_config: Optional[Config] = None

def init_config(config_file: Optional[str] = None) -> Config:
    """Initialize global configuration"""
    global _config
    _config = Config(config_file)
    return _config

def get_config() -> Config:
    """Get global configuration instance"""
    global _config
    if _config is None:
        _config = Config()
    return _config
