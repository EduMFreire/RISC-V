library ieee;
use ieee.std_logic_1164.all;

entity instruction_parser is
    port (
        instruction_i : in  std_logic_vector(31 downto 0); -- 32-bit RISC-V instruction

        -- Extracted fields
        opcode_o      : out std_logic_vector(6 downto 0);  -- bits 6-0
        rd_o          : out std_logic_vector(4 downto 0);  -- bits 11-7
        rs1_o         : out std_logic_vector(4 downto 0);  -- bits 19-15
        rs2_o         : out std_logic_vector(4 downto 0)  -- bits 24-20
    );
end entity instruction_parser;

architecture behavioral of instruction_parser is
begin

    -- Simple direct assignments for common fields
    opcode_o <= instruction_i(6 downto 0);
    rd_o     <= instruction_i(11 downto 7);
    rs1_o    <= instruction_i(19 downto 15);
    rs2_o    <= instruction_i(24 downto 20);

end architecture behavioral;


        -- Example 1: R-type instruction (add x3, x1, x2)
        -- Opcode: 0x33 (0110011), Funct3: 0x0 (000), Funct7: 0x00 (0000000)
        -- rd: 3, rs1: 1, rs2: 2
        -- Instruction: 0x002081B3
        test_instruction <= x"002081B3";
        wait for 10 ns;
        print_parsed_fields(test_instruction, decoded_opcode, decoded_rd, decoded_funct3, decoded_rs1, decoded_rs2, decoded_funct7, decoded_instr_type, "R-type (add x3, x1, x2)");

        -- Example 2: I-type instruction (addi x5, x0, 100)
        -- Opcode: 0x13 (0010011), Funct3: 0x0 (000)
        -- rd: 5, rs1: 0, imm: 100 (bits not parsed here, but for context)
        -- Instruction: 0x06400293
        test_instruction <= x"06400293";
        wait for 10 ns;
        print_parsed_fields(test_instruction, decoded_opcode, decoded_rd, decoded_funct3, decoded_rs1, decoded_rs2, decoded_funct7, decoded_instr_type, "I-type (addi x5, x0, 100)");

        -- Example 3: S-type instruction (sw x6, 4(x5))
        -- Opcode: 0x23 (0100011), Funct3: 0x2 (010)
        -- rs1: 5, rs2: 6
        -- Instruction: 0x0062A023 (example for sw x6, 4(x5))
        test_instruction <= x"0062A023";
        wait for 10 ns;
        print_parsed_fields(test_instruction, decoded_opcode, decoded_rd, decoded_funct3, decoded_rs1, decoded_rs2, decoded_funct7, decoded_instr_type, "S-type (sw x6, 4(x5))");

        -- Example 4: B-type instruction (beq x0, x0, label_offset)
        -- Opcode: 0x63 (1100011), Funct3: 0x0 (000)
        -- rs1: 0, rs2: 0
        -- Instruction: 0x00000463 (example for beq x0, x0, 8)
        test_instruction <= x"00000463";
        wait for 10 ns;
        print_parsed_fields(test_instruction, decoded_opcode, decoded_rd, decoded_funct3, decoded_rs1, decoded_rs2, decoded_funct7, decoded_instr_type, "B-type (beq x0, x0, 8)");

        -- Example 5: U-type instruction (lui x10, 0x12345)
        -- Opcode: 0x37 (0110111)
        -- rd: 10
        -- Instruction: 0x12345537
        test_instruction <= x"12345537";
        wait for 10 ns;
        print_parsed_fields(test_instruction, decoded_opcode, decoded_rd, decoded_funct3, decoded_rs1, decoded_rs2, decoded_funct7, decoded_instr_type, "U-type (lui x10, 0x12345)");

        -- Example 6: J-type instruction (jal x1, 0x100)
        -- Opcode: 0x6F (1101111)
        -- rd: 1
        -- Instruction: 0x008000EF (example for jal x0, 8)
        test_instruction <= x"008000EF";
        wait for 10 ns;
        print_parsed_fields(test_instruction, decoded_opcode, decoded_rd, decoded_funct3, decoded_rs1, decoded_rs2, decoded_funct7, decoded_instr_type, "J-type (jal x1, 0x100)");

        -- Example 7: Unknown instruction (arbitrary value)
        test_instruction <= x"FFFFFFFF";
        wait for 10 ns;
        print_parsed_fields(test_instruction, decoded_opcode, decoded_rd, decoded_funct3, decoded_rs1, decoded_rs2, decoded_funct7, decoded_instr_type, "Unknown Instruction");

        -- End simulation
        wait;
    end process stimulus_process;

end architecture test_bench;