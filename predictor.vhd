
-- BELESKE SA AUDIO SNIMAKA

-- adresa sledece instrukcije uvek se cita sa PC-a
-- recimo ako imamo slucaj da smo pogresili, doslo je do misprediction-a
-- uzmemo tu tacnu adresu, gde je trebalo da se skoci, pa je upisemo u PC
-- onda se iz PC-a cita sledeca instrukcija
-- kaze gubi se jedan takt al je tako bolje

-- PC NEXT moze da dobije 3 vrednosti
-- 1) pc+1
-- 2) tacna adresa skoka, ukoliko je doslo do mispredikcije
-- 3) vrednost iz prediktora
-- znaci lagani multiplekser ovde

-- kes bi bio recimo (tekuci_pc, konacni_automat, adresa_skoka)
-- mozda da se doda i da li je ulaz validan (jedan bit)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity predictor is
	port(
		-- ulazni signali
		if_predictor_in  : in  if_predictor_t;
		mem_predictor_in : in  mem_predictor_t;

		-- izlazni signali
		predictor_if_out : out predictor_if_t;

		-- globalni signali
		clk, rst         : in  std_logic
	);
end entity predictor;

-- Probacu kao kod registarkog fajla
-- citanje da bude asinhrono a upis sinhrona operacija

architecture RTL of predictor is
	-- za pocetak neka ima 4 ulaza
	type predictor_mem_t is array (3 downto 0) of predictor_entry_t;

	signal mem_reg, mem_next : predictor_mem_t;

	-- algoritam zamene
	signal cnt_reg, cnt_next : std_logic_vector(1 downto 0);
begin
	sinhroni_deo : process(clk, rst) is
	begin
		if rst = '1' then
			for i in 0 to 3 loop
				mem_reg(i) <= PREDICTOR_ENTRY_RESET_VALUE;
			end loop;
			cnt_reg <= "00";
		elsif rising_edge(clk) then
			mem_reg <= mem_next;
			cnt_reg <= cnt_next;
		end if;
	end process sinhroni_deo;

	upis : process(mem_predictor_in.branch_taken, mem_predictor_in.pc, mem_reg(0).fsm, mem_reg(0).pc, mem_reg(1).fsm, mem_reg(1).pc, mem_reg(2).fsm, mem_reg(2).pc, mem_reg(3).fsm, mem_reg(3).pc, cnt_reg, mem_predictor_in.branch_destination, mem_reg, mem_predictor_in.is_branch) is
		alias pc is mem_predictor_in.pc;
	begin

		-- za pocetak sve isto
		mem_next <= mem_reg;
		cnt_next <= cnt_reg;

		-- ako se radi o skoku azuriraj stanje
		-- ako ne, iskuliraj, sve ostaje isto
		if mem_predictor_in.is_branch then

			-- ako imamo poklapanje onda je azuriranje
			-- malo glupo uradjeno al za pocetak je ok

			if pc = mem_reg(0).pc then

				-- inicijalno ostaje isto
				mem_next(0).fsm <= mem_reg(0).fsm;

				case mem_reg(0).fsm is
					when "00" =>
						if mem_predictor_in.branch_taken then
							mem_next(0).fsm <= "01";
						end if;
					when "01" =>
						if mem_predictor_in.branch_taken then
							mem_next(0).fsm <= "11";
						else
							mem_next(0).fsm <= "00";
						end if;
					when "10" =>
						if mem_predictor_in.branch_taken then
							mem_next(0).fsm <= "11";
						else
							mem_next(0).fsm <= "00";
						end if;
					when "11" =>
						if not mem_predictor_in.branch_taken then
							mem_next(0).fsm <= "10";
						end if;
					when others =>
						null;
				end case;
			elsif pc = mem_reg(1).pc then

				-- inicijalno ostaje isto
				mem_next(1).fsm <= mem_reg(1).fsm;

				case mem_reg(1).fsm is
					when "00" =>
						if mem_predictor_in.branch_taken then
							mem_next(1).fsm <= "01";
						end if;
					when "01" =>
						if mem_predictor_in.branch_taken then
							mem_next(1).fsm <= "11";
						else
							mem_next(1).fsm <= "00";
						end if;
					when "10" =>
						if mem_predictor_in.branch_taken then
							mem_next(1).fsm <= "11";
						else
							mem_next(1).fsm <= "00";
						end if;
					when "11" =>
						if not mem_predictor_in.branch_taken then
							mem_next(1).fsm <= "10";
						end if;
					when others =>
						null;
				end case;
			elsif pc = mem_reg(2).pc then

				-- inicijalno ostaje isto
				mem_next(2).fsm <= mem_reg(2).fsm;

				case mem_reg(2).fsm is
					when "00" =>
						if mem_predictor_in.branch_taken then
							mem_next(2).fsm <= "01";
						end if;
					when "01" =>
						if mem_predictor_in.branch_taken then
							mem_next(2).fsm <= "11";
						else
							mem_next(2).fsm <= "00";
						end if;
					when "10" =>
						if mem_predictor_in.branch_taken then
							mem_next(2).fsm <= "11";
						else
							mem_next(2).fsm <= "00";
						end if;
					when "11" =>
						if not mem_predictor_in.branch_taken then
							mem_next(2).fsm <= "10";
						end if;
					when others =>
						null;
				end case;
			elsif pc = mem_reg(3).pc then

				-- inicijalno ostaje isto
				mem_next(3).fsm <= mem_reg(3).fsm;

				case mem_reg(3).fsm is
					when "00" =>
						if mem_predictor_in.branch_taken then
							mem_next(3).fsm <= "01";
						end if;
					when "01" =>
						if mem_predictor_in.branch_taken then
							mem_next(3).fsm <= "11";
						else
							mem_next(3).fsm <= "00";
						end if;
					when "10" =>
						if mem_predictor_in.branch_taken then
							mem_next(3).fsm <= "11";
						else
							mem_next(3).fsm <= "00";
						end if;
					when "11" =>
						if not mem_predictor_in.branch_taken then
							mem_next(3).fsm <= "10";
						end if;
					when others =>
						null;
				end case;
			else

				-- onda je upis nove vrednosti
				mem_next(to_integer(unsigned(cnt_reg))) <= (
						pc => mem_predictor_in.pc,
						fsm => "10",
						pc_next => mem_predictor_in.branch_destination
					);

				-- cnt_next++
				cnt_next <= std_logic_vector(to_unsigned(to_integer(unsigned(cnt_reg) + 1), 2));

			end if;
		end if;
	end process upis;

	main : process(if_predictor_in, mem_reg) is
		alias pc is if_predictor_in.pc;
	begin
		-- neke inicijalne vrednosti
		predictor_if_out.take_prediction              <= '0';
		predictor_if_out.predicted_pc_next <= ZERO_ADDR;

		if pc = mem_reg(0).pc then
			predictor_if_out.take_prediction              <= mem_reg(0).fsm(1);
			predictor_if_out.predicted_pc_next <= mem_reg(0).pc_next;
		elsif pc = mem_reg(1).pc then
			predictor_if_out.take_prediction              <= mem_reg(1).fsm(1);
			predictor_if_out.predicted_pc_next <= mem_reg(1).pc_next;
		elsif pc = mem_reg(2).pc then
			predictor_if_out.take_prediction              <= mem_reg(2).fsm(1);
			predictor_if_out.predicted_pc_next <= mem_reg(2).pc_next;
		elsif pc = mem_reg(3).pc then
			predictor_if_out.take_prediction              <= mem_reg(3).fsm(1);
			predictor_if_out.predicted_pc_next <= mem_reg(3).pc_next;
		end if;
	end process main;

end architecture RTL;



