# CLASSB_STARTUP_STATUS

**Summary**

Identifies startup test status.

**Description**

This is return type for the function which calls all self-tests during startup.

**Remarks**

None.

```c
typedef enum
{
CLASSB_STARTUP_TEST_PASSED = 1,
CLASSB_STARTUP_TEST_FAILED = 2
} CLASSB_STARTUP_STATUS;
```

