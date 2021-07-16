![Microchip logo](https://raw.githubusercontent.com/wiki/Microchip-MPLAB-Harmony/Microchip-MPLAB-Harmony.github.io/images/microchip_logo.png)
![Harmony logo small](https://raw.githubusercontent.com/wiki/Microchip-MPLAB-Harmony/Microchip-MPLAB-Harmony.github.io/images/microchip_mplab_harmony_logo_small.png)

# Microchip MPLAB® Harmony 3 Release Notes
## PIC32CM MC00 Class B Release v1.0.1
### New features
1. Initial version of the Class B Library for PIC32CM MC00 devices

### Device Support and UL/VDE Certification Status

| **Device Family**   | **Certification Status**|
| ---                 | ---                     |
| PIC32CM MC00        | Planned |

### Known issues
1. The device runs startup tests with 4 MHz default CPU clock. This results in longer test duration.
2. RAM March routines are not checking for a valid minimum test size.
3. Flash CRC test does not store the intial status. If the test is invoked with invalid input arguments,
   the status returned will be correct but the result in SRAM will be the previously stored result. 
4. Time taken by self-tests are not characterized.


### Development Tools

* [MPLAB® X IDE v5.50](https://www.microchip.com/mplab/mplab-x-ide)
* [MPLAB® XC32 C/C++ Compiler v3.00](https://www.microchip.com/mplab/compilers)
* MPLAB® X IDE plug-ins:
    * MPLAB® Harmony Configurator (MHC) v3.7.2 and above.
* [Keil MDK IDE v5.34](https://www2.keil.com/mdk5)
* [ARMCC Compiler v6.16](https://www2.keil.com/mdk5)