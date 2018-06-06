library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity ex_phase is
	port(
		id_ex_in        : in  id_ex_t;
		ctrl_id_ex_in   : in  ctrl_t;

		ex_mem_out      : out ex_mem_t;
		ctrl_ex_mem_out : out ctrl_t;

		-- za potrebe prosledjivanja
		ex_fwd_out      : out phase_fwd_t;

		ex_id_res_out   : out phase_id_res_t;

		mispred         : in  std_logic;
		clk             : in  std_logic;
		rst             : in  std_logic
	);
end entity ex_phase;

architecture RTL of ex_phase is
	signal id_ex_next, id_ex_reg : id_ex_t;
	signal ctrl_reg, ctrl_next   : ctrl_t;

	signal alu_A, alu_B, alu_RESULT : word_t;
	signal should_take_branch       : std_logic;

	signal is_prediction_ok : std_logic;

	signal real_branch_destination : addr_t;

	signal resized_pc_next : word_t;
begin
	process(clk, rst) is
	begin
		if (rst = '1') then
			id_ex_reg <= ID_EX_RESET_VALUE;
			ctrl_reg  <= CTRL_REG_RESET_VALUE;
		elsif rising_edge(clk) then
			id_ex_reg <= id_ex_next;

			ctrl_reg <= ctrl_next;
		end if;
	end process;

	-- Izracunava ispunjenost uslova za skok
	comparator_inst : entity work.comparator
		generic map(
			size => WORD_SIZE
		)
		port map(
			a  => id_ex_reg.rs1,
			b  => id_ex_reg.rs2,
			op => ctrl_reg.cmp_op,
			ok => should_take_branch
		);

	id_ex_next <= id_ex_in;
	ctrl_next  <= ctrl_id_ex_in;
	
	resized_pc_next <= word_t(resize(unsigned(id_ex_reg.pc_next), WORD_SIZE));

	-- Prvi operand za ALU
	assign_alu_A : with ctrl_reg.src_op1 select alu_A <=
		id_ex_reg.rs1 when SRC_RS1,
		id_ex_reg.rs2 when SRC_RS2,
		id_ex_reg.immed when SRC_IMMED,
		resized_pc_next when SRC_PC_NEXT,
		(others => '0') when others;

	-- Drugi operand za ALU
	assign_alu_B : with ctrl_reg.src_op2 select alu_B <=
		id_ex_reg.rs1 when SRC_RS1,
		id_ex_reg.rs2 when SRC_RS2,
		id_ex_reg.immed when SRC_IMMED,
		resized_pc_next when SRC_PC_NEXT,
		(others => '0') when others;

	main : process(alu_A, alu_B, ctrl_reg.alu_op) is
	begin

		-- inicijalno
		alu_RESULT <= ZERO_WORD;

		case ctrl_reg.alu_op is
			when ALU_ADD =>
				alu_RESULT <= std_logic_vector(to_unsigned((to_integer(unsigned(alu_A)) + to_integer(unsigned(alu_B))), WORD_SIZE));
			when ALU_SUB =>
				alu_RESULT <= std_logic_vector(to_unsigned((to_integer(unsigned(alu_A)) - to_integer(unsigned(alu_B))), WORD_SIZE));
			when ALU_AND =>
				alu_RESULT <= alu_A AND alu_B;
			when ALU_OR =>
				alu_RESULT <= alu_A OR alu_B;
			when ALU_XOR =>
				alu_RESULT <= alu_A XOR alu_B;
			when ALU_NOT =>
				alu_RESULT <= NOT alu_A;
			when ALU_SHL =>
				-- alu_RESULT <= alu_A sll to_integer(unsigned(alu_B));
				alu_RESULT <= word_t(SHIFT_LEFT(unsigned(alu_A), to_integer(unsigned(alu_B))));
			when ALU_SHR =>
				alu_RESULT <= word_t(SHIFT_RIGHT(unsigned(alu_A), to_integer(unsigned(alu_B))));
			when ALU_SAR =>
				alu_RESULT <= word_t(SHIFT_RIGHT(signed(alu_A), to_integer(unsigned(alu_B))));
			when ALU_ROL =>
				alu_RESULT <= word_t(ROTATE_LEFT(unsigned(alu_A), to_integer(unsigned(alu_B))));
			when ALU_ROR =>
				alu_RESULT <= word_t(ROTATE_RIGHT(unsigned(alu_A), to_integer(unsigned(alu_B))));
			when ALU_MOVI =>
				alu_RESULT <= alu_A(31 downto 16) & alu_B(15 downto 0);
		end case;

	end process main;

	-- Poredi se prediktovana i prava destinacija skoka
	pc_comparator : entity work.comparator
		generic map(
			size => ADDR_SIZE
		)
		port map(
			a  => real_branch_destination,
			b  => id_ex_reg.pc_predicted,
			op => CMP_EQ,
			ok => is_prediction_ok
		);

	branch_destination_calculator : process(alu_RESULT, should_take_branch, id_ex_in.pc_next) is
	begin
		real_branch_destination <= id_ex_in.pc_next;

		if should_take_branch then
			real_branch_destination <= alu_RESULT(15 downto 0);
		end if;
	end process branch_destination_calculator;

	misprediction : process(ctrl_reg, is_prediction_ok, should_take_branch, mispred) is
	begin
		-- ako je u pitanju instrukcija skoka
		-- ako je cmp_result ok, ispunjen je uslov za skok
		-- ako je vec skoceno to znaci da smo okej predvideli
		-- ako nije skoceno greska, mispred signal verovatno

		-- u sustini vidimo sve to i saljemo mem fazi neka se zajebava

		-- maltene samo treba da vidi da li je predikcija bila dobra
		-- ta informacija je validna samo ako je u pitanju skok

		-- poslednje:
		-- ako jeste skok i ako je skoceno proveri da li je predikcija dobra

		ctrl_ex_mem_out              <= ctrl_reg;
		ctrl_ex_mem_out.branch_taken <= should_take_branch;
		ctrl_ex_mem_out.mispred      <= '0';

		ctrl_ex_mem_out.flushed <= ctrl_reg.flushed OR mispred;

		if ctrl_reg.is_branch then
			ctrl_ex_mem_out.mispred <= not is_prediction_ok;
		end if;
	end process misprediction;

	ex_mem_out.pc                      <= id_ex_reg.pc;
	ex_mem_out.pc_next                 <= id_ex_reg.pc_next;
	ex_mem_out.pc_predicted            <= id_ex_reg.pc_predicted;
	ex_mem_out.real_branch_destination <= real_branch_destination;

	ex_mem_out.alu_result <= alu_RESULT;
	ex_mem_out.rd_num     <= id_ex_reg.rd_num;
	ex_mem_out.rs2        <= id_ex_reg.rs2;

	-- za potrebe prosledjivanja
	-- salju se informacije u BRAIN jedinicu
	ex_fwd_out.rd_num  <= id_ex_reg.rd_num;
	ex_fwd_out.ready   <= '1' when (ctrl_reg.mem_op /= MEM_LOAD) AND (ctrl_reg.stack_op /= STACK_POP) else '0';
	ex_fwd_out.wb      <= ctrl_reg.reg_wb;
	ex_fwd_out.flushed <= ctrl_reg.flushed OR mispred;

	-- prosledi alu rezultat u id fazu, ako mu treba uzece
	ex_id_res_out.result <= alu_RESULT;

	-- gerenisi halt
	-- TODO: ovo treba da se prebaci u neku kasniju fazu
	-- Ideja je sledeca. Kad HALT stigne do MEM faze i validan je (nije flushed), treba reci da su sve prethodne instrukcije flushed
	-- I pustiti da prodje jos jedna takt da instrukcija koja je pre HALT zavrsi i WB fazu jer mozda upisuje jos nesto
	-- Kada HALT dodje do WB, zaustavi procesor
	-- halt <= ctrl_reg.halt_detected AND not ctrl_reg.flushed AND not mispred;

end architecture RTL;