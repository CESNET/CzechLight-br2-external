#!/usr/bin/env python
import argparse
import binascii
import datetime
import re
import struct
import sys

TLV_PRODUCT_NAME=0x21
TLV_PART_NO=0x22
TLV_SN=0x23
TLV_MAC1=0x24
TLV_MFG_DATE=0x25
TLV_DEVICE_VERSION=0x26
TLV_LABEL_REVISION=0x27
TLV_PLATFROM_NAME=0x28
TLV_ONIE_VER=0x29
TLV_NUM_MACS=0x2a
TLV_MFG=0x2b
TLV_CC=0x2c
TLV_VENDOR=0x2d
TLV_DIAG_VERSION=0x2e
TLV_SERVICE_TAG=0x2f
TLV_VENDOR_EXT=0xfd

def czechlight_blob(model, sn, calibration):
    """
    Returns CzechLight-specific ONIE TLV headers fields with serialized data.
    This field can use at most 255 bytes, including the vendor prefix,
    thus it may be split into multiple TLV_VENDOR_EXT entries.

    >>> czechlight_blob(model='sdn-bidi-cplus1572-g2', sn='ph-tech-0001', calibration=[23, 5, 0, 1, -122, -128, 127, 32])
    [(253, b'\\x00\\x00\\x1fy\\x00\\x0cph-tech-0001\\x00\\t\\x00\\x17\\x05\\x00\\x01\\x86\\x80\\x7f 8\\x81\\x84\\x93')]
    """
    sn = sn.encode('utf-8')
    calibration = [struct.pack('>b', int(x)) for x in calibration]
    if model == 'sdn-bidi-cplus1572-g2':
        if len(calibration) == 8:
            calibration = b''.join(calibration)
        elif len(calibration) == 0:
            calibration = b'\x00' * 8
        else:
            raise RuntimeError(f'CzechLight model {model} requires 8 bytes of calibration data')
        # version info
        calibration = b'\x00' + calibration
    else:
        raise RuntimeError('Unknown CzechLight model')

    cesnet_prefix = b'\x00\x00\x1f\x79'
    czechlight_prefix = cesnet_prefix + b'\x00'
    one_czechlight_payload_len = 250
    # one_czechlight_payload_len = 10

    czechlight_payload = struct.pack('>b', len(sn)) + sn + struct.pack('>H', len(calibration)) + calibration
    czechlight_payload += struct.pack('>I', binascii.crc32(czechlight_payload))

    headers = []

    while len(czechlight_payload) > one_czechlight_payload_len:
        tmp = czechlight_payload[0:one_czechlight_payload_len]
        czechlight_payload = czechlight_payload[one_czechlight_payload_len:]
        headers.append((TLV_VENDOR_EXT, czechlight_prefix + tmp))
    headers.append((TLV_VENDOR_EXT, czechlight_prefix + czechlight_payload))

    return headers

def generic(model, part_number, serial_number, mac_base, mfg_date, device_version, manufacturer, vendor, country):
    """
    Returns generic ONIE TLV headers fields with serialized data

    >>> generic(model='sdn-bidi-cplus1572-g2', part_number='PHTECH-CL-SDN-BIDI-C-L', serial_number='ph-tech-0001', mac_base='00:11:17:01:00:28', mfg_date=datetime.datetime(2025,5,26,12,34,56), device_version=99, manufacturer='Photonic tech.', vendor='Photonic tech.', country='CZ')
    [(45, b'\\x0ePhotonic tech.'), (34, b'\\x16PHTECH-CL-SDN-BIDI-C-L'), (33, b'\\x15sdn-bidi-cplus1572-g2'), (35, b'\\x0cph-tech-0001'), (36, b'\\x06\\x00\\x11\\x17\\x01\\x00('), (42, b'\\x02\\x00\\x03'), (37, b'\\x1305/26/2025 12:34:56'), (43, b'\\x0ePhotonic tech.'), (44, b'\\x02CZ'), (38, b'\\x01c')]
    """

    if mfg_date is None:
        mfg_date = datetime.datetime.now()
    def text_field(t, v):
        blob = v.encode('utf-8')
        return (t, struct.pack(f'>B{len(blob)}s', len(blob), blob))
    headers = []
    headers.append(text_field(TLV_VENDOR, vendor))
    headers.append(text_field(TLV_PART_NO, part_number))
    headers.append(text_field(TLV_PRODUCT_NAME, model))
    headers.append(text_field(TLV_SN, serial_number))
    mac_address = re.fullmatch('([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2})', mac_base)
    headers.append((TLV_MAC1, struct.pack('>7B', 6, *[int(x, 16) for x in mac_address.groups()])))
    headers.append((TLV_NUM_MACS, struct.pack('>BH', 2, 3)))
    date_str = mfg_date.strftime('%m/%d/%Y %H:%M:%S')
    if len(date_str) != 19:
        raise RuntimeError(f'unexpected date length for {mfg_date}: {len(mfg_date)}')
    headers.append(text_field(TLV_MFG_DATE, date_str))
    headers.append(text_field(TLV_MFG, manufacturer))
    headers.append(text_field(TLV_CC, country))
    headers.append((TLV_DEVICE_VERSION, struct.pack('>BB', 1, device_version)))
    return headers

def as_onie_blob(tlvs):
    """
    Serializes TLV headers into ONIE EEPROM blob

    >>> as_onie_blob([(33, b'\\x15sdn-bidi-cplus1572-g2'), (253, b'!\\x00\\x00\\x1fy\\x00\\x0cph-tech-0001\\x00\\t\\x00\\x17\\x05\\x00\\x01\\x86\\x80\\x7f 8\\x81\\x84\\x93')])
    b'TlvInfo\\x00\\x01\\x00@!\\x15sdn-bidi-cplus1572-g2\\xfd!\\x00\\x00\\x1fy\\x00\\x0cph-tech-0001\\x00\\t\\x00\\x17\\x05\\x00\\x01\\x86\\x80\\x7f 8\\x81\\x84\\x93\\xfe\\x04#\\x91\\xba1'
    """

    buf = b''
    for (t, blob) in tlvs:
        buf += struct.pack('>B', t) + blob
    buf = b'TlvInfo\x00\x01' +  struct.pack('>H', len(buf) + 6) + buf + b'\xfe\x04'
    buf += struct.pack('>I', binascii.crc32(buf))
    return buf

def regex_type(pattern: str, example: str):
    def validate(val):
        if not re.fullmatch(pattern, val):
            raise argparse.ArgumentTypeError(f'invalid value, expected e.g. {example}')
        return val
    return validate

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Generate ONIE-ish EEPROM content for CzechLight devices',
    )
    parser.add_argument('--model', required=True, help='Device ID string as recognized by CzechLight SW (e.g., sdn-bidi-cplus1572-g2)')
    parser.add_argument('--serial', required=True, help='Vendor-specific serial number as printed on the chassis')
    parser.add_argument('--mac', required=True, help='First MAC address', type=regex_type('([0-9a-f]{2})(:[0-9a-f]{2}){5}', '00:11:17:01:ab:33'))
    parser.add_argument('--vendor', required=True,
                        help='The name of the vendor who contracted with the manufacturer for the production of this device. This is typically the company name on the outside of the device.')
    parser.add_argument('--manufacturer', required=True,
                        help='Name of the entity that manufactured the device.')
    parser.add_argument('--part-no', required=True, help='Vendor-specific part number, e.g., PG-CL-SDN_dualBiDi-C-L')
    parser.add_argument('--country', required=True, type=regex_type('[A-Z]{2}', 'CZ'))
    parser.add_argument('--ftdi', required=True, help='USB-to-UART S/N')
    parser.add_argument('--date', help='When the device was manufactured, e.g., "2025-05-26 12:34:56"', type=datetime.datetime.fromisoformat)
    parser.add_argument('--version', default=1, help='Vendor-defined revision of the device', type=int)
    parser.add_argument('calibration', nargs='*')
    args = parser.parse_args()
    headers = generic(args.model, args.part_no, args.serial, args.mac, args.date, args.version, args.manufacturer, args.vendor, args.country) + \
        [(t, struct.pack('>B', len(without_len)) + without_len) for (t, without_len) in czechlight_blob(args.model, args.ftdi, args.calibration)]
    sys.stdout.buffer.write(as_onie_blob(headers))
