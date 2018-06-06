library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity prediction_fsm is
	port(
		branch_taken_in : in std_logic;

		enable          : in std_logic;
		
		clk             : in std_logic;
		rst             : in std_logic
	);
end entity prediction_fsm;

architecture RTL of prediction_fsm is
	signal reg_reg, reg_next : std_logic_vector(1 downto 0);

begin
	sinhroni_deo : process(clk, rst) is
	begin
		if rst = '1' then
			reg_reg <= "00";
		elsif rising_edge(clk) then
			reg_reg <= reg_next;
		end if;
	end process sinhroni_deo;

	konacni_automat : process(branch_taken_in, reg_reg) is
	begin

		-- inicijalno ostaje isto
		reg_next <= reg_reg;

		case reg_reg is
			when "00" =>
				if branch_taken_in then
					reg_next <= "01";
				end if;
			when "01" =>
				if branch_taken_in then
					reg_next <= "11";
				else
					reg_next <= "00";
				end if;
			when "10" =>
				if branch_taken_in then
					reg_next <= "11";
				else
					reg_next <= "00";
				end if;
			when "11" =>
				if not branch_taken_in then
					reg_next <= "10";
				end if;
		end case;

	end process konacni_automat;

end architecture RTL;
