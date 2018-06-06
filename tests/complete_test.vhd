library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

use std.textio.all;

entity complete_test_bench is
end complete_test_bench;

architecture Test of complete_test_bench is
	signal clk, rst : std_logic;

	signal if_id_test             : if_id_t;
	signal if_icache_test         : if_icache_t;
	signal icache_id_test         : icache_id_t;
	signal id_ex_test             : id_ex_t;
	signal control_id_ex          : ctrl_t;
	signal ex_mem_test            : ex_mem_t;
	signal control_ex_mem         : ctrl_t;
	signal wb_id_test             : wb_id_t;
	signal mem_wb_test            : mem_wb_t;
	signal control_mem_wb         : ctrl_t;
	signal mem_dcache_test        : mem_dcache_t;
	signal dcache_wb_test         : dcache_wb_t;
	signal startpc_test           : addr_t;
	signal ex_fwd_test            : phase_fwd_t;
	signal id_fwd_test            : id_fwd_t;
	signal fwd_id_test            : fwd_id_t;
	signal ex_id_res_test         : phase_id_res_t;
	signal mem_id_res_test        : phase_id_res_t;
	signal wb_id_res_test         : phase_id_res_t;
	signal mem_fwd_test           : phase_fwd_t;
	signal wb_fwd_test            : phase_fwd_t;
	signal stall                  : std_logic;
	signal ctrl_if_id_test        : ctrl_t;
	signal mem_predictor_test     : mem_predictor_t;
	signal mem_if_prediction_test : mem_if_prediction_t;
	signal mispred_test           : std_logic;
	signal halt                   : std_logic;
begin
	clock_driver : process
		constant period : time := 10 ns;
	begin
		clk <= '0';
		wait for period / 2;

		if halt = '1' then
			wait;
		end if;

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

	get_start_pc : process is
		file input : text is FILE_INSTR;
		variable line : line;
		variable temp : word_t;
	begin
		readline(input, line);
		hread(line, temp);
		startpc_test <= temp(15 downto 0);
		wait;
	end process get_start_pc;

	------

	brain_inst : entity work.brain
		port map(
			ex_fwd_in  => ex_fwd_test,
			mem_fwd_in => mem_fwd_test,
			wb_fwd_in  => wb_fwd_test,
			id_fwd_in  => id_fwd_test,
			fwd_id_out => fwd_id_test,
			clk        => clk,
			rst        => rst,
			stall      => stall
		);

	------

	if_phase_inst : entity work.if_phase
		port map(
			mem_if_prediction_in => mem_if_prediction_test,
			mem_predictor_in     => mem_predictor_test,
			startpc_in           => startpc_test,
			if_id_out            => if_id_test,
			if_icache_out        => if_icache_test,
			ctrl_if_id_out       => ctrl_if_id_test,
			stall                => stall,
			clk                  => clk,
			rst                  => rst
		);

	instr_cache_inst : entity work.instr_cache
		port map(
			addr_in  => if_icache_test.addr,
			data_out => icache_id_test
		);

	id_phase_inst : entity work.id_phase
		port map(
			
			mispred        => mispred_test,
			if_id_in       => if_id_test,
			icache_id_in   => icache_id_test,
			wb_id_in       => wb_id_test,
			fwd_id_in      => fwd_id_test,
			id_fwd_out     => id_fwd_test,
			ex_id_res_in   => ex_id_res_test,
			mem_id_res_in  => mem_id_res_test,
			wb_id_res_in   => wb_id_res_test,
			id_ex_out      => id_ex_test,
			ctrl_id_ex_out => control_id_ex,
			ctrl_if_id_in  => ctrl_if_id_test,
			stall          => stall,
			clk            => clk,
			rst            => rst
		);

	ex_phase_inst : entity work.ex_phase
		port map(
			mispred         => mispred_test,
			id_ex_in        => id_ex_test,
			ctrl_id_ex_in   => control_id_ex,
			ex_mem_out      => ex_mem_test,
			ctrl_ex_mem_out => control_ex_mem,
			ex_fwd_out      => ex_fwd_test,
			ex_id_res_out   => ex_id_res_test,
			clk             => clk,
			rst             => rst
		);

	mem_phase_inst : entity work.mem_phase
		port map(
						halt           => halt,
			mispred               => mispred_test,
			mem_if_prediction_out => mem_if_prediction_test,
			ex_mem_in             => ex_mem_test,
			mem_predictor_out     => mem_predictor_test,
			ctrl_ex_mem_in        => control_ex_mem,
			mem_wb_out            => mem_wb_test,
			ctrl_mem_wb_out       => control_mem_wb,
			mem_dcache_out        => mem_dcache_test,
			mem_id_res_out        => mem_id_res_test,
			mem_fwd_out           => mem_fwd_test,
			clk                   => clk,
			rst                   => rst
		);

	data_cache_inst : entity work.data_cache
		port map(
			mem_dcache_in => mem_dcache_test,
			dcache_wb_out => dcache_wb_test,
			clk           => clk
		);

	wb_phase_inst : entity work.wb_phase
		port map(
			mem_wb_in      => mem_wb_test,
			dcache_wb_in   => dcache_wb_test,
			ctrl_mem_wb_in => control_mem_wb,
			wb_id_out      => wb_id_test,
			wb_id_res_out  => wb_id_res_test,
			wb_fwd_out     => wb_fwd_test,
			clk            => clk,
			rst            => rst
		);

end architecture Test;
