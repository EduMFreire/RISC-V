library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu is
    Port (
	clk           : in  std_logic;
        reset         : in  std_logic;
        a_in           : in  std_logic_vector(31 downto 0);
        b_in           : in std_logic_vector(31 downto 0);
	c_in		: in std_logic_vector(4 downto 0);
	result_out	: out std_logic_vector(31 downto 0);
	zero_flag_out	: out std_logic
    );
end alu;

architecture Behavioral of alu is

signal B_operand : std_logic_vector(31 downto 0);
signal carry_in  : std_logic;
signal result    : std_logic_vector(32 downto 0); -- 33 bits para incluir carry out

begin
-- Seleção do operando B (inverte bits para subtração)
    B_operand <= not b_in when c_in(2) = '1' else b_in;
    carry_in  <= '1' when c_in(2) = '1' else '0';
    
    -- Implementação do somador com Carry-Lookahead
    result <= std_logic_vector(unsigned('0' & a_in) + unsigned('0' & B_operand) + ("" & carry_in));

  process(clk, reset)
	variable temp : std_logic_vector(31 downto 0);
	variable temp2 : std_logic_vector(31 downto 0);
  begin
    if reset = '1' then
        result_out <= (others => '0');
	zero_flag_out <= '0';
    elsif rising_edge(clk) then
	temp  := (others => '0');
	temp2 := std_logic_vector(to_unsigned(0,32));
	case c_in is
		when "00000" =>
			temp := a_in and b_in;
		when "00001" =>
			temp := a_in or b_in;
		when "00011" =>
			temp := a_in xor b_in;
		when "00010" =>
			temp := std_logic_vector(unsigned(a_in) + unsigned(b_in));
		when "00110" =>
			temp := std_logic_vector(signed(unsigned(a_in) - unsigned(b_in)));
		when "00100" =>
			temp :=	std_logic_vector(shift_left(unsigned(a_in), to_integer(unsigned(b_in(4 downto 0)))));
		when "00101" =>
			temp :=	std_logic_vector(shift_right(unsigned(a_in), to_integer(unsigned(b_in(4 downto 0)))));
		when "01000" => -- Soma 4 bits
                	temp(3 downto 0) := result(3 downto 0);
                	temp(31 downto 4) := (others => '0');
		when "01100" => -- Subtração 4 bits
			temp(3 downto 0) := result(3 downto 0);
                	temp(31 downto 4) := (others => '0');
            	when "01001" => -- Soma 8 bits
                	temp(7 downto 0) := result(7 downto 0);
                	temp(31 downto 8) := (others => '0');
		when "01101" => -- Subtração 8 bits
                	temp(7 downto 0) := result(7 downto 0);
                	temp(31 downto 8) := (others => '0');
            	when "01010" => -- Soma 16 bits
                	temp(15 downto 0) := result(15 downto 0);
                	temp(31 downto 16) := (others => '0');
		when "01110" => -- Subtração 16 bits
                	temp(15 downto 0) := result(15 downto 0);
                	temp(31 downto 16) := (others => '0');
		when "10000" => -- SLV 4 bits
            		for i in 0 to 7 loop
                		temp(i*4+3 downto i*4) := std_logic_vector(shift_left(unsigned(a_in(i*4+3 downto i*4)), to_integer(unsigned(b_in(4 downto 0)))));
            		end loop;
        	when "10001" => -- SlV 8 bits
            		for i in 0 to 3 loop
                		temp(i*8+7 downto i*8) := std_logic_vector(shift_left(unsigned(a_in(i*8+7 downto i*8)), to_integer(unsigned(b_in(4 downto 0)))));
            		end loop;
       	 	when "10010" => -- SLV 16 bits
            		for i in 0 to 1 loop
                		temp(i*16+15 downto i*16) := std_logic_vector(shift_left(unsigned(a_in(i*16+15 downto i*16)), to_integer(unsigned(b_in(4 downto 0)))));
            		end loop;
        	when "11000" => -- SRV 4 bits
            		for i in 0 to 7 loop
                		temp(i*4+3 downto i*4) := std_logic_vector(shift_right(unsigned(a_in(i*4+3 downto i*4)), to_integer(unsigned(b_in(4 downto 0)))));
            		end loop;
        	when "11001" => -- SRV 8 bits
            		for i in 0 to 3 loop
                		temp(i*8+7 downto i*8) := std_logic_vector(shift_right(unsigned(a_in(i*8+7 downto i*8)), to_integer(unsigned(b_in(4 downto 0)))));
            		end loop;
        	when "11010" => -- SRV 16 bits
            		for i in 0 to 1 loop
                		temp(i*16+15 downto i*16) := std_logic_vector(shift_right(unsigned(a_in(i*16+15 downto i*16)), to_integer(unsigned(b_in(4 downto 0)))));
            		end loop;
		when others =>
			temp := (others => '0');
	end case;
	
	result_out <= temp;
	
	if temp=temp2 then
    		zero_flag_out <= '1';
	else
    		zero_flag_out <= '0';
	end if;
	
    end if;
  end process;
end Behavioral;
