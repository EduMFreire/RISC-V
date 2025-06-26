
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity HDU is
	Port (
        -- Entradas que vêm do estágio ID
        rs1: in std_logic_vector(4 downto 0);
        rs2: in std_logic_vector(4 downto 0);
        opcode: in std_logic_vector(6 downto 0);

        jump: in std_logic; -- Indica se será feito um salto este ciclo

        -- Entradas que vêm dos demais estágios
        rd_IDEX: in std_logic_vector(4 downto 0);
        memRead_IDEX: in std_logic;
        regWrite_IDEX: in std_logic;

        rd_EXMEM: in std_logic_vector(4 downto 0);
        memRead_EXMEM: in std_logic;

    	-- Saídas
        -- Saídas freeze
        -- Se uma delas é '1', o registrador em questão mantém seu valor atual no próximo ciclo
        PC_freeze: out std_logic;
        IFID_freeze: out std_logic;

        -- Saídas bubble
        -- Se uma delas é '1', o registrador em questão recebe um NOP no próximo ciclo. Seu valor atual pode continuar se propagando ao longo da pipeline (pois o NOP é inserido de forma síncrona)
        IFID_bubble: out std_logic;
        IDEX_bubble: out std_logic
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

process(rs1, rs2, opcode, rd_IDEX, memRead_IDEX, jump)

    variable inst_type: integer;

    -- Temos dois tipos de hazard: DataHazard e ControlHazard
    -- DataHazard ocorre em três situações: load-use, write-jump e load-jump
    -- ControlHazard ocorre em jump

    -- inst_type = 1 indica que a instrução é jal, auipc, lui, ou seja, não está sujeita a DataHazard

    -- inst_type = 2 indica que a instrução é addi, andi, ori, xori, lli, srli, lw, sw, ou seja, está sujeita a DataHazard (load-use) apenas em rs1

    -- inst_type = 3 indica que a instrução é add, sub, and, or, xor, sll, srl, ou seja, está sujeita a DataHazard (load-use) em rs1 e rs2

    -- inst_type = 4 indica que a instrução é jalr, ou seja, está sujeita a DataHazard (load-branch ou write-branch) apenas em rs1

    -- inst_type = 5 indica que a instrução é beq, bne, ou seja, está sujeita a DataHazard (load-branch ou write-branch) em rs1 e rs2

    variable DataHazard: std_logic; -- Indica que há um DataHazard

begin
    -- Identificar se a instução em ID é tipo 1, 2, ou 3
    case opcode is
        when JAL_OP | LUI_OP | AUIPC_OP =>
            inst_type := 1;
        when I_TYPE_OP | L_TYPE_OP | S_TYPE_OP =>
            inst_type := 2;
        when R_TYPE_OP =>
            inst_type := 3;
        when JALR_OP =>
            inst_type := 4;
        when B_TYPE_OP =>
            inst_type := 5;
        when others =>
            -- No caso de instrução inválida, vou considerar como tipo 1 (não suscetível a hazard de escrita-leitura)
            inst_type := 1;
    end case;

    -- Identificar com base nisso se há DataHazard
    case inst_type is            
        when 2 =>
            if memRead_IDEX = '1' and rd_IDEX = rs1 then
                DataHazard := '1'; -- load-use
            else
                DataHazard := '0';
            end if;

        when 3 =>
            if memRead_IDEX = '1' and (rd_IDEX = rs1 or rd_IDEX = rs2) then
                DataHazard := '1'; -- load-use
            else
                DataHazard := '0';
            end if;

        when 4 =>
            if regWrite_IDEX = '1' and rd_IDEX = rs1 then
                DataHazard := '1'; -- write-jump

            elsif memRead_IDEX = '1' and rd_IDEX = rs1 then
                DataHazard := '1'; -- load-jump em IDEX
            
            elsif memRead_EXMEM = '1' and rd_EXMEM = rs1 then
                DataHazard := '1'; -- load-jump em EXMEM
            
            else
                DataHazard := '0';

            end if;

        when 5 =>
            if regWrite_IDEX = '1' and (rd_IDEX = rs1 or rd_IDEX = rs2) then
                DataHazard := '1'; -- write-jump

            elsif memRead_IDEX = '1' and (rd_IDEX = rs1 or rd_IDEX = rs2) then
                DataHazard := '1'; -- load-jump em IDEX

            elsif memRead_EXMEM = '1' and (rd_EXMEM = rs1 or rd_EXMEM = rs2) then
                DataHazard := '1'; -- load-jump em EXMEM
            
            else
                DataHazard := '0';

            end if;

        when others =>
            -- No tipo 1, não temos DataHazard
            DataHazard := '0';
    end case;

    -- De acordo com DataHazard e jump, determinar as saídas
    if DataHazard = '1' then
        PC_freeze <= '1';
        IFID_freeze <= '1';
        IFID_bubble <= '0';
        IDEX_bubble <= '1';
    elsif jump = '1' then
        PC_freeze <= '0';
        IFID_freeze <= '0';
        IFID_bubble <= '1';
        IDEX_bubble <= '0';
    else
        PC_freeze <= '0';
        IFID_freeze <= '0';
        IFID_bubble <= '0';
        IDEX_bubble <= '0';
    end if;
end process;

end Behavioral;
