library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ID_EX_Pipeline is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;

        -- Control signals
        ALUOp_in      : in  std_logic_vector(1 downto 0);
        ALUSrc_in     : in  std_logic;
        memRead_in   : in  std_logic;
        memWrite_in  : in  std_logic;
        memToReg_in  : in  std_logic_vector(1 downto 0);
        regWrite_in  : in  std_logic;
        size_in     : in  std_logic_vector(1 downto 0); -- Size for vector operations
        -- Data signals
        Rs1_data_in  : in  std_logic_vector(31 downto 0);
        Rs2_data_in  : in  std_logic_vector(31 downto 0);
        Imm_in : in  std_logic_vector(31 downto 0);
        Rs1_in         : in  std_logic_vector(4 downto 0);
        Rs2_in         : in  std_logic_vector(4 downto 0);
        Rd_in         : in  std_logic_vector(4 downto 0);
        funct_3_in      : in  std_logic_vector(2 downto 0);
        funct_7_in      : in  std_logic_vector(6 downto 0); 
        
        bubble        : in std_logic; -- Input de bubble síncrono
        pc_in        : in std_logic_vector(31 downto 0);
        alu_pc_in    : in std_logic;
        pc4_in	     : in std_logic_vector(31 downto 0);
        immSrc_in    : in std_logic;

        -- Control outputs
        ALUOp_out     : out std_logic_vector(1 downto 0);
        ALUSrc_out    : out std_logic;
        memRead_out   : out std_logic;
        memWrite_out  : out std_logic;
        memToReg_out  : out std_logic_vector(1 downto 0);
        regWrite_out  : out std_logic;
        -- Data outputs
        Rs1_data_out       : out std_logic_vector(31 downto 0);
        Rs2_data_out       : out std_logic_vector(31 downto 0);
        Imm_out       : out std_logic_vector(31 downto 0);
        Rs1_out       : out std_logic_vector(4 downto 0);
        Rs2_out       : out std_logic_vector(4 downto 0);
        Rd_out        : out std_logic_vector(4 downto 0);
        funct_3_out     : out  std_logic_vector(2 downto 0);
        funct_7_5     : out  std_logic;
        pc_out	      : out std_logic_vector(31 downto 0);
        alu_pc_out    : out std_logic;
        pc4_out       : out std_logic_vector(31 downto 0);
        immSrc_out    : out std_logic;
        size_out     : out std_logic_vector(1 downto 0) -- Size for vector operations
    );
end ID_EX_Pipeline;

architecture Behavioral of ID_EX_Pipeline is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            -- On reset, clear all outputs
            ALUOp_out      <= (others => '0');
            ALUSrc_out     <= '0';
            memRead_out    <= '0';
            memWrite_out   <= '0';
            memToReg_out   <= "00";
            regWrite_out   <= '0';
            Rs1_data_out       <= (others => '0');
            Rs2_data_out       <= (others => '0');
            Imm_out       <= (others => '0');
            Rs1_out         <= (others => '0');
            Rs2_out         <= (others => '0');
            Rd_out         <= (others => '0');
            funct_3_out <= (others => '0');
            funct_7_5 <= '0';
            pc_out <= (others => '0');
            alu_pc_out <= '0';
            pc4_out <= (others => '0');
            immSrc_out <= '0';
            size_out <= (others => '0');
        elsif rising_edge(clk) then
            if bubble = '1' then
                ALUOp_out      <= (others => '0');
                ALUSrc_out     <= '0';
                memRead_out    <= '0';
                memWrite_out   <= '0';
                memToReg_out   <= "00";
                regWrite_out   <= '0';
                Rs1_data_out       <= (others => '0');
                Rs2_data_out       <= (others => '0');
                Imm_out       <= (others => '0');
                Rs1_out         <= (others => '0');
                Rs2_out         <= (others => '0');
                Rd_out         <= (others => '0');
                funct_3_out <= (others => '0');
                        funct_7_5 <= '0';
                pc_out <= (others => '0');
                alu_pc_out <= '0';
                pc4_out <= (others => '0');
                immSrc_out <= '0';
                size_out <= (others => '0');
            else
                -- On clock edge, latch inputs to outputs
                ALUOp_out      <= ALUOp_in;
                ALUSrc_out     <= ALUSrc_in;
                memRead_out    <= memRead_in;
                memWrite_out   <= memWrite_in;
                memToReg_out   <= memToReg_in;
                regWrite_out   <= regWrite_in;
                Rs1_data_out       <= Rs1_data_in;
                Rs2_data_out       <= Rs2_data_in;
                Imm_out       <= Imm_in;
                Rs1_out         <= Rs1_in;
                Rs2_out         <= Rs2_in;
                Rd_out         <= Rd_in;
                funct_3_out <= funct_3_in;
                funct_7_5 <= funct_7_in(5);
                pc_out <= pc_in;
                alu_pc_out <= alu_pc_in;
                pc4_out <= pc4_in;
                immSrc_out <= immSrc_in;
                size_out <= size_in;
            end if;
        end if;
    end process;
end Behavioral;