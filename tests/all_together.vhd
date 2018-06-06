library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity all_together is
	port(
		if_icache_out  : out if_icache_t;
		icache_id_in   : in  icache_id_t;

		mem_dcache_out : out mem_dcache_t;
		dcache_wb_in   : in  dcache_wb_t;

		halt           : out std_logic;
		clk            : in  std_logic;
		rst            : in  std_logic
	);
end entity all_together;

architecture RTL of all_together is
	signal startpc_in             : addr_t;
	signal stall                  : std_logic;
	signal mem_predictor_test     : mem_predictor_t;
	signal mem_if_prediction_test : mem_if_prediction_t;
	signal if_id_test             : if_id_t;
	signal ctrl_if_id_test        : ctrl_t;
	signal wb_id_test             : wb_id_t;
	signal fwd_id_test            : fwd_id_t;
	signal id_fwd_test            : id_fwd_t;
	signal ex_id_res_test         : phase_id_res_t;
	signal mem_id_res_test        : phase_id_res_t;
	signal wb_id_res_test         : phase_id_res_t;
	signal id_ex_test             : id_ex_t;
	signal ctrl_id_ex_test        : ctrl_t;
	signal mispred                : std_logic;
	signal ex_mem_test            : ex_mem_t;
	signal ctrl_ex_mem_test       : ctrl_t;
	signal ex_fwd_test            : phase_fwd_t;
	signal mem_wb_test            : mem_wb_t;
	signal ctrl_mem_wb_test       : ctrl_t;
	signal mem_fwd_test           : phase_fwd_t;
	signal wb_fwd_test            : phase_fwd_t;

begin
	if_phase_inst : entity work.if_phase
		port map(
			startpc_in           => startpc_in,
			mem_predictor_in     => mem_predictor_test,
			mem_if_prediction_in => mem_if_prediction_test,
			if_id_out            => if_id_test,
			if_icache_out        => if_icache_out,
			ctrl_if_id_out       => ctrl_if_id_test,
			stall                => stall,
			clk                  => clk,
			rst                  => rst
		);

	id_phase_inst : entity work.id_phase
		port map(
			if_id_in       => if_id_test,
			icache_id_in   => icache_id_in,
			wb_id_in       => wb_id_test,
			ctrl_if_id_in  => ctrl_if_id_test,
			fwd_id_in      => fwd_id_test,
			id_fwd_out     => id_fwd_test,
			ex_id_res_in   => ex_id_res_test,
			mem_id_res_in  => mem_id_res_test,
			wb_id_res_in   => wb_id_res_test,
			id_ex_out      => id_ex_test,
			ctrl_id_ex_out => ctrl_id_ex_test,
			mispred        => mispred,
			stall          => stall,
			clk            => clk,
			rst            => rst
		);

	ex_phase_inst : entity work.ex_phase
		port map(
			id_ex_in        => id_ex_test,
			ctrl_id_ex_in   => ctrl_id_ex_test,
			ex_mem_out      => ex_mem_test,
			ctrl_ex_mem_out => ctrl_ex_mem_test,
			ex_fwd_out      => ex_fwd_test,
			ex_id_res_out   => ex_id_res_test,
			halt            => halt,
			mispred         => mispred,
			clk             => clk,
			rst             => rst
		);

	mem_phase_inst : entity work.mem_phase
		port map(
			ex_mem_in             => ex_mem_test,
			ctrl_ex_mem_in        => ctrl_ex_mem_test,
			mem_wb_out            => mem_wb_test,
			ctrl_mem_wb_out       => ctrl_mem_wb_test,
			mem_dcache_out        => mem_dcache_out,
			mem_id_res_out        => mem_id_res_test,
			mem_fwd_out           => mem_fwd_test,
			mem_predictor_out     => mem_predictor_test,
			mem_if_prediction_out => mem_if_prediction_test,
			mispred               => mispred,
			clk                   => clk,
			rst                   => rst
		);

	wb_phase_inst : entity work.wb_phase
		port map(
			mem_wb_in      => mem_wb_test,
			dcache_wb_in   => dcache_wb_in,
			ctrl_mem_wb_in => ctrl_mem_wb_test,
			wb_id_out      => wb_id_test,
			wb_id_res_out  => wb_id_res_test,
			wb_fwd_out     => wb_fwd_test,
			clk            => clk,
			rst            => rst
		);

	brain_inst : entity work.brain
		port map(
			clk        => clk,
			rst        => rst,
			ex_fwd_in  => ex_fwd_test,
			mem_fwd_in => mem_fwd_test,
			wb_fwd_in  => wb_fwd_test,
			id_fwd_in  => id_fwd_test,
			fwd_id_out => fwd_id_test,
			stall      => stall
		);
end architecture RTL;
