library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Proj_Pipeline is
	port (
		clock	    : in std_logic;
		reset	    : in std_logic
		);
end entity;

architecture behavior of Proj_Pipeline is
    type memoria_dados is array (integer range 0 to 255) of std_logic_vector(7 downto 0);
    type memoria_instrucao is array (integer range 0 to 255) of std_logic_vector(15 downto 0);
    type banco_regs is array (integer range 0 to 15) of std_logic_vector(7 downto 0);

    signal PC	                                         : std_logic_vector(7 downto 0); 
    signal regs                                          : banco_regs := (others => (others => '0'));
    signal desvio	                                     : std_logic; 
    signal mul, muli                                     : std_logic_vector(15 downto 0); 
    signal ula                                           : std_logic_vector(7 downto 0); 
    signal equal	                                     : std_logic;
    signal R1                                            : std_logic_vector(7 downto 0);
    signal R2                                            : std_logic_vector(7 downto 0);
    signal Ri_ID, Ri_EX, Ri_WB                           : std_logic_vector(7 downto 0); 
    signal PC_ID, PC_EX, PC_MEM, PC_WB                   : std_logic_vector(7 downto 0); 
    signal inst_ID, inst_EX, inst_MEM, inst_WB           : std_logic_vector(15 downto 0);     
    
    signal mem_inst  	        : memoria_instrucao:= (
        0  => "0011000000001010", -- BNE R1 != R2 FALSO
        1  => "0110000000000001", -- LDA endereço 1 para R1 (Valor 1)
        2  => "0110000100000010", -- LDA endereço 2 para R2 (Valor 3)
        3  => "1010100000000111", -- LWI Valor 7 no registrador 8
        4  => "1111111111111111", -- Bolha artificial
        5  => "1111111111111111", -- Bolha artificial
        6  => "0100000000011111", -- BEQ R1 = R2 VAI DAR FALSO
        7  => "0000001000000001", -- ADD R1 + R2 -> R2 => (Valor 4) // hazard de dependência de dados!!
        8  => "1111111111111111", -- Bolha artificial
        9  => "1111111111111111", -- Bolha artificial
        10 => "1000001100100101", -- ADDI R2 + 5 -> R3 => (Valor 9)
        11 => "1111111111111111", -- Bolha artificial
        12 => "1111111111111111", -- Bolha artificial
        13 => "0010010000100011", -- MUL R3 * R2 no R4 (Valor 36)
        14 => "1011010100010101", -- MUI R2 * 5 no R5 (Valor 15)
        15 => "0111001000000100", -- STA R2 no endereço 4 (Valor 4)
        16 => "0011001000010010", -- BNE R2 != R2 SALTO PC+2 => PC 21
        17 => "0111001100000101", -- STA R3 no endereço 5 (Valor 9)
        18 => "0010100000100011", -- MUL R3 * R2 no R8 (Valor 36)
        19 => "1011101000010101", -- MUI R2 * 5 no R20 (Valor 15)
        20 => "1111111111111111", -- Bolha artificial
        21 => "0001011000110010", -- SUB R3 - R2 -> R6 (Valor 5)
        22 => "1001011100100001", -- SUI R2 - 1 -> R7 (Valor 3)
        23 => "0111010000000100", -- STA R4 no endereço 4 (Valor 36)
        24 => "0101000000000001", -- JMP para endereço 1
        25 => "1111111111111111", -- Bolha artificial
        26 => "1111111111111111", -- Bolha artificial
        27 => "1111111111111111", -- Bolha artificial
        others => (others => '1') -- Demais posiçoe zeradas
    );

    signal mem_dados	            : memoria_dados := ( 
        0 => "00000000",
        1 => "00000001", --1
        2 => "00000011", --3
        others => (others => '0') 
    ); 

   

begin 
           
     equal <= '1' when (R1 = Ri_EX) else
          '0';

     desvio <= '1' when (inst_MEM(15 downto 12) = "0011" and equal = '0') or (inst_MEM(15 downto 12) = "0100" and equal = '1') else
          '0';

      muli <= R1 * (("0000") & inst_MEM(3 downto 0));
      mul  <= R1 * R2;

      
process(reset, clock)
    begin
----------------------SE O RESET ESTÁ ATIVO ZERA TODOS OS REGISTRADORES
	       if (reset = '1') then 
	           regs    <= (others => (others => '0'));
	           PC      <= (others => '0');
	           PC_ID <= (others => '0');
	           PC_EX <= (others => '0');
	           PC_MEM <= (others => '0');
	           PC_WB<= (others => '0');
	           inst_ID   <= (others => '0');
	           inst_EX   <= (others => '0');
	           inst_MEM  <= (others => '0');
	           inst_WB  <= (others => '0');
	           ula <= (others => '0');
	           R1     <= (others => '0');
	           R2     <= (others => '0');
	           Ri_ID  <= (others => '0');
	           Ri_EX  <= (others => '0');
	           Ri_WB  <= (others => '0');
	
	       elsif (clock = '1' and clock'event) then
	       
------------------------------------PASSAGEM DA INSTRUÇÃO E DO PC
	           inst_ID  <= mem_inst(conv_integer(PC))(15 downto 0);
	           inst_EX  <= inst_ID;
	           inst_MEM <= inst_EX;
	           inst_WB  <= inst_MEM;
	
	           PC_ID  <= PC;
	           PC_EX  <= PC_ID;
	           PC_MEM <= PC_EX;
	           PC_WB  <= PC_MEM;
	
--------------------------DECODIFICAÇÃO DA INSTRUÇÃO PEGA OS REGS 

	     if (inst_EX(15 downto 12) = "0000" or inst_EX(15 downto 12) = "0001" or inst_EX(15 downto 12) = "0010") then
	            R1 <= regs(conv_integer(inst_EX(7 downto 4)));
	            R2 <= regs(conv_integer(inst_EX(3 downto 0)));
	
	     else --Imediatos e BEQ/BNE
	            R1      <= regs(conv_integer(inst_EX(7 downto 4)));
	            Ri_ID   <= regs(conv_integer(inst_EX(11 downto 8)));
	     end if;
	     
----------------------------------DESVIO QUE OCORRE  
	    
		 if (desvio = '1') then
	        if (inst_MEM(15 downto 12) = "0011" or inst_MEM(15 downto 12) = "0100") then
	            PC <= PC + inst_MEM(3 downto 0); -- BEQ/BNE
	           	
	           elsif (inst_MEM(15 downto 12) = "0101") then
	               PC <= inst_MEM(7 downto 0); -- JMP    
	          end if;
		 else
	           PC <= PC + 1;
	     end if;
		
--------------------------EXECUÇÃO DAS OPERAÇÕES DA ULA
	    
		 Ri_EX <= Ri_ID;
	     case inst_MEM(15 downto 12) is
	                   when "0000" => ula <= R1 + R2; -- FAZ O ADD
	                   when "0001" => ula <= R1 - R2;-- FAZ O SUBT
	                   when "0010" => ula <= mul(7 downto 0);
	                   when "1000" => ula <= R1 + inst_MEM(3 downto 0);
	                   when "1001" => ula <= R1 - inst_MEM(3 downto 0);
	                   when "1011" => ula <= muli(7 downto 0);
	                   when others =>
	                   end case;
	         	                   
-------------------ULTIMO ESTÁGIO ACESSO A MEMORIA E WRITEBACK

		 Ri_WB <= Ri_EX;
		 case inst_WB(15 downto 12) is
		    when "0111" =>  -- STORE
		        mem_dados(conv_integer(inst_WB(7 downto 0))) <= Ri_EX;
		
		    when "0110" =>  -- LOAD
		        regs(conv_integer(inst_WB(11 downto 8))) <= mem_dados(conv_integer(inst_WB(7 downto 0)));
			
		    when "1010" =>  -- LOAD-I
		        regs(conv_integer(inst_WB(11 downto 8))) <= inst_WB(7 downto 0);
			
		    when "0011" | "0100" | "0101" | "1111" =>  -- DESVIO OU BOLHA
			        -- NÃO HAVERÁ NADA NESSA ETAPA AQUI
			
		    when others =>  -- TIPO R e I
		        regs(conv_integer(inst_WB(11 downto 8))) <= ula;
		 end case;
        	
        end if;
    end process;
end behavior;



