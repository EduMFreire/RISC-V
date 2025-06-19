library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VectorAdderSubtractor is
    Port (
        A_i       : in  std_logic_vector(31 downto 0);
        B_i       : in  std_logic_vector(31 downto 0);
        mode_i    : in  std_logic; -- '0' para soma, '1' para subtração
        vecSize_i : in  std_logic_vector(1 downto 0); -- Tamanho do vetor
        S_o       : out std_logic_vector(31 downto 0)
    );
end VectorAdderSubtractor;

architecture Behavioral of VectorAdderSubtractor is
    signal B_operand : std_logic_vector(31 downto 0);
    signal carry_in  : std_logic;
    signal result    : std_logic_vector(32 downto 0); -- 33 bits para incluir carry out
begin
    -- Seleção do operando B (inverte bits para subtração)
    B_operand <= not B_i when mode_i = '1' else B_i;
    carry_in  <= '1' when mode_i = '1' else '0';
    
    -- Implementação do somador com Carry-Lookahead
    result <= std_logic_vector(unsigned('0' & A_i) + unsigned('0' & B_operand) + ("" & carry_in));
    
    -- Processo para mascarar os bits não utilizados com base no tamanho do vetor
    process(A_i, B_i, mode_i, vecSize_i, result)
    begin
        case vecSize_i is
            when "00" => -- 4 bits
                S_o(3 downto 0) <= result(3 downto 0);
                S_o(31 downto 4) <= (others => '0');
            when "01" => -- 8 bits
                S_o(7 downto 0) <= result(7 downto 0);
                S_o(31 downto 8) <= (others => '0');
            when "10" => -- 16 bits
                S_o(15 downto 0) <= result(15 downto 0);
                S_o(31 downto 16) <= (others => '0');
            when "11" => -- 32 bits
                S_o <= result(31 downto 0);
            when others =>
                S_o <= (others => '0');
        end case;
    end process;
end Behavioral;


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity main is
  port (
    A: in std_logic_vector(31 downto 0);
    B: in std_logic_vector(31 downto 0);
    Mode: in std_logic;
    Size: in std_logic_vector(1 downto 0);
    result: out std_logic_vector(31 downto 0));
end main;

architecture Behavioral of main is
begin
  gate0: entity work.VectorAdderSubtractor -- VectorAdderSubtractor
    port map (
      A_i => A,
      B_i => B,
      mode_i => Mode,
      vecSize_i => Size,
      S_o => result);
end Behavioral;
