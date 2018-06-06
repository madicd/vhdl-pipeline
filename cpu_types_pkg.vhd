library ieee;
use ieee.std_logic_1164.all;

package cpu_types is
	constant WORD_SIZE  : natural := 32;
	constant ADDR_SIZE  : natural := 16;
	constant MEM_SIZE   : integer := 2 ** ADDR_SIZE;
	constant FILE_INSTR : string  := "D:\Faks\VLSI\Projekat\vlsi\projekat\files\instr.txt";
	constant FILE_DATA  : string  := "D:\Faks\VLSI\Projekat\vlsi\projekat\files\data.txt";

	subtype opcode_t is std_logic_vector(2 downto 0);

	subtype word_t is std_logic_vector(WORD_SIZE - 1 downto 0);
	subtype addr_t is std_logic_vector(ADDR_SIZE - 1 downto 0);

	constant ZERO_WORD : word_t := (others => '0');
	constant ZERO_ADDR : addr_t := (others => '0');

	subtype regfile_adr_t is std_logic_vector(4 downto 0);

	-- tipovi vezani za predikciju
	type if_predictor_t is record
		pc : addr_t;
	end record if_predictor_t;

	type predictor_if_t is record
		predicted_pc_next : addr_t;
		take_prediction   : std_logic;
	end record predictor_if_t;

	type mem_predictor_t is record
		-- potreban je sam PC
		pc                 : addr_t;
		-- da li je skoceno
		branch_taken       : std_logic;
		-- na koju adresu je skoceno (za potrebe dodavanja novog ulaza)
		branch_destination : addr_t;
		-- da li je uopste skok
		is_branch          : std_logic;
	end record mem_predictor_t;

	type predictor_entry_t is record
		pc      : addr_t;
		fsm     : std_logic_vector(1 downto 0); -- kao finite state machine
		pc_next : addr_t;
	end record predictor_entry_t;

	constant PREDICTOR_ENTRY_RESET_VALUE : predictor_entry_t := (
		pc      => ZERO_ADDR,
		fsm     => "10",
		pc_next => ZERO_ADDR
	);

	-- tipovi vezani za prosledjivanje

	type phase_fwd_t is record
		rd_num  : regfile_adr_t;
		wb      : std_logic;
		ready   : std_logic;
		-- nije potrebno vise
		-- value  : word_t;
		flushed : std_logic;
	end record phase_fwd_t;

	type id_fwd_t is record
		rs1_num : regfile_adr_t;
		rs1_rd  : std_logic;
		rs2_num : regfile_adr_t;
		rs2_rd  : std_logic;            -- da li stvarno cita taj registar
	end record id_fwd_t;

	type pb_t is record
		stall   : std_logic;
		rs1_hit : std_logic;
		rs2_hit : std_logic;
	end record pb_t;

	type fwd_src_t is (FWD_SRC_NONE, FWD_SRC_EX, FWD_SRC_MEM, FWD_SRC_WB);

	type fwd_id_t is record
		rs1_fwd_src : fwd_src_t;
		rs2_fwd_src : fwd_src_t;
	end record fwd_id_t;

	type phase_id_res_t is record
		result : word_t;
	end record;

	-- ostali tipovi

	type if_id_t is record
		pc_next      : addr_t;
		pc           : addr_t;
		pc_predicted : addr_t;
	end record if_id_t;

	constant IF_ID_RESET_VALUE : if_id_t := (
		pc_next      => ZERO_ADDR,
		pc           => ZERO_ADDR,
		pc_predicted => ZERO_ADDR
	);

	type if_icache_t is record
		addr : addr_t;
	end record if_icache_t;

	type icache_id_t is record
		instr : word_t;
	end record icache_id_t;

	type instruction_t is record
		rd    : std_logic_vector(4 downto 0);
		rs1   : std_logic_vector(4 downto 0);
		rs2   : std_logic_vector(4 downto 0);
		immed : std_logic_vector(15 downto 0);
	end record instruction_t;

	type alu_op_t is (ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR, ALU_NOT, ALU_SHL, ALU_SHR, ALU_SAR, ALU_ROL, ALU_ROR, ALU_MOVI);

	type cmp_op_t is (CMP_EQ, CMP_NQ, CMP_GT, CMP_LT, CMP_GE, CMP_LE, CMP_ALWAYS_TRUE);

	type src_op_t is (SRC_RS1, SRC_RS2, SRC_IMMED, SRC_PC_NEXT, SRC_NONE);

	type mem_op_t is (MEM_LOAD, MEM_STORE, MEM_NONE);

	type stack_op_t is (STACK_PUSH, STACK_POP, STACK_NONE);

	type ctrl_t is record
		flushed : std_logic;

		-- Kontrolni singali za ID
		took_predicted_pc : std_logic;

		-- Kontrolni signali za EX fazu
		cmp_op    : cmp_op_t;
		is_branch : std_logic;

		alu_op  : alu_op_t;
		src_op1 : src_op_t;
		src_op2 : src_op_t;

		-- Kontrolni signali za MEM fazu
		-- novo zbog predikcije
		mispred      : std_logic;
		branch_taken : std_logic;

		mem_op : mem_op_t;

		-- Kontrolni signali za WB fazu
		reg_wb : std_logic;

		--
		halt_detected : std_logic;
		stack_op      : stack_op_t;
		is_jsr        : std_logic;
		is_rts        : std_logic;
	end record;

	constant CTRL_REG_RESET_VALUE : ctrl_t := (
		flushed           => '1',
		took_predicted_pc => '0',
		cmp_op            => CMP_EQ,
		is_branch         => '0',
		alu_op            => ALU_ADD,
		src_op1           => SRC_NONE,
		src_op2           => SRC_NONE,
		mispred           => '0',
		branch_taken      => '0',
		mem_op            => MEM_NONE,
		reg_wb            => '0',
		halt_detected     => '0',
		stack_op          => STACK_NONE,
		is_jsr            => '0',
		is_rts            => '0'
	);

	type id_ex_t is record
		-- deo za predikciju
		pc_next      : addr_t;
		pc           : addr_t;
		pc_predicted : addr_t;

		-- stari deo
		rs1    : word_t;
		rs2    : word_t;
		immed  : word_t;
		rd_num : regfile_adr_t;
	end record;

	constant ID_EX_RESET_VALUE : id_ex_t := (
		pc_next      => ZERO_ADDR,
		pc           => ZERO_ADDR,
		pc_predicted => ZERO_ADDR,
		rs1          => ZERO_WORD,
		rs2          => ZERO_WORD,
		immed        => ZERO_WORD,
		rd_num       => (others => '0')
	);

	type ex_mem_t is record
		-- deo za predikciju
		pc_next                 : addr_t;
		pc                      : addr_t;
		pc_predicted            : addr_t;
		real_branch_destination : addr_t;

		-- staro
		alu_result : word_t;
		rs2        : word_t;
		rd_num     : regfile_adr_t;
	end record;

	constant EX_MEM_RESET_VALUE : ex_mem_t := (
		pc_next                 => ZERO_ADDR,
		pc                      => ZERO_ADDR,
		pc_predicted            => ZERO_ADDR,
		real_branch_destination => ZERO_ADDR,
		alu_result              => ZERO_WORD,
		rs2                     => ZERO_WORD,
		rd_num                  => (others => '0')
	);

	type mem_wb_t is record
		result : word_t;
		rd_num : regfile_adr_t;
	end record;

	constant MEM_WB_RESET_VALUE : mem_wb_t := (
		result => ZERO_WORD,
		rd_num => (others => '0')
	);

	type mem_dcache_t is record
		addr_in : addr_t;
		data_in : word_t;
		wr      : std_logic;
	end record;

	type dcache_wb_t is record
		data_out : word_t;
	end record;

	type wb_id_t is record
		data : word_t;
		addr : regfile_adr_t;
		wr   : std_logic;
	end record;

	type mem_if_prediction_t is record
		pc_update : addr_t;
		mispred   : std_logic;
	end record;

	-- Konstante za inicijalizaciju faznih registara prilikom reset-a


	-- opcodes
	-- group0
	constant GROUP_0 : opcode_t := "000";

	constant LOAD_op  : opcode_t := "000";
	constant STORE_op : opcode_t := "001";
	constant MOV_op   : opcode_t := "100";
	constant MOVI_op  : opcode_t := "101";

	-- group1
	constant GROUP_1 : opcode_t := "001";

	constant ADD_op  : opcode_t := "000";
	constant SUB_op  : opcode_t := "001";
	constant ADDI_op : opcode_t := "100";
	constant SUBI_op : opcode_t := "101";

	-- group2
	constant GROUP_2 : opcode_t := "010";

	constant AND_op : opcode_t := "000";
	constant OR_op  : opcode_t := "001";
	constant XOR_op : opcode_t := "010";
	constant NOT_op : opcode_t := "011";

	-- group3
	constant GROUP_3 : opcode_t := "011";

	constant SHL_op : opcode_t := "000";
	constant SHR_op : opcode_t := "001";
	constant SAR_op : opcode_t := "010";
	constant ROL_op : opcode_t := "011";
	constant ROR_op : opcode_t := "100";

	-- group4
	constant GROUP_4 : opcode_t := "100";

	constant JMP_op  : opcode_t := "000";
	constant JSR_op  : opcode_t := "001";
	constant RTS_op  : opcode_t := "010";
	constant PUSH_op : opcode_t := "100";
	constant POP_op  : opcode_t := "101";

	-- group5
	constant GROUP_5 : opcode_t := "101";

	constant BEQ_op : opcode_t := "000";
	constant BNQ_op : opcode_t := "001";
	constant BGT_op : opcode_t := "010";
	constant BLT_op : opcode_t := "011";
	constant BGE_op : opcode_t := "100";
	constant BLE_op : opcode_t := "101";

	-- group7, just halt
	constant GROUP_7 : opcode_t := "111";

	constant HALT_op : opcode_t := "111";
end package cpu_types;
