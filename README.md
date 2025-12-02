<div align="center">

  <h1>DumprX</h1>

  <h4>Based Upon Phoenix Firmware Dumper from DroidDumps, with some Changes and Improvements</h4>

</div>


## What this really is

You might've used firmware extractor via dumpyara from https://github.com/AndroidDumps/. This toolkit is revamped edition of the tools with some improvements and feature additions.

## The improvements over dumpyara

- [x] dumpyara's and firmware_extractor's scripts are merged with handpicked shellcheck-ed and pylint-ed improvements
- [x] The script can download and dump firmware from different filehosters such as Mega.NZ, Mediafire.com, AndroidFileHost.com and from Google Drive URLs
- [x] File as-well-as Folder as an input is processed thoroughly to check all kinds of supported firmware types
- [x] All the external tools are now inherited into one place and unnecessary files removed
- [x] Binary tools are updated to latest available source
- [x] LG KDZ utilities are updated to support latest firmwares
- [x] Installation requirements are narrowed down to minimal for playing with this toolkit
- [x] Recovery Dump is made too
- [x] **NEW**: Comprehensive logging system with multiple levels (DEBUG, INFO, WARN, ERROR, FATAL)
- [x] **NEW**: Colored console output with progress tracking and spinners
- [x] **NEW**: Configuration file support (.dumprx.conf)
- [x] **NEW**: Command-line options (--verbose, --quiet, --dry-run, --help)
- [x] **NEW**: File logging support for troubleshooting
- [x] **NEW**: Modular library architecture for better code organization
- [x] **NEW**: Enhanced error handling and retry logic
- [x] **NEW**: Checksum verification for downloads
- [x] **NEW**: Samsung OMC decoder for automatic decryption of optics partition XML files

## Recommendations before Playing with Firmware Dumper

This toolkit can run in any Debian/Ubuntu distribution, Ubuntu Bionic and Focal would be best, other versions are not tested.

Support for Alpine Linux is added and tested. You can give it a try.

For any other UNIX Distributions, please refer to internal [Setup File](setup.sh) and install the required programs via their own package manager.

## Prepare toolkit dependencies / requirements

To prepare for this toolkit, run [Setup File](setup.sh) at first, which is needed only one time. After that, run [Main Script](dumper.sh) with proper argument.

## Usage

Run this toolkit with proper firmware file/folder path or URL

```bash
./dumper.sh 'Firmware File/Extracted Folder -OR- Supported Website Link'
```

### New Command-Line Options

```bash
# Basic usage
./dumper.sh firmware.zip

# Verbose mode (show debug messages)
./dumper.sh --verbose firmware.zip
./dumper.sh -v firmware.zip

# Quiet mode (only show errors)
./dumper.sh --quiet firmware.zip
./dumper.sh -q firmware.zip

# Dry run (don't actually perform operations)
./dumper.sh --dry-run firmware.zip

# Disable colored output
./dumper.sh --no-colors firmware.zip

# Use custom configuration file
./dumper.sh --config mycustom.conf firmware.zip

# Show help
./dumper.sh --help
```

### Advanced Usage

See [LOGGING.md](LOGGING.md) for detailed documentation on:
- Logging system features
- Configuration file options
- Environment variables
- Progress tracking
- Summary reports

Help Context:

```text
  >> Supported Websites:
        1. Directly Accessible Download Link From Any Website
        2. Filehosters like - mega.nz | mediafire | gdrive | onedrive | androidfilehost
         >> Must Wrap Website Link Inside Single-quotes ('')
  >> Supported File Formats For Direct Operation:
         *.zip | *.rar | *.7z | *.tar | *.tar.gz | *.tgz | *.tar.md5
         *.ozip | *.ofp | *.ops | *.kdz | ruu_*exe
         system.new.dat | system.new.dat.br | system.new.dat.xz
         system.new.img | system.img | system-sign.img | UPDATE.APP
         *.emmc.img | *.img.ext4 | system.bin | system-p | payload.bin
         *.nb0 | .*chunk* | *.pac | *super*.img | *system*.sin
```

## How to use it to Upload the Dump in GitHub

- Copy your GITHUB_TOKEN in a file named .github_token and add your GitHub Organization name in another file named .github_orgname inside the project directory.
  - If only Token is given but Organization is not, your Git Username will be used.
- Copy your Telegram Token in a file named .tg_token and Telegram Chat/Channel ID in another file named .tg_chat file if you want to publish the uploading info in Telegram.

## Troubleshooting

If you encounter HTTP 500 errors or other issues during upload, please refer to the [Troubleshooting Guide](TROUBLESHOOTING.md).

## Main Scripture Credit

As mentioned above, this toolkit is entirely focused on improving the Original Firmware Dumper available:  [Dumpyara](https://github.com/AndroidDumps/) [Phoenix Firmware Dumper](https://github.com/DroidDumps)

Credit for those tools goes to everyone whosoever worked hard to put all those programs in one place to make an awesome project.

## Download Utilities Credits

- mega-media-drive_dl.sh (for downloading from mega.nz, mediafire.com, google drive)
  - shell script, most of it's part belongs to badown by @stck-lzm
- afh_dl (for downloading from androidfilehosts.com)
  - python script, by @kade-robertson
- aria2c
- wget

## Internal Utilities Credits

- sdat2img.py (system-dat-to-img v1.2, python script)
  - by @xpirt, @luxi78, @howellzhu
- simg2img (Android sparse-to-raw images converter, binary built from source)
  - by @anestisb
- unsin (Xperia Firmware Unpacker v1.13, binary)
  - by @IgorEisberg
- extract\_android\_ota\_payload.py (OTA Payload Extractor, python script)
  - by @cyxx, with metadata update from [Android's update_engine Git Repository](https://android.googlesource.com/platform/system/update_engine/)
- extract-dtb.py (dtbs extractor v1.3, python script)
  - by @PabloCastellano
- dtc (Device Tree Compiler v1.6, binary built from source)
  - by kernel.org, from their [dtc Git Repository](https://git.kernel.org/pub/scm/utils/dtc/dtc.git)
- vmlinux-to-elf and kallsyms_finder (kernel binary to analyzable ELF converter, python scripts)
  - by @marin-m
- ozipdecrypt.py (Oppo/Oneplus .ozip Firmware decrypter v1.2, python script)
  - by @bkerler
- ofp\_qc\_extract.py and ofp\_mtk\_decrypt.py (Oppo .ofp firmware extractor, python scripts)
  - by @bkerler
- opscrypto.py (OnePlus/Oppo ops firmware extractor, python script)
  - by @bkerler
- lpunpack (OnePlus/Other super.img unpacker, binary built from source)
  - by @LonelyFool
- splituapp.py (UPDATE.APP extractor, python script)
  - by @superr
- pacextractor (Extractor of SpreadTrum firmware files with extension pac. See)
  - by @HemanthJabalpuri
- nb0-extract (Nokia/Sharp/Infocus/Essential nb0-extract, binary built from source)
  - by Heineken @Eddie07 / "FIH mobile"
- kdztools' unkdz.py and undz.py (LG KDZ and DZ Utilities, python scripts)
  - Originally by IOMonster (thecubed on XDA), Modified by @ehem (Elliott Mitchell) and improved by @steadfasterX
- RUU\_Decrypt\_Tool (HTC RUU/ROM Decryption Tool v3.6.8, binary)
  - by @nkk71 and @CaptainThrowback
- extract-ikconfig (.config file extractor from kernel image, shell script)
  - From within linux's source code by @torvalds
- unpackboot.sh (bootimg and ramdisk extractor, modified shell script)
  - Originally by @xiaolu and @carlitros900, stripped to unpack functionallity, by me @rokibhasansagar
- twrpdtgen by @SebaUbuntu
- OMCDecoder (Samsung OMC/CSC XML decoder, C++ binary)
  - by @soulr344, uses gzip-hpp by @mapbox

