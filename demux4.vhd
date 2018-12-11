library ieee;
use IEEE.std_logic_1164.all;

entity demux4 is
	generic (
		W_SIZE 	: natural := 32
	);
	port(
	  in0                    : in std_logic_vector(W_SIZE-1 downto 0);
	  sel                    : in std_logic_vector(1 downto 0);
	  out0, out1, out2, out3 : out std_logic_vector(7 downto 0)
	);
end demux4;

architecture rtl of demux4 is
begin

	out3 <= 	in0(7 downto 0) when (sel = "11") else
				(others => '0');
	out2 <= 	in0(7 downto 0) when (sel = "10") else
				(others => '0');
	out1 <= 	in0(7 downto 0) 	when (sel = "01") else
				(others => '0');
	out0 <= 	in0(7 downto 0) 	when (sel = "00") else
				(others => '0');

end rtl;
