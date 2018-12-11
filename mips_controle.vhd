LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use work.mips_pkg.all;

ENTITY mips_controle IS

	PORT
	(
		clk, rst				: IN std_logic;
		opcode					: IN std_logic_vector (5 DOWNTO 0);
		wr_ir						: OUT std_logic;
		wr_pc						: OUT std_logic;
		wr_mem					: OUT std_logic;
		is_beq					: OUT std_logic;
		is_bne					: OUT std_logic;
		s_datareg				: OUT std_logic;
		op_alu					: OUT std_logic_vector (2 DOWNTO 0);
		s_mem_add				: OUT std_logic;
		s_PCin					: OUT std_logic_vector (1 DOWNTO 0);
		s_aluAin 				: OUT std_logic;
		s_aluBin 				: OUT std_logic_vector (1 DOWNTO 0);
		wr_breg					: OUT std_logic;
		logic_ext				: OUT std_logic;
		s_reg_add				: OUT std_logic;
		is_unsigned_s   : OUT std_logic;
		mdr_mux_sel_v   : OUT std_logic_vector (1 DOWNTO 0);
		wdata_mux_sel_v : OUT std_logic_vector (1 DOWNTO 0)
	);

END ENTITY;

ARCHITECTURE control_op OF mips_controle IS

	type ctr_state is (
								fetch_st,
								decode_st,
								c_mem_add_st,
								readmem_st,
								ldreg_st,
								writemem_st,
								rtype_ex_st,
								writereg_st,
								branch_ex_st,
								jump_ex_st,
								andi_ex_st,
								ori_ex_st,
								arith_imm_st,
								ldreghalf_st,
								ldregbyte_st,
								streghalf_st,
								stregbyte_st);

	signal pstate, nstate : ctr_state;

	BEGIN

reg: process(clk, rst)
	begin
		if (rst = '1') then
			pstate <= fetch_st;
		elsif (rising_edge(clk)) then
			pstate <= nstate;
		end if;
	end process;

logic: process (opcode, pstate)
	begin
		wr_ir						<= '0';
		wr_pc						<= '0';
		wr_mem					<= '0';
		wr_breg					<= '0';
		is_beq 					<= '0';
		is_bne 					<= '0';
		op_alu					<= "000";
		s_datareg 			<= '0';
		s_mem_add 			<= '0';
		s_PCin					<= "00";
		s_aluAin 				<= '0';
		s_aluBin  			<= "00";
		s_reg_add 			<= '0';
		logic_ext 			<= '0';
		mdr_mux_sel_v		<= "00";
		wdata_mux_sel_v <= "00";
		is_unsigned_s   <= '0';
		case pstate is
			when fetch_st 		=> wr_pc 	<= '1';
										s_aluBin <= "01";
										wr_ir 	<= '1';

			when decode_st 	=>	s_aluBin <= "11";

			when c_mem_add_st => s_aluAin <= '1';
										s_aluBin <= "10";

			when readmem_st 	=> s_mem_add <= '1';

			when ldreghalf_st => s_mem_add <= '1';
										mdr_mux_sel_v <= "01";
										if opcode = iLHU
										then is_unsigned_s <= '1';
										end if;

			when ldregbyte_st => s_mem_add <= '1';
										mdr_mux_sel_v <= "10";
										if opcode = iLBU
										then is_unsigned_s <= '1';
										end if;

			when ldreg_st 		=>	s_datareg <= '1';
										wr_breg	  <= '1';

			when writemem_st 	=> wr_mem 	 <= '1';
										s_mem_add <= '1';

			when streghalf_st => wr_mem 	 <= '1';
										s_mem_add <= '1';
										wdata_mux_sel_v <= "01";

			when stregbyte_st => wr_mem 	 <= '1';
										s_mem_add <= '1';
										wdata_mux_sel_v <= "10";

			when rtype_ex_st	=> op_alu <= "010";
										s_aluAin <= '1';

			when writereg_st 	=> s_reg_add <= '1';
										wr_breg <= '1';

			when branch_ex_st => s_aluAin <= '1';
										op_alu <= "001";
										s_PCin <= "01";
										if opcode = iBEQ
										then is_beq <= '1';
										else is_bne <= '1';
										end if;

			when jump_ex_st 	=>	s_PCin  <= "10";
										wr_pc   <= '1';

			when arith_imm_st => wr_breg <= '1';

			when andi_ex_st	=> s_aluAin <= '1';
										s_aluBin <= "10";
										logic_ext <= '1';
										op_alu <= "011";

			when ori_ex_st		=> s_aluAin <= '1';
										s_aluBin <= "10";
										logic_ext <= '1';
										op_alu <= "100";
		end case;
	end process;

new_state: process (opcode, pstate)
		begin

			nstate <= fetch_st;

			case pstate is
				when fetch_st => 	nstate <= decode_st;
				when decode_st =>	case opcode is
										when iRTYPE => nstate <= rtype_ex_st;
										when iLW | iSW | iADDI | iADDIU | iLH | iLHU | iLB | iLBU | iSH | iSB => nstate <= c_mem_add_st;
										when iANDI => nstate <= andi_ex_st;
										when iORI => nstate <= ori_ex_st;
										when iBEQ | iBNE => nstate <= branch_ex_st;
										when iJ => nstate <= jump_ex_st;
										when others => null;
										end case;
				when c_mem_add_st => case opcode is
										when iLW => nstate <= readmem_st;
										when iSW => nstate <= writemem_st;
										when iADDI | iADDIU => nstate <= arith_imm_st;
										when iLH | iLHU => nstate <= ldreghalf_st;
										when iLB | iLBU => nstate <= ldregbyte_st;
										when iSH => nstate <= streghalf_st;
										when iSB => nstate <= stregbyte_st;
										when others => null;
									 end case;
				when readmem_st 	=> nstate <= ldreg_st;
				when ldreghalf_st => nstate <= ldreg_st;
				when ldregbyte_st => nstate <= ldreg_st;
				when rtype_ex_st 	=> nstate <= writereg_st;
				when andi_ex_st 	=> nstate <= arith_imm_st;
				when ori_ex_st 	=> nstate <= arith_imm_st;
				when others 		=> nstate <= fetch_st;
			end case;
		end process;

end control_op;
