import binascii
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

model = sys.argv[1]
sn = sys.argv[2].encode('utf-8')
calibration = [struct.pack('>b', int(x)) for x in sys.argv[3:]]

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

print(','.join(f'{hex(t)}={" ".join(str(int(x)) for x in v)}' for (t, v) in headers if t == TLV_VENDOR_EXT))
