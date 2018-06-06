library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity id_phase is
	port(
		-- ulazni podaci
		if_id_in       : in  if_id_t;
		icache_id_in   : in  icache_id_t;
		wb_id_in       : in  wb_id_t;

		ctrl_if_id_in  : in  ctrl_t;

		-- za potrebe prosledjivanja
		fwd_id_in      : in  fwd_id_t;
		id_fwd_out     : out id_fwd_t;

		-- prosledjivanje alu rezultata iz ostalih faza
		ex_id_res_in   : in  phase_id_res_t;
		mem_id_res_in  : in  phase_id_res_t;
		wb_id_res_in   : in  phase_id_res_t;

		-- izlazni podaci
		id_ex_out      : out id_ex_t;
		ctrl_id_ex_out : out ctrl_t;

		-- globani kontrolni signali
		mispred        : in  std_logic;
		stall          : in  std_logic;
		clk            : in  std_logic;
		rst            : in  std_logic
	);
end entity id_phase;

architecture RTL of id_phase is
	-- signal oldpc_reg, oldpc_next : addr_t;
	signal IR : instruction_t;

	signal operand_rs1, operand_rs2 : word_t;

	-- fazni registri
	signal if_id_reg, if_id_next         : if_id_t;
	signal ctrl_reg, ctrl_next           : ctrl_t;
	signal icache_id_reg, icache_id_next : word_t;

	alias ireg    : word_t is icache_id_reg;
	alias opcode1 : opcode_t is ireg(31 downto 29);
	alias opcode2 : opcode_t is ireg(28 downto 26);
begin

	--  zamenjeno ovim ispod
	--	if_id_next <= if_id_in when stall = '0' else if_id_reg;
	--	ctrl_next  <= ctrl_if_id_in when stall = '0' else ctrl_reg;
	--	IR_next    <= icache_id_in.instr when stall = '0' else IR_reg;


	changing_next_signals : process(icache_id_reg, ctrl_if_id_in, ctrl_reg, icache_id_in.instr, if_id_in, if_id_reg, stall) is
	begin
		if_id_next     <= if_id_reg;
		ctrl_next      <= ctrl_reg;
		icache_id_next <= icache_id_reg;

		if not stall then
			if_id_next     <= if_id_in;
			ctrl_next      <= ctrl_if_id_in;
			icache_id_next <= icache_id_in.instr;
		end if;
	end process changing_next_signals;

	-- zastarelo, zamenjeno sa if_id_reg, if_id_next
	-- oldpc_next <= if_id_in.oldpc when stall = '0' else oldpc_reg;

	process(clk, rst) is
	begin
		if rst = '1' then
			if_id_reg     <= IF_ID_RESET_VALUE;
			ctrl_reg      <= CTRL_REG_RESET_VALUE;
			icache_id_reg <= ZERO_WORD;
		elsif rising_edge(clk) then
			if_id_reg     <= if_id_next;
			ctrl_reg      <= ctrl_next;
			icache_id_reg <= icache_id_next;
		end if;
	end process;

	process(ctrl_reg, ctrl_reg.flushed, icache_id_reg(10 downto 0), icache_id_reg(15 downto 0), icache_id_reg(15 downto 11), icache_id_reg(20 downto 16), icache_id_reg(25 downto 21), icache_id_reg(28 downto 26), icache_id_reg(31 downto 29), mispred, stall) is
	begin

		-- Najveci broj instrukcija ovako parsira podatke
		IR.rd    <= ireg(25 downto 21);
		IR.rs1   <= ireg(20 downto 16);
		IR.rs2   <= ireg(15 downto 11);
		IR.immed <= ireg(15 downto 0);

		-- Podrazumevano kontrolni signali su iz ctrl_reg
		ctrl_id_ex_out <= ctrl_reg;

		-- Ova instrukcija je flushovana u sledecim slucajevima
		-- 1) Vec je dosla kao flushovana
		-- 2) Stigao je stall
		-- 3) Doslo je do mispredikcije
		ctrl_id_ex_out.flushed <= ctrl_reg.flushed OR stall OR mispred;

		-- da li stvarno cita te registre
		id_fwd_out.rs1_rd <= '0';
		id_fwd_out.rs2_rd <= '0';

		case opcode1 is
			when GROUP_0 =>
				case opcode2 is
					when LOAD_op =>

						-- Postavljamo immed
						IR.immed <= ireg(15 downto 0);

						-- Postavljamo ALU operaciju
						ctrl_id_ex_out.alu_op  <= ALU_ADD;
						ctrl_id_ex_out.src_op1 <= SRC_RS1;
						ctrl_id_ex_out.src_op2 <= SRC_IMMED;

						-- da li stvarno cita te registre
						id_fwd_out.rs1_rd <= '1';

						ctrl_id_ex_out.mem_op <= MEM_LOAD;
						ctrl_id_ex_out.reg_wb <= '1';

					when STORE_op =>

						-- Postavljamo immed
						IR.immed <= ireg(25 downto 21) & ireg(10 downto 0);

						-- Postavljamo ALU operaciju
						ctrl_id_ex_out.alu_op  <= ALU_ADD;
						ctrl_id_ex_out.src_op1 <= SRC_RS1;
						ctrl_id_ex_out.src_op2 <= SRC_IMMED;

						-- Postavljamo MEM operaciju
						ctrl_id_ex_out.mem_op <= MEM_STORE;

						-- Brain jedinici kazemo da nam treba rs1 i rs2
						id_fwd_out.rs1_rd <= '1';
						id_fwd_out.rs2_rd <= '1';

					when MOV_op =>

						-- Postavljamo ALU operaciju
						ctrl_id_ex_out.alu_op  <= ALU_ADD;
						ctrl_id_ex_out.src_op1 <= SRC_RS1;
						ctrl_id_ex_out.src_op2 <= SRC_NONE;

						-- Radi se Write-Back
						ctrl_id_ex_out.reg_wb <= '1';

					when MOVI_op =>
						IR.rs1 <= ireg(25 downto 21);

						-- Postavljamo ALU operaciju
						ctrl_id_ex_out.alu_op  <= ALU_MOVI;
						ctrl_id_ex_out.src_op1 <= SRC_RS1;
						ctrl_id_ex_out.src_op2 <= SRC_IMMED;

						id_fwd_out.rs1_rd <= '1';

						-- Radi se Write-Back
						ctrl_id_ex_out.reg_wb <= '1';

					when others =>
						null;
				end case;

			when GROUP_1 =>

				-- Sve instrukcije ove grupe rade Write-Back				
				ctrl_id_ex_out.reg_wb <= '1';

				case opcode2 is
					when ADD_op =>
						ctrl_id_ex_out.alu_op  <= ALU_ADD;
						ctrl_id_ex_out.src_op1 <= SRC_RS1;
						ctrl_id_ex_out.src_op2 <= SRC_RS2;

						id_fwd_out.rs1_rd <= '1';
						id_fwd_out.rs2_rd <= '1';

					when SUB_op =>
						ctrl_id_ex_out.alu_op  <= ALU_SUB;
						ctrl_id_ex_out.src_op1 <= SRC_RS1;
						ctrl_id_ex_out.src_op2 <= SRC_RS2;

						id_fwd_out.rs1_rd <= '1';
						id_fwd_out.rs2_rd <= '1';

					when ADDI_op =>
						ctrl_id_ex_out.alu_op  <= ALU_ADD;
						ctrl_id_ex_out.src_op1 <= SRC_RS1;
						ctrl_id_ex_out.src_op2 <= SRC_IMMED;

						id_fwd_out.rs1_rd <= '1';

					when SUBI_op =>
						ctrl_id_ex_out.alu_op  <= ALU_SUB;
						ctrl_id_ex_out.src_op1 <= SRC_RS1;
						ctrl_id_ex_out.src_op2 <= SRC_IMMED;

						id_fwd_out.rs1_rd <= '1';

					when others =>
						null;
				end case;

			when GROUP_2 =>

				-- AND, OR, XOR, NOT

				-- Sve instrukcije rade Write-Back
				ctrl_id_ex_out.reg_wb <= '1';

				ctrl_id_ex_out.src_op1 <= SRC_RS1;
				ctrl_id_ex_out.src_op2 <= SRC_RS2;

				case opcode2 is
					when AND_op =>
						ctrl_id_ex_out.alu_op <= ALU_AND;
					when OR_op =>
						ctrl_id_ex_out.alu_op <= ALU_OR;
					when XOR_op =>
						ctrl_id_ex_out.alu_op <= ALU_XOR;
					when NOT_op =>
						ctrl_id_ex_out.src_op2 <= SRC_NONE;
						ctrl_id_ex_out.alu_op  <= ALU_NOT;
					when others =>
						null;
				end case;

			when GROUP_3 =>

				-- SHL, SHR, SAR, ROL, ROR

				IR.immed <= (others => '0');
				IR.immed(4 downto 0) <= ireg(15 downto 11);
				IR.rs1   <= ireg(25 downto 21);

				ctrl_id_ex_out.src_op1 <= SRC_RS1;
				ctrl_id_ex_out.src_op2 <= SRC_IMMED;

				ctrl_id_ex_out.reg_wb <= '1';

				id_fwd_out.rs1_rd <= '1';

				case opcode2 is
					when SHL_op =>
						ctrl_id_ex_out.alu_op <= ALU_SHL;
					when SHR_op =>
						ctrl_id_ex_out.alu_op <= ALU_SHR;
					when SAR_op =>
						ctrl_id_ex_out.alu_op <= ALU_SAR;
					when ROL_op =>
						ctrl_id_ex_out.alu_op <= ALU_ROL;
					when ROR_op =>
						ctrl_id_ex_out.alu_op <= ALU_ROR;
					when others =>
						null;
				end case;

			when GROUP_4 =>

				-- JMP, JSR, RTS, PUSH, POP

				case opcode2 is
					when JMP_op =>
						IR.rs1   <= ireg(20 downto 16);
						IR.immed <= ireg(15 downto 0);

						ctrl_id_ex_out.alu_op  <= ALU_ADD;
						ctrl_id_ex_out.src_op1 <= SRC_RS1;
						ctrl_id_ex_out.src_op2 <= SRC_IMMED;

						ctrl_id_ex_out.is_branch <= '1';

						-- uslov za skok je uvek ispunjen
						ctrl_id_ex_out.cmp_op <= CMP_ALWAYS_TRUE;

					when JSR_op =>
						IR.rs1   <= ireg(20 downto 16);
						IR.immed <= ireg(15 downto 0);

						ctrl_id_ex_out.alu_op  <= ALU_ADD;
						ctrl_id_ex_out.src_op1 <= SRC_RS1;
						ctrl_id_ex_out.src_op2 <= SRC_IMMED;

						ctrl_id_ex_out.is_branch <= '1';

						-- uslov za skok je uvek ispunjen
						ctrl_id_ex_out.cmp_op <= CMP_ALWAYS_TRUE;

						ctrl_id_ex_out.is_jsr <= '1';

						ctrl_id_ex_out.stack_op <= STACK_PUSH;

					when RTS_op =>
						ctrl_id_ex_out.is_rts <= '1';

					when PUSH_op =>

						-- na stek stavlja vrednost rs1

						ctrl_id_ex_out.alu_op  <= ALU_ADD;
						ctrl_id_ex_out.src_op1 <= SRC_RS1;
						ctrl_id_ex_out.src_op2 <= SRC_NONE;

						ctrl_id_ex_out.stack_op <= STACK_PUSH;

						id_fwd_out.rs1_rd <= '1';

					when POP_op =>

						-- skida sa vrha steka i smesta u rd

						ctrl_id_ex_out.stack_op <= STACK_POP;

						ctrl_id_ex_out.reg_wb <= '1';

					when others =>
						null;
				end case;

			when GROUP_5 =>

				-- BRANCHES

				IR.rs1   <= ireg(20 downto 16);
				IR.rs2   <= ireg(15 downto 11);
				IR.immed <= ireg(25 downto 21) & ireg(10 downto 0);

				-- za sad neka bude da mu kaze da je skok u pitanju
				-- on zna sta treba da poredi

				ctrl_id_ex_out.alu_op  <= ALU_ADD;
				ctrl_id_ex_out.src_op1 <= SRC_PC_NEXT;
				ctrl_id_ex_out.src_op2 <= SRC_IMMED;

				ctrl_id_ex_out.is_branch <= '1';
				
				id_fwd_out.rs1_rd <= '1';
				id_fwd_out.rs2_rd <= '1';

				case opcode2 is
					when BEQ_op =>
						ctrl_id_ex_out.cmp_op <= CMP_EQ;
					when BNQ_op =>
						ctrl_id_ex_out.cmp_op <= CMP_NQ;
					when BGT_op =>
						ctrl_id_ex_out.cmp_op <= CMP_GT;
					when BLT_op =>
						ctrl_id_ex_out.cmp_op <= CMP_LT;
					when BGE_op =>
						ctrl_id_ex_out.cmp_op <= CMP_GE;
					when BLE_op =>
						ctrl_id_ex_out.cmp_op <= CMP_LE;
					when others =>
						null;
				end case;

			when GROUP_7 =>

				-- HALT

				case opcode2 is
					when HALT_op =>
						ctrl_id_ex_out.halt_detected <= '1';
					when others =>
						null;
				end case;

			when others =>
				null;
		end case;
	end process;

	-- Registarski fajl
	reg_file_inst : entity work.reg_file
		port map(
			rd_addr1_in  => IR.rs1,
			rd_addr2_in  => IR.rs2,
			rd_data1_out => operand_rs1,
			rd_data2_out => operand_rs2,
			wr_addr_in   => wb_id_in.addr,
			wr_data_in   => wb_id_in.data,
			wr_in        => wb_id_in.wr,
			clk          => clk,
			rst          => rst
		);

	-- Brain jedinici saljemo koje registre citamo
	id_fwd_out.rs1_num <= IR.rs1;
	id_fwd_out.rs2_num <= IR.rs2;

	-- Prosledjivanje podataka EX fazi
	id_ex_out.immed        <= word_t(resize(signed(IR.immed), WORD_SIZE));
	id_ex_out.rd_num       <= IR.rd;
	id_ex_out.pc           <= if_id_reg.pc;
	id_ex_out.pc_next      <= if_id_reg.pc_next;
	id_ex_out.pc_predicted <= if_id_reg.pc_predicted;

	-- Brain jedinica nam salje kontrolne signale i u zavisnosti od toga odlucujemo
	-- koja ce se vrednost proslediti EX fazi kao registar rs1 i rs2.
	-- Ukoliko je doslo do prosledjivanja prosledice se rezultat iz neke od narednih faza koji je spreman
	-- a ukoliko nije, prosledice se vrednost procitana iz registarskog fajla.

	for_rs1 : with fwd_id_in.rs1_fwd_src select id_ex_out.rs1 <=
		operand_rs1 when FWD_SRC_NONE,
		ex_id_res_in.result when FWD_SRC_EX,
		mem_id_res_in.result when FWD_SRC_MEM,
		wb_id_res_in.result when FWD_SRC_WB;

	for_rs2 : with fwd_id_in.rs2_fwd_src select id_ex_out.rs2 <=
		operand_rs2 when FWD_SRC_NONE,
		ex_id_res_in.result when FWD_SRC_EX,
		mem_id_res_in.result when FWD_SRC_MEM,
		wb_id_res_in.result when FWD_SRC_WB;

end architecture RTL;
