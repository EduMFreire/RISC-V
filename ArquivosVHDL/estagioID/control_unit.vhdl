library ieee;
use ieee.std_logic_1164.all;

entity control_unit is
    port (
        -- Inputs
        opcode      : in  std_logic_vector(6 downto 0); -- 7-bit opcode from the instruction

        -- Outputs: Control signals for the datapath
        alu_op      : out std_logic_vector(1 downto 0); -- Controls the ALU's main operation:
                                                        -- "00" = Add (for Loads/Stores/AUIPC/LUI/JAL/JALR address calc or pass-through)
                                                        -- "01" = Subtract (for Branches for comparison)
                                                        -- "10" = R-type operation (further decoded by funct3/funct7)
                                                        -- "11" = I-type operation (further decoded by funct3)
        alu_src     : out std_logic;                    -- Selects the second ALU source:
                                                        -- '0' = rs2 data (for R-type)
                                                        -- '1' = immediate (for I, S, B, U, J-types)
        mem_read    : out std_logic;                    -- Enables reading from data memory
        mem_write   : out std_logic;                    -- Enables writing to data memory
        mem_to_reg  : out std_logic_vector(1 downto 0);                    -- Selects if data from memory goes to the register file (for loads)
        reg_write   : out std_logic;                    -- Enable writing to the register file
        branch      : out std_logic;                    -- Indicates a conditional branch instruction (for enabling branch logic)
        jump        : out std_logic;                    -- Indicates an unconditional jump instruction (JAL, JALR)
        pc_sel      : out std_logic;                     -- Selects next PC: '0' = PC+4, '1' = Branch/Jump Target
        alu_pc       : out std_logic;
        immSrc      : out std_logic;
        vector_size  : out std_logic_vector(1 downto 0) -- Selects the vector size for vector operations:
                                                        -- "00" = 4 bytes, "01" = 8 bytes, "10" = 16 bytes, "11" = 32 bytes
    );
end entity control_unit;

architecture behavioral of control_unit is
    -- Define the opcodes for different instruction types as constants for readability
    constant R_TYPE_OP   : std_logic_vector(6 downto 0) := "0110011"; -- OP (e.g., ADD, SUB, AND, OR, XOR)
    constant I_TYPE_OP   : std_logic_vector(6 downto 0) := "0010011"; -- OP-IMM (e.g., ADDI, ANDI, ORI)
    constant L_TYPE_OP   : std_logic_vector(6 downto 0) := "0000011"; -- LOAD (e.g., LW)
    constant S_TYPE_OP   : std_logic_vector(6 downto 0) := "0100011"; -- STORE (e.g., SW)
    constant B_TYPE_OP   : std_logic_vector(6 downto 0) := "1100011"; -- BRANCH (e.g., BEQ, BNE)
    constant JAL_OP      : std_logic_vector(6 downto 0) := "1101111"; -- JAL (Jump and Link)
    constant JALR_OP     : std_logic_vector(6 downto 0) := "1100111"; -- JALR (Jump and Link Register)
    constant LUI_OP      : std_logic_vector(6 downto 0) := "0110111"; -- LUI (Load Upper Immediate)
    constant AUIPC_OP    : std_logic_vector(6 downto 0) := "0010111"; -- AUIPC (Add Upper Immediate to PC)
    constant VECTOR_R_OP4B   : std_logic_vector(6 downto 0) := "1010000"; -- Vectorial operations (custom opcode) - 4 bits
    constant VECTOR_R_OP8B   : std_logic_vector(6 downto 0) := "1010001"; -- Vectorial operations (custom opcode) - 8 bits
    constant VECTOR_R_OP16B  : std_logic_vector(6 downto 0) := "1010010"; -- Vectorial operations (custom opcode) - 16 bits
    constant VECTOR_I_OP4B   : std_logic_vector(6 downto 0) := "1010100"; -- Vectorial operations with immediate (custom opcode) - 4 bits
    constant VECTOR_I_OP8B   : std_logic_vector(6 downto 0) := "1010101"; -- Vectorial operations with immediate (custom opcode) - 8 bits
    constant VECTOR_I_OP16B  : std_logic_vector(6 downto 0) := "1010110"; -- Vectorial operations with immediate (custom opcode) - 16 bits
    constant VECTOR_U_OP4B  : std_logic_vector(6 downto 0) := "1011000"; -- Vectorial operations with immediate (custom opcode) - 4 bits
    constant VECTOR_U_OP8B  : std_logic_vector(6 downto 0) := "1011001"; -- Vectorial operations with immediate (custom opcode) - 8 bits
    constant VECTOR_U_OP16B : std_logic_vector(6 downto 0) := "1011010"; -- Vectorial operations with immediate (custom opcode) - 16 bits

begin

    -- Main control logic process.
    -- This process is sensitive to 'opcode'.
    -- All output signals must be assigned within this single process to avoid latches.
    process(opcode)
    begin
        -- safe default (e.g., NOP-like behavior, no writes, no branches/jumps).
        reg_write  <= '0';
        mem_to_reg <= "00";
        mem_read   <= '0';
        mem_write  <= '0';
        alu_src    <= '0';
        branch     <= '0';
        jump       <= '0';
        pc_sel     <= '0'; -- Default to PC+4
        alu_op     <= "00"; -- Default to "00" (Add/Pass-through) for ALU
        alu_pc     <= '0';
        immSrc	   <= '0';
                vector_size <= "11"; -- Default vector size (32 bytes)

        -- Use a case statement to decode the opcode and assert specific control signals.
        case opcode is
            -- R-Type instructions (e.g., ADD, SUB, AND, OR)
            when R_TYPE_OP =>
                reg_write  <= '1';
                alu_src    <= '0';
                alu_op     <= "10";

            -- I-Type instructions (Arithmetic/Logical with Immediate, excluding Loads/JALR)
            when I_TYPE_OP =>
                reg_write  <= '1';
                alu_src    <= '1';
                alu_op     <= "11";

            -- Load instructions (I-type, e.g., LW)
            when L_TYPE_OP =>
                reg_write  <= '1';
                mem_to_reg <= "01";
                mem_read   <= '1';
                alu_src    <= '1';
                alu_op     <= "00";

            -- Store instructions (S-type, e.g., SW)
            when S_TYPE_OP =>
                mem_write  <= '1';
                alu_src    <= '1';
                alu_op     <= "00";

            -- Branch instructions (B-type, e.g., BEQ, BNE)
            when B_TYPE_OP =>
                branch     <= '1';    -- This signal enables the branch comparison logic
                pc_sel     <= '1';    -- Take jump target (maybe)
                alu_op     <= "01";   -- ALU performs subtraction (for comparison)

            -- LUI (Load Upper Immediate)
            when LUI_OP =>
                reg_write  <= '1';
		        immSrc	   <= '1';

            -- AUIPC (Add Upper Immediate to PC)
            when AUIPC_OP =>
                reg_write  <= '1';
                alu_src    <= '1';
                alu_op     <= "00";
		        alu_pc     <= '1';

            -- JAL (Jump and Link)
            when JAL_OP =>
                reg_write  <= '1';
                jump       <= '1';    -- This signal indicates an unconditional jump
                pc_sel     <= '1';    -- Take jump target 
                alu_op     <= "00";   -- ALU may be used to calculate target address (PC + immediate) or pass PC+4
		        mem_to_reg <= "10";

            -- JALR (Jump and Link Register)
            when JALR_OP =>
                reg_write  <= '1';
                jump       <= '1';    -- This signal indicates an unconditional jump
                pc_sel     <= '1';    -- Take jump target 
                alu_src    <= '1';    -- Immediate is used by ALU (for address calculation)
                alu_op     <= "00";   -- ALU performs addition (rs1 + immediate)
		        mem_to_reg <= "10";

            -- Vector R operations (custom opcodes)
            when VECTOR_R_OP4B | 
                 VECTOR_R_OP8B | 
                 VECTOR_R_OP16B =>
                
                reg_write  <= '1';
                alu_src    <= '0';
                alu_op     <= "10";

                case opcode is
                    when VECTOR_R_OP4B =>
                        vector_size <= "00"; -- 4 bytes
                    when VECTOR_R_OP8B =>
                        vector_size <= "01"; -- 8 bytes
                    when VECTOR_R_OP16B =>
                        vector_size <= "10"; -- 16 bytes
                    when others =>
                        vector_size <= "11"; -- Default to 32 bytes
                end case;

            -- Vector I operations (custom opcodes)
            when VECTOR_I_OP4B | 
                 VECTOR_I_OP8B | 
                 VECTOR_I_OP16B =>

                reg_write  <= '1';
                alu_src    <= '1';
                alu_op     <= "11";

                case opcode is
                    when VECTOR_I_OP4B =>
                        vector_size <= "00"; -- 4 bytes
                    when VECTOR_I_OP8B =>
                        vector_size <= "01"; -- 8 bytes
                    when VECTOR_I_OP16B =>
                        vector_size <= "10"; -- 16 bytes
                    when others =>
                        vector_size <= "11"; -- Default to 32 bytes
                end case;

            -- Vector U operations (custom opcodes)
            when VECTOR_U_OP4B | 
                 VECTOR_U_OP8B | 
                 VECTOR_U_OP16B =>

                reg_write  <= '1';
                alu_src    <= '1';
                alu_op     <= "00";
                alu_pc     <= '1';

                case opcode is
                    when VECTOR_U_OP4B =>
                        vector_size <= "00"; -- 4 bytes
                    when VECTOR_U_OP8B =>
                        vector_size <= "01"; -- 8 bytes
                    when VECTOR_U_OP16B =>
                        vector_size <= "10"; -- 16 bytes
                    when others =>
                        vector_size <= "11"; -- Default to 32 bytes
                end case;

            when others =>
                null;
        end case;
    end process;

end architecture behavioral;