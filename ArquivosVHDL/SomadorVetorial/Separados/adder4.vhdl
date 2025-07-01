-- Ideia
-- Ter 8 somadores de 4 bits com carry lookahead. Assim, o carry se propaga de 4 em 4 em vez de se propagar de 1 em 1
-- Ao instanciar os somadores, propagar carry apenas no meio dos blocos (dependendo de vecSize_i). No início dos blocos, colocar carry '0' para adição. Para subtração, inverter todos os bits de B, e colocar carry '1' no início de cada bloco.

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