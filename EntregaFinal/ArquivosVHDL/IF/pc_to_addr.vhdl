-- Recebe pc(31 downto 0) e retorna pc(25 downto 2), para ser usado como endereco da memória de instrução.

-- Isso ocorre porque a memória de instrução do Digital só recebe 24 bits de endereço. Para facilitar ao máximo a gente editar a memória de instrução e fazer testes, vou configurar a memória de instrução com 24 bits de endereço e 32 bits por palavra.
-- Como os últimos 2 bits de PC são ignorados, quando somamos PC+4, estamos indo para a próxima palavra de 32 bits da memória de instrução.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pc_to_addr is
	Port (
    	pc_i : in std_logic_vector(31 downto 0);
    	
        addr_o: out std_logic_vector(23 downto 0)
    	);
end pc_to_addr;

architecture Behavioral of pc_to_addr is

begin

process(pc_i)
begin
    addr_o <= pc_i(25 downto 2);
end process;

end Behavioral;
