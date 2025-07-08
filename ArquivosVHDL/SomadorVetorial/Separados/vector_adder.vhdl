-- Ideia
-- Ter 8 somadores de 4 bits com carry lookahead. Assim, o carry se propaga de 4 em 4 em vez de se propagar de 1 em 1
-- Ao instanciar os somadores, propagar carry apenas no meio dos blocos (dependendo de vecSize_i). No início dos blocos, colocar carry '0' para adição. Para subtração, inverter todos os bits de B, e colocar carry '1' no início de cada bloco.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity vector_adder is
    Port(
        A_i       : in  std_logic_vector(31 downto 0);
        B_i       : in  std_logic_vector(31 downto 0);
        mode_i    : in  std_logic; -- '0' para soma, '1' para subtração
        vecSize_i : in  std_logic_vector(1 downto 0); -- 00:4b, 01:8b, 10:16b, 11:32b
        S_o       : out std_logic_vector(31 downto 0);
	zero_out  : out std_logic
    );
end vector_adder;

architecture Behavioral of vector_adder is
    signal not_B: std_logic_vector(31 downto 0);
    signal carry: std_logic_vector(8 downto 0); -- O último carry é descartado

    component adder4 is
        Port(
            A: in std_logic_vector(3 downto 0);
            B: in std_logic_vector(3 downto 0);
            Cin: in std_logic;

            S: out std_logic_vector(3 downto 0);
            Cout: out std_logic
        );
    end component;

begin
    not_B <= not(B_i); -- Calculado uma vez só, para não ser necessário um conjunto de portas not por somador

    -- Instanciar os 8 somadores
    adder_generate: for i in 0 to 7 generate

        signal prop: std_logic;
        signal actual_carry: std_logic;
        signal B: std_logic_vector(3 downto 0);

    begin
        -- Propagar carry apenas no meio dos blocos
        prop <=
            '1' when
                ((vecSize_i = "01") and (i mod 2 /= 0)) or -- Blocos de 8, os adders se juntam de 2 em 2
                ((vecSize_i = "10") and (i mod 4 /= 0)) or -- Blocos de 16, os adders se juntam de 4 em 4
                ((vecSize_i = "11") and (i /= 0)) -- Bloco de 32, todos os 8 adders se juntam

                -- com vecSize_i = "00", não há propagação
            else '0';

        -- No meio dos blocos, propagamos carry. No início dos blocos, colocamos carry '0' para soma e carry '1' para subtração (complemento de 2)
        actual_carry <=
            carry(i) when prop = '1'
            else mode_i;

        B <=
            B_i(4*i+3 downto 4*i) when mode_i = '0'
            else not_B(4*i+3 downto 4*i);

        adder: adder4
        port map(
            A => A_i(4*i+3 downto 4*i),

            B => B,
            
            Cin => actual_carry,
            
            S => S_o(4*i+3 downto 4*i),

            Cout => carry(i+1)
        );
    end generate;

	process(S_o)
    	begin
        	if S_o = X"00000000" then
    			zero_out <= '1';
		else
    			zero_out <= '0';
		end if;
        end process;

	
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity adder4 is
    Port(
        A: in std_logic_vector(3 downto 0);
        B: in std_logic_vector(3 downto 0);
        Cin: in std_logic;

        S: out std_logic_vector(3 downto 0);
        Cout: out std_logic
    );
end adder4;

architecture arch of adder4 is

    signal prop: std_logic_vector(3 downto 0);
    signal gen: std_logic_vector(3 downto 0);
    signal carry: std_logic_vector(3 downto 0);

begin

    signals_generate: for i in 0 to 3 generate
        prop(i) <= A(i) xor B(i);
        gen(i) <= A(i) and B(i);
    end generate;

    -- Carry lookahead
    carry(0) <= Cin;
    carry(1) <= gen(0) or (prop(0) and Cin);

    carry(2) <= gen(1) or (prop(1) and gen(0)) or (prop(1) and prop(0) and Cin);

    carry(3) <= gen(2) or (prop(2) and gen(1)) or (prop(2) and prop(1) and gen(0)) or (prop(2) and prop(1) and prop(0) and Cin);

    Cout <= gen(3) or (prop(3) and gen(2)) or (prop(3) and prop(2) and gen(1)) or (prop(3) and prop(2) and prop(1) and gen(0)) or (prop(3) and prop(2) and prop(1) and prop(0) and Cin);

    sum_generate: for i in 0 to 3 generate
        S(i) <= prop(i) xor carry(i);
    end generate;

end arch;
