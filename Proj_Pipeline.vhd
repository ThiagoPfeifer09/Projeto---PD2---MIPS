library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Proj_Pipeline is
	port (
		clock	    : in std_logic;
		reset	    : in std_logic;
        R1_out      : out std_logic_vector(7 downto 0);
        R2_out      : out std_logic_vector(7 downto 0)
		);
end Proj_Pipeline;

architecture behavior of Proj_Pipeline is
    type memo_dados is array (integer range 0 to 255) of std_logic_vector(7 downto 0);
    type mem_instruc is array (integer range 0 to 255) of std_logic_vector(15 downto 0);
    type banco_regs is array (integer range 0 to 15) of std_logic_vector(7 downto 0);

      signal mem_inst : mem_instruc := (
	    0  => "1010001000001111",  -- LWI no reg 2 o 15 
	    1  => "0000000000000000",  -- NOP (Bolha para evitar conflito de dados)
	    2  => "0110001100000010",  -- LW da pos 2 da mem no reg 3
	    3  => "0000000000000000",  -- NOP (Bolha para evitar conflito de dados)
	    4  => "1000000100000001",  -- ADDI no reg 1 R0 + 1
	    5  => "0000000000000000",  -- NOP (Bolha para evitar conflito de dados)
	    6  => "0000010000100000",  -- ADD no R4 R2 + R0
	    7  => "0100010000100001",  -- BEQ R0 = R2 e pula para o jump se houver o desvio
	    8  => "0000000000000000",  -- NOP (Bolha para ajustar para desvio, se necessário)
	    9  => "0001010001000011",  -- SUBI no R4 o R4 - R3
	    10 => "0000010101010001",  -- ADDI no R5 R5 + 1
	    11 => "0101000000000111",  -- JMP para inst 7 (BEQ)
	    12 => "0111010100000100",  -- SW do R5 na pos 4 GUARDA O RESULTADO
	    13 => "0000000000000000",  -- NOP (Bolha para ajuste de dados na MEM)
	    14 => "0010100000110101",  -- MULT R3 e R5 e guarda em R8
	    15 => "0000000000000000",  -- NOP (Bolha para aguardar resultado da MULT)
	    16 => "0111100000001000",  -- SW do resultado da mult na pos 8 da mem
	    others => (others => '1')  -- Resto da memória preenchido com NOPs
);


    signal mem_dado	            : memo_dados := ( 
        0 => "00000000",
        1 => "00000001", --1
        2 => "00000011", --3
        others => (others => '0')
    ); 

    signal PC	                                    : std_logic_vector(7 downto 0); 
    signal regs                                     : banco_regs := (others => (others => '0'));
    signal desvio	                                : std_logic; 
    signal mul, muli                                : std_logic_vector(15 downto 0);
    signal ula                                      : std_logic_vector(7 downto 0); 
    signal equal	                                : std_logic;
    signal R1_ID                                    : std_logic_vector(7 downto 0);
    signal R2_ID                                    : std_logic_vector(7 downto 0);
    signal Ri_ID, Ri_EX, Ri_MEM                     : std_logic_vector(7 downto 0); 
    signal PC_ID, PC_EX, PC_MEM, PC_WB              : std_logic_vector(7 downto 0); 
    signal Inst_ID, Inst_EX, Inst_MEM, Inst_WB      : std_logic_vector(15 downto 0);


begin 
            --Verifica se R0 e R1 tem valores iguais.
            equal <= '1' when (R1_ID= Ri_EX) else
                '0';

            --Indica se um salto deve ocorrer.
            desvio <= '1' when (Inst_MEM(15 downto 12) = "0011" and equal = '0') or (Inst_MEM(15 downto 12) = "0100" and equal = '1') else
                '0';

            muli <= R1_ID* (("0000") & Inst_MEM(3 downto 0));
            mul <= R1_ID* R2_ID;
            R1_out <= R1_ID;
            R2_out <= R2_ID;

    process(reset, clock)
        begin
            if (reset = '1') then   
                regs    <= (others => (others => '0'));
                PC      <= (others => '0');
                PC_ID <= (others => '0');
                PC_EX <= (others => '0');
                PC_MEM <= (others => '0');
                PC_WB<= (others => '0');

                Inst_ID   <= (others => '0');
                Inst_EX   <= (others => '0');
                Inst_MEM  <= (others => '0');
                Inst_WB  <= (others => '0');

                ula<= (others => '0');

                R1_ID <= (others => '0');
                R2_ID  <= (others => '0');
                Ri_ID  <= (others => '0');
                Ri_EX  <= (others => '0');
                Ri_MEM  <= (others => '0');

            elsif (clock = '1' and clock'event) then
            
-------------------------PASSA A INSTRUÇÃO ADIANTE NO PROGRAMA 
                Inst_ID <= mem_inst(conv_integer(PC))(15 downto 0);
                Inst_EX <= Inst_ID;
                Inst_MEM <= Inst_EX;
                Inst_WB <= Inst_MEM;
                
--------------------------PASSA O PC POR TODOS OS ESTAGIO APENAS PARA VISUALIZAÇÃO 

                PC_ID <= PC;
                PC_EX <= PC_ID;
                PC_MEM <= PC_EX;
                PC_WB<= PC_MEM;

----------------------------------DESVIO QUE OCORRE  

                if (desvio = '1') then

                    if (Inst_MEM(15 downto 12) = "0011" or Inst_MEM(15 downto 12) = "0100") then
                        PC <= PC + Inst_MEM(3 downto 0); -- BEQ/BNE
                    end if;

                elsif (Inst_MEM(15 downto 12) = "0101") then
                    PC <= Inst_MEM(7 downto 0); -- JMP    

                else
                    PC <= PC + 1;
                    
                end if;
                
--------------------------DECODIFICAÇÃO DA INSTRUÇÃO PEGA OS REGS 

                if(Inst_EX(15 downto 12) = "0101") then --jump
                    Ri_ID <= (others => '0');
                    R1_ID<= (others => '0');
                    R2_ID <= (others => '0');
                    Inst_EX <= (others => '1');
                    Inst_ID <= (others => '1');

                elsif(Inst_EX(15 downto 12) = "0001" or Inst_EX(15 downto 12) = "0010" or Inst_EX(15 downto 12) = "0000") then
                    --R
                    R1_ID<= regs(conv_integer(Inst_EX(7 downto 4)));
                    R2_ID <= regs(conv_integer(Inst_EX(3 downto 0)));

                else --Imediatos e BEQ/BNE
                    R1_ID<= regs(conv_integer(Inst_EX(7 downto 4)));
                    Ri_ID <= regs(conv_integer(Inst_EX(11 downto 8)));
                
                end if;                
                
--------------------------EXECUÇÃO DAS OPERAÇÕES DA ULA

                if(desvio = '1') then --BOLHAS
                    ula<= (others => '0');
                    Ri_ID <= (others => '0');
                    R1_ID<= (others => '0');
                    R2_ID <= (others => '0');
                    Inst_MEM <= (others => '1');
                    Inst_EX <= (others => '1');
                    Inst_ID <= (others => '1');
                
                else
                    Ri_EX <= Ri_ID;
                    case Inst_MEM(15 downto 12) is
                        when "0000" => -- ADD
                            ula<= R1_ID + R2_ID;

                        when "0001" => -- SUB
                            ula<= R1_ID - R2_ID;

                        when "0010" => -- MULT
                            ula<= mul(7 downto 0);
                            
                        when "1000" => -- ADDI
                            ula<= R1_ID + Inst_MEM(3 downto 0);

                        when "1001" => -- SUI
                            ula<= R1_ID - Inst_MEM(3 downto 0);
                    
                        when "1011" => -- MUI
                            ula<= muli(7 downto 0);

                        when others =>
                            
                        end case;
                end if;
                
-------------------ULTIMO ESTÁGIO ACESSO A MEMORIA E WRITEBACK

                if(Inst_WB(15 downto 12) = "0111") then --STORE
                    mem_dado(conv_integer(Inst_WB(7 downto 0))) <= Ri_EX;

                elsif(Inst_WB(15 downto 12) = "0110") then -- LOAD
                    regs(conv_integer(Inst_WB(11 downto 8))) <= mem_dado(conv_integer(Inst_WB(7 downto 0)));

                elsif(Inst_WB(15 downto 12) = "1010") then -- LOAD-I
                    regs(conv_integer(Inst_WB(11 downto 8))) <= Inst_WB(7 downto 0);

                elsif(Inst_WB(15 downto 12) = "0011" or Inst_WB(15 downto 12) = "0100" or Inst_WB(15 downto 12) = "0101" or Inst_WB(15 downto 12) = "1111") then -- Desvio ou bolha

                else --TIPO R e I
                    regs(conv_integer(Inst_WB(11 downto 8))) <= ula;

                end if;

            end if;
    end process;

end behavior;


