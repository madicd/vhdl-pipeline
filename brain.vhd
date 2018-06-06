library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity brain is
	port(
		clk, rst   : in  std_logic;

		ex_fwd_in  : in  phase_fwd_t;
		mem_fwd_in : in  phase_fwd_t;
		wb_fwd_in  : in  phase_fwd_t;

		id_fwd_in  : in  id_fwd_t;

		fwd_id_out : out fwd_id_t;

		stall      : out std_logic
	);
end entity brain;

architecture RTL of brain is
	signal pb_ex_brain  : pb_t;
	signal pb_mem_brain : pb_t;
	signal pb_wb_brain  : pb_t;

	signal stall_reg, stall_next : std_logic;
begin
	stall_next <= rst;
	
	process(clk, rst) is
	begin
		if rst = '1' then
			stall_reg <= '1';
		elsif rising_edge(clk) then
			stall_reg <= stall_next;
		end if;
	end process;

	ex_brain : entity work.phase_brain
		port map(
			id_fwd_in    => id_fwd_in,
			phase_fwd_in => ex_fwd_in,
			pb_out       => pb_ex_brain
		);

	mem_brain : entity work.phase_brain
		port map(
			id_fwd_in    => id_fwd_in,
			phase_fwd_in => mem_fwd_in,
			pb_out       => pb_mem_brain
		);

	phase_brain_inst : entity work.phase_brain
		port map(
			id_fwd_in    => id_fwd_in,
			phase_fwd_in => wb_fwd_in,
			pb_out       => pb_wb_brain
		);

	main : process(pb_ex_brain.rs1_hit, pb_ex_brain.rs2_hit, pb_mem_brain.rs1_hit, pb_mem_brain.rs2_hit, pb_wb_brain.rs1_hit, pb_wb_brain.rs2_hit, pb_ex_brain.stall, pb_mem_brain.stall, pb_wb_brain.stall, stall_reg) is
		alias stall_ex is pb_ex_brain.stall;
		alias stall_mem is pb_mem_brain.stall;
		alias stall_wb is pb_wb_brain.stall;
	begin
		fwd_id_out.rs1_fwd_src <= FWD_SRC_NONE;
		fwd_id_out.rs2_fwd_src <= FWD_SRC_NONE;

		if pb_wb_brain.rs1_hit = '1' then
			fwd_id_out.rs1_fwd_src <= FWD_SRC_WB;
		end if;
		if pb_mem_brain.rs1_hit = '1' then
			fwd_id_out.rs1_fwd_src <= FWD_SRC_MEM;
		end if;
		if pb_ex_brain.rs1_hit = '1' then
			fwd_id_out.rs1_fwd_src <= FWD_SRC_EX;
		end if;

		if pb_wb_brain.rs2_hit = '1' then
			fwd_id_out.rs2_fwd_src <= FWD_SRC_WB;
		end if;
		if pb_mem_brain.rs2_hit = '1' then
			fwd_id_out.rs2_fwd_src <= FWD_SRC_MEM;
		end if;
		if pb_ex_brain.rs2_hit = '1' then
			fwd_id_out.rs2_fwd_src <= FWD_SRC_EX;
		end if;

		stall <= stall_reg OR stall_ex OR stall_mem OR stall_wb;
	end process main;

end architecture RTL;
