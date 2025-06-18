-- VHDL Code for a 32-bit Equality Comparator
-- This component is used in the ID stage to compare two register values
-- for conditional branch instructions like BEQ and BNE.

library ieee;
use ieee.std_logic_1164.all;

-- The entity declaration for the comparator
entity comparator_32bit is
    port (
        -- Inputs: The two 32-bit data values to compare.
        -- These will come from the register file (reading rs1 and rs2).
        DataA   : in  std_logic_vector(31 downto 0);
        DataB   : in  std_logic_vector(31 downto 0);

        -- Output: A single bit indicating the result of the comparison.
        -- '1' if DataA is equal to DataB.
        -- '0' if DataA is not equal to DataB.
        AreEqual : out std_logic
    );
end entity comparator_32bit;

-- Architecture definition for the comparator
architecture behavioral of comparator_32bit is
begin

    -- This is a purely combinational process.
    -- It continuously compares the two input vectors.
    process(DataA, DataB)
    begin
        -- The comparison logic is straightforward.
        -- If the two input vectors are identical, the output is '1'.
        -- Otherwise, the output is '0'.
        -- This can be implemented efficiently by synthesizers.
        if DataA = DataB then
            AreEqual <= '1';
        else
            AreEqual <= '0';
        end if;
    end process;

    -- Alternative (and more concise) concurrent assignment statement:
    -- AreEqual <= '1' when DataA = DataB else '0';

end architecture behavioral;