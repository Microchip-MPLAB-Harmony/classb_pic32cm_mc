# CLASSB_App_WDT_Recovery
**Function**

```c
static void CLASSB_App_WDT_Recovery(void);
```

**Summary**

This function is called if a WDT reset is caused during run-time.

**Description**

This function is used inside the CLASSB_Init() function. When the device comes back from a WDT reset,
if a WDT test by the Class B library has not been in progress, it is assumed that the WDT reset has
happened since the application failed to clear the WDT during regular intervals.
In this case, the CLASSB_App_WDT_Recovery() function is called from CLASSB_Init().

**Precondition**

None.

**Parameters**

None.

**Returns**

None.

**Example**

```c
if ((RSTC_REGS->RSTC_RCAUSE & RSTC_RCAUSE_WDT_Msk) == RSTC_RCAUSE_WDT_Msk)
{
    if (!(*wdt_test_in_progress == CLASSB_TEST_STARTED))
    {
        CLASSB_SST_WDT_Recovery();
    }
}
```

**Remarks**

This function is for the internal use of the Class B library.

