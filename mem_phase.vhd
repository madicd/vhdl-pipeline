library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity mem_phase is
	port(
		ex_mem_in             : in  ex_mem_t;
		ctrl_ex_mem_in        : in  ctrl_t;

		mem_wb_out            : out mem_wb_t;
		ctrl_mem_wb_out       : out ctrl_t;

		mem_dcache_out        : out mem_dcache_t;

		-- za potrebe prosledjivanja
		mem_id_res_out        : out phase_id_res_t;

		mem_fwd_out           : out phase_fwd_t;

		-- za potrebe prediktora
		mem_predictor_out     : out mem_predictor_t;
		mem_if_prediction_out : out mem_if_prediction_t;

		halt : out std_logic;
		mispred               : out std_logic;
		clk                   : in  std_logic;
		rst                   : in  std_logic
	);
end entity mem_phase;

architecture RTL of mem_phase is
	signal ex_mem_reg, ex_mem_next : ex_mem_t;
	signal ctrl_reg, ctrl_next     : ctrl_t;

	alias cache is mem_dcache_out;

	signal st_push        : std_logic;
	signal st_input_data  : word_t;
	signal st_pop         : std_logic;
	signal st_output_data : word_t;
begin
	process(clk, rst) is
	begin
		if rst = '1' then
			ex_mem_reg <= EX_MEM_RESET_VALUE;
			ctrl_reg   <= CTRL_REG_RESET_VALUE;
		elsif rising_edge(clk) then
			ex_mem_reg <= ex_mem_next;
			ctrl_reg   <= ctrl_next;
		end if;
	end process;

	ex_mem_next <= ex_mem_in;
	ctrl_next   <= ctrl_ex_mem_in;

	-- Pristupanje kes memoriji
	process(ex_mem_reg.alu_result, ex_mem_reg.rs2, ctrl_reg.mem_op, ctrl_reg.flushed) is
		alias operation is ctrl_reg.mem_op;
	begin
		cache.addr_in <= ex_mem_reg.alu_result(15 downto 0);
		cache.data_in <= ex_mem_reg.rs2;
		cache.wr      <= '0';
		if operation = MEM_STORE AND ctrl_reg.flushed = '0' then
			cache.wr <= '1';
		end if;
	end process;

	-- Proces za obradu mispred signala
	process(ctrl_reg.branch_taken, ctrl_reg.is_branch, ctrl_reg.mispred, ex_mem_reg.alu_result(15 downto 0), ex_mem_reg.pc, ex_mem_reg.real_branch_destination, ctrl_reg.flushed, ex_mem_reg.pc_next, ctrl_reg.is_rts, st_output_data) is
	begin

		-- TODO: Sredi ovo da ne radi nista ako je stall
		-- DONE

		-- Ako je is_branch aktivan tada ce da menja branch predictor
		-- Ako je trenutna instrukcija flushed mi to ne zelimo tako da cemo da ga resetujemo
		if ctrl_reg.flushed then
			mem_predictor_out.is_branch   <= '0';
			mispred                       <= '0';
			mem_if_prediction_out.mispred <= '0';
		else
			mem_predictor_out.is_branch   <= ctrl_reg.is_branch;
			mem_if_prediction_out.mispred <= ctrl_reg.mispred OR ctrl_reg.is_rts;
			mispred                       <= ctrl_reg.mispred OR ctrl_reg.is_rts;
		end if;

		mem_predictor_out.pc                 <= ex_mem_reg.pc;
		mem_predictor_out.branch_destination <= ex_mem_reg.alu_result(15 downto 0);

		mem_predictor_out.branch_taken <= ctrl_reg.branch_taken;

		if ctrl_reg.is_rts then
			mem_if_prediction_out.pc_update <= st_output_data(15 downto 0);
		elsif ctrl_reg.branch_taken then
			mem_if_prediction_out.pc_update <= ex_mem_reg.real_branch_destination;
		else
			mem_if_prediction_out.pc_update <= ex_mem_reg.pc_next;
		end if;
		
	end process;

	-- Prosledjivanje podataka WB fazi
	ctrl_mem_wb_out   <= ctrl_reg;
	mem_wb_out.result <= ex_mem_reg.alu_result when ctrl_reg.stack_op /= STACK_POP else st_output_data;
	mem_wb_out.rd_num <= ex_mem_reg.rd_num;

	-- Prosledjivanje alu rezultata ID fazi, dodato je i prosledjivanje stack_pop-a
	mem_id_res_out.result <= ex_mem_reg.alu_result when ctrl_reg.stack_op /= STACK_POP else st_output_data;

	-- Prosledjivanje podataka BRAIN jedinici
	mem_fwd_out.rd_num  <= ex_mem_reg.rd_num;
	mem_fwd_out.ready   <= '1' when (ctrl_reg.mem_op /= MEM_LOAD) else '0';
	mem_fwd_out.wb      <= ctrl_reg.reg_wb;
	mem_fwd_out.flushed <= ctrl_reg.flushed;

	st_push <= '1' when ctrl_reg.stack_op = STACK_PUSH else '0';
	st_pop  <= '1' when ctrl_reg.stack_op = STACK_POP else '0';

	-- TODO: promeni ovo da bude alu_result ako je push a pc_next ako je JSR
	-- DONE
	-- st_input_data <= (15 downto 0 => ex_mem_reg.pc_next, others => '0') when ctrl_reg.is_jsr else ex_mem_reg.alu_result;
	
	process(ctrl_reg.is_jsr, ex_mem_reg.pc_next, ex_mem_reg.alu_result) is
	begin
		st_input_data <= ZERO_WORD;
		
		if ctrl_reg.is_jsr then
			st_input_data(15 downto 0) <= ex_mem_reg.pc_next;
		else
			st_input_data <= ex_mem_reg.alu_result;
		end if;
	end process;

	-- Rad sa stekom
	stack_inst : entity work.stack
		port map(
			push        => st_push,
			input_data  => st_input_data,
			pop         => st_pop,
			output_data => st_output_data,
			clk         => clk,
			rst         => rst
		);
		
	halt <= ctrl_reg.halt_detected AND not ctrl_reg.flushed;
end architecture RTL;

