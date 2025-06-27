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
    type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
    signal registers : reg_array := (others => (others => '0'));
begin

    -- Write Process: Synchronous to the rising edge (first half)
    write_proc: process(clk, reset)
    begin
        if reset = '1' then
            for i in 0 to 31 loop
                registers(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if reg_write = '1' and rd_addr /= "00000" then
                registers(to_integer(unsigned(rd_addr))) <= rd_data;
            end if;
        end if;
    end process write_proc;

    -- Read Process: Synchronous to the falling edge (second half)
    read_proc: process(clk, reset)
    begin
        if reset = '1' then
            rs1_data <= (others => '0');
            rs2_data <= (others => '0');
        elsif falling_edge(clk) then
            -- Read rs1
            if rs1_addr = "00000" then
                rs1_data <= (others => '0');
            else
                rs1_data <= registers(to_integer(unsigned(rs1_addr)));
            end if;

            -- Read rs2
            if rs2_addr = "00000" then
                rs2_data <= (others => '0');
            else
                rs2_data <= registers(to_integer(unsigned(rs2_addr)));
            end if;
        end if;
    end process read_proc;

end architecture behavioral;
