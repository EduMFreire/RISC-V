-- Registrador que guarda os dados necessários entre IF e ID. Esses dados são o valor de PC e a instrução da vez
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity IFID is
	Port (
    	pc_i : in std_logic_vector(31 downto 0);
        inst_i: in std_logic_vector(31 downto 0);

    	clk: in std_logic;
        reset: in std_logic;

		freeze: in std_logic;
		bubble: in std_logic;

        pc_o: out std_logic_vector(31 downto 0);
        inst_o: out std_logic_vector(31 downto 0)
    	);
end IFID;

architecture Behavioral of IFID is

begin

process(clk, reset)
begin
	if reset = '1' then
        pc_o <= X"00000000";
        inst_o <= X"00000000";

	elsif rising_edge(clk) then

		if freeze = '0' then
			if bubble = '1' then
				pc_o <= X"00000000";
				inst_o <= X"00000000";
			else
				pc_o <= pc_i;
				inst_o <= inst_i;
			end if;
		end if;

	end if;
end process;

end Behavioral;
