library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity if_phase is
	port(
		-- ulazni signali
		startpc_in           : in  addr_t;

		mem_predictor_in     : in  mem_predictor_t;
		mem_if_prediction_in : in  mem_if_prediction_t;

		-- izlazni signali
		if_id_out            : out if_id_t;
		if_icache_out        : out if_icache_t;

		ctrl_if_id_out       : out ctrl_t;

		-- globalni signali
		stall                : in  std_logic;
		clk                  : in  std_logic;
		rst                  : in  std_logic
	);
end entity if_phase;

architecture RTL of if_phase is
	signal pc_reg, pc_next : addr_t;

	signal next_addr : addr_t;

	signal if_predictor_out : if_predictor_t;
	signal predictor_if_in  : predictor_if_t;

	signal predicted_pc_next : addr_t;
begin

	-- Sinhroni deo
	process(clk, rst) is
	begin
		if rst = '1' then
			pc_reg <= startpc_in;
		elsif rising_edge(clk) then
			pc_reg <= pc_next;
		end if;
	end process;

	-- Instanca prediktora
	predictor_inst : entity work.predictor
		port map(
			if_predictor_in  => if_predictor_out,
			mem_predictor_in => mem_predictor_in,
			predictor_if_out => predictor_if_in,
			clk              => clk,
			rst              => rst
		);

	-- Prediktoru dajemo kljuc za tabelu
	if_predictor_out.pc <= pc_reg;

	-- Adresa naredne instrukcije
	next_addr <= addr_t(unsigned(pc_reg) + 1);

	-- Predvidja se vrednost iz prediktora ako imamo informacije u njemu
	-- Ako nemamo predvidja se izvrsavanje naredne instrukcije
	predicted_pc_next <= predictor_if_in.predicted_pc_next when predictor_if_in.take_prediction
		else next_addr;

	-- Promena pc-a
	change_of_pc_next : process(mem_if_prediction_in.mispred, mem_if_prediction_in.pc_update, pc_reg, predicted_pc_next, stall) is
	begin
		pc_next <= pc_reg;

		if not stall then
			if not mem_if_prediction_in.mispred then
				pc_next <= predicted_pc_next;
			else
				pc_next <= mem_if_prediction_in.pc_update;
			end if;
		end if;
	end process change_of_pc_next;

	if_id_out.pc_next      <= next_addr;
	if_id_out.pc           <= pc_reg;
	if_id_out.pc_predicted <= predicted_pc_next;

	if_icache_out.addr <= pc_reg;

	control_signals_to_send : process (mem_if_prediction_in.mispred, predictor_if_in.take_prediction, stall) is
	begin
		
		ctrl_if_id_out <= CTRL_REG_RESET_VALUE;

		-- Ova instrukcija je flushed ako je stall dosao ili ako je doslo do mispredikcije
		ctrl_if_id_out.flushed           <= stall OR mem_if_prediction_in.mispred;
		ctrl_if_id_out.took_predicted_pc <= predictor_if_in.take_prediction;
		
	end process control_signals_to_send;

end architecture RTL;
