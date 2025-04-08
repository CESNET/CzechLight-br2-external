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
| `0xfd` | Vendor Extension | Defined by CESNET, as shown below. |

## CzechLight-specific Vendor Extension TLV

There might be multiple instances of this TLV.
This document describes those which begin with a four-byte prefix `00 00 1f 79` which corresponds to CESNET's IANA-assigned enterprise number, 8057.
The fifth byte is always `0x00` (signifying the "CzechLight data, initial version").
Since the ONIE standard says that the entire byte-string, including the enterprise number, is 255 bytes long at most,
this leaves 250 bytes (255 - 4 - 1) as a useful payload per each instance of this TLV field.
In the next step, these 0-250 bytes from all TLVs which match this pattern are concatenated (in the same order as they appear in the EEPROM).
The resulting binary payload therefore consists of TLVs "Value" fields after stripping out the leading `00 00 1f 79 00` prefixes.

The binary payload stores serial numbers of those components which cannot be easily read by the host CPU, and also contains optical calibration data.
It has the following layout:

| Field no. | Length | Description |
|---|---|---|
| 0 | 1 | Length of the USB-UART serial number. |
| 1 | variable | Byte array (size is given in field no. 0), stores the ASCII serial number of the FTDI chip which connects the host's serial console over USB. |
| 2 | 2 | Length of optical calibration block. |
| 3 | Variable | Optical calibration data (size is given in field no. 2). Structure is described below. |
| 4 | 4 | CRC32 checksum spanning fields 0 to 3, the same CRC32 variant as ONIE's. |

### Optical calibration data

The calibration block always begins with a version number (currently fixed at `0x00`).
The structure of the remaining part of the block depends on the device type ID (as set in the TLV field ID `0x22`).
It typically consists of a number of "IL offset" definitions.
The `<IL offset>` refers to a static offset which is added to the value read from an underlying optical component when propagating the value towards the northbound API.
The offset is an `int8_t` (two's complement) in one-tenths of a decibel (⅒ dB).
As an example, if the measured value -12.3 dBm is expected to correspond to a real value of -9.9 dBm, the parameter should be set to `0x18` (decimal 24).
If the measured value -12.3 dBm corresponds to an actual value of -12.5 dBm, the parameter should be set to `0xfe`.

#### BiDi Amplifiers

| Field no. | Length | Type | Description |
|---|---|---|---|
| 0 | 1 | n/a | Version number, currently `0x00` |
| 1 | 1 | `<IL offset>` | C-band, west in |
| 2 | 1 | `<IL offset>` | C-band, west out |
| 3 | 1 | `<IL offset>` | C-band, east in |
| 4 | 1 | `<IL offset>` | C-band, east out |
| 5 | 1 | `<IL offset>` | L-band, west in |
| 6 | 1 | `<IL offset>` | L-band, west out |
| 7 | 1 | `<IL offset>` | L-band, east in |
| 8 | 1 | `<IL offset>` | L-band, east out |

## Examples

As an example, a dual-band BiDi optical amplifier with all IL offsets set to 0 and the FTDI serial number `DQ000MPW` might have the following vendor-extension TLV:

```
                     +----------------------------------------------------------------------------------+
                     |                                                                                  |
                     vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv                        |
fd 1d 00 00 1f 79 00 08 44 51 30 30 30 4d 50 57 00 09 00 00 00 00 00 00 00 00 00 02 60 51 4b            |
^^ ^^ ^^^^^^^^^^^ ^^ ^^ ^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^ ^^ ^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^            |
|  |  |           |  |  |                       |     |  |                       |                      |
|  |  |           |  |  |                       |     |  |                       + payload checksum is  |
|  |  |           |  |  |                       |     |  |                         computed over this --+
|  |  |           |  |  |                       |     |  |                         range
|  |  |           |  |  |                       |     |  |
|  |  |           |  |  |                       |     |  + Actual calibration data
|  |  |           |  |  |                       |     |
|  |  |           |  |  |                       |     |  ^^^^^^^^^^^ ^^^^^^^^^^^
|  |  |           |  |  |                       |     |     C-band     L-band
|  |  |           |  |  |                       |     |
|  |  |           |  |  |                       |     |  ^^^^^       ^^^^^
|  |  |           |  |  |                       |     |  |           |
|  |  |           |  |  |                       |     |  +-----------+-- west port
|  |  |           |  |  |                       |     |
|  |  |           |  |  |                       |     |        ^^^^^       ^^^^^
|  |  |           |  |  |                       |     |        |           |
|  |  |           |  |  |                       |     |        +-----------+-- east port
|  |  |           |  |  |                       |     |
|  |  |           |  |  |                       |     |  ^^    ^^    ^^    ^^
|  |  |           |  |  |                       |     |  |     |     |     |
|  |  |           |  |  |                       |     |  +-----+-----+-----+-- input power
|  |  |           |  |  |                       |     |
|  |  |           |  |  |                       |     |     ^^    ^^    ^^    ^^
|  |  |           |  |  |                       |     |     |     |     |     |
|  |  |           |  |  |                       |     |     +-----+-----+-----+-- output power
|  |  |           |  |  |                       |     |
|  |  |           |  |  |                       |     + Version number of optical calibration block
|  |  |           |  |  |                       |
|  |  |           |  |  |                       + Length of the calibration block
|  |  |           |  |  |
|  |  |           |  |  + USB-UART serial number
|  |  |           |  |
|  |  |           |  + Length of the USB-UART serial number
|  |  |           |
|  |  |           +-- CzechLight ONIE TLV payload, version 0
|  |  |
|  |  +-- CESNET's IANA prefix
|  |
|  +-- Length of the TLV field
|
+-- Vendor Extension ONIE TLV field identification
```

Alternatively, the same data could be conveyed, for example, as two TLVs set in this order:

```
fd 1c 00 00 1f 79 00 08 44 51 30 30 30 4d 50 57 00 09 00 00 00 00 00 00 00 00 00 02 60 51
^^ ^^ ^^^^^^^^^^^ ^^ ^^ ^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^ ^^ ^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^
|  |  |           |  |  |                       |     |  |                       |
|  |  |           |  |  |                       |     |  |                       + first three MSB
|  |  |           |  |  |                       |     |  |                         bytes of the checksum
|  |  |           |  |  |                       |     |  |
|  |  |           |  |  |                       |     |  + Actual calibration data
|  |  |           |  |  |                       |     |
|  |  |           |  |  |                       |     + Version number of optical calibration block
|  |  |           |  |  |                       |
|  |  |           |  |  |                       + Length of the calibration block
|  |  |           |  |  |
|  |  |           |  |  + USB-UART serial number
|  |  |           |  |
|  |  |           |  + Length of the USB-UART serial number
|  |  |           |
|  |  |           +-- CzechLight ONIE TLV payload, version 0
|  |  |
|  |  +-- CESNET's IANA prefix
|  |
|  +-- Length of the TLV field
|
+-- Vendor Extension ONIE TLV field identification

fd 06 00 00 1f 79 00 4b
^^ ^^ ^^^^^^^^^^^ ^^ ^^
|  |  |           |  |
|  |  |           |  + The last byte of the checksum
|  |  |           |
|  |  |           +-- CzechLight ONIE TLV payload, version 0
|  |  |
|  |  +-- CESNET's IANA prefix
|  |
|  +-- Length of the TLV field
|
+-- Vendor Extension ONIE TLV field identification
```
