-- Libraries definitions
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_proj is
end entity;

architecture behaviour of tb_proj is


    component proj is
        port(
            clock       : in std_logic;
            reset       : in std_logic;
            R1_out      : out std_logic_vector(7 downto 0);
			R2_out      : out std_logic_vector(7 downto 0)
        );
    end component;


    signal reset_sg       : std_logic := '1'; 
    signal clock_sg       : std_logic := '0'; 
    signal R1_out_sg      : std_logic_vector(7 downto 0);
	signal R2_out_sg      : std_logic_vector(7 downto 0);

begin

    inst_proj : proj
        port map (
            clock     => clock_sg,
            reset     => reset_sg,
            R1_out => R1_out_sg,
            R2_out => R2_out_sg
        );

    
    clock_sg <= not clock_sg after 3 ns;

    
    process
    begin
      
        wait for 2 ns;
        reset_sg <= '0';  -- Desativa o reset

        wait for 7 ns;
       
        wait for 9 ns;

        wait for 9 ns;

        wait;
    end process;

end behaviour;
