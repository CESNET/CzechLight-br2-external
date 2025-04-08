# EEPROM for Product Information

The "main EEPROM" contains information about the HW, including manufacturing metadata and optical calibration.
On ClearFog-based devices, these data are stored in an EEPROM at bus 2, address 0x53.
The internal layout currently conforms to the [ONIE EEPROM format](https://opencomputeproject.github.io/onie/design-spec/hw_requirements.html#board-eeprom-information-format).

## ONIE TLV Fields

| TLV ID | TLV Name | Description |
|---|---|---|
| `0x21` | Product Name | Human readable pretty name. Controlled by the vendor. |
| `0x22` | Part Number | CzechLight-specific device type ID, e.g., `sdn-roadm-line-g2`. |
| `0x23` | Serial Number | Assigned by manufacturer, visible on the front plate. |
| `0x24` | MAC #1 Base | A complete MAC address of the `eth0` interface. |
| `0x25` | Manufacture Date | Date of the final assembly of the device. |
| `0x2a` | Num MACs | Currently fixed at `0x03`. |
| `0x2b` | Manufacturer | This identifies the party which actually produced/manufactured the device, which is not necessarily the entity that's shown on the front plate. Controlled by the vendor. |
| `0x2c` | Country Code | Country-code in which the device was assembled. Controlled by the vendor. |
| `0x2d` | Vendor | The "final vendor" as shown on the front plate. |
| `0xfd` | Vendor Extension | Defined by CESNET, as [shown below](#czechlight-onie-tlv). |

### CzechLight-specific Vendor Extension TLV (#czechlight-onie-tlv)

There might be multiple instances of this TLV.
This document describes those which begin with a four-byte prefix `\x00\x00\x1f\x79` which corresponds to CESNET's IANA-assigned enterprise number, 8057.
The fifth byte is always `0x00` (signifying the "initial version").
Since the ONIE standard says that the entire byte-string, including the enterprise number, is 255 bytes long at most,
this leaves 250 bytes (255 - 4 - 1) as a useful payload.
In the next step, these 250 bytes from all TLVs which match this pattern are concatenated (in the same order as they appear in the EEPROM).
The resulting binary payload is then parsed.

The structure of the binary payload depends on the device type ID.
Typically, it stores low-level calibration parameters which are related to the optical performance of the device.
In the current version, it begins with a version number `0x00` and ends with a checksum.
The checksum is a big-endian `uint32\_t` in the CRC32 format (same as used in ONIE), and it covers the entire internal payload (from the leading version number right to the last byte before the CRC32).

From here on, "IL offset" refers to a static offset which is added to the value read from an underlying optical component when propagating the value towards the northbound API.
The offset is an `int8\_t` (two's complement) in one-tenths of a decibel (⅒ dB).
As an example, if the measured value -12.3 dBm is expected to correspond to a real value of -9.9 dBm, the parameter should be set to `0x18` (decimal 24).
If the measured value -12.3 dBm corresponds to an actual value of -12.5 dBm, the parameter should be set to `0xfe`.

#### BiDi Amplifiers (#payload-bidi-cplus1572)

```
0x00 # version number
0x08 # eight bytes
IL offset, C-band, west in
IL offset, C-band, west out
IL offset, C-band, east in
IL offset, C-band, east out
IL offset, L-band, west in
IL offset, L-band, west out
IL offset, L-band, east in
IL offset, L-band, east out
CRC32 # as computed over the previous 10 bytes
```

As an example, for a device with all IL offsets set to 0, the inner binary payload should be:

```
fd 0e 00 00 1f 79 00 00 08 00 00 00 00 00 00 00 00 58 52 ca 6e
^^ ^^ ^^^^^^^^^^^ ^^ ^^ ^^ ^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^
|  |  |           |  |  |  |                       |
|  |  |           |  |  |  |                       +-----------+
|  |  |           |  |  |  |                                   |
|  |  |           |  |  |  + Eight bytes of calibration data   |
|  |  |           |  |  |                                      |
|  |  |           |  |  + Length of the calibration data       |
|  |  |           |  |                                         |
|  |  |           |  + Version marker for the inner payload    |
|  |  |           |                                            |
|  |  |           |  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^             |
|  |  |           |           This part                        |
|  |  |           |       ...is covered by this checksum ------+
|  |  |           |
|  |  |           +-- CzechLight version-0 ONIE TLV payload follows
|  |  |
|  |  +-- CESNET's IANA prefix
|  |
|  +-- Length of the TLV field
|
+-- Vendor Extension ONIE TLV field identification
```

Alternatively, the same data could be conveyed, for example, as two TLVs set in this order:

```
fd 0d 00 00 1f 79 00 00 08 00 00 00 00 00 00 00 00 58 52 ca
^^ ^^ ^^^^^^^^^^^ ^^ ^^ ^^ ^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^
|  |  |           |  |  |  |                       |
|  |  |           |  |  |  |                       +-- First three bytes of the checksum
|  |  |           |  |  |  |
|  |  |           |  |  |  + Eight bytes of calibration data
|  |  |           |  |  |
|  |  |           |  |  + Length of the calibration data
|  |  |           |  |
|  |  |           |  + Version marker for the inner payload
|  |  |           |
|  |  |           +-- CzechLight version-0 ONIE TLV payload follows
|  |  |
|  |  +-- CESNET's IANA prefix
|  |
|  +-- Length of the TLV field
|
+-- Vendor Extension ONIE TLV field identification

fd 01 00 00 1f 79 00 6e
^^ ^^ ^^^^^^^^^^^ ^^ ^^
|  |  |           |  |
|  |  |           |  + The last byte of the checksum
|  |  |           |
|  |  |           +-- CzechLight version-0 ONIE TLV payload follows
|  |  |
|  |  +-- CESNET's IANA prefix
|  |
|  +-- Length of the TLV field
|
+-- Vendor Extension ONIE TLV field identification
```
