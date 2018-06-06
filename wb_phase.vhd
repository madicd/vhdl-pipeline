library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity wb_phase is
	port(
		mem_wb_in      : in  mem_wb_t;
		dcache_wb_in   : in  dcache_wb_t;
		ctrl_mem_wb_in : in  ctrl_t;

		wb_id_out      : out wb_id_t;

		-- za potrebe prosledjivanja
		wb_id_res_out  : out phase_id_res_t;

		wb_fwd_out     : out phase_fwd_t;

		clk            : in  std_logic;
		rst            : in  std_logic
	);
end entity wb_phase;

architecture RTL of wb_phase is
	signal mem_wb_reg, mem_wb_next : mem_wb_t;
	signal ctrl_reg, ctrl_next     : ctrl_t;
begin
	process(clk, rst) is
	begin
		if rst = '1' then
			mem_wb_reg <= MEM_WB_RESET_VALUE;
			ctrl_reg   <= CTRL_REG_RESET_VALUE;
		elsif rising_edge(clk) then
			mem_wb_reg <= mem_wb_next;
			ctrl_reg   <= ctrl_next;
		end if;
	end process;

	mem_wb_next <= mem_wb_in;
	ctrl_next   <= ctrl_mem_wb_in;

	wb_id_out.addr <= mem_wb_reg.rd_num;
	wb_id_out.data <= dcache_wb_in.data_out when ctrl_reg.mem_op = MEM_LOAD else mem_wb_reg.result;
	wb_id_out.wr   <= ctrl_reg.reg_wb when ctrl_reg.flushed = '0' else '0';

	-- Prosledjivanje alu rezultata u ID fazu
	wb_id_res_out.result <= dcache_wb_in.data_out when ctrl_reg.mem_op = MEM_LOAD else mem_wb_reg.result;

	-- Prosledjivanje u BRAIN jedinicu
	wb_fwd_out.rd_num  <= mem_wb_reg.rd_num;
	wb_fwd_out.ready   <= '1';
	wb_fwd_out.wb      <= ctrl_reg.reg_wb;
	wb_fwd_out.flushed <= ctrl_reg.flushed;
end architecture RTL;
