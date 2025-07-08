library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vector_shifter is
    Port(
        A_i       : in  std_logic_vector(31 downto 0);
        B_i       : in  std_logic_vector(31 downto 0);  -- rs2 ou imediato
        mode_i    : in  std_logic;                      -- '0' = shift left, '1' = shift right
        vecSize_i : in  std_logic_vector(1 downto 0);   -- 00:4b, 01:8b, 10:16b, 11:32b
        S_o       : out std_logic_vector(31 downto 0);
	zero_out  : out std_logic
    );
end vector_shifter;

architecture Behavioral of vector_shifter is

    signal result : std_logic_vector(31 downto 0);
    signal shamt  : std_logic_vector(4 downto 0);
    signal shamt_int : integer;
    constant ALL_ZEROS_32 : std_logic_vector(31 downto 0) := (others => '0');

begin

    -- Pega os 5 LSBs do B_i como shift amount
    shamt <= B_i(4 downto 0);
    shamt_int <= to_integer(unsigned(shamt));

    -- Processo único com geradores internos para diferentes tamanhos de vetores
    process(A_i, shamt_int, mode_i, vecSize_i)
        variable temp_result : std_logic_vector(31 downto 0);
	variable segment4 : std_logic_vector(3 downto 0);
    	variable segment8 : std_logic_vector(7 downto 0);
    	variable segment16 : std_logic_vector(15 downto 0);
    begin
        temp_result := (others => '0');

        case vecSize_i is

            when "00" =>  -- 4-bit vetores (8 grupos)
                gen4: for i in 0 to 7 loop
		if shamt_int >= 4 then
            		segment4 := (others => '0');
		else
                    if mode_i = '0' then
                        segment4 := std_logic_vector(shift_left(unsigned(A_i(4*i+3 downto 4*i)), shamt_int mod 4));
                    else
                        segment4 := std_logic_vector(shift_right(unsigned(A_i(4*i+3 downto 4*i)), shamt_int mod 4));
                    end if;
		end if;
                    temp_result(4*i+3 downto 4*i) := segment4;
                end loop;

            when "01" =>  -- 8-bit vetores (4 grupos)
                gen8: for i in 0 to 3 loop
                    if mode_i = '0' then
                        segment8 := std_logic_vector(shift_left(unsigned(A_i(8*i+7 downto 8*i)), shamt_int mod 8));
                    else
                        segment8 := std_logic_vector(shift_right(unsigned(A_i(8*i+7 downto 8*i)), shamt_int mod 8));
                    end if;
                    temp_result(8*i+7 downto 8*i) := segment8;
                end loop;

            when "10" =>  -- 16-bit vetores (2 grupos)
                gen16: for i in 0 to 1 loop
                    if mode_i = '0' then
                        segment16 := std_logic_vector(shift_left(unsigned(A_i(16*i+15 downto 16*i)), shamt_int mod 16));
                    else
                        segment16 := std_logic_vector(shift_right(unsigned(A_i(16*i+15 downto 16*i)), shamt_int mod 16));
                    end if;
                    temp_result(16*i+15 downto 16*i) := segment16;
                end loop;

            when others =>  -- 32-bit vetor (1 grupo)
                if mode_i = '0' then
                    temp_result := std_logic_vector(shift_left(unsigned(A_i), shamt_int mod 32));
                else
                    temp_result := std_logic_vector(shift_right(unsigned(A_i), shamt_int mod 32));
                end if;

        end case;

        S_o <= temp_result;
	if temp_result = ALL_ZEROS_32 then
            zero_out <= '1';
        else
            zero_out <= '0';
        end if;

    end process;

end Behavioral
