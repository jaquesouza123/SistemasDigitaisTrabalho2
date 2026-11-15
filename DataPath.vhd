library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.ExponentialSearch_pkg.all;

entity DataPath is
    generic (
        DATA_WIDTH  : integer := 8;
        ADDR_WIDTH  : integer := 8
    );
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        data        : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        A           : in std_logic_vector(DATA_WIDTH - 1 downto 0); 
        cmd         : in Command; -- ordens que o Control Path dá para o Datapath
        sts         : out Status; -- respostas que o Datapath dá para o Control Path
        addr        : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
        pos         : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end DataPath;

architecture structural of DataPath is

    -- saídas dos registradores
    signal regBase, regLen, regKey, regI : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal regLeft, regRight, regMid     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal regAddr, regPos               : std_logic_vector(DATA_WIDTH - 1 downto 0);

    -- entradas dos registradores
    signal in_i, in_left, in_right, in_pos : std_logic_vector(DATA_WIDTH - 1 downto 0);

    -- splitters
    signal i_mult      : std_logic_vector(DATA_WIDTH - 1 downto 0); -- i * 2 
    signal i_div       : std_logic_vector(DATA_WIDTH - 1 downto 0); -- i / 2
    signal add2_div    : std_logic_vector(DATA_WIDTH - 1 downto 0); -- left + right /2

    -- sinais dos muxes e somadores
    signal sx1          : std_logic_vector(2 downto 0);
    signal sy1          : std_logic_vector(1 downto 0);
    signal sy2          : std_logic_vector(1 downto 0);
    signal x1_out, y1_out, y1_xor : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal x2_out, y2_out         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal add1_out, add2_out     : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin
    -- instâncias dos registradores
    U_REG_BASE: entity work.RegisterNbits generic map(WIDTH => DATA_WIDTH)
        port map(clock => clk,
                 reset => rst,
                 ce => cmd.ld_base,
                 d => data,
                 q => regBase);

    U_REG_LEN: entity work.RegisterNbits generic map(WIDTH => DATA_WIDTH)
        port map(clock => clk,
                 reset => rst,
                 ce => cmd.ld_len,
                 d => data,
                 q => regLen);

    U_REG_KEY: entity work.RegisterNbits generic map(WIDTH => DATA_WIDTH)
        port map(clock => clk,
                 reset => rst, 
                 ce => cmd.ld_key,
                 d => data,
                 q => regKey);

    U_REG_I: entity work.RegisterNbits generic map(WIDTH => DATA_WIDTH)
        port map(clock => clk,
                 reset => rst,
                 ce => cmd.ld_i,
                 d => in_i,
                 q => regI);

    U_REG_LEFT: entity work.RegisterNbits generic map(WIDTH => DATA_WIDTH)
        port map(clock => clk,
                 reset => rst,
                 ce => cmd.ld_left,
                 d => in_left,
                 q => regLeft);

    U_REG_RIGHT: entity work.RegisterNbits generic map(WIDTH => DATA_WIDTH)
        port map(clock => clk,
                 reset => rst,
                 ce => cmd.ld_right,
                 d => in_right,
                 q => regRight);

    U_REG_MID: entity work.RegisterNbits generic map(WIDTH => DATA_WIDTH)
        port map(clock => clk,
                 reset => rst, 
                 ce => cmd.ld_mid,
                 d => add2_div,
                 q => regMid);

    U_REG_ADDR: entity work.RegisterNbits generic map(WIDTH => ADDR_WIDTH)
        port map(clock => clk,
                 reset => rst,
                 ce => cmd.ld_addr,
                 d => add2_out,
                 q => regAddr);

    U_REG_POS: entity work.RegisterNbits generic map(WIDTH => DATA_WIDTH)
        port map(clock => clk,
                 reset => rst,
                 ce => cmd.ld_pos, 
                 d => in_pos,
                 q => regPos);

    -- deslocadores de bits
    i_mult   <= regI(DATA_WIDTH - 2 downto 0) & '0';
    i_div    <= '0' & regI(DATA_WIDTH - 1 downto 1);
    add2_div <= '0' & add2_out(DATA_WIDTH - 1 downto 1);

    -- multiplexadores de entrada dos registradores
    in_i     <= x"01"   when cmd.sel_i = '0'     else i_mult;
    in_left  <= i_div  when cmd.sel_left = '0'  else add1_out;
    in_right <= regI    when cmd.sel_right = '0' else add1_out;
    in_pos  <= regMid when cmd.sel_pos  = '0' else x"ff";  

    -- agrupamento dos seletores dos muxes principais
    sx1 <= cmd.sx1_2 & cmd.sx1_1 & cmd.sx1_0;
    sy1 <= cmd.sy1_1 & cmd.sy1_0;
    sy2 <= cmd.sy2_1 & cmd.sy2_0;

    -- mux X1 
    with sx1 select x1_out <=
        regLen   when "000",
        regI     when "001", 
        A        when "010",
        regRight when "011",
        regMid   when "100",
        (others => '0') when others;

    -- mux y1 
    with sy1 select y1_out <=
        x"01"    when "00",
        regLen   when "01",
        regKey   when "10",
        regLeft  when others;

 
    y1_xor <= y1_out xor (DATA_WIDTH - 1 downto 0 => cmd.sub1);

    -- somador ADD1 
    U_ADD1: entity work.Adder_nbits generic map(WIDTH => DATA_WIDTH)
        port map(
            a    => x1_out,
            b    => y1_xor,
            cin  => cmd.sub1,
            sum  => add1_out,
            cout => open
        );

    -- mux X2
    x2_out <= regBase when cmd.sx2 = '0' else regLeft;

    -- mux Y2
    with sy2 select y2_out <=
        regI     when "00",
        regMid   when "01",
        regRight when "10",
        (others => '0') when others;

    -- somador ADD2
    U_ADD2: entity work.Adder_nbits generic map(WIDTH => DATA_WIDTH)
        port map(
            a    => x2_out,
            b    => y2_out,
            cin  => '0',
            sum  => add2_out,
            cout => open
        );

    -- sinais de status
    sts.neg  <= add1_out(DATA_WIDTH - 1);
    sts.zero <= '1' when add1_out = (DATA_WIDTH - 1 downto 0 => '0') else '0';

    -- saídas do datapath
    addr <= regAddr;
    pos  <= regPos;

end structural;