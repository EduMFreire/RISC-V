library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vector_adder is
    Port (
        A_i       : in  std_logic_vector(31 downto 0);
        B_i       : in  std_logic_vector(31 downto 0);
        mode_i    : in  std_logic; -- '0' para soma, '1' para subtração
        vecSize_i : in  std_logic_vector(1 downto 0); -- 00:4b, 01:8b, 10:16b, 11:32b
        S_o       : out std_logic_vector(31 downto 0)
    );
end vector_adder;

architecture Behavioral of vector_adder is
    signal A_u, B_u     : unsigned(31 downto 0);
    signal B_operand    : std_logic_vector(31 downto 0);
    signal C            : std_logic_vector(8 downto 0);  -- carry entre blocos
    signal S_temp       : unsigned(31 downto 0);
    
    -- Constantes para os tamanhos de bloco
    constant BLOCK_4  : integer := 4;
    constant BLOCK_8  : integer := 8;
    constant BLOCK_16 : integer := 16;
    constant BLOCK_32 : integer := 32;
begin

    -- Inverte B para subtração (complemento de 2)
    B_operand <= not B_i when mode_i = '1' else B_i;

    A_u <= unsigned(A_i);
    B_u <= unsigned(B_operand);

    process(A_u, B_u, mode_i, vecSize_i)
        variable blockSize : integer := 32;
        variable numBlocks : integer := 1;
        variable maxValue  : unsigned(31 downto 0);
    begin
        -- Determinar tamanho do bloco e número de blocos
        case vecSize_i is
            when "00" =>  -- 4 bits
                blockSize := BLOCK_4;
                numBlocks := 8;
                maxValue := to_unsigned(16, 32);  -- 2^4
            when "01" =>  -- 8 bits
                blockSize := BLOCK_8;
                numBlocks := 4;
                maxValue := to_unsigned(256, 32);  -- 2^8
            when "10" =>  -- 16 bits
                blockSize := BLOCK_16;
                numBlocks := 2;
                maxValue := to_unsigned(65536, 32);  -- 2^16
            when others =>  -- 32 bits
                blockSize := BLOCK_32;
                numBlocks := 1;
                maxValue := (others => '1');  -- Valor máximo não usado neste caso
        end case;

        -- Inicializa carry[0] com o modo ('1' para subtração)
        C(0) <= mode_i;

        -- Realiza soma dos blocos com carry correspondente
        for i in 0 to numBlocks - 1 loop
            -- Verifica limites antes de acessar
            if (i+1)*blockSize-1 <= 31 then
                -- Cálculo seguro sem exponenciação
                S_temp((i+1)*blockSize - 1 downto i*blockSize) <=
                    A_u((i+1)*blockSize - 1 downto i*blockSize) +
                    B_u((i+1)*blockSize - 1 downto i*blockSize) +
                    unsigned'("" & C(i));
                
                -- Gera carry para próximo bloco (sem usar exponenciação)
                if blockSize < 32 then
                    if (A_u((i+1)*blockSize - 1 downto i*blockSize)) + 
                       B_u((i+1)*blockSize - 1 downto i*blockSize) + 
                       unsigned'("" & C(i)) >= maxValue then
                        if i < numBlocks - 1 then
                            C(i+1) <= '1';
                        end if;
                    else
                        if i < numBlocks - 1 then
                            C(i+1) <= '0';
                        end if;
                    end if;
                end if;
            end if;
        end loop;

        -- Zera blocos não utilizados
        if numBlocks * blockSize < 32 then
            S_temp(31 downto numBlocks*blockSize) <= (others => '0');
        end if;

        S_o <= std_logic_vector(S_temp);
    end process;
end Behavioral;
