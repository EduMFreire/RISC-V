library ieee;
use ieee.std_logic_1164.all;

-- The forwarding unit entity declaration
entity forwarding_unit is
    port (
        -- Inputs from pipeline registers
        -- Source registers for the instruction currently in the EX stage (for ALU operations)
        ID_EX_rs1        : in std_logic_vector(4 downto 0);
        ID_EX_rs2        : in std_logic_vector(4 downto 0);

        -- Source registers for the instruction currently in the ID stage (for Branch Comparison)
        IF_ID_rs1        : in std_logic_vector(4 downto 0);
        IF_ID_rs2        : in std_logic_vector(4 downto 0);

        -- Destination register for the instruction in the MEM stage
        EX_MEM_rd        : in std_logic_vector(4 downto 0);
        EX_MEM_RegWrite  : in std_logic; -- Control signal: Does the instruction in MEM write to a register?

        -- Destination register for the instruction in the WB stage
        MEM_WB_rd        : in std_logic_vector(4 downto 0);
        MEM_WB_RegWrite  : in std_logic; -- Control signal: Does the instruction in WB write to a register?

        -- Outputs: Control signals for the ALU input multiplexers (EX stage)
        -- 00: No forwarding (use ID/EX register value)
        -- 01: Forward from EX/MEM stage (ALU result)
        -- 10: Forward from MEM/WB stage (Memory data or older ALU result)
        ForwardA         : out std_logic_vector(1 downto 0);
        ForwardB         : out std_logic_vector(1 downto 0);

        -- New Outputs: Control signals for the Branch Comparison input multiplexers (ID stage)
        -- 00: No forwarding (use IF/ID register value from RegFile read)
        -- 01: Forward from EX/MEM stage (ALU result)
        -- 10: Forward from MEM/WB stage (Memory data or older ALU result)
        Forward_ID_A     : out std_logic_vector(1 downto 0);
        Forward_ID_B     : out std_logic_vector(1 downto 0)
    );
end entity forwarding_unit;

-- Architecture definition for the forwarding unit
architecture behavioral of forwarding_unit is
begin

    -- This process contains the combinational logic for the forwarding unit.
    -- It continuously checks for hazard conditions.
    process(ID_EX_rs1, ID_EX_rs2, IF_ID_rs1, IF_ID_rs2,
            EX_MEM_rd, EX_MEM_RegWrite, MEM_WB_rd, MEM_WB_RegWrite)
    begin
        -- Default to no forwarding for EX stage ALU
        ForwardA <= "00";
        ForwardB <= "00";

        -- Default to no forwarding for ID stage Branch Comparison
        Forward_ID_A <= "00";
        Forward_ID_B <= "00";

        -- --- FORWARDING LOGIC FOR OPERAND A (rs1) in EX stage (ALU) ---

        -- EX/MEM Hazard Check for EX stage rs1
        if (EX_MEM_RegWrite = '1') and
           (EX_MEM_rd /= "00000") and
           (EX_MEM_rd = ID_EX_rs1) then
            ForwardA <= "01"; -- Forward from EX/MEM 

        -- MEM/WB Hazard Check for EX stage rs1
        elsif (MEM_WB_RegWrite = '1') and
              (MEM_WB_rd /= "00000") and
              (MEM_WB_rd = ID_EX_rs1) then
            ForwardA <= "10"; -- Forward from MEM/WB 
        end if;


        -- --- FORWARDING LOGIC FOR OPERAND B (rs2) in EX stage (ALU) ---

        -- EX/MEM Hazard Check for EX stage rs2
        if (EX_MEM_RegWrite = '1') and
           (EX_MEM_rd /= "00000") and
           (EX_MEM_rd = ID_EX_rs2) then
            ForwardB <= "01"; -- Forward from EX/MEM

        -- MEM/WB Hazard Check for EX stage rs2
        elsif (MEM_WB_RegWrite = '1') and
              (MEM_WB_rd /= "00000") and
              (MEM_WB_rd = ID_EX_rs2) then
            ForwardB <= "10"; -- Forward from MEM/WB
        end if;


        -- OPERAND A (rs1) in ID stage (Branch Comparison) ---
        -- This logic is for instructions whose comparison is happening in the ID stage.
        -- These forwardings prevent stalls if the branch's operands are produced by
        -- instructions recently completed or currently in EX or MEM stages.

        -- Hazard with EX/MEM stage (most recent result) for ID stage rs1
        -- This means the result is available at the end of the EX stage.
        -- For a branch in ID, this requires bypassing the ALU result back to ID.
        if (EX_MEM_RegWrite = '1') and
           (EX_MEM_rd /= "00000") and
           (EX_MEM_rd = IF_ID_rs1) then
            Forward_ID_A <= "01"; -- Forward from EX/MEM pipeline register (ALU result)

        -- Hazard with MEM/WB stage for ID stage rs1
        -- This means the result is available at the end of the MEM stage.
        elsif (MEM_WB_RegWrite = '1') and
              (MEM_WB_rd /= "00000") and
              (MEM_WB_rd = IF_ID_rs1) then
            Forward_ID_A <= "10"; -- Forward from MEM/WB (Memory data or older ALU result)
        end if;


        -- OPERAND B (rs2) in ID stage (Branch Comparison) ---

        -- Hazard with EX/MEM stage for ID stage rs2
        if (EX_MEM_RegWrite = '1') and
           (EX_MEM_rd /= "00000") and
           (EX_MEM_rd = IF_ID_rs2) then
            Forward_ID_B <= "01"; -- Forward from EX/MEM pipeline register (ALU result)

        -- Hazard with MEM/WB stage for ID stage rs2
        elsif (MEM_WB_RegWrite = '1') and
              (MEM_WB_rd /= "00000") and
              (MEM_WB_rd = IF_ID_rs2) then
            Forward_ID_B <= "10"; -- Forward from MEM/WB (Memory data or older ALU result)
        end if;

    end process;

end architecture behavioral;