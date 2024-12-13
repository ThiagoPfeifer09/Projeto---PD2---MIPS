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
end entity;

architecture behavior of Proj_Pipeline is
    type memoria_dados is array (integer range 0 to 255) of std_logic_vector(7 downto 0);
    type memoria_instrucao is array (integer range 0 to 255) of std_logic_vector(15 downto 0);
    type banco_regs is array (integer range 0 to 15) of std_logic_vector(7 downto 0);

    signal PC	                                 : std_logic_vector(7 downto 0); 
    signal regs                                  : banco_regs := (others => (others => '0'));
    signal desvio	                             : std_logic; 
    signal mul, muli                             : std_logic_vector(15 downto 0); 
    signal ula                                   : std_logic_vector(7 downto 0); 
    signal equal	                             : std_logic;
    signal R1                                    : std_logic_vector(7 downto 0);
    signal R2                                    : std_logic_vector(7 downto 0);
    signal Ri_ID, Ri_EX, Ri_WB                   : std_logic_vector(7 downto 0); 
    signal PC_ID, PC_EX, PC_MEM, PC_WB           : std_logic_vector(7 downto 0); 
    signal inst_ID, inst_EX, inst_MEM, inst_WB   : std_logic_vector(15 downto 0);     
    
    signal mem_inst  	        : memoria_instrucao:= (	
		0 => "1010000100000110",
		1 => "1010001000000100",
		2 => "1111111111111111",
		3 => "1111111111111111",
		4 => "1111111111111111",
		5 => "0000001100010010",
		6 => "0001010000010010",
		7 => "1011010100100010",
	    others => (others => '1') -- Demais posições zeradas
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



