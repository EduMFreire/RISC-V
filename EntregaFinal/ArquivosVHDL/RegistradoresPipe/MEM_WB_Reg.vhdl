library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MEM_WB_Pipeline is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        -- Control signals
        MemToReg_in   : in  std_logic;
        RegWrite_in   : in  std_logic;
        -- Data signals
        ReadData_in   : in  std_logic_vector(31 downto 0);
        ALUResult_in  : in  std_logic_vector(31 downto 0);
        Rd_in         : in  std_logic_vector(4 downto 0);

        -- Outputs to WB stage
        MemToReg_out  : out std_logic;
        RegWrite_out  : out std_logic;
        ALUResult_out : out std_logic_vector(31 downto 0);
        ReadData_out  : out std_logic_vector(31 downto 0);
        Rd_out   : out std_logic_vector(4 downto 0)
    );
end MEM_WB_Pipeline;

architecture Behavioral of MEM_WB_Pipeline is
begin
    process(clk, reset)
    begin
        if reset = '1' then
            RegWrite_out  <= '0';
            MemToReg_out  <= '0';
            ReadData_out  <= (others => '0');
            ALUResult_out <= (others => '0');
            Rd_out   <= (others => '0');
        elsif rising_edge(clk) then
            RegWrite_out  <= RegWrite_in;
            MemToReg_out  <= MemToReg_in;
            ReadData_out  <= ReadData_in;
            ALUResult_out <= ALUResult_in;
            Rd_out   <= Rd_in;
        end if;
    end process;
end Behavioral;
