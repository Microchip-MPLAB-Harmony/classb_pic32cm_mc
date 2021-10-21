# MPLAB® Harmony Class B Library for PIC32CM MC00 devices

The Class B Library provides APIs to perform self-tests for the on-board systems of the microcontroller.

**Features Tested by the Class B Library**

Following table shows the components tested by the Class B library.

|Component|Reference \(Table H1 of IEC 60730-1\)|Fault/Error|Acceptable Measures|
|---------|-------------------------------------|-----------|-------------------|
|CPU Registers|1.1|Stuck-at|Static memory test|
|CPU Program Counter|1.3|Stuck-at|Static memory test|
|Interrupts|2|No interrupt / too frequent interrupt|Functional test|
|CPU Clock|3|Wrong frequency|Frequency monitoring|
|Flash|4.1|All single bit faults|Modified checksum|
|SRAM|4.2|DC fault|Static memory test|
|SRAM data path|5.1|Stuck-at|Static memory test|
|SRAM data path|5.2|Wrong address|Static memory test|
|Digital I/O|7.1|Abnormal operation|Input comparison or output verification|

**Class B Peripheral Library Usage**

This topic describes the basic architecture of the Class B library and provides information and examples on how to use it. APIs defined by the Class B library can be used either by the start-up code or by the application code. The application may use PLIBs, drivers or middleware from the Harmony 3 software framework along with the Class B library code.

Abstraction Model

The following picture shows positioning of Class B library in a Harmony 3 based application.

![](GUID-2CFCDCD8-83A3-453B-BB00-B398598611C3-low.png)

**Start-up vs. Run-time**

The Class B library contains many self-test routines those can be executed at startup and run-time. If a self-test is executed at startup, it is called as a Start-up Self-test \(SST\) and if it is executed at run-time, then it is called a Run-time Self-test \(RST\). There are a few self-tests which can be used only as SST or as RST, such self-tests have SST or RST in the API name eg: `CLASSB_RST_IOTest()`, `CLASSB_SST_InterruptTest()`. If a self-test API does not have SST or RST in its name, then it can be used at startup as well as runtime.

**Start-up Self-test \(SST\)**

SSTs are used to test a component inside the microcontroller before it is initialized and used. When the Class B library is added via MHC, the selected SSTs are inserted into the `_on_reset()` function which is called from the `Reset_Handler()`. This means that none of the data initialization could have happened before running SSTs. So, the Class B library initializes necessary variables before using them. It is not mandatory to test all the components during startup. The SRAM can be tested partially if a faster startup is needed by the application. In this case, modify the corresponding configuration macro \(`CLASSB_SRAM_STARTUP_TEST_SIZE`\) present in `classb.h` file to change the size of the tested area.

**Run-time Self-test \(RST\)**

RSTs can be used by the application during run-time to check safe operation of different components in the microcontroller. These tests are non-destructive. In the case of run-time tests, the application shall decide which test to execute when.

**Components in the Library**

The Class B library contains self-test routines for different components inside the CPU.

![](GUID-2E1A324F-CC7E-42BF-B865-A5F9A2D6333A-low.png)

**Critical and Non-critical Components**

Based on the impact of failure, different components inside this Class B library are categorized as critical or non-critical.

If the self-test for CPU registers, PC or Flash detects a failure, the code execution is stopped, and it remains in an infinite loop. This is to prevent unsafe code execution. In the case of non-critical components, a failsafe function \(`CLASSB_SelfTest_FailSafe`\) is called when a failure is detected. This function contains a software break point and an infinite loop. Further code shall be added into this function as per the application need. The failsafe function must not return to the Class B library, since it is called due to a self-test failure. Avoid use of features which depend on the failed component. For example, if self-test for clock is failed, it is not advisable to use UART for error reporting as BAUD rate may not be accurate. In the case of SRAM failure, avoid the use of function calls or use of variables in SRAM. A simple error reporting mechanism in this case of SRAM failure can be toggling of an IO pin.

**Critical Components**

1.  CPU registers including the Program Counter

2.  Internal Flash program memory


Generic Flow of Critical Tests

![](GUID-950CED79-D1C0-483F-B9E9-852BB00D3AAE-low.png)

**Non-critical Components**

1.  CPU clock

2.  IO pins

3.  Internal SRAM

4.  Interrupts


Generic Flow of Non-Critical Tests

![](GUID-402961DC-5098-45C4-9FE0-F87D48B6374E-low.png)

**Self-tests for Components in the Library**

**CPU Registers**

The ARM® Cortex®-M0+ is the CPU on the PIC32CM MC00 devices. The Class B library checks the processor core registers for stuck-at faults. The stuck-at condition causes register bit to remain at logic 0 or logic 1. Code execution should be stopped if this error condition is detected in any of the CPU registers.

This self-test follows the register save/restore convention specified by AAPCS. It can be used at startup as well as run-time. The Program Counter \(PC\) self-test is designed as a separate test since this register cannot be checked with usual test data patterns.

Flow chart of the self-test for CPU registers

![](GUID-166631A1-EEBB-4060-A9E1-C4247F6CE440-low.png)

**Program Counter \(PC\)**

The self-test for PC checks whether a stuck-at condition is present in the PC register. The stuck-at condition causes register bit to remain at logic 0 or logic 1. Code execution should be stopped if this error condition is detected.

The self-test for PC calls multiple functions in predefined order and verifies that each function is executed and returns the expected value. If the return values of all test functions are correct, the Program Counter is assumed to be working fine. This self-test can be used at startup as well as run-time.

Flow chart of the self-test for Program Counter \(PC\)

![](GUID-58C32B9E-2455-4D5D-AA05-DE04E2AAEECF-low.png)

**Flash**

The internal flash memory of the device needs to be checked for proper functionality. The self-test for internal flash performs CRC check on the internal flash memory of the device. The address range is configurable for this self-test. It runs CRC-32 algorithm with reversed representation of the polynomial 0x04C11DB7 and compares the generated checksum with the expected checksum. It uses table-based approach where the table is generated during the execution.

This self-test uses a CRC-32 generation function. This function is used inside the Class B library to generate CRC-32 of the internal Flash memory but it can be used on any contiguous memory area. The flash self-test can be used at startup as well as run-time. If this self-test is used during start up, it must be ensured that the CRC of the application area is precalculated and stored at a specific memory address which is passed as an argument for the Flash self-test. If this self-test detects a failure, it remains in an infinite loop.

Flow chart of the self-test for internal flash program memory

![](GUID-BDD32550-044E-4B84-BA33-620536CDFF77-low.png)

**SRAM**

Self-test for the SRAM element looks for stuck-at faults, DC faults and addressing faults with the help of RAM March algorithms. One of the input arguments to this self-test selects the algorithm. This self-test copies the data from the tested area of the SRAM into the reserved area in the SRAM and restore the data after the test. Refer to section Configuring the Library for the details on reserving the SRAM. The stack pointer is moved to the reserved area in the SRAM before running this self-test. The SRAM self-test can be used at startup as well as run-time.

It provides three standard tests to detect error conditions,

1.  March C

2.  March C minus

3.  March B


Fault Coverage for March Algorithms

|Name|Fault Coverage|
|----|--------------|
|March C|Addressing faults, Stuck-at faults, Transition faults, all coupling faults|
|March C-|Unlinked addressing faults, Stuck-at faults, Transition faults, all coupling faults|
|March B|Addressing faults, Stuck-at faults, Transition faults, Linked idempotent coupling faults, Linked inversion coupling faults|

Flow chart of the self-test for SRAM

![](GUID-8E6604F8-FA39-4CFC-847E-D439881E59F2-low.png)

Flow chart of the internal routine for SRAM self-test

![](GUID-3EFECA4B-00A4-4514-AB80-6F570021F3A4-low.png)

**Clock**

The self-test for CPU clock checks whether the CPU clock frequency is within the permissible range. It uses RTC and SysTick to measure the CPU clock frequency. The RTC is clocked at 32768 Hz from the 32 kHz External Crystal Oscillator and CPU clock can be from any other high frequency oscillator. If the CPU clock frequency is within specified error limit, it returns PASS. The test duration is defined by one of the input arguments. The clock self-test can be used at startup as well as run-time.

Note

1.  This self-test uses the RTC peripheral. Thus, if it is used during run-time, the RTC shall not be used by the application for continuous modes such as real time clock or calendar. If the RTC is used for some other purpose, it must be reconfigured after running the clock self-test.

2.  Keep the clock test duration lesser than the WDT timeout period, to avoid the WDT resetting the device.


Flow chart of the self-test for CPU clock frequency

![](GUID-1DABC9F1-CFC1-4406-A636-DD84F87563DA-low.png)

**Interrupt**

The self-test for this element checks the interrupts functionality of the microcontroller. It configures the Nested Vectored Interrupt Controller \(NVIC\), the Real-Time Counter \(RTC\) and the Timer Counter 0 \(TC0\) peripherals to test the interrupt handling mechanism. It verifies that at least one interrupt is generated and handled properly. This self-test also checks whether the number of interrupts generated are too many within a given time period. It reports a PASS if the RTC has generated at least one interrupt and the total number of interrupts generated by the TC0 is greater than one and less than the specified upper limit. The clock used for RTC is 1kHz from the internal OSCULP32K and for TC0 the clock is same as the default CPU clock \(48MHz from the DFLL48M\). The interrupt self-test can be used only at startup.

Note

1.  This startup self-test utilizes the interrupts generated by RTC and TC0. For run-time testing of interrupts, a separate self-test need to be developed.


Flow chart of the self-test for interrupts

![](GUID-B9D8A546-D3CD-4EC4-B704-BD0030842C01-low.png)

**IO pin**

The self-test for IO pins verifies that any output pin is able to keep the configured logic state on the pin and any input pin is able to read the logic state present on the pin.

As the exact use of an IO pin is decide by the application, it is the responsibility of the application to configure the IO pin direction and drive the pin to the expected state before calling this self-test. Before testing an output pin, call CLASSB\_IO\_InputSamplingEnable\(\) function to enable input sampling for the IO pin. When testing an input pin, ensure that the IO pin is externally kept at a defined logic state. The IO pin self-test can be used only at run-time.

Flow chart of the self-test for IO pins

![](GUID-651007EF-CA66-4239-950D-76A2ACFCFCE8-low.png)

**Class B Peripheral Library - Timing of self-tests**

Peripherals other than Flash and SRAM

|Name|Time \(in microseconds\)|
|----|-----------------------|
|CLASSB\_CPU\_RegistersTest|14|
|CLASSB\_CPU\_PCTest|8|
|CLASSB\_RST\_IOTest|5|
|CLASSB\_ClockTest|5100|
|CLASSB\_SST\_InterruptTest|9200|

Flash and SRAM

|Name|Time \(in milliseconds\)|Tested size|
|----|-----------------------|-----------|
|CLASSB\_FlashCRCTest|12|32 KB|
|CLASSB\_SRAM\_MarchTestInit|282|8 KB|

Note

1.  Timing is measured using onchip peripherals \(SysTick and TC\) at optimization level -O1 with CPU running at 48MHz from the internal 48MHz oscillator. Before using these self-tests in an application it is recommended to check self-test timings with the required configuration \(CPU clock, compiler optimization, memory size\).

2.  Timing measured for CLASSB\_SRAM\_MarchTestInit using the ‘March C’ algorithm.

3.  Following IDE and toolchain are used for timing measurements

    1.  MPLAB X v5.50

    2.  XC32 Compiler v3.00


**Configuring the Library \(MPLAB X\)**

This section provides details necessary to integrate the Class B library with other software components.

**Optimization Requirements**

The self-test routines provides by the Class B software has specific optimization requirements which are listed in the following table. If the optimization level for the project is different from what is listed in this table, file level optimization has to be applied as per this table.

|File|Optimization Level|
|----|------------------|
|classb\_cpu\_pc\_test.c, classb\_sram\_algorithm.c|-O0|
|All other files \(.h, .c, .S\)|-O1 or -O2 or -O3|

**Applying File Level Optimization MPLAB X**

![](GUID-F59EF12D-14B0-4A19-B57C-F66D1D3F9335-low.png)

**Reserved SRAM area for the Class B library**

It is required to reserve 1kB of SRAM for exclusive use by the Class B library. This reserved SRAM must not be accessed from outside the Class B library. To check or update test results, use the corresponding interface APIs. When the Class B library is added into the project with the help of MHC, the linker setting is modified by MHC as shown below. In this example, the PIC32CM1216MC00048 device with 16kB of SRAM is used.

`-DRAM_ORIGIN=0x20000400,-DRAM_LENGTH=0x3C00`

![](GUID-E4577708-C82B-4F16-8E78-599548007E5E-low.png)

**Modified Startup Sequence**

When generating project with help of MPLAB Harmony 3, the startup code is present in a file named `startup_xc32`. This file contains the `Reset_Handler` which has all startup code that runs before the `main()` function. Initialization of the Class B library is done from the `_on_reset` function which is the first function to be executed from the `Reset_Handler`. The function named `CLASSB_Startup_Tests` executes all startup self-tests inserted into `classb.c` file by the MHC. If none of the self-tests are failed, this function returns `CLASSB_STARTUP_TEST_PASSED`. If any of the startup self-tests are failed, this function does not return becasue of the following reason. In the case of critical failures \(CPU registers or internal flash\), the corresponding self-test remains in an infinite loop to avoid unsafe execution of code. The self-tests for SRAM, Clock and Interrupt are considered non-critical since it may be possible to execute a fail-safe function after detecting a failure. In such case, the `CLASSB_SelfTest_FailSafe()` function is called when a failure is detected. Since the default implementation of `CLASSB_SelfTest_FailSafe` routine contains an infinite loop, it won't return to the caller.

Note

1.  The library defines the `_on_reset` function and handles some of the reset causes. The application developer shall insert functions to handle the rest of the reset causes.


**WDT Test and Timeout**

The Watchdog timer is used as a recovery mechanism in case of software failures. The Class B library enables the WDT and checks whether a WDT reset is issued if the timer is not cleared. In `CLASSB_Startup_Tests` \(in file `classb.c`\), before performing startup self-tests, the WDT timeout period is configured. It can be modified after generating the project. During startup, the device runs from 4 MHz internal clock. Before running any self-test which takes longer time \(SRAM or Flash test\), configuring the CPU clock at 48 MHz will help to recude the exection time. If any of these self-tests takes more time than the WDT timeout period, it results in a WDT reset. Thus, properly configuring the WDT period is essential during startup as well as runtime.

![](GUID-BCB7FF3B-CFD5-4CA3-80A8-CBDF25BA22E0-low.png) ![](GUID-94C97E0C-BC14-42EB-AE69-3042034CE9B5-low.png)

**Configuring Startup Tests via MHC**

Clone the `classb_pic32cm_mc` repo. When an MPLAB Harmony 3 project is created, the MHC lists all available components that can be added to the project. The self-tests which need to run during startup can be configured via MHC. The `Configuration Options` menu appears with a mouse click on the `Class B Library` component inside the `Project Graph`. The configurations done via MHC does not configure the library, instead it helps to modify the input arguments and to decide whether to run a specific test during startup.

**Class B Library Interface**

|Name|Description|
|----|-----------|
|**Constants Summary**| |
|CLASSB\_CLOCK\_DEFAULT\_CLOCK\_FREQ|Default CPU clock speed.|
|CLASSB\_CLOCK\_ERROR\_PERCENT|Clock error percentage selected for startup test.|
|CLASSB\_CLOCK\_MAX\_CLOCK\_FREQ|Maximum CPU clock speed.|
|CLASSB\_CLOCK\_MAX\_SYSTICK\_VAL|Upper limit of SysTick counter.|
|CLASSB\_CLOCK\_MAX\_TEST\_ACCURACY|Maximum detectable accuracy for clock self-test.|
|CLASSB\_CLOCK\_MUL\_FACTOR|Multiplication factor used in clock test.|
|CLASSB\_CLOCK\_RTC\_CLK\_FREQ|RTC clock frequency.|
|CLASSB\_CLOCK\_TEST\_RTC\_RATIO\_NS|Duration of RTC clock in nano seconds.|
|CLASSB\_CLOCK\_TEST\_RATIO\_NS\_MS|Ratio of milli second to nano second.|
|CLASSB\_COMPL\_RESULT\_ADDR|Address of one's complement test results.|
|CLASSB\_FLASH\_CRC32\_POLYNOMIAL|CRC-32 polynomial.|
|CLASSB\_INTERRUPT\_COUNT\_VAR\_ADDR|Address of the variable which keeps interrupt count.|
|CLASSB\_INTERRUPT\_TEST\_VAR\_ADDR|Address of the variable which keeps interrupt test internal status.|
|CLASSB\_INTR\_DEVICE\_VECT\_OFFSET|Defines the offset for first device specific interrupt.|
|CLASSB\_INTR\_MAX\_INT\_COUNT|Defines the upper limit for interrupt count.|
|CLASSB\_INTR\_TEST\_RTC\_COUNT|Defines the counter value for RTC peripheral.|
|CLASSB\_INTR\_TEST\_TC\_COUNT|Defines the counter value for TC0 peripheral.|
|CLASSB\_INTR\_VECTOR\_TABLE\_SIZE|Defines the size of the vector table.|
|CLASSB\_INVALID\_TEST\_ID|Invalid test ID.|
|CLASSB\_ONGOING\_TEST\_VAR\_ADDR|Address at which the ID of ongoing test is stored.|
|CLASSB\_RESULT\_ADDR|Address of test results.|
|CLASSB\_SRAM\_ALL\_32BITS\_HIGH|Defines name for max 32-bit unsigned value.|
|CLASSB\_SRAM\_APP\_AREA\_START|Defines the start address of the SRAM for the application.|
|CLASSB\_SRAM\_BUFF\_START\_ADDRESS|SRAM test buffer start address.|
|CLASSB\_SRAM\_FINAL\_WORD\_ADDRESS|Final word address in the SRAM.|
|CLASSB\_SRAM\_STARTUP\_TEST\_SIZE|Size of the SRAM tested during startup.|
|CLASSB\_SRAM\_TEST\_BUFFER\_SIZE|Defines the size of the buffer used for SRAM test.|
|CLASSB\_SRAM\_TEMP\_STACK\_ADDRESS|Address of the temporary stack.|
|CLASSB\_TEST\_IN\_PROG\_VAR\_ADDR|Address of the variable which indicates that a Class B test is in progress.|
|CLASSB\_WDT\_TEST\_IN\_PROG\_VAR\_ADDR|Address of the variable which indicates that a WDT test is in progress.|
|**Data types Summary**| |
|\*CLASSB\_SST\_RESULT\_BF|Pointer to the structure for the Class B library startup self-test result. This can be used to point to the result address 0x20000000. It will help to see the result in text form via watch window|
|\*CLASSB\_RST\_RESULT\_BF|Pointer to the structure for the Class B library run-time self-test result. This can be used to point to the result address 0x20000004. It will help to see the result in text form via watch window|
|CLASSB\_CPU\_PC\_TEST\_VALUES|Data type for PC Test input and output values.|
|CLASSB\_INIT\_STATUS|Identifies Class B initialization status.|
|CLASSB\_PORT\_INDEX|PORT index definitions for Class B library I/O pin test.|
|CLASSB\_PORT\_PIN|PIN definitions for Class B library I/O pin test.|
|CLASSB\_PORT\_PIN\_STATE|PORT pin state.|
|CLASSB\_SRAM\_MARCH\_ALGO|Selects the RAM March algorithm to run.|
|CLASSB\_STARTUP\_STATUS|Identifies startup test status.|
|CLASSB\_TEST\_ID|Identifies Class B library tests.|
|CLASSB\_TEST\_STATUS|Identifies result from Class B library test.|
|CLASSB\_TEST\_STATE|Identifies Class B library test state.|
|CLASSB\_TEST\_TYPE|Identifies type of the Class B library test.|
|**Interface Routines Summary**| |
|CLASSB\_App\_WDT\_Recovery|This function is called if a WDT reset has happened during run-time.|
|CLASSB\_CPU\_RegistersTest|This self-test checks the processor core registers.|
|CLASSB\_CPU\_PCTest|This self-test checks the Program Counter register \(PC\).|
|CLASSB\_ClearTestResults|Clears the results of SSTs or RSTs.|
|CLASSB\_ClockTest|This self-test checks whether the CPU clock frequency is within the permissible limit.|
|CLASSB\_GetTestResult|Returns the result of the specified self-test.|
|CLASSB\_FlashCRCGenerate|Generates CRC-32 checksum for a given memory area.|
|CLASSB\_FlashCRCTest|This self-test checks the internal Flash program memory to detect single bit faults.|
|CLASSB\_GlobalsInit|This function initializes the global variables for the classb library.|
|CLASSB\_IO\_InputSamplingEnable|Enable input sampling for an IO pin.|
|CLASSB\_Init|This function is executed on every device reset. This shall be called right after the reset, before any other initialization is performed.|
|CLASSB\_SelfTest\_FailSafe|This function is called if any of the non-critical tests detects a failure.|
|CLASSB\_SRAM\_MarchTestInit|This self-test checks the SRAM with the help of RAM March algorithm.|
|CLASSB\_SST\_InterruptTest|This self-test checks basic functionality of the interrupt handling mechanism.|
|CLASSB\_SST\_WDT\_Recovery|This function is called if a WDT reset has happened during the execution of an SST.|
|CLASSB\_Startup\_Tests|This function executes all startup self-tests inserted into classb.c file.|
|CLASSB\_RST\_IOTest|This self-test can be used to perform plausibility checks on IO pins.|
|CLASSB\_TestWDT|This function tests the WatchDog Timer \(WDT\).|

-   **[CLASSB\_CLOCK\_DEFAULT\_CLOCK\_FREQ](GUID-BA554A7F-DEB8-4A5A-8812-FFFE14F65020.md)**  

-   **[CLASSB\_CLOCK\_ERROR\_PERCENT](GUID-A3D1F26A-7159-4A3F-9A3B-974D2BAB9B95.md)**  

-   **[CLASSB\_CLOCK\_MAX\_CLOCK\_FREQ](GUID-08228661-66B9-4298-A542-A9882C7E70AC.md)**  

-   **[CLASSB\_CLOCK\_MAX\_SYSTICK\_VAL](GUID-19B67E2D-FD6A-4902-BE08-8E8BA55B07D5.md)**  

-   **[CLASSB\_CLOCK\_MAX\_TEST\_ACCURACY](GUID-B7F252F0-0B9C-4382-AD91-DAF1277CB236.md)**  

-   **[CLASSB\_CLOCK\_MUL\_FACTOR](GUID-2FEE15A7-F8B7-4D89-9955-3EFE10903C5D.md)**  

-   **[CLASSB\_CLOCK\_RTC\_CLK\_FREQ](GUID-E0DF7CAA-2654-411E-9B6B-0AAD81483829.md)**  

-   **[CLASSB\_CLOCK\_TEST\_RTC\_CYCLES](GUID-458C1313-CAD3-4A74-915B-331437224304.md)**  

-   **[CLASSB\_CLOCK\_TEST\_RTC\_RATIO\_NS](GUID-789FBABD-423A-40FE-9246-E0875E4EC540.md)**  

-   **[CLASSB\_CLOCK\_TEST\_RATIO\_NS\_MS](GUID-4E6F799C-48CE-4787-B2F9-E4E051B60535.md)**  

-   **[CLASSB\_COMPL\_RESULT\_ADDR](GUID-DFE110AB-47FE-43F2-ACF2-B2C499BFA378.md)**  

-   **[CLASSB\_FLASH\_CRC32\_POLYNOMIAL](GUID-136BD53F-F5E9-47C3-8D3B-58A8509CFE17.md)**  

-   **[CLASSB\_INTERRUPT\_COUNT\_VAR\_ADDR](GUID-14891D5C-8B73-4B92-A517-01887DB06E68.md)**  

-   **[CLASSB\_INTERRUPT\_TEST\_VAR\_ADDR](GUID-6EDB97E9-092B-46A5-9FBF-38A056AAC5C5.md)**  

-   **[CLASSB\_INTR\_DEVICE\_VECT\_OFFSET](GUID-F4F039D0-481D-4E5E-BCA3-01084D73C216.md)**  

-   **[CLASSB\_INTR\_MAX\_INT\_COUNT](GUID-DA60B842-88F2-4B55-AAB6-28DDF959C1E4.md)**  

-   **[CLASSB\_INTR\_TEST\_RTC\_COUNT](GUID-BCB6C96E-C12B-4367-AFC5-11DE2296B469.md)**  

-   **[CLASSB\_INTR\_TEST\_TC\_COUNT](GUID-7310FB9C-BB14-4BB4-8EBA-504CA0AB5783.md)**  

-   **[CLASSB\_INTR\_VECTOR\_TABLE\_SIZE](GUID-D98906C7-7303-44BC-945E-3895937ED945.md)**  

-   **[CLASSB\_INVALID\_TEST\_ID](GUID-9FF32589-7BC4-47A4-BCE8-AB3195696933.md)**  

-   **[CLASSB\_ONGOING\_TEST\_VAR\_ADDR](GUID-7275D322-84BC-4310-BC78-35372820FA94.md)**  

-   **[CLASSB\_RESULT\_ADDR](GUID-39B3C6BD-375C-49B7-859A-E622F4C283D9.md)**  

-   **[CLASSB\_SRAM\_ALL\_32BITS\_HIGH](GUID-21E61CA8-F941-4300-96F2-1ABE68C2E5AB.md)**  

-   **[CLASSB\_SRAM\_APP\_AREA\_START](GUID-B2968FB3-23F8-472A-AFEF-31F68759E1C9.md)**  

-   **[CLASSB\_SRAM\_BUFF\_START\_ADDRESS](GUID-A91492F2-ADE8-4D7A-A5CA-ED9BB3B21311.md)**  

-   **[CLASSB\_SRAM\_FINAL\_WORD\_ADDRESS](GUID-2F6E5181-F4D6-4174-9A3B-29423124DECA.md)**  

-   **[CLASSB\_SRAM\_STARTUP\_TEST\_SIZE](GUID-38FA6B2D-57DA-4937-BA18-90F2DCA92C94.md)**  

-   **[CLASSB\_SRAM\_TEMP\_STACK\_ADDRESS](GUID-C5E7BBDB-F7E8-40A8-996F-7F8AE6B008C7.md)**  

-   **[CLASSB\_TEST\_IN\_PROG\_VAR\_ADDR](GUID-2D5F9127-DC70-493E-9E2B-9CE0F159A9C5.md)**  

-   **[CLASSB\_WDT\_TEST\_IN\_PROG\_VAR\_ADDR](GUID-DA71EB0A-7016-49E2-BB0C-C16B8A638EAA.md)**  

-   **[CLASSB\_SST\_RESULT\_BF](GUID-285B7F9F-C3D0-4223-84D4-4559AC9DE45C.md)**  

-   **[CLASSB\_RST\_RESULT\_BF](GUID-D664142F-E3DC-4FB2-AFA0-E6BB9B6BBA38.md)**  

-   **[CLASSB\_CPU\_PC\_TEST\_VALUES](GUID-223F89A3-CABA-4004-B4EE-EBEB41A26C20.md)**  

-   **[CLASSB\_INIT\_STATUS](GUID-5589A6DE-5C57-4C1B-A686-A6D74FD54C5E.md)**  

-   **[CLASSB\_PORT\_INDEX](GUID-A63AA7C7-ED9F-4FCF-8592-5ACDE85BFA93.md)**  

-   **[CLASSB\_PORT\_PIN](GUID-05593F9C-D5B5-45F0-8DC3-EDF5488B57A0.md)**  

-   **[CLASSB\_PORT\_PIN\_STATE](GUID-2D2A6AC4-B699-4944-A452-0AABC1BEF5CE.md)**  

-   **[CLASSB\_SRAM\_MARCH\_ALGO](GUID-9C37C92A-D080-4E98-9864-FE7F3C0F3649.md)**  

-   **[CLASSB\_STARTUP\_STATUS](GUID-D897FFEF-3FA5-4046-82FF-C88BF955BEA6.md)**  

-   **[CLASSB\_TEST\_ID](GUID-6B323EDA-614A-4201-927B-F918B39A5801.md)**  

-   **[CLASSB\_TEST\_STATUS](GUID-C2BE080F-AE0E-409C-B3EE-1F8BE3B6C57E.md)**  

-   **[CLASSB\_TEST\_STATE](GUID-545B6C94-BF80-4DE3-8C3C-4A98D92F5CBE.md)**  

-   **[CLASSB\_TEST\_TYPE](GUID-1A32CB4B-CE63-4C56-B1A7-3C0AC22829AE.md)**  

-   **[CLASSB\_App\_WDT\_Recovery](GUID-BBA8F1A1-BFAD-4E06-A915-E9BB73A29131.md)**  

-   **[CLASSB\_CPU\_RegistersTest](GUID-5CF51E51-E2C0-4BA6-BF10-0E3C8088CCD4.md)**  

-   **[CLASSB\_CPU\_PCTest](GUID-7130628E-C1D2-450E-92BD-CC8D8228F08C.md)**  

-   **[CLASSB\_ClearTestResults](GUID-83848FD5-F48B-47DB-A17A-7A8116CC540B.md)**  

-   **[CLASSB\_ClockTest](GUID-B458B684-B082-47D1-8BE3-72BA6A35203C.md)**  

-   **[CLASSB\_GetTestResult](GUID-34CC2102-C031-4C70-9A24-E3434DF2DA4F.md)**  

-   **[CLASSB\_FlashCRCGenerate](GUID-19F1D13E-6B26-494B-AD54-1DFF7D64941B.md)**  

-   **[CLASSB\_FlashCRCTest](GUID-1486C6AF-64C9-4DFC-9D29-E078F932490A.md)**  

-   **[CLASSB\_GlobalsInit](GUID-2AE43B44-2F6C-408D-AA33-F5D4D77E669B.md)**  

-   **[CLASSB\_IO\_InputSamplingEnable](GUID-A2B796A2-D97F-460C-9344-349FE42BF4DC.md)**  

-   **[CLASSB\_Init](GUID-7ECDFAA5-505F-4506-BD5F-BB16E3873B4D.md)**  

-   **[CLASSB\_SelfTest\_FailSafe](GUID-993C2D51-1ECE-4F4D-9A02-206FF0F5EA90.md)**  

-   **[CLASSB\_SRAM\_MarchTestInit](GUID-3D7CFE61-9064-41B5-B69D-E435AFE7ED1C.md)**  

-   **[CLASSB\_RST\_IOTest](GUID-EB28803B-2BB6-4EF3-B891-834D36C79DDA.md)**  

-   **[CLASSB\_SRAM\_TEST\_BUFFER\_SIZE](GUID-D20D6D1F-AC4F-48C5-97CC-8D49410AC9DB.md)**  

-   **[CLASSB\_SST\_InterruptTest](GUID-2D50D267-FDA7-4B04-A33A-A3AADC2A894D.md)**  

-   **[CLASSB\_SST\_WDT\_Recovery](GUID-D6B4260F-94E1-4A2E-B24E-73E6ADB105DB.md)**  

-   **[CLASSB\_Startup\_Tests](GUID-41195D54-BB95-4252-A19F-87CA96A8B450.md)**  

-   **[CLASSB\_TestWDT](GUID-115BCDEA-64D5-4115-9F4C-DE5C3CE39364.md)**  


