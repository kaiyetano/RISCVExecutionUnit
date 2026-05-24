# RISCVExecutionUnit RTL Views

- `01_execunit_baseline.svg` - Shows the baseline execution unit combining ripple arithmetic, Log64 logic, Sft64 shifting, result selection, and arithmetic flags.
- `02_execunit_bka_sft.svg` - Shows the execution unit variant that pairs Brent-Kung arithmetic with the numeric_std Sft64 shifter.
- `03_execunit_bka_brl.svg` - Shows the execution unit variant that pairs Brent-Kung arithmetic with the explicit Brl64 barrel shifter.
- `04_execunit_csa_sft.svg` - Shows the execution unit variant that pairs conditional-sum arithmetic with the numeric_std Sft64 shifter.
- `05_execunit_csa_brl.svg` - Shows the execution unit variant that pairs conditional-sum arithmetic with the explicit Brl64 barrel shifter.
- `06_arithmetic_baseline.svg` - Shows the ripple-carry ArithmeticUnit baseline with add/subtract preprocessing, carry propagation, ExtWord handling, and flags.
- `07_arithmetic_brent_kung.svg` - Shows the BrentKung ArithmeticUnit prefix flow from generate/propagate signals through prefix stages to carry reconstruction and flags.
- `08_arithmetic_conditional_sum.svg` - Shows the ConditionalSum ArithmeticUnit recursive low-half computation and upper-half carry-select structure.
- `09_logic_log64.svg` - Shows the Log64 LogicUnit case selection for pass-through, XOR, OR, and AND operations.
- `10_shift_sft64.svg` - Shows the Sft64 ShiftUnit using numeric_std full-width and half-width shift operations.
- `11_shift_brl64.svg` - Shows the Brl64 ShiftUnit barrel-loop datapath for power-of-two conditional shifts.
