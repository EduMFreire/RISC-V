library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
    port (
        -- System signals
        clk      : in  std_logic;
        reset    : in  std_logic; -- Asynchronous reset

        -- Write Port
        reg_write: in  std_logic; -- Control signal to enable writing
        rd_addr  : in  std_logic_vector(4 downto 0);
        rd_data  : in  std_logic_vector(31 downto 0);

        -- Read Port 1
        rs1_addr : in  std_logic_vector(4 downto 0);
        rs1_data : out std_logic_vector(31 downto 0);

        -- Read Port 2
        rs2_addr : in  std_logic_vector(4 downto 0);
        rs2_data : out std_logic_vector(31 downto 0)
    );
end entity register_file;

architecture behavioral of register_file is

    -- The core storage for the 32 registers.
    type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
    signal registers : reg_array := (others => (others => '0'));

begin

    write_proc: process(clk, reset)
    begin
        -- Asynchronously reset all registers to zero.
        if reset = '1' then
            -- Using a loop for clarity; (others => (others => '0')) is also valid.
            for i in 0 to 31 loop
                registers(i) <= (others => '0');
            end loop;
        -- On the rising edge of the clock, perform the write operation.
        elsif rising_edge(clk) then
            -- Check if the write enable signal is active and the destination
            -- is not the hardwired-zero register (r0).
            if reg_write = '1' and rd_addr /= "00000" then
                registers(to_integer(unsigned(rd_addr))) <= rd_data;
            end if;
        end if;
    end process write_proc;


    -- This is achieved by "forwarding" the write data directly to the output
    -- if a read is requested for the address that is currently being written to.


    -- Read Port 1 Logic
    rs1_data <=
        -- CASE 1: Forwarding Condition
        -- If we are writing (reg_write='1') to a valid register (rd_addr /= 0)
        -- AND the address we are writing to is the same as the address we are
        -- reading from (rd_addr = rs1_addr), then forward the input data (rd_data).
        rd_data when (reg_write = '1' and rd_addr = rs1_addr and rd_addr /= "00000") else

        -- CASE 2: Normal Read from Register File
        -- If we are reading from register 0, output all zeros.
        -- Otherwise, output the value stored in the specified register.
        (others => '0') when (rs1_addr = "00000") else
        registers(to_integer(unsigned(rs1_addr)));

    -- Read Port 2 Logic (Identical logic to Read Port 1)
    rs2_data <=
        -- CASE 1: Forwarding Condition
        rd_data when (reg_write = '1' and rd_addr = rs2_addr and rd_addr /= "00000") else

        -- CASE 2: Normal Read from Register File
        (others => '0') when (rs2_addr = "00000") else
        registers(to_integer(unsigned(rs2_addr)));

end architecture behavioral;