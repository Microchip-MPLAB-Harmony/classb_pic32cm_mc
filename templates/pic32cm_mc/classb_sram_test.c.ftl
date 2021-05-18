/*******************************************************************************
  Class B Library ${REL_VER} Release

  Company:
    Microchip Technology Inc.

  File Name:
    classb_sram_test.c

  Summary:
    Class B Library SRAM self-test source file

  Description:
    This file provides SRAM self-test function.

*******************************************************************************/

/*******************************************************************************
* Copyright (C) ${REL_YEAR} Microchip Technology Inc. and its subsidiaries.
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

/*----------------------------------------------------------------------------
 *     include files
 *----------------------------------------------------------------------------*/
#include "classb/classb_sram_test.h"

/*----------------------------------------------------------------------------
 *     Constants
 *----------------------------------------------------------------------------*/
#define CLASSB_SRAM_FINAL_WORD_ADDRESS      (0x${CLASSB_SRAM_LASTWORD_ADDR}U)
#define CLASSB_SRAM_BUFF_START_ADDRESS      (0x20000200U)
#define CLASSB_SRAM_TEMP_STACK_ADDRESS      (0x20000100U)
#define CLASSB_SRAM_ALL_32BITS_HIGH         (0xFFFFFFFFU)
#define CLASSB_SRAM_MARCH_BIT_WIDTH         (32U)

/*----------------------------------------------------------------------------
 *     Global Variables
 *----------------------------------------------------------------------------*/
extern uint32_t _heap;
extern uint32_t _min_heap_size;
extern uint32_t _stack;

/*----------------------------------------------------------------------------
 *     Functions
 *----------------------------------------------------------------------------*/
extern void _CLASSB_UpdateTestResult(CLASSB_TEST_TYPE test_type,
    CLASSB_TEST_ID test_id, CLASSB_TEST_STATUS value);

bool __attribute__((optimize("-O0"))) _CLASSB_ReadZeroWriteOne(uint32_t * ptr);
bool __attribute__((optimize("-O0"))) _CLASSB_ReadZeroWriteOneWriteZero(uint32_t * ptr);
bool __attribute__((optimize("-O0"))) _CLASSB_ReadOneWriteZero(uint32_t * ptr);
bool __attribute__((optimize("-O0"))) _CLASSB_ReadOneWriteZeroWriteOne(uint32_t * ptr);
bool __attribute__((optimize("-O0"))) _CLASSB_WriteOneWriteZero(uint32_t * ptr);
bool __attribute__((optimize("-O0"))) _CLASSB_ReadZero(uint32_t * ptr );

/*============================================================================
static uint32_t _CLASSB_GetStackPointer(void)
------------------------------------------------------------------------------
Purpose: Get the address stored in the Stack Pointer.
Input  : None
Output : Address stored in the Stack Pointer register.
Notes  : This function is used by SRAM tests.
============================================================================*/
static uint32_t _CLASSB_GetStackPointer(void)
{
    uint32_t result = 0U;

    __ASM volatile ("MRS %0, msp\n" : "=r" (result));

    return result;
}

/*============================================================================
static void _CLASSB_SetStackPointer(uint32_t new_stack_address)
------------------------------------------------------------------------------
Purpose: Store a new address into the Stack Pointer.
Input  : New address for the Stack.
Output : None
Notes  : This function is used by SRAM tests.
============================================================================*/
static void _CLASSB_SetStackPointer(uint32_t new_stack_address)
{
    __ASM volatile ("MSR msp, %0\n" : : "r" (new_stack_address));
}

/*============================================================================
static void _CLASSB_MemCopy(uint32_t* dest, uint32_t* src, uint32_t size_in_bytes)
------------------------------------------------------------------------------
Purpose: Copies given number of bytes, from one SRAM area to the other.
Input  : Destination address, source address and size
Output : None
Notes  : This function is used by SRAM tests.
============================================================================*/
static void _CLASSB_MemCopy(uint32_t* dest, uint32_t* src, uint32_t size_in_bytes)
{
    uint32_t i = 0u;
    uint32_t size_in_words = (uint32_t) (size_in_bytes / 4);

    for (i = 0; i < size_in_words; i++)
    {
        dest[i] = src[i];
    }
}

/*============================================================================
bool _CLASSB_ReadZeroWriteOne(uint32_t * ptr) 
------------------------------------------------------------------------------
Purpose: Read 0 and write 1 to each bits of the SRAM location
Input  : Address of the memory location
Output : Success or failure
Notes  : This function is used by SRAM tests.
         It checks bit by bit.
         Opmization level of this function must be -O0.
============================================================================*/
bool __attribute__((optimize("-O0"))) _CLASSB_ReadZeroWriteOne(uint32_t * ptr)
{
    uint32_t ram_data = 0U;
    int8_t bit_pos = 0;
    bool return_val = true;

    for (bit_pos = CLASSB_SRAM_MARCH_BIT_WIDTH - 1; bit_pos >= 0; bit_pos--)
    {
        ram_data =(((*ptr) >> bit_pos) & 1);
        if (ram_data != 0U) 
        {
            return_val = false;
            break;
        } 

        // Write one at the bit position
        *ptr = (*ptr | (1 << bit_pos));
    }

    return return_val;  
}

/*============================================================================
bool _CLASSB_ReadZeroWriteOneWriteZero(uint32_t * ptr) 
------------------------------------------------------------------------------
Purpose: Read 0, write 1 and write 0 to each bits of the SRAM location
Input  : Address of the memory location
Output : Success or failure
Notes  : This function is used by SRAM tests.
         It checks bit by bit.
         Opmization level of this function must be -O0.
============================================================================*/
bool __attribute__((optimize("-O0"))) _CLASSB_ReadZeroWriteOneWriteZero(uint32_t * ptr)
{
    uint32_t ram_data = 0U;
    int8_t bit_pos = 0;
    bool return_val = true;

    for (bit_pos = CLASSB_SRAM_MARCH_BIT_WIDTH - 1; bit_pos >= 0; bit_pos--)
    {
        ram_data =(((*ptr) >> bit_pos) & 1);
        if (ram_data != 0U) 
        {
            return_val = false;
            break;
        } 

        // Write one at the bit position
        *ptr = (*ptr | (1 << bit_pos));
        // Write zero at the bit position
        ram_data = *ptr  & (~(1 << bit_pos));
        *ptr = ram_data;
    }

    return return_val;  
}

/*============================================================================
bool _CLASSB_ReadOneWriteZero(uint32_t * ptr) 
------------------------------------------------------------------------------
Purpose: Read 1 and write 0 to each bits of the SRAM location
Input  : Address of the memory location
Output : Success or failure
Notes  : This function is used by SRAM tests.
         It checks bit by bit.
         Opmization level of this function must be -O0.
============================================================================*/
bool __attribute__((optimize("-O0"))) _CLASSB_ReadOneWriteZero(uint32_t * ptr) 
{
    uint32_t ram_data = 0U;
    int8_t bit_pos = 0;
    bool return_val = true;

    for (bit_pos = 0; bit_pos < CLASSB_SRAM_MARCH_BIT_WIDTH; bit_pos++)
    {
        ram_data = (((*ptr) >> bit_pos) & 1);

        if (ram_data != 1U) 
        {
            return_val = false;
            break;
        }
        
        // Write zero at the bit position
        ram_data = *ptr  & (~(1 << bit_pos));
        *ptr = ram_data;     
    }

    return return_val; 
}

/*============================================================================
bool _CLASSB_ReadOneWriteZeroWriteOne(uint32_t * ptr) 
------------------------------------------------------------------------------
Purpose: Read 1, write 1 and 0 to each bits of the SRAM location
Input  : Address of the memory location
Output : Success or failure
Notes  : This function is used by SRAM tests.
         It checks bit by bit.
         Opmization level of this function must be -O0.
============================================================================*/
bool __attribute__((optimize("-O0"))) _CLASSB_ReadOneWriteZeroWriteOne(uint32_t * ptr) 
{
    uint32_t ram_data = 0U;
    int8_t bit_pos = 0;
    bool return_val = true;

    for (bit_pos = 0; bit_pos < CLASSB_SRAM_MARCH_BIT_WIDTH; bit_pos++)
    {
        ram_data = (((*ptr) >> bit_pos) & 1);

        if (ram_data != 1U) 
        {
            return_val = false;
            break;
        }
        
        // Write zero at the bit position
        ram_data = *ptr  & (~(1 << bit_pos));
        *ptr = ram_data;
        // Write one at the bit position
        *ptr = (*ptr | (1 << bit_pos));
    }

    return return_val; 
}

/*============================================================================
bool _CLASSB_WriteOneWriteZero(uint32_t * ptr) 
------------------------------------------------------------------------------
Purpose: Write 1 and 0 to each bits of the SRAM location
Input  : Address of the memory location
Output : Success or failure
Notes  : This function is used by SRAM tests.
         It checks bit by bit.
         Opmization level of this function must be -O0.
============================================================================*/
bool __attribute__((optimize("-O0"))) _CLASSB_WriteOneWriteZero(uint32_t * ptr) 
{
    uint32_t ram_data = 0U;
    int8_t bit_pos = 0;
    bool return_val = true;

    for (bit_pos = 0; bit_pos < CLASSB_SRAM_MARCH_BIT_WIDTH; bit_pos++)
    {
        // Write one at the bit position
        *ptr = (*ptr | (1 << bit_pos));
        // Write zero at the bit position
        ram_data = *ptr  & (~(1 << bit_pos));
        *ptr = ram_data;
    }

    return return_val; 
}

/*============================================================================
bool _CLASSB_ReadZero(uint32_t * ptr) 
------------------------------------------------------------------------------
Purpose: Check whether all bits of a memory location in SRAM are 0s
Input  : Address of the memory location
Output : Success or failure
Notes  : This function is used by SRAM tests.
         It checks bit by bit.
         Opmization level of this function must be -O0.
============================================================================*/
bool __attribute__((optimize("-O0"))) _CLASSB_ReadZero(uint32_t * ptr) 
{
    uint32_t ram_data = 0U;
    int8_t bit_pos = 0;
    bool return_val = true;

    for (bit_pos = 0; bit_pos < CLASSB_SRAM_MARCH_BIT_WIDTH; bit_pos++)
    {
        ram_data = (((*ptr) >> bit_pos) & 1);

        if (ram_data != 0U) 
        {
            return_val = false;
            break;
        }
    }
    
    return return_val; 
}

/*============================================================================
bool CLASSB_RAMMarchC(uint32_t * start_addr, uint32_t test_size_bytes)
------------------------------------------------------------------------------
Purpose: Runs March C algorithm on the given SRAM area
Input  : Start address and size
Output : Success or failure
Notes  : This function is used by SRAM tests. It performs the following,
        // March C
        // Low to high, write zero
        // Low to high, read zero write one
        // Low to high, read one write zero
        // Low to high, read zero

        // High to low, read zero write one
        // High to low, read one write zero
        // High to low, read zero
============================================================================*/
bool CLASSB_RAMMarchC(uint32_t * start_addr, uint32_t test_size_bytes)
{
    bool sram_march_c_result = true;
    int32_t i = 0;
    uint32_t test_size_words = (uint32_t) (test_size_bytes / 4);

    // Test size is limited to CLASSB_SRAM_TEST_BUFFER_SIZE
    if (test_size_bytes > CLASSB_SRAM_TEST_BUFFER_SIZE)
    {
        sram_march_c_result = false;
    }

    // Perform the next check only if the previous stage is passed
    if (sram_march_c_result == true)
    {
        // Low to high, write zero
        for (i = 0; i < test_size_words; i++)
        {
            start_addr[i] = 0;
        }
        // Low to high, read zero write one
        for (i = 0; i < test_size_words; i++)
        {
            sram_march_c_result =  _CLASSB_ReadZeroWriteOne(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }
    if (sram_march_c_result == true)
    {
        // Low to high, read one write zero
        for (i = 0; i < test_size_words; i++)
        {
            sram_march_c_result =  _CLASSB_ReadOneWriteZero(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }
    if (sram_march_c_result == true)
    {
        // Low to high, read zero
        for (i = 0; i < test_size_words; i++)
        {
            sram_march_c_result =  _CLASSB_ReadZero(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }
    if (sram_march_c_result == true)
    {
        // High to low, read zero, write one
        for (i = (test_size_words - 1); i >= 0 ; i--)
        {
            sram_march_c_result =  _CLASSB_ReadZeroWriteOne(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }
    if (sram_march_c_result == true)
    {
        // High to low, read one, write zero
        for (i = (test_size_words - 1); i >= 0 ; i--)
        {
            sram_march_c_result =  _CLASSB_ReadOneWriteZero(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }
    if (sram_march_c_result == true)
    {
        // High to low, read zero
        for (i = (test_size_words - 1); i >= 0 ; i--)
        {
            sram_march_c_result =  _CLASSB_ReadZero(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }
    return sram_march_c_result;
}

/*============================================================================
bool CLASSB_RAMMarchCMinus(uint32_t * start_addr, uint32_t test_size_bytes)
------------------------------------------------------------------------------
Purpose: Runs March C algorithm on the given SRAM area
Input  : Start address and size
Output : Success or failure
Notes  : This function is used by SRAM tests. It performs the following,
        // March C minus
        // Low to high, write zero
        // Low to high, read zero write one
        // Low to high, read one write zero

        // High to low, read zero write one
        // High to low, read one write zero
        // High to low, read zero
============================================================================*/
bool CLASSB_RAMMarchCMinus(uint32_t * start_addr, uint32_t test_size_bytes)
{
    bool sram_march_c_result = true;
    int32_t i = 0;
    uint32_t test_size_words = (uint32_t) (test_size_bytes / 4);

    // Test size is limited to CLASSB_SRAM_TEST_BUFFER_SIZE
    if (test_size_bytes > CLASSB_SRAM_TEST_BUFFER_SIZE)
    {
        sram_march_c_result = false;
    }

    // Perform the next check only if the previous stage is passed
    if (sram_march_c_result == true)
    {
        // Low to high, write zero
        for (i = 0; i < test_size_words; i++)
        {
            start_addr[i] = 0;
        }
        // Low to high, read zero write one
        for (i = 0; i < test_size_words; i++)
        {
            sram_march_c_result =  _CLASSB_ReadZeroWriteOne(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }
    if (sram_march_c_result == true)
    {
        // Low to high, read one write zero
        for (i = 0; i < test_size_words; i++)
        {
            sram_march_c_result =  _CLASSB_ReadOneWriteZero(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }

    if (sram_march_c_result == true)
    {
        // High to low, read zero, write one
        for (i = (test_size_words - 1); i >= 0 ; i--)
        {
            sram_march_c_result =  _CLASSB_ReadZeroWriteOne(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }
    if (sram_march_c_result == true)
    {
        // High to low, read one, write zero
        for (i = (test_size_words - 1); i >= 0 ; i--)
        {
            sram_march_c_result =  _CLASSB_ReadOneWriteZero(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }
    if (sram_march_c_result == true)
    {
        // High to low, read zero
        for (i = (test_size_words - 1); i >= 0 ; i--)
        {
            sram_march_c_result =  _CLASSB_ReadZero(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }

    return sram_march_c_result;
}

/*============================================================================
bool CLASSB_RAMMarchB(uint32_t * start_addr, uint32_t test_size_bytes)
------------------------------------------------------------------------------
Purpose: Runs March C algorithm on the given SRAM area
Input  : Start address and size
Output : Success or failure
Notes  : This function is used by SRAM tests. It performs the following,
        // March B
        // Low to high, write zero
        // Low to high, read zero write one, read one write zero,
               read zero write one
        // Low to high, read one write zero, write one

        // High to low, read one write zero, write one write zero
        // High to low, read zero write one, write zero
============================================================================*/
bool CLASSB_RAMMarchB(uint32_t * start_addr, uint32_t test_size_bytes)
{
    bool sram_march_c_result = true;
    int32_t i = 0;
    uint32_t test_size_words = (uint32_t) (test_size_bytes / 4);

    // Test size is limited to CLASSB_SRAM_TEST_BUFFER_SIZE
    if (test_size_bytes > CLASSB_SRAM_TEST_BUFFER_SIZE)
    {
        sram_march_c_result = false;
    }

    // Perform the next check only if the previous stage is passed
    if (sram_march_c_result == true)
    {
        // Low to high, write zero
        for (i = 0; i < test_size_words; i++)
        {
            start_addr[i] = 0;
        }
        // Low to high
        for (i = 0; i < test_size_words; i++)
        {
            // Read zero write one
            sram_march_c_result =  _CLASSB_ReadZeroWriteOne(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
            // Read one write zero
            sram_march_c_result =  _CLASSB_ReadOneWriteZero(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
            // Read zero write one
            sram_march_c_result =  _CLASSB_ReadZeroWriteOne(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }

    if (sram_march_c_result == true)
    {
        // Low to high
        for (i = 0; i < test_size_words; i++)
        {
            // Read one, write zero, write one
            sram_march_c_result =  _CLASSB_ReadOneWriteZeroWriteOne(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }

    // High to low tests
    if (sram_march_c_result == true)
    {
        for (i = (test_size_words - 1); i >= 0 ; i--)
        {
            //High to low, read one, write zero
            sram_march_c_result =  _CLASSB_ReadOneWriteZero(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
            //High to low, write one, write zero
            sram_march_c_result =  _CLASSB_WriteOneWriteZero(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }
    
    if (sram_march_c_result == true)
    {
        // High to low, read zero, write one, write zero
        for (i = (test_size_words - 1); i >= 0 ; i--)
        {
            sram_march_c_result =  _CLASSB_ReadZeroWriteOneWriteZero(start_addr + i);
  
            if (sram_march_c_result == false)
            {
                break;
            }
        }
    }

    return sram_march_c_result;
}

/*============================================================================
CLASSB_TEST_STATUS CLASSB_SRAM_MarchTestInit(uint32_t * start_addr,
    uint32_t test_size_bytes, CLASSB_SRAM_MARCH_ALGO march_algo,
    bool running_context)
------------------------------------------------------------------------------
Purpose: Initialize to perform March-tests on SRAM.
Input  : Start address, size of SRAM area to be tested,
         selected algorithm and the context (startup or run-time)
Output : Test status.
Notes  : This function uses register variables since the stack
         in SRAM also need to be tested.
============================================================================*/
CLASSB_TEST_STATUS CLASSB_SRAM_MarchTestInit(uint32_t * start_addr,
    uint32_t test_size_bytes, CLASSB_SRAM_MARCH_ALGO march_algo,
    bool running_context)
{
    /* This function uses register variables since the Stack also
     * need to be tested
     */
    // Find the last word address in the tested area
    register uint32_t march_test_end_address = (uint32_t)start_addr +
        test_size_bytes - 4U;
    // Use a local variable for calculations
    register uint32_t mem_start_address = (uint32_t)start_addr;
    register uint32_t stack_address = 0U;
    register CLASSB_TEST_STATUS sram_init_retval =
        CLASSB_TEST_NOT_EXECUTED;

    /* The address and test size must be a multiple of 4
     * The tested area should be above the reserved SRAM for Class B library
     * Address should be within the last SRAM word address.
     */

    if ((((uint32_t)start_addr % 4) != 0U)
            || ((test_size_bytes % 4) != 0U)
            || (march_test_end_address > CLASSB_SRAM_FINAL_WORD_ADDRESS)
            || (mem_start_address < CLASSB_SRAM_APP_AREA_START))
    {
        ;
    }
    else
    {
        // Move stack pointer to the reserved area before any SRAM test
        stack_address = _CLASSB_GetStackPointer();
        _CLASSB_SetStackPointer(CLASSB_SRAM_TEMP_STACK_ADDRESS);
        if (running_context == true)
        {
            _CLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_RAM,
                CLASSB_TEST_INPROGRESS);
        }
        else
        {
            _CLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_RAM,
                CLASSB_TEST_INPROGRESS);
        }
        
        sram_init_retval = CLASSB_SRAM_MarchTest(start_addr, test_size_bytes,
            march_algo, running_context);

        if (sram_init_retval == CLASSB_TEST_PASSED)
        {
            if (running_context == true)
            {
                _CLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_RAM,
                    CLASSB_TEST_PASSED);
            }
            else
            {
                _CLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_RAM,
                    CLASSB_TEST_PASSED);
            }
        }
        else if (sram_init_retval == CLASSB_TEST_FAILED)
        {
            if (running_context == true)
            {
                _CLASSB_UpdateTestResult(CLASSB_TEST_TYPE_RST, CLASSB_TEST_RAM,
                    CLASSB_TEST_FAILED);
            }
            else
            {
                _CLASSB_UpdateTestResult(CLASSB_TEST_TYPE_SST, CLASSB_TEST_RAM,
                    CLASSB_TEST_FAILED);
            }
            
            CLASSB_SelfTest_FailSafe(CLASSB_TEST_RAM);
        }
        
        _CLASSB_SetStackPointer(stack_address);
    }

    return sram_init_retval;
}

/*============================================================================
CLASSB_TEST_STATUS CLASSB_SRAM_MarchTest(uint32_t * start_addr,
    uint32_t test_size_bytes, CLASSB_SRAM_MARCH_ALGO march_algo,
    bool running_context)
------------------------------------------------------------------------------
Purpose: Perform March-tests on SRAM.
Input  : Start address, size of SRAM area to be tested,
         selected algorithm and the context (startup or run-time)
Output : Test status.
Notes  : None.
============================================================================*/
CLASSB_TEST_STATUS CLASSB_SRAM_MarchTest(uint32_t * start_addr,
    uint32_t test_size_bytes, CLASSB_SRAM_MARCH_ALGO march_algo,
    bool running_context)
{
    CLASSB_TEST_STATUS classb_sram_status = CLASSB_TEST_NOT_EXECUTED;
    bool march_test_retval = false;
    // Use a local variable for calculations
    uint32_t mem_start_address = (uint32_t)start_addr;
    // Test will be done on blocks on 512 bytes
    volatile uint32_t march_c_iterations = (volatile uint32_t) (test_size_bytes / CLASSB_SRAM_TEST_BUFFER_SIZE);
    // If the size is not a multiple of 512, then check the remaining area
    volatile uint32_t march_c_short_itr_size = (volatile uint32_t) (test_size_bytes % CLASSB_SRAM_TEST_BUFFER_SIZE);
    // Variable for loops
    int32_t i = 0;
    uint32_t * iteration_start_addr = 0U;
    uint32_t itr_start_addr = 0U;

    for (i = 0; i < march_c_iterations; i++)
    {
        itr_start_addr = (uint32_t) mem_start_address + (i * CLASSB_SRAM_TEST_BUFFER_SIZE);
        iteration_start_addr = (uint32_t *) itr_start_addr;
        // Copy the tested area
        _CLASSB_MemCopy((uint32_t *)CLASSB_SRAM_BUFF_START_ADDRESS,
            iteration_start_addr, CLASSB_SRAM_TEST_BUFFER_SIZE);
        // Run the selected RAM March algorithm
        if (march_algo == CLASSB_SRAM_MARCH_C)
        {
            march_test_retval = CLASSB_RAMMarchC(iteration_start_addr,
                CLASSB_SRAM_TEST_BUFFER_SIZE);
        }
        else if (march_algo == CLASSB_SRAM_MARCH_C_MINUS)
        {
            march_test_retval = CLASSB_RAMMarchCMinus(iteration_start_addr,
                CLASSB_SRAM_TEST_BUFFER_SIZE);
        }
        else if (march_algo == CLASSB_SRAM_MARCH_B)
        {
            march_test_retval = CLASSB_RAMMarchB(iteration_start_addr,
                CLASSB_SRAM_TEST_BUFFER_SIZE);
        }
        if (march_test_retval == false)
        {
            // If March test fails, exit the loop
            classb_sram_status = CLASSB_TEST_FAILED;
            break;
        }
        else
        {
        // Restore the tested area
        _CLASSB_MemCopy(iteration_start_addr, (uint32_t *)CLASSB_SRAM_BUFF_START_ADDRESS,
            CLASSB_SRAM_TEST_BUFFER_SIZE);
        }
        classb_sram_status = CLASSB_TEST_PASSED;
    }

    // If the tested area is not a multiple of 512 bytes
    if ((march_c_short_itr_size > 0) && (march_test_retval == true))
    {
        iteration_start_addr = (uint32_t *) (mem_start_address + (march_c_iterations * CLASSB_SRAM_TEST_BUFFER_SIZE));
        _CLASSB_MemCopy((uint32_t *)CLASSB_SRAM_BUFF_START_ADDRESS,
            iteration_start_addr, march_c_short_itr_size);
        // Run the selected RAM March algorithm
        if (march_algo == CLASSB_SRAM_MARCH_C)
        {
            march_test_retval = CLASSB_RAMMarchC(iteration_start_addr,
                CLASSB_SRAM_TEST_BUFFER_SIZE);
        }
        else if (march_algo == CLASSB_SRAM_MARCH_C_MINUS)
        {
            march_test_retval = CLASSB_RAMMarchCMinus(iteration_start_addr,
                CLASSB_SRAM_TEST_BUFFER_SIZE);
        }
        else if (march_algo == CLASSB_SRAM_MARCH_B)
        {
            march_test_retval = CLASSB_RAMMarchB(iteration_start_addr,
                CLASSB_SRAM_TEST_BUFFER_SIZE);
        }
        if (march_test_retval == false)
        {
            classb_sram_status = CLASSB_TEST_FAILED;
        }
        else
        {
            classb_sram_status = CLASSB_TEST_PASSED;
            // Restore the tested area
            _CLASSB_MemCopy(iteration_start_addr,
                (uint32_t *)CLASSB_SRAM_BUFF_START_ADDRESS, march_c_short_itr_size);
        }
    }

    return classb_sram_status;
}
