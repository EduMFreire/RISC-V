library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- For signed arithmetic and type conversions

entity immediate_extractor is
    port (
        instruction_i : in  std_logic_vector(31 downto 0); -- 32-bit RISC-V instruction input
        immediate_o   : out std_logic_vector(31 downto 0)  -- 32-bit sign-extended immediate output
    );
end entity immediate_extractor;

architecture behavioral of immediate_extractor is
    -- Internal signal to hold the opcode (bits 6 downto 0) for use in the process.
    signal opcode_s : std_logic_vector(6 downto 0);
begin

    -- Extract the opcode from the instruction. This assignment is concurrent.
    opcode_s <= instruction_i(6 downto 0);

    -- This process block implements the combinational logic for immediate extraction.
    -- The sensitivity list includes all signals that, when changed, should
    -- re-evaluate the logic inside the process.
    process(instruction_i, opcode_s)
        -- Declare a local variable to build the immediate value before assigning it
        -- to the output signal. Variables are evaluated immediately within the process.
        variable imm : std_logic_vector(31 downto 0);
    begin
        -- Use a case statement to select the immediate extraction logic
        -- based on the instruction's opcode.
        case opcode_s is
            -- I-type immediate (Load, Op-Imm, JALR)
            -- Opcode values: 0x03 (LOAD), 0x13 (OP-IMM), 0x67 (JALR)
            -- Format: imm[11:0] is instruction[31:20]
            when "0000011" | "0010011" | "1100111" =>
                -- Sign-extend the 12-bit immediate: replicate bit 31 of the instruction
                -- (which is imm[11]) across the higher bits (31 downto 12) of the 32-bit immediate.
                imm := (others => instruction_i(31));
                -- Place the 12-bit immediate into the lower 12 bits of 'imm'.
                imm(11 downto 0) := instruction_i(31 downto 20);
                -- Assign the constructed immediate to the output.
                immediate_o <= imm;

            -- S-type immediate (Store)
            -- Opcode value: 0x23 (STORE)
            -- Format: imm[11:5] from instruction[31:25], imm[4:0] from instruction[11:7]
            -- Reconstructed: imm[11:5] << 5 | imm[4:0]
            when "0100011" =>
                -- Sign-extend the 12-bit immediate: use bit 31 of the instruction
                -- (which is imm[11]) for sign extension.
                imm := (others => instruction_i(31));
                -- Place the high part of the immediate (imm[11:5]) into its position.
                imm(11 downto 5) := instruction_i(31 downto 25);
                -- Place the low part of the immediate (imm[4:0]) into its position.
                imm(4 downto 0)  := instruction_i(11 downto 7);
                -- Assign the constructed immediate to the output.
                immediate_o <= imm;

            -- B-type immediate (Branch)
            -- Opcode value: 0x63 (BRANCH)
            -- Format: imm[12|10:5|4:1|11]
            -- Bits: instruction[31] (imm[12]), instruction[30:25] (imm[10:5]),
            --       instruction[11:8] (imm[4:1]), instruction[7] (imm[11])
            -- Reconstructed: imm[12] << 12 | imm[11] << 11 | imm[10:5] << 5 | imm[4:1] << 1 (imm[0] is always '0')
            when "1100011" =>
                -- Sign-extend the 13-bit immediate: use bit 31 of the instruction
                -- (which is imm[12]) for sign extension.
                imm := (others => instruction_i(31));
                -- Place fragmented immediate bits into their correct positions.
                imm(12)        := instruction_i(31);         -- imm[12]
                imm(11)        := instruction_i(7);          -- imm[11]
                imm(10 downto 5) := instruction_i(30 downto 25); -- imm[10:5]
                imm(4 downto 1) := instruction_i(11 downto 8);  -- imm[4:1]
                imm(0)         := '0';                       -- imm[0] is always 0 for branches
                -- Assign the constructed immediate to the output.
                immediate_o <= imm;

            -- U-type immediate (LUI, AUIPC)
            -- Opcode values: 0x37 (LUI), 0x17 (AUIPC)
            -- Format: imm[31:12] is instruction[31:12]
            -- This immediate is already effectively shifted left by 12 bits.
            when "0110111" | "0010111" =>
                -- Concatenate the upper 20 bits of the instruction with 12 zeros.
                -- No explicit sign extension needed, as the value is simply the upper bits.
                imm := instruction_i(31 downto 12) & (11 downto 0 => '0');
                -- Assign the constructed immediate to the output.
                immediate_o <= imm;

            -- J-type immediate (JAL)
            -- Opcode value: 0x6F (JAL)
            -- Format: imm[20|10:1|11|19:12]
            -- Bits: instruction[31] (imm[20]), instruction[19:12] (imm[19:12]),
            --       instruction[20] (imm[11]), instruction[30:21] (imm[10:1])
            -- Reconstructed: imm[20] << 20 | imm[19:12] << 12 | imm[11] << 11 | imm[10:1] << 1 (imm[0] is always '0')
            when "1101111" =>
                -- Sign-extend the 21-bit immediate: use bit 31 of the instruction
                -- (which is imm[20]) for sign extension.
                imm := (others => instruction_i(31));
                -- Place fragmented immediate bits into their correct positions.
                imm(20)        := instruction_i(31);         -- imm[20]
                imm(19 downto 12) := instruction_i(19 downto 12); -- imm[19:12]
                imm(11)        := instruction_i(20);         -- imm[11]
                imm(10 downto 1) := instruction_i(30 downto 21); -- imm[10:1]
                imm(0)         := '0';                       -- imm[0] is always 0 for jumps
                -- Assign the constructed immediate to the output.
                immediate_o <= imm;

            -- VECTOR_I_OP*
            when "1010100" | "1010101" | "1010110" =>
                imm := (others => instruction_i(31));
                imm(11 downto 0) := instruction_i(31 downto 20);
                immediate_o <= imm;

            -- VECTOR_U_OP*
            when "1011000" | "1011001" | "1011010" =>
                imm := instruction_i(31 downto 12) & (11 downto 0 => '0');
                immediate_o <= imm;

            -- VECTOR_R_OP*
            when "1010000" | "1010001" | "1010010" =>
                immediate_o <= (others => '0');

            -- Default case
            when others =>
                immediate_o <= (others => '0');
        end case;
    end process;

end architecture behavioral;
