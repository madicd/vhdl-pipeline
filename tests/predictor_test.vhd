library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity predictor_test_bench is
end predictor_test_bench;

architecture Test of predictor_test_bench is
	signal clk : std_logic;
	signal rst : std_logic;
	signal mem_predictor_in : mem_predictor_t;
	signal if_predictor_in : if_predictor_t;
	signal predictor_if_out : predictor_if_t;
begin
	
	clock_driver : process
		constant period : time := 10 ns;
	begin
		clk <= '0';
		wait for period / 2;
		clk <= '1';
		wait for period / 2;
	end process clock_driver;
	
	reset_generator : process is
	begin
		rst <= '1';
		wait for 30 ns;
		rst <= '0';
		wait;
	end process reset_generator;
	
	predictor_inst : entity work.predictor
		port map(
			if_predictor_in  => if_predictor_in,
			mem_predictor_in => mem_predictor_in,
			predictor_if_out => predictor_if_out,
			clk              => clk,
			rst              => rst
		);
	
	main : process is
	begin
		if_predictor_in.pc <= x"1500";
		
		mem_predictor_in.pc <= x"1000";
		mem_predictor_in.branch_destination <= x"4000";
		mem_predictor_in.branch_taken <= '0';
		
		wait until falling_edge(rst);
		
		wait until rising_edge(clk);
		
		if_predictor_in.pc <= x"1500";
		
		mem_predictor_in.pc <= x"2000";
		mem_predictor_in.branch_destination <= x"5000";
		mem_predictor_in.branch_taken <= '0';
		
		wait until rising_edge(clk);
		
		if_predictor_in.pc <= x"1000";
		
		mem_predictor_in.pc <= x"3000";
		mem_predictor_in.branch_destination <= x"7000";
		mem_predictor_in.branch_taken <= '0';
		
		wait;
	end process main;
	
end architecture Test;
