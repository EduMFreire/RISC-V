library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity vector_adder is
    Port(
        A_i       : in  std_logic_vector(31 downto 0);
        B_i       : in  std_logic_vector(31 downto 0);
        mode_i    : in  std_logic; -- '0' para soma, '1' para subtração
        vecSize_i : in  std_logic_vector(1 downto 0); -- 00:4b, 01:8b, 10:16b, 11:32b

        S_o       : out std_logic_vector(31 downto 0)
    );
end vector_adder;

architecture Behavioral of vector_adder is
    signal not_B: std_logic_vector(31 downto 0);
    signal carry: std_logic_vector(8 downto 0); -- O último carry é descartado

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
                ((vecSize_i = "00") and (i mod 4 /= 0)) or
                ((vecSize_i = "01") and (i mod 8 /= 0)) or
                ((vecSize_i = "10") and (i mod 16 /= 0)) or
                ((vecSize_i = "11") and (i /= 0))
            else '0';

        -- No meio dos blocos, propagamos carry. No início dos blocos, colocamos carry '0' para soma e carry '1' para subtração (complemento de 2)
        actual_carry <=
            carry(i) when prop = '1'
            else mode_i;

        B <=
            B_i(4*i+3 downto 4*i) when mode_i = '0'
            else not_B(4*i+3 downto 4*i);

        adder: entity work.adder4(arch)
        port map(
            A => A_i(4*i+3 downto 4*i),

            B => B,
            
            Cin => actual_carry,
            
            S => S_o(4*i+3 downto 4*i),

            Cout => carry(i+1)
        );
    end generate;

end Behavioral;