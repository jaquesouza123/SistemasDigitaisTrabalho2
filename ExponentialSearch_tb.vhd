library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ExponentialSearch_tb is
end ExponentialSearch_tb;

architecture behavioral of ExponentialSearch_tb is

    constant DATA_WIDTH : integer := 8;
    constant ADDR_WIDTH : integer := 8;

    signal clk          : std_logic := '0';
    signal rst          : std_logic;
    signal data_av      : std_logic;
    signal data         : std_logic_vector(DATA_WIDTH - 1 downto 0);

    -- sinais da arquitetura comportamental + estrutural
    signal pos1         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal done1        : std_logic;
    signal addr1        : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal mem1_data_in : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal mem1_data_out: std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal sel1, ld1    : std_logic;

    -- sinais da totalmente comportamental
    signal pos2         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal done2        : std_logic;
    signal addr2        : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal mem2_data_in : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal mem2_data_out: std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal sel2, ld2    : std_logic;

begin

    -- instância: estrutural + comportamental
    COMP_ESTR: entity work.ExponentialSearch(structural)
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk      => clk,
            rst      => rst,
            data_av  => data_av,
            data     => data,
            pos      => pos1,
            done     => done1,
            addr     => addr1,
            data_in  => mem1_data_out,
            data_out => mem1_data_in,
            sel      => sel1,
            ld       => ld1
         
        );

    RAM1: entity work.Memory
        generic map (
            DATA_WIDTH    => DATA_WIDTH,
            ADDR_WIDTH    => ADDR_WIDTH,
            imageFileName => "image.txt"
        )
        port map (
            clk      => clk,
            ce       => sel1,
            wr       => ld1,
            data_in  => mem1_data_in,
            data_out => mem1_data_out,
            address  => addr1
        );

    -- instância 2: totalmente comportamental
    TOTAL_COMP: entity work.ExponentialSearch(behavioral)
        generic map (
            DATA_WIDTH => DATA_WIDTH,
            ADDR_WIDTH => ADDR_WIDTH
        )
        port map (
            clk      => clk,
            rst      => rst,
            data_av  => data_av,
            data     => data,
            pos      => pos2,
            done     => done2,
            addr     => addr2,
            data_in  => mem2_data_out,
            data_out => mem2_data_in,
            sel      => sel2,
            ld       => ld2
        );

    RAM2: entity work.Memory
        generic map (
            DATA_WIDTH    => DATA_WIDTH,
            ADDR_WIDTH    => ADDR_WIDTH,
            imageFileName => "image.txt"
        )
        port map (
            clk      => clk,
            ce       => sel2,
            wr       => ld2,
            data_in  => mem2_data_in,
            data_out => mem2_data_out,
            address  => addr2
        );

    -- gerar clock e reset
    rst <= '1', '0' after 15 ns;
    clk <= not clk after 20 ns;

    
process
begin
    data_av <= '0';
    data    <= (others => '0');
    wait until rst = '0';
    wait until rising_edge(clk);

    data <= x"00"; data_av <= '1';   -- base = 0
    wait until rising_edge(clk);
    data <= x"0b";                   -- tamanho = 11
    wait until rising_edge(clk);
    data <= x"06";                   -- key = 06
    wait until rising_edge(clk);
    data_av <= '0';
    --saída esperada: pos = 03
    wait until done1 = '1';
    wait;
end process;
end behavioral;