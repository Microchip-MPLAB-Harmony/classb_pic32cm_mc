# CLASSB_RST_RESULT_BF

**Summary**

Pointer to the structure for the Class B library run-time self-test result.

**Description**

For bit-field representation of Class B library test results.

**Remarks**

None.

```c
typedef struct
{
CLASSB_TEST_STATUS CPU_STATUS:2;
CLASSB_TEST_STATUS PC_STATUS:2;
CLASSB_TEST_STATUS RAM_STATUS:2;
CLASSB_TEST_STATUS FLASH_STATUS:2;
CLASSB_TEST_STATUS CLOCK_STATUS:2;
CLASSB_TEST_STATUS UNUSED_STATUS:2;
CLASSB_TEST_STATUS IO_STATUS:2;
} *CLASSB_RST_RESULT_BF;
```

