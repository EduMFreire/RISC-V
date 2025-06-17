library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        reg_write: in  std_logic; -- Control signal to enable writing
        rs1_addr : in  std_logic_vector(4 downto 0);
        rs2_addr : in  std_logic_vector(4 downto 0);
        rd_addr  : in  std_logic_vector(4 downto 0);
        rd_data  : in  std_logic_vector(31 downto 0);
        rs1_data : out std_logic_vector(31 downto 0);
        rs2_data : out std_logic_vector(31 downto 0)
    );
end entity register_file;

architecture behavioral of register_file is
    -- Define the storage for 32 registers, each 32 bits wide
    type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
    signal registers : reg_array := (others => (others => '0'));

begin

    -- Read Process: Synchronous to the rising edge (first half of the clock)
    read_proc: process(clk, reset)
    begin
        if reset = '1' then
            -- On reset, clear output data
            rs1_data <= (others => '0');
            rs2_data <= (others => '0');
        elsif rising_edge(clk) then
            -- Read rs1. Reading x0 always returns zero.
            if rs1_addr = "00000" then
                rs1_data <= (others => '0');
            else
                rs1_data <= registers(to_integer(unsigned(rs1_addr)));
            end if;

            -- Read rs2. Reading x0 always returns zero.
            if rs2_addr = "00000" then
                rs2_data <= (others => '0');
            else
                rs2_data <= registers(to_integer(unsigned(rs2_addr)));
            end if;
        end if;
    end process read_proc;

    -- Write Process: Synchronous to the falling edge (second half of the clock)
    write_proc: process(clk, reset)
    begin
        if reset = '1' then
            -- On reset, clear all registers
            for i in 0 to 31 loop
                registers(i) <= (others => '0');
            end loop;
        elsif falling_edge(clk) then
            -- Write only if reg_write is enabled and the destination is not x0
            if reg_write = '1' and rd_addr /= "00000" then
                registers(to_integer(unsigned(rd_addr))) <= rd_data;
            end if;
        end if;
    end process write_proc;

end architecture behavioral;