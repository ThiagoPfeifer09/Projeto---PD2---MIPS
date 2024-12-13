library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity proj is
	port (
		clock	    : in std_logic;
		reset	    : in std_logic;
		R1_out      : out std_logic_vector(7 downto 0);
		R2_out      : out std_logic_vector(7 downto 0)
		);
end proj;

architecture behavior of proj is

    type memo_dados is array (integer range 0 to 255) of std_logic_vector(7 downto 0);
    type mem_instrucao is array (integer range 0 to 255) of std_logic_vector(15 downto 0);
    type banco_regs is array (integer range 0 to 15) of std_logic_vector(7 downto 0);
 	signal regs         : banco_regs := (others => (others => '0')); 
    signal PC	        : std_logic_vector(7 downto 0);
    signal desvio	    : std_logic; 
    signal mul		    : std_logic_vector(15 downto 0);
    signal muli		    : std_logic_vector(15 downto 0);
    signal equal	    : std_logic; 
    signal R1, R2, Rim  : std_logic_vector(7 downto 0);
    signal ula, add, addi, subt,subi : std_logic_vector(7 downto 0);
    signal pulo_brench  : std_logic_vector(3 downto 0);
    
    signal mem_inst    	        : mem_instrucao:= (
        0  => "1010001000001111",  --LWI no reg 2 o 15 
        1  => "0110001100000010",  --LW da pos 2 da mem no reg 3
        2  => "1000000100000001",  --ADDI no reg 1 R0+1
        3  => "0000010000100000",  --ADD no R4 R2+0
        4  => "0100010000100000",  --BEQ R0=R2 e pula 4
        5  => "0001010001000011",  --SUBI no R4 o R4-R3
        6  => "0000010101010001",  --ADDi no R5 R5+R1
        7  => "0101000000000100",  --JMP para inst 4(BEQ)
        8  => "0111010100000100",  --SW do R5 na pos 4 GUARDA O RESULTADO
        9  => "0010100000110101",  --MULT R3 e R5 e guarda em R8
        10 => "0111100000001000",  --Sw do resultado da mult na pos 8 da mem
        others => (others => '1') 
    );

    signal mem_dado	: memo_dados := (
        0 => "00000000",
        1 => "00000000",
        2 => "00000101", --5
        others => (others => '0') 
    );
    
begin 
    
	R1_out <= R1;
	R2_out <= R2;
--ALOCA OS REGS DA SAÍDA DO BANCO DE REGISTRADORES EM R1 E R2 E O OPERADOR IMEDIATO---------------------------------

    R1 <= regs(conv_integer(mem_inst(conv_integer(PC))(7 downto 4)));

    R2 <= regs(conv_integer(mem_inst(conv_integer(PC))(3 downto 0)));
    
    Rim <= (("0000") & mem_inst(conv_integer(PC))(3 downto 0));
    
--VERIFICA ESTÁ IGUAL OU NÃO, PODE SER USADO SE IGUAL OU SE DIFERENTE BEQ OU BNE -----------------------------------
    equal <= '1' when (R1 = R2) else
        '0';

--MOSTRA SE VAI TER ALGUM DESVIO NO PC OU NÃO ----------------------------------------------------------------------
    desvio <= '1' when (mem_inst(conv_integer(PC))(15 downto 12) = "0101" and equal = '0') or (mem_inst(conv_integer(PC))(15 downto 12) = "0100" and equal = '1') or (mem_inst(conv_integer(PC))(15 downto 12) = "0101" and equal = '0') else
        '0';
  
    pulo_brench <= mem_inst(conv_integer(PC))(11 downto 8);
--OPERAÇÕES SÃO FEITAS AQUI----------------------------------------------------------------------------------------
    mul  <= R1 * R2;
    muli <= R1 * Rim;
    add  <= R1 + R2;
    addi <= R1 + Rim;
    subt <= R1 - R2;
    subi <= R1 - Rim;

--ULA QUE SERÁ A ENTRADA PARA A ESCRITA NO BANCO DE REGISTRADORES --------------------------------------------------        
    ula <= add when mem_inst(conv_integer(PC))(15 downto 12) = "0000" else 
    	subt when mem_inst(conv_integer(PC))(15 downto 12) = "0001" else
    	addi when mem_inst(conv_integer(PC))(15 downto 12) = "1000" else
    	subi when mem_inst(conv_integer(PC))(15 downto 12) = "1001" else
    	muli(7 downto 0) when mem_inst(conv_integer(PC))(15 downto 12) = "1011" else
    	mul(7 downto 0);
 	


    process(reset, clock)
     begin
     --
       if (reset = '1') then 
           regs    <= (others => (others => '0'));
           PC      <= (others => '0');

       elsif (clock = '1' and clock'event) then
       --DECODER BASEADO NO OPCODE DE CADA INSTRUÇÃO QUE NÃO SEJA DE DESVIO DO PC
           case mem_inst(conv_integer(PC))(15 downto 12) is --
           
               when "0000" => regs(conv_integer(mem_inst(conv_integer(PC))(11 downto 8))) <= ula; --ADD

               when "0001" => regs(conv_integer(mem_inst(conv_integer(PC))(11 downto 8))) <= ula;--SUB
                   
               when "0010" => regs(conv_integer(mem_inst(conv_integer(PC))(11 downto 8))) <= ula; --MULTI
               
               when "0110" => regs(conv_integer(mem_inst(conv_integer(PC))(11 downto 8))) <= mem_dado(conv_integer(mem_inst(conv_integer(PC))(7 downto 0)));--LW
              
               when "0111" =>  mem_dado(conv_integer(mem_inst(conv_integer(PC))(7 downto 0))) <= regs(conv_integer(mem_inst(conv_integer(PC))(11 downto 8)));--SW
               
               when "1000" => regs(conv_integer(mem_inst(conv_integer(PC))(11 downto 8))) <= ula;--ADDI

               when "1001" => regs(conv_integer(mem_inst(conv_integer(PC))(11 downto 8))) <= ula;--SUBI
           
               when "1010" => regs(conv_integer(mem_inst(conv_integer(PC))(11 downto 8))) <= mem_inst(conv_integer(PC))(7 downto 0); --LDI
               
               when "1011" => regs(conv_integer(mem_inst(conv_integer(PC))(11 downto 8))) <= ula;--MULI
                   
               when others => --NÃO FAZ NADA CASO NÃO HAJA MAIS OPERAÇÕES A SEREM FEITAS          
        end case;

        --CASO A FLAG DE DESVIO ESTEJA DESATIVADA, IRÁ OCORRER SOMENTE A SOMA NORMAL DO PC, 
           if (desvio = '0') then 
               PC <= PC + 1;

        --SE ANTERIORMENTE, FOI LEVANTADA A FLAG DE DESVIO, SERÁ USADO AQUI, JÁ SABENDO QUE VAI HAVER O DESVIO
           else 
               if (mem_inst(conv_integer(PC))(15 downto 12) = "0100" or mem_inst(conv_integer(PC))(15 downto 12) = "0011") then --
                   PC <= PC + pulo_brench;
               
               elsif (mem_inst(conv_integer(PC))(15 downto 12) = "0101") then
                   PC <= mem_inst(conv_integer(PC))(7 downto 0);

              end if; --IF PARA SABER QUAL DESVIO ? TOMADO
           end if; --IF DO DESVIO
   end if; --IF DO CLOCK
end process;
end behavior;