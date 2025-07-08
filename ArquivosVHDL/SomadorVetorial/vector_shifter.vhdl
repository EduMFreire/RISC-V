library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vector_shifter is
    Port(
        A_i       : in  std_logic_vector(31 downto 0);
        B_i       : in  std_logic_vector(31 downto 0);  -- rs2 ou imediato
        mode_i    : in  std_logic; -- '0' = shift left, '1' = shift right
        vecSize_i : in  std_logic_vector(1 downto 0); -- 00:4b, 01:8b, 10:16b, 11:32b

        S_o       : out std_logic_vector(31 downto 0)
    );
end vector_shifter;

architecture Behavioral of vector_shifter is

    constant NUM_BLOCKS : integer := 8;

    type vec4_array is array (0 to NUM_BLOCKS-1) of std_logic_vector(3 downto 0);
    signal A_blocks, S_blocks : vec4_array;
    signal result : std_logic_vector(31 downto 0);

    -- Extrai os 5 bits de shift amount (seguindo RISC-V)
    signal shamt : std_logic_vector(4 downto 0);

begin

    -- Pegando apenas os 5 LSBs de B_i
    shamt <= B_i(4 downto 0);

    -- Dividir A_i em blocos de 4 bits
    splitter: for i in 0 to NUM_BLOCKS-1 generate
        A_blocks(i) <= A_i(4*i+3 downto 4*i);
    end generate;

    -- Aplica shift vetorial por bloco, considerando o tamanho do vetor
    shifter: for i in 0 to NUM_BLOCKS-1 generate
        process(A_blocks, shamt, mode_i, vecSize_i)
            variable local_shift : integer;
            variable A_val       : std_logic_vector(3 downto 0);
            variable result_val  : std_logic_vector(3 downto 0);
        begin
            A_val := A_blocks(i);
            result_val := (others => '0');

            -- Determina o quanto deslocar com base no tamanho do vetor
            if vecSize_i = "00" then       -- 4-bit vetores (1 bloco)
                local_shift := to_integer(unsigned(shamt)) mod 4;
            elsif vecSize_i = "01" then    -- 8-bit vetores (2 blocos)
                local_shift := to_integer(unsigned(shamt)) mod 8;
            elsif vecSize_i = "10" then    -- 16-bit vetores (4 blocos)
                local_shift := to_integer(unsigned(shamt)) mod 16;
            else                           -- 32-bit vetor (8 blocos)
                local_shift := to_integer(unsigned(shamt)) mod 32;
            end if;

            -- SHIFT lógico
            if mode_i = '0' then
                -- Shift Left
                result_val := std_logic_vector(shift_left(unsigned(A_val), local_shift mod 4));
            else
                -- Shift Right
                result_val := std_logic_vector(shift_right(unsigned(A_val), local_shift mod 4));
            end if;

            S_blocks(i) <= result_val;
        end process;
    end generate;

    -- Reconstroi resultado final
    joiner: for i in 0 to NUM_BLOCKS-1 generate
        result(4*i+3 downto 4*i) <= S_blocks(i);
    end generate;

    S_o <= result;

end Behavioral;
