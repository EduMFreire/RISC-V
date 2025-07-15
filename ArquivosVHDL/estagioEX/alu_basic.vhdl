library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu_combinational is
    Port (
        a_in            : in  std_logic_vector(31 downto 0);
        b_in            : in  std_logic_vector(31 downto 0);
        c_in            : in  std_logic_vector(3 downto 0);
        result_out      : out std_logic_vector(31 downto 0)

    );
end alu_combinational;

architecture Behavioral of alu_combinational is

begin

    process(a_in, b_in, c_in)
        variable temp_result : std_logic_vector(31 downto 0);
    begin
        -- Initialize temp_result for safety (though not strictly necessary for full case coverage)
        temp_result := (others => '0');

        case c_in is
            when "0000" =>
                temp_result := a_in and b_in;
            when "0001" =>
                temp_result := a_in or b_in;
            when "0011" =>
                temp_result := a_in xor b_in;
            when "0010" =>
                temp_result := std_logic_vector(unsigned(a_in) + unsigned(b_in));
            when "0110" =>
                -- For subtraction, ensure both operands are treated as unsigned for consistent arithmetic.
                -- If signed subtraction is intended, use signed types for both a_in and b_in.
                temp_result := std_logic_vector(unsigned(a_in) - unsigned(b_in));
            when "0100" =>
                -- For shift operations, the shift amount should be an integer,
                -- and using 'unsigned' directly on the slice ensures proper conversion.
                temp_result := std_logic_vector(shift_left(unsigned(a_in), to_integer(unsigned(b_in(4 downto 0)))));
            when "0101" =>
                temp_result := std_logic_vector(shift_right(unsigned(a_in), to_integer(unsigned(b_in(4 downto 0)))));
            when others =>
                temp_result := (others => '0'); -- Default or undefined operation
        end case;

        -- Assign the calculated temporary result to the output signal
        result_out <= temp_result;

        -- Determine the zero flag based on the calculated result
    end process;

end Behavioral;
