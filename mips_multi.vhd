-- Quartus II VHDL Template
-- Basic Shift Register

library ieee;
use ieee.std_logic_1164.all;
use work.mips_pkg.all;

entity mips_multi is
	port
	(
		clk		  : in std_logic;
		clk_rom	: in std_logic;
		rst	    : in std_logic;
		debug		: in std_logic_vector(1 downto 0);
		data  	: out std_logic_vector(WORD_SIZE-1 downto 0);

		led_clk       : out std_logic;
		primeiro_7seg : out STD_LOGIC_VECTOR(7 downto 0);
		segundo_7seg  : out STD_LOGIC_VECTOR(7 downto 0);
		terceiro_7seg : out STD_LOGIC_VECTOR(7 downto 0);
		quarto_7seg   : out STD_LOGIC_VECTOR(7 downto 0);
		quinto_7seg   : out STD_LOGIC_VECTOR(7 downto 0);
		sexto_7seg    : out STD_LOGIC_VECTOR(7 downto 0);
		setimo_7seg   : out STD_LOGIC_VECTOR(7 downto 0);
		oitavo_7seg   : out STD_LOGIC_VECTOR(7 downto 0)
	);
end entity;

architecture rtl of mips_multi is


--=======================================================================
-- Convencoes:
--        _v - sufixo para std_logic_vector
--	       _s - sufixo para std_logic
--
--=======================================================================

signal  fpga_out : std_logic_vector(31 downto 0);
signal 	pcin_v   : std_logic_vector(31 downto 0) := (others => '0'); -- entrada PC
signal
	pcout_v,  		-- saida PC
	pccond_v,		-- PC somado ao offset
	pcbranch_v,		-- Saida primeiro mux PC
	pcjump_v,  		-- Endereco de Jump
	regdata_v,		-- entrada de dados BREG
	memout_v,		-- saida da memoria
	rdmout_v,		-- saida do registrador de dados da memoria
	rULA_out_v,		-- registrador na saida da ula
	memadd_v,		-- endereco da memoria
	datadd_v,		-- endereco de dado na memoria
	pcadd_v,			-- endereco de isntrucao
	regAin_v,		-- saida A do BREG
	regBin_v,		-- saida B do BREG
	regA_v,			-- saida A do BREG
	regB_v,			-- saida B do BREG
	aluA_v,			-- entrada A da ULA
	aluB_v,			-- entrada B da ULA
	alu_out_v,		-- saida ULA
	instruction_v,	-- saida do reg de instrucoes
	imm32_x4_v,	   -- imediato extendido e multiplicado por 4
	imm32_v,			-- imediato extendido a 32 bits
	imm32_shift_v,	-- shamt extendido a 32 bits
	aluA_shift_v	-- entrada da ula A, after shift
	: std_logic_vector(31 downto 0);

signal addsht2_v 			 : std_logic_vector(31 downto 0);
signal rset_s, clock_s : std_logic;
signal iwreg_v 			   : std_logic_vector(4 downto 0);  -- indice registador escrito
signal alu_sel_v			 : std_logic_vector(3 downto 0);  -- indice registador escrito
signal sel_aluB_v 		 : std_logic_vector(1 downto 0);	-- seleciona entrada B da ula
signal alu_op_v			   : std_logic_vector(2 downto 0);	-- codigo op ula
signal org_pc_v			   : std_logic_vector(1 downto 0);	-- selecao entrada do PC

signal 	byte_out_v      : std_logic_vector(7 downto 0);
signal 	half_out_v      : std_logic_vector(15 downto 0);
signal 	byte_ext_v      : std_logic_vector(31 downto 0);
signal 	half_ext_v      : std_logic_vector(31 downto 0);
signal 	mdr_mux_sel_v   : std_logic_vector(1 downto 0);
signal 	mdr_in_v 	      : std_logic_vector(31 downto 0);
signal 	wdata_mux_sel_v : std_logic_vector(1 downto 0);
signal 	write_data 	    : std_logic_vector(31 downto 0);

signal
			branch_s,			-- beq ou bne
			is_beq_s,    		-- beq
			is_bne_s,			-- bne
			ir_wr_s,				-- escreve instrucao no ir
			jump_s,				-- instrucao jump
			mem_read_s,			-- leitura memoria
			mem_reg_s,			-- controle dado breg
			mem_wr_s,			-- escrita na memoria
			--ovfl_s,			-- overflow da ULA
			pc_wr_s,				-- escreve pc
			reg_dst_s,			-- controle endereco reg
			reg_wr_s,			-- escreve breg
			sel_end_mem_s,		-- seleciona endereco memoria
			zero_s,				-- sinal zero da ula
			logic_ext_s,		-- extensão lógica com 0s
			sel_aluA_shift_s,	-- seleciona shift
			sel_aluA_s,			-- seleciona entrada A da ula
			is_unsigned_s,	   -- verifica se load é unsigned ou não
			byteena_b_s,		-- flag byte
			byteena_h_s,		-- flag half word
			byteena_w_s			-- word
			: std_logic;


alias    func_field_v  : std_logic_vector(5 downto 0)  is instruction_v(5 downto 0);
alias    rs_field_v	 	 : std_logic_vector(4 downto 0)  is instruction_v(25 downto 21);
alias    rt_field_v	 	 : std_logic_vector(4 downto 0)  is instruction_v(20 downto 16);
alias    rd_field_v	 	 : std_logic_vector(4 downto 0)  is instruction_v(15 downto 11);
alias    imm16_field_v : std_logic_vector(15 downto 0) is instruction_v(15 downto 0);
alias 	imm26_field_v  : std_logic_vector(25 downto 0) is instruction_v(25 downto 0);
alias 	sht_field_v		 : std_logic_vector(4 downto 0)  is instruction_v(10 downto 6);
alias    op_field_v		 : std_logic_vector(5 downto 0)  is instruction_v(31 downto 26);
--lb
alias 	byte0_mem_v 	: std_logic_vector(7 downto 0)  is memout_v(7 downto 0);
alias 	byte1_mem_v 	: std_logic_vector(7 downto 0)  is memout_v(15 downto 8);
alias 	byte2_mem_v 	: std_logic_vector(7 downto 0)  is memout_v(23 downto 16);
alias 	byte3_mem_v 	: std_logic_vector(7 downto 0)  is memout_v(31 downto 24);
--lh
alias 	half0_mem_v 	: std_logic_vector(15 downto 0)  is memout_v(15 downto 0);
alias 	half1_mem_v 	: std_logic_vector(15 downto 0)  is memout_v(31 downto 16);
--sb
signal 	s_byte0_mem_v 	: std_logic_vector(7 downto 0);
signal 	s_byte1_mem_v 	: std_logic_vector(7 downto 0);
signal 	s_byte2_mem_v 	: std_logic_vector(7 downto 0);
signal 	s_byte3_mem_v 	: std_logic_vector(7 downto 0);
--sh
signal 	s_half0_mem_v 	: std_logic_vector(15 downto 0);
signal 	s_half1_mem_v 	: std_logic_vector(15 downto 0);

signal memin_h_v : std_logic_vector(WORD_SIZE-1 downto 0);
signal memin_b_v : std_logic_vector(WORD_SIZE-1 downto 0);
signal byte_clt_out_v : STD_LOGIC_VECTOR (3 DOWNTO 0);

begin

data 			<=  fpga_out;

fpga_out 	<= pcout_v when debug = "00" else
					alu_out_v when debug = "01" else
					instruction_v when debug = "10" else
					memout_v;

pcjump_v 	<= pcout_v(31 downto 28) & imm26_field_v & "00";

pc_wr_s 		<= jump_s or (zero_s and is_beq_s) or ((not zero_s) and is_bne_s);

imm32_x4_v 	<= imm32_v(29 downto 0) & "00";

datadd_v		<= X"000000" & '1' & rULA_out_v(8 downto 2);

pcadd_v		<= X"000000" & pcout_v(9 downto 2);

led_clk <= clk;

--=======================================================================
-- 7 seg
--=======================================================================
--conv1 : convbinario7seg
--		port map (
--			numbinario => fpga_out(3 downto 0),
--			num7seg	  => primeiro_7seg
--		);

--conv2 : convbinario7seg
--		port map (
--			numbinario => fpga_out(7 downto 4),
--			num7seg	  => segundo_7seg
--		);
--conv3 : convbinario7seg
--	port map (
--		numbinario => fpga_out(11 downto 8),
--		num7seg	  => terceiro_7seg
--	);
--conv4 : convbinario7seg
--	port map (
--		numbinario => fpga_out(15 downto 12),
--		num7seg	  => quarto_7seg
--	);
--conv5 : convbinario7seg
--	port map (
--		numbinario => fpga_out(19 downto 16),
--		num7seg	  => quinto_7seg
--	);
--conv6 : convbinario7seg
--	port map (
--		numbinario => fpga_out(23 downto 20),
--		num7seg	  => sexto_7seg
--	);
--conv7 : convbinario7seg
--	port map (
--		numbinario => fpga_out(27 downto 24),
--		num7seg	  => setimo_7seg
--	);
--conv8 : convbinario7seg
--	port map (
--		numbinario => fpga_out(31 downto 28),
--		num7seg	  => oitavo_7seg
--	);



--=======================================================================
-- PC - Contador de programa
--=======================================================================
pc:	reg
		generic map (SIZE => 32)
		port map (sr_in => pcin_v,
		 					sr_out => pcout_v,
							rst => rst,
							clk => clk,
							enable => pc_wr_s);

--=======================================================================
-- mux para enderecamento da memoria
--=======================================================================
mux_mem: mux_2
		port map (
			in0 	=> pcout_v,
			in1 	=> datadd_v,
			sel 	=> sel_end_mem_s,
			m_out => memadd_v
			);

--=======================================================================
-- Memoria do MIPS
--=======================================================================
mem_sel:  byte_ctl
		port map (
			store_ctl => wdata_mux_sel_v,
			a1a0 => rULA_out_v(1 downto 0),
			byteena => byte_clt_out_v
		);


mem:  mips_mem
		port map (address => memadd_v(7 downto 0),
		data => regB_v,
		wren => mem_wr_s,
		clk => clk_rom, Q => memout_v );

--=======================================================================
-- RI - registrador de instruções
--=======================================================================
ir:	reg
		generic map (SIZE => 32)
		port map (sr_in => memout_v,
		sr_out => instruction_v,
		rst => '0',
		clk => clk,
		enable => ir_wr_s );

--=======================================================================
-- RDM - registrador de dados da memoria
--=======================================================================
rdm:	regbuf
		generic map (SIZE => 32)
		port map (sr_in => memout_v, clk => clk, sr_out => rdmout_v);

--=======================================================================
-- Mux para enderecamento do registrador a ser escrito
--=======================================================================
mux_reg_add: mux_2
		generic map (SIZE => 5)
		port map (in0 => rt_field_v,
					 in1 => rd_field_v,
					 sel => reg_dst_s,
					 m_out => iwreg_v);

--=======================================================================
-- Mux de selecao de dado para escrita no banco de registradores
--=======================================================================
breg_data_mux: mux_2
		generic map (SIZE => 32)
		port map (in0 => rULA_out_v,
					 in1 => rdmout_v,
					 sel => mem_reg_s,
					 m_out => regdata_v);

--=======================================================================
-- Banco de registradores
--=======================================================================
bcoreg: breg
		port map (
			clk		=> clk,
			enable	=> reg_wr_s,
			idxA		=> rs_field_v,
			idxB		=> rt_field_v,
			idxwr		=> iwreg_v,
			data_in	=> regdata_v,
			regA 		=> regAin_v,
			regB 		=> regBin_v
			);

--=======================================================================
-- Registrador A
--=======================================================================
rgA:	regbuf
		generic map (SIZE => 32)
		port map (sr_in => regAin_v, clk => clk, sr_out => regA_v);

--=======================================================================
-- Registrador B
--=======================================================================
rgB:	regbuf
		generic map (SIZE => 32)
		port map (sr_in => regBin_v, clk => clk, sr_out => regB_v);

--=======================================================================
-- Modulo de extensao de sinal: 16 para 32 bits
--=======================================================================
sgnx:	extsgn
		port map (
			input => imm16_field_v,
			logic_ext => logic_ext_s,
			output => imm32_v
		);

sgnx_s:	extsgn_shift
		port map (
			input => sht_field_v,
			output => imm32_shift_v
		);
--=======================================================================
-- Mux para selecao da entrada de cima da ula
--=======================================================================
mux_ulaA: mux_2
		port map (
			in0 	=> pcout_v,
			in1 	=> regA_v,
			sel 	=> sel_aluA_s,
			m_out => aluA_v
		);

mux_ulaA_shift: mux_2
		port map (
			in0 	=> aluA_v,
			in1 	=> imm32_shift_v,
			sel 	=> sel_aluA_shift_s,
			m_out => aluA_shift_v
		);

--=======================================================================
-- Mux para selecao da entrada de baixo da ULA
--=======================================================================
mux_ulaB: muxp_4
		port map (
			in0 	=> regB_v,
			in1 	=> INC_PC,
			in2	=> imm32_v,
			in3	=> imm32_x4_v,
			sel 	=> sel_aluB_v,
			m_out => aluB_v
		);

--=======================================================================
-- Modulo de controle da ULA
--=======================================================================
actr: alu_ctr
			port map (
				op_alu 	 => alu_op_v,
				funct	 	 => func_field_v,
				shift_ctr => sel_aluA_shift_s,
				alu_ctr	 => alu_sel_v
			);

--=======================================================================
-- ULA
--=======================================================================
alu:	ulamips
		port map (
			aluctl => alu_sel_v,
			A 		 => aluA_shift_v,
			B		 => aluB_v,
			aluout => alu_out_v,
			zero	 => zero_s
			--ovfl 	 => ovfl_s
		);


--=======================================================================
-- Registrador que armazena a saida da ULA
--=======================================================================
regULA:	regbuf
		generic map (SIZE => 32)
		port map (sr_in => alu_out_v,
		clk => clk, sr_out => rULA_out_v);

--=======================================================================
-- Mux para selecao da entrada do PC
--=======================================================================
mux_pc: mux_3
		port map (
			in0 	=> alu_out_v,
			in1 	=> rULA_out_v,
			in2   => pcjump_v,
			sel 	=> org_pc_v,
			m_out => pcin_v
			);

--=======================================================================
-- Unidade de Controle do MIPS
--=======================================================================
ctr_mips: mips_controle
		port map (
			clk 		=> clk,
			rst 		=> rst,
			opcode 	=> op_field_v,
			wr_ir		=> ir_wr_s,
			wr_pc		=> jump_s,
			wr_mem	=> mem_wr_s,
			is_beq	=> is_beq_s,
			is_bne	=> is_bne_s,
			s_datareg => mem_reg_s,
			op_alu	=> alu_op_v,
			s_mem_add => sel_end_mem_s,
			s_PCin	=> org_pc_v,
			s_aluAin => sel_aluA_s,
			s_aluBin => sel_aluB_v,
			wr_breg	=> reg_wr_s,
			s_reg_add => reg_dst_s,
			logic_ext => logic_ext_s,
			is_unsigned_s => is_unsigned_s,
			mdr_mux_sel_v => mdr_mux_sel_v,
			wdata_mux_sel_v => wdata_mux_sel_v
		);

mux_byte : mux_4_byte
	port map (
		in0 	=> byte0_mem_v,
		in1 	=> byte1_mem_v,
		in2	=> byte2_mem_v,
		in3	=> byte3_mem_v,
		sel 	=> rULA_out_v(1 downto 0),
		m_out => byte_out_v
	);

extsgn_byte: extsgn8
	port map(
		input => byte_out_v,
		logic_ext => is_unsigned_s,
		output => byte_ext_v
	);

mux_half: mux_2_half
	port map (
		in0		=> half0_mem_v,
		in1	   => half1_mem_v,
		sel		=> rULA_out_v(1),
		m_out		=> half_out_v
	);

extsgn_half: extsgn
	port map (
		input => half_out_v,
		logic_ext => is_unsigned_s,
		output => half_ext_v
	);

mux_mdr: mux_3
	port map(
		in0		=> memout_v,
		in1	   => half_ext_v,
		in2		=> byte_ext_v,
		sel		=> mdr_mux_sel_v,
		m_out		=> mdr_in_v
	);

demux_sb: demux4
	port map (
		in0 	=> regB_v,
		sel 	=> rULA_out_v(1 downto 0),
		out0	=> s_byte0_mem_v,
		out1	=> s_byte1_mem_v,
		out2	=> s_byte2_mem_v,
		out3	=> s_byte3_mem_v
		);

demux_sh: demux2
	port map (
		in0	=> regB_v,
		sel 	=> rULA_out_v(1),
		out0	=> s_half0_mem_v,
		out1	=> s_half1_mem_v
		);
memin_h_v <= s_half1_mem_v & s_half0_mem_v;
memin_b_v <= s_byte3_mem_v & s_byte2_mem_v & s_byte1_mem_v & s_byte0_mem_v;

mux_store: mux_3
	port map (
		in0   => regB_v,
		in1 	=> memin_h_v,
		in2 	=> memin_b_v,
		sel 	=> wdata_mux_sel_v,
		m_out => write_data
		);

end architecture;
