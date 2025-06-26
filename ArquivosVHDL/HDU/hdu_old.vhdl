
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity HDU is
	Port (
        -- Entradas que vêm do estágio ID
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        opcode: in std_logic_vector(6 downto 0);

        -- Entradas que vêm dos demais estágios
        rd_IDEX: in std_logic_vector(4 downto 0);
        RegWrite_IDEX: in std_logic;

        rd_EXMEM: in std_logic_vector(4 downto 0);
        RegWrite_EXMEM: in std_logic;

        rd_MEMWB: in std_logic_vector(4 downto 0);
        RegWrite_MEMWB: in std_logic;

        jump: in std_logic; -- Indica se será feito um salto este ciclo

    	-- Saídas
        -- Saídas freeze
        -- Se uma delas é '1', o registrador em questão mantém seu valor atual no próximo ciclo
        PC_freeze: out std_logic;
        IFID_freeze: out std_logic;

        -- Saídas bubble
        -- Se uma delas é '1', o registrador em questão recebe um NOP no próximo ciclo. Seu valor atual pode continuar se propagando ao longo da pipeline (pois o NOP é inserido de forma síncrona)
        IFID_bubble: out std_logic;
        IDEX_bubble: out std_logic;
        EXMEM_bubble: out std_logic
    	);
end HDU;

architecture Behavioral of HDU is

    -- Opcodes para diferentes tipos de instrução
    constant R_TYPE_OP   : std_logic_vector(6 downto 0) := "0110011"; -- OP (ADD, SUB, AND, OR, XOR)
    constant I_TYPE_OP   : std_logic_vector(6 downto 0) := "0010011"; -- OP-IMM (ADDI, ANDI, ORI)
    constant L_TYPE_OP   : std_logic_vector(6 downto 0) := "0000011"; -- LOAD (LW)
    constant S_TYPE_OP   : std_logic_vector(6 downto 0) := "0100011"; -- STORE (SW)
    constant B_TYPE_OP   : std_logic_vector(6 downto 0) := "1100011"; -- BRANCH (BEQ, BNE)
    constant JAL_OP      : std_logic_vector(6 downto 0) := "1101111"; -- JAL
    constant JALR_OP     : std_logic_vector(6 downto 0) := "1100111"; -- JALR
    constant LUI_OP      : std_logic_vector(6 downto 0) := "0110111"; -- LUI
    constant AUIPC_OP    : std_logic_vector(6 downto 0) := "0010111"; -- AUIPC

begin

process(rs1, rs2, opcode, rd_IDEX, RegWrite_IDEX, rd_EXMEM, RegWrite_EXMEM, rd_MEMWB, RegWrite_MEMWB, jump)

    variable inst_type: integer;

    -- inst_type = 1 indica que a instrução é jal, jalr, auipc, lui, ou seja, não está sujeita a hazard de escrita-leitura
    -- inst_type = 2 indica que a instrução é addi, andi, ori, xori, lli, srli, lw, sw, ou seja, está sujeita a hazard de escrita-leitura apenas em rs1
    -- inst_type = 3 indica que a instrução e add, sub, and, or, xor, sll, srl, beq, bne, ou seja, está sujeita a hazard de escrita-leitura em rs1 e rs2

    variable WriteReadHazard: std_logic; -- Indica que há um hazard de escrita-leitura

begin
    -- Primeiro, vamos verificar se há um jump acontecendo. Nesse caso, independentemente dos demais hazards, as instruções em IFID, IDEX estão erradas, e o valor de PC também está errado (está prestes a ser atualizado)
    -- Precisamos dar bubble em IFID, IDEX, EXMEM, e não congelar PC
    if jump = '1' then
        PC_freeze <= '0';
        IFID_freeze <= '0';

        IFID_bubble <= '1';
        IDEX_bubble <= '1';
        EXMEM_bubble <= '1';
    else

        -- Identificar se a instução em ID é tipo 1, 2, ou 3
        case opcode is
            when JAL_OP | JALR_OP | LUI_OP | AUIPC_OP =>
                inst_type := 1;
            when I_TYPE_OP | L_TYPE_OP | S_TYPE_OP =>
                inst_type := 2;
            when R_TYPE_OP | B_TYPE_OP =>
                inst_type := 3;
            when others =>
                -- No caso de instrução inválida, vou considerar como tipo 1 (não suscetível a hazard de escrita-leitura)
                inst_type := 1;
        end case;

        -- Identificar com base nisso se há hazard de escrita-leitura
        case inst_type is            
            when 2 =>
                if RegWrite_IDEX = '1' and rd_IDEX = rs1 then
                    writeReadHazard := '1';

                elsif RegWrite_EXMEM = '1' and rd_EXMEM = rs1 then
                    writeReadHazard := '1';
                
                elsif RegWrite_MEMWB = '1' and rd_MEMWB = rs1 then
                    writeReadHazard := '1';
                
                else
                    writeReadHazard := '0';
                
                end if;

            when 3 =>
                if RegWrite_IDEX = '1' and (rd_IDEX = rs1 or rd_IDEX = rs2) then
                    writeReadHazard := '1';

                elsif RegWrite_EXMEM = '1' and (rd_EXMEM = rs1 or rd_EXMEM = rs2) then
                    writeReadHazard := '1';

                elsif RegWrite_MEMWB = '1' and (rd_MEMWB = rs1 or rd_MEMWB = rs2) then
                    writeReadHazard := '1';

                else
                    writeReadHazard := '0';

                end if;

            when others =>
                -- No tipo 1, não temos hazard de escrita-leitura
                writeReadHazard := '0';
        end case;

        -- De acordo com writeReadHazard, decidimos as saídas
        if writeReadHazard = '1' then
            -- Nesse caso, o valor que estamos lendo em ID está errado. Precisamos inserir bolha em IDEX para esse valor não se propagar, e congelar PC e IFID
            PC_freeze <= '1';
            IFID_freeze <= '1';

            IFID_bubble <= '0';
            IDEX_bubble <= '1';
            EXMEM_bubble <= '0';
        else
            -- Sem hazard
            PC_freeze <= '0';
            IFID_freeze <= '0';

            IFID_bubble <= '0';
            IDEX_bubble <= '0';
            EXMEM_bubble <= '0';
        end if;

    end if;

end process;

end Behavioral;
