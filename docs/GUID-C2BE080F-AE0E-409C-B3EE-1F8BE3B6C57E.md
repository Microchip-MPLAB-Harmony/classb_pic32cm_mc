# CLASSB_TEST_STATUS

**Summary**

Identifies result from Class B library test.

**Description**

This is return type for self-tests.

**Remarks**

None.

```c
typedef enum
{
CLASSB_TEST_NOT_EXECUTED = 0,
CLASSB_TEST_PASSED = 1,
CLASSB_TEST_FAILED = 2,
CLASSB_TEST_INPROGRESS = 3
} CLASSB_TEST_STATUS;
```

