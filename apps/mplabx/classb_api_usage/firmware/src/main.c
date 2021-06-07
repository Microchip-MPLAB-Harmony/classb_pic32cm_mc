/*******************************************************************************
  Main Source File

  Company:
    Microchip Technology Inc.

  File Name:
    main.c

  Summary:
    This file contains the "main" function for a project.

  Description:
    This file contains the "main" function for a project.  The
    "main" function calls the "SYS_Initialize" function to initialize the state
    machines of all modules in the system
 *******************************************************************************/

/*******************************************************************************
* Copyright (C) 2021 Microchip Technology Inc. and its subsidiaries.
*
* Subject to your compliance with these terms, you may use Microchip software
* and any derivatives exclusively with Microchip products. It is your
* responsibility to comply with third party license terms applicable to your
* use of third party software (including open source software) that may
* accompany Microchip software.
*
* THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
* EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
* WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
* PARTICULAR PURPOSE.
*
* IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
* INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
* WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
* BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
* FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
* ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
* THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
*******************************************************************************/

// *****************************************************************************
// *****************************************************************************
// Section: Included Files
// *****************************************************************************
// *****************************************************************************

#include <stddef.h>                     // Defines NULL
#include <stdbool.h>                    // Defines true
#include <stdlib.h>                     // Defines EXIT_FAILURE
#include "definitions.h"                // SYS function prototypes

#define SRAM_RST_SIZE           4096U
#define SRAM_TESTADDR           0x20000400U
#define FLASH_CRC32_ADDR        0x1FF00U
#define APP_FLASH_LIMIT         0x1FF00U
#define RX_BUFFER_SIZE          256U
#define CPU_CLOCK_FREQ          48000000U
#define CPU_CLOCK_ERROR         5U
#define CPU_CLOCK_TEST_CYCLES   164U

char test_status_str[4][25] = {"CLASSB_TEST_NOT_EXECUTED",
                                "CLASSB_TEST_PASSED",
                                "CLASSB_TEST_FAILED",
                                "CLASSB_TEST_INPROGRESS"};
char console_message[] = "\r\n Type a line of characters and press the Enter key. \r\n\
 \r\n Entered line will be echoed back, and the LED0 is toggled on the reception of each character. \r\n";
char newline[] = "\r\n ";
char error_message[] = "\r\n!!!!! USART error has occurred !!!!!r\n";
char receive_buffer[RX_BUFFER_SIZE] = {};
char data = 0;
uint32_t crc_val[1] = {0};
uint32_t * app_crc_addr = (uint32_t *)FLASH_CRC32_ADDR;

/*============================================================================
void runtimeClassBChecks(void)
------------------------------------------------------------------------------
Purpose: Execute periodic run-time self-tests
Input  : None.
Output : None.
Notes  : Insert the required self-tests into this function.
============================================================================*/
bool runtimeClassBChecks(void)
{
    bool ret_val = false;
    CLASSB_TEST_STATUS classb_rst1_status = CLASSB_TEST_NOT_EXECUTED;
    CLASSB_TEST_STATUS classb_rst2_status = CLASSB_TEST_NOT_EXECUTED;
    
    classb_rst1_status = CLASSB_CPU_RegistersTest(true);
    classb_rst2_status = CLASSB_FlashCRCTest(0, APP_FLASH_LIMIT,
            *(uint32_t *)FLASH_CRC32_ADDR, true);
    
    if ((classb_rst1_status == CLASSB_TEST_PASSED) &&
            (classb_rst2_status == CLASSB_TEST_PASSED))
    {
        ret_val = true;
    }
    
    return ret_val;
}

// *****************************************************************************
// *****************************************************************************
// Section: Main Entry Point
// *****************************************************************************
// *****************************************************************************

int main ( void )
{
    uint16_t rx_counter=0U;
    bool rst_status = false;
    
    /* Initialize all modules */
    SYS_Initialize ( NULL );
    printf("\r\n\r\n        Class B API Usage Demo      \r\n");
    CLASSB_TEST_STATUS classb_test_status = CLASSB_TEST_NOT_EXECUTED;
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_CPU);
    printf("\r\n Result of CPU SST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_PC);
    printf("\r\n Result of PC SST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_RAM);
    printf("\r\n Result of SRAM SST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_FLASH);
    printf("\r\n Result of Flash SST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_CLOCK);
    printf("\r\n Result of Clock SST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_GetTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_INTERRUPT);
    printf("\r\n Result of Interrupt SST is %s\r\n", test_status_str[classb_test_status]);
    
    WDT_Clear();

    printf("\r\n\r\n Class B run-time self-tests \r\n");
    classb_test_status = CLASSB_TEST_FAILED;
    classb_test_status = CLASSB_CPU_RegistersTest(true);
    printf("\r\n Result of CPU RST is %s\r\n", test_status_str[classb_test_status]);
    classb_test_status = CLASSB_TEST_FAILED;
    classb_test_status = CLASSB_CPU_PCTest(true);
    printf("\r\n Result of PC RST is %s\r\n", test_status_str[classb_test_status]);
    
    WDT_Clear();

    classb_test_status = CLASSB_TEST_FAILED;
    __disable_irq();
    classb_test_status = CLASSB_SRAM_MarchTestInit((uint32_t *)SRAM_TESTADDR,
                SRAM_RST_SIZE, CLASSB_SRAM_MARCH_C, true);
    __enable_irq();
    printf("\r\n Result of SRAM RST is %s\r\n", test_status_str[classb_test_status]);
    
    // Generate CRC-32 over internal flash address 0 to 0x1FF00
    crc_val[0] = CLASSB_FlashCRCGenerate(0, APP_FLASH_LIMIT);
    // Use NVMCTRL to write the calculated CRC into a Flash location
    bool nvm_ret_val = false;
    nvm_ret_val = NVMCTRL_PageWrite(crc_val, FLASH_CRC32_ADDR);
    if(!nvm_ret_val)
    {
        printf("\r\n NVM write failed\r\n");
    }
    else
    {
        ;
    }
    
    WDT_Clear();
    
    classb_test_status = CLASSB_TEST_FAILED;
    classb_test_status = CLASSB_FlashCRCTest(0, APP_FLASH_LIMIT,
        *(uint32_t *)FLASH_CRC32_ADDR, true);
    printf("\r\n Result of Flash RST is %s\r\n", test_status_str[classb_test_status]);
    
    WDT_Clear();
    __disable_irq();
    classb_test_status = CLASSB_ClockTest(CPU_CLOCK_FREQ, CPU_CLOCK_ERROR, CPU_CLOCK_TEST_CYCLES, true);
	__enable_irq();
    printf("\r\n Result of CPU Clock RST is %s\r\n", test_status_str[classb_test_status]);
    
    //Drive HIGH on the pin to be tested.
    LED0_Set();
    CLASSB_IO_InputSamplingEnable(PORTA, PIN24);
    classb_test_status = CLASSB_RST_IOTest(PORTA, PIN24, PORT_PIN_HIGH);
    printf("\r\n Result of PA24 HIGH is %s\r\n", test_status_str[classb_test_status]);
    
    // Check HIGH on SW0 (PA25)
    classb_test_status = CLASSB_RST_IOTest(PORTA, PIN25, PORT_PIN_HIGH);
    printf("\r\n Result of PA25 HIGH is %s\r\n", test_status_str[classb_test_status]);
    
    printf("%s", console_message);
    while ( true )
    {
        /* Maintain state machines of all polled MPLAB Harmony modules. */
        SYS_Tasks ( );
        WDT_Clear();
        /* Check if there is a received character */
        if(SERCOM0_USART_ReceiverIsReady() == true)
        {
            if(SERCOM0_USART_ErrorGet() == USART_ERROR_NONE)
            {
                SERCOM0_USART_Read(&data, 1);
                LED0_Toggle();
                if((data == '\n') || (data == '\r'))
                {
                    printf("\r\n Received : ");
                    SERCOM0_USART_Write(&receive_buffer[0],rx_counter);
                    printf("\r\n");
                    rx_counter = 0;
                    printf("\r\n Executing periodic run-time tests : ");
                    rst_status = runtimeClassBChecks();
                    if (rst_status == true)
                    {
                        printf(" All periodic tests passed \r\n");
                    }
                    else
                    {
                        printf(" Periodic test failure \r\n");
                    }
                }
                else
                {
                    receive_buffer[rx_counter++] = data;
                }
            }
            else
            {
                SERCOM0_USART_Write(&error_message[0],sizeof(error_message));
            }
        }
    }

    /* Execution should not come here during normal operation */

    return ( EXIT_FAILURE );
}


/*******************************************************************************
 End of File
*/

