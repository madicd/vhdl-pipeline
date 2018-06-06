library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cpu_types.all;

entity phase_brain is
	port(
		id_fwd_in    : in  id_fwd_t;
		phase_fwd_in : in  phase_fwd_t;

		pb_out       : out pb_t
	);
end entity phase_brain;

architecture RTL of phase_brain is
begin
	main : process(id_fwd_in.rs1_num, id_fwd_in.rs1_rd, id_fwd_in.rs2_num, id_fwd_in.rs2_rd, phase_fwd_in.rd_num, phase_fwd_in.ready, phase_fwd_in.flushed, phase_fwd_in.wb) is
	begin
		pb_out.stall   <= '0';
		pb_out.rs1_hit <= '0';
		pb_out.rs2_hit <= '0';

		if phase_fwd_in.flushed = '0' AND phase_fwd_in.wb = '1' then
			if id_fwd_in.rs1_rd = '1' AND id_fwd_in.rs1_num = phase_fwd_in.rd_num then
				if phase_fwd_in.ready = '1' then
					pb_out.rs1_hit <= '1';
				else
					pb_out.stall <= '1';
				end if;
			end if;

			if id_fwd_in.rs2_rd = '1' AND id_fwd_in.rs2_num = phase_fwd_in.rd_num then
				if phase_fwd_in.ready = '1' then
					pb_out.rs2_hit <= '1';
				else
					pb_out.stall <= '1';
				end if;
			end if;
		end if;

	end process main;

end architecture RTL;
