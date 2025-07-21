library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity last_bit_zero_aligner is
    -- O Digital estava dando problema, como se WIDTH_G fosse 1 a despeito de seu valor default. Tirei o generic
    port (
        -- Input: The address that needs alignment
        addr_in  : in  STD_LOGIC_VECTOR(31 downto 0);
        -- Output: The aligned address with the LSB cleared
        addr_out : out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity last_bit_zero_aligner;

architecture behavioral of last_bit_zero_aligner is
begin

    addr_out <= addr_in(31 downto 1) & '0';

end architecture behavioral;