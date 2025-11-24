#!/usr/bin/env python
# -*- coding: utf-8 -*-
# REFACTORED: 2025-11-24 (Enhanced logging and error handling)

from __future__ import absolute_import
from __future__ import print_function
from builtins import input

import re
import cgi
import json
import math
import sys
import clint
import argparse
import humanize
import requests

mirror_url = r"https://androidfilehost.com/libs/otf/mirrors.otf.php"
url_matchers = [
    re.compile(r"fid=(?P<id>\d+)")
]

# ANSI color codes
class Colors:
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    CYAN = '\033[96m'
    ENDC = '\033[0m'

def log_info(msg):
    print('{}[INFO]{} {}'.format(Colors.CYAN, Colors.ENDC, msg))

def log_success(msg):
    print('{}[SUCCESS]{} {}'.format(Colors.OKGREEN, Colors.ENDC, msg))

def log_error(msg):
    print('{}[ERROR]{} {}'.format(Colors.FAIL, Colors.ENDC, msg))

def log_warning(msg):
    print('{}[WARNING]{} {}'.format(Colors.WARNING, Colors.ENDC, msg))

class Mirror:
    def __init__(self, **entries):
        self.__dict__.update(entries)

def download_file(url, fname, fsize):
    """Download file with progress bar"""
    try:
        log_info('Downloading: {}'.format(fname))
        dat = requests.get(url, stream=True)
        with open(fname, 'wb') as f:
            bar = clint.textui.progress.bar(dat.iter_content(chunk_size=4096),
                                            expected_size=math.floor(fsize / 4096) + 1)
            for chunk in bar:
                f.write(chunk)
                f.flush()
        return True
    except Exception as e:
        log_error('Download failed: {}'.format(e))
        return False

def get_file_info(url):
    """Get file information from URL"""
    try:
        data = requests.head(url)
        rsize = int(data.headers['Content-Length'])
        size = humanize.naturalsize(rsize, binary=True)
        ftype, fdata = cgi.parse_header(data.headers['Content-Disposition'])
        return (rsize, size, fdata['filename'])
    except Exception as e:
        log_error('Failed to get file info: {}'.format(e))
        return None

def download_servers(fid):
    """Get list of download mirrors"""
    try:
        log_info('Obtaining available download servers...')
        cook = requests.get("https://androidfilehost.com/?fid={}".format(fid))
        post_data = {
            "submit": "submit",
            "action": "getdownloadmirrors",
            "fid": fid
        }
        mirror_headers = {
            "User-Agent": ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                           "AppleWebKit/537.36 (KHTML, like Gecko) "
                           "Chrome/63.0.3239.132 Safari/537.36"),
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            "Referer": "https://androidfilehost.com/?fid={}".format(fid),
            "X-MOD-SBB-CTYPE": "xhr",
            "X-Requested-With": "XMLHttpRequest"
        }
        mirror_data = requests.post(mirror_url,
                                    headers=mirror_headers,
                                    data=post_data,
                                    cookies=cook.cookies)
        
        mirror_json = json.loads(mirror_data.text)
        if not mirror_json["STATUS"] == "1" or not mirror_json["CODE"] == "200":
            log_error('Failed to retrieve server list')
            return None
        
        mirror_opts = []
        for mirror in mirror_json["MIRRORS"]:
            mirror_opts.append(Mirror(**mirror))
        
        log_success('Found {} download server(s)'.format(len(mirror_opts)))
        return mirror_opts
        
    except Exception as e:
        log_error('Failed to get download servers: {}'.format(e))
        return None

def match_url(url):
    """Match AndroidFileHost URL pattern"""
    for pattern in url_matchers:
        res = pattern.search(url)
        if res is not None:
            return res
    return None

def main(link=None):
    """Main download function"""
    given_url = link
    if not link:
        given_url = input("Provide an AndroidFileHost URL: ")
    
    file_match = match_url(given_url)
    if file_match:
        file_id = file_match.group('id')
        log_info('File ID: {}'.format(file_id))
        
        servers = download_servers(file_id)
        if servers == None:
            log_error('Unable to retrieve download servers')
            log_warning('You may have been rate limited')
            return 1
        
        svc = len(servers) - 1
        print('\nAvailable servers:')
        for idx, server in enumerate(servers):
            print('  {}: {}'.format(idx, server.name))
        
        choice = "0"
        if not link:
            choice = input("\nChoose a server to download from (0-{}): ".format(svc))
        
        while not choice.isdigit() or int(choice) > svc or int(choice) < 0:
            choice = input("Not a valid input, choose again (0-{}): ".format(svc))
        
        server = servers[int(choice)]
        log_info('Selected server: {}'.format(server.name))
        
        file_info = get_file_info(server.url)
        if file_info is None:
            log_error('Failed to get file information')
            return 1
        
        rsize, size, fname = file_info
        log_info('File: {}'.format(fname))
        log_info('Size: {}'.format(size))
        
        if download_file(server.url, fname, rsize):
            log_success('Download complete!')
            return 0
        else:
            log_error('Download failed')
            return 1
    else:
        log_error('This does not appear to be a supported AndroidFileHost link')
        log_info('Expected format: https://androidfilehost.com/?fid=XXXXXXXXX')
        return 1

def entry_main():
    """Entry point with argument parsing"""
    parser = argparse.ArgumentParser(
        description='Download files from AndroidFileHost',
        epilog='Supports interactive and direct download modes'
    )
    parser.add_argument("-i", "--interactive", action="store_true", default=False,
                        help="Run afh-dl in interactive mode")
    parser.add_argument("-l", "--link", action="store", nargs="?", type=str, default=None,
                        help="AndroidFileHost link to download")
    parsed = parser.parse_args()
    
    try:
        if parsed.interactive == True:
            return main()
        elif not parsed.link == None:
            return main(parsed.link)
        else:
            log_error('A link must be specified if not in interactive mode')
            log_info('Use -h for help')
            return 1
    except KeyboardInterrupt:
        log_error('\nOperation cancelled by user')
        return 1
    except Exception as e:
        log_error('Unexpected error: {}'.format(e))
        return 1

if __name__ == '__main__':
    sys.exit(entry_main())
