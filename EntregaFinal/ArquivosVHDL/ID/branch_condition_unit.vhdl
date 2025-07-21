library ieee;
use ieee.std_logic_1164.all;

entity branch_condition_unit is -- Renamed for broader scope (branch and jump)
    port (
        -- Inputs
        funct3      : in  std_logic_vector(2 downto 0); -- funct3 field from the instruction
        AreEqual    : in  std_logic;                    -- Result from an ALU/comparator: '1' if rs1 = rs2 (i.e., rs1 - rs2 = 0), '0' otherwise
        Jump_enable : in  std_logic;                    -- Control signal: '1' if the current instruction is a jump (e.g., JAL, JALR)
        Branch_enable : in  std_logic;                  -- Control signal: '1' if the current instruction is a branch (e.g., BEQ, BNE, BLT, BGE, etc.)

        -- Output for controlling PC update via MUX
        pc_write_enable : out std_logic                 -- '1' if the PC should be updated with a new target address
                                                        -- (either due to a taken branch or any jump instruction), '0' otherwise
    );
end entity branch_condition_unit;

architecture behavioral of branch_condition_unit is
begin

    -- Logic for determining if the PC should be updated with a new target address
    process(funct3, AreEqual, Jump_enable, Branch_enable)
    begin
        -- Default to not taking a branch/jump
        pc_write_enable <= '0';

        -- If it's a jump instruction, always enable PC write (JAL, JALR)
        if Jump_enable = '1' then
            pc_write_enable <= '1';
        elsif Branch_enable = '1' then -- Only evaluate branch conditions if it's a branch instruction
            case funct3 is
                -- BEQ: Branch if Equal (funct3 = 000)
                when "000" =>
                    if AreEqual = '1' then
                        pc_write_enable <= '1';
                    else
                        pc_write_enable <= '0';
                    end if;

                -- BNE: Branch if Not Equal (funct3 = 001)
                when "001" =>
                    if AreEqual = '0' then
                        pc_write_enable <= '1';
                    else
                        pc_write_enable <= '0';
                    end if;

                -- You can add other branch types here if needed (e.g., BLT, BGE, BLTU, BGEU)
                -- These would require additional inputs for ALU flags (e.g., LessThan, GreaterThan)
                -- For example:
                -- when "100" => -- BLT
                --    if LessThan = '1' then
                --        pc_write_enable <= '1';
                --    end if;

                when others =>
                    -- For any other funct3 value when Branch_enable is '1' (e.g., unsupported branch type)
                    pc_write_enable <= '0';
            end case;
        else
            -- If neither Jump_enable nor Branch_enable is '1',
            -- then it's a sequential instruction, and pc_write_enable remains '0' (default)
            pc_write_enable <= '0';
        end if;
    end process;

end architecture behavioral;