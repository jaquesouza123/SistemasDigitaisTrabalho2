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

    -- Sinais da Arquitetura 1 (Structural)
    signal pos1         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal done1        : std_logic;
    signal addr1        : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal mem1_data_in : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal mem1_data_out: std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal sel1, ld1    : std_logic;

    -- Sinais da Arquitetura 2 (Behavioral)
    signal pos2         : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal done2        : std_logic;
    signal addr2        : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    signal mem2_data_in : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal mem2_data_out: std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal sel2, ld2    : std_logic;

begin

    -- Instância 1: Estrutural + Comportamental
    PROC_STR: entity work.ExponentialSearch(structural)
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

    -- Instância 2: Totalmente Comportamental
    PROC_BEH: entity work.ExponentialSearch(behavioral)
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

    -- Geração de Clock e Reset
    rst <= '1', '0' after 15 ns;
    clk <= not clk after 20 ns;

    -- Estímulos de Teste (Base, Len, Key)
    process
    begin
        data_av <= '0';
        data    <= (others => '0');

        wait until rst = '0';
        wait until rising_edge(clk);

        -- Inicia busca
        data_av <= '1';
        wait until rising_edge(clk);
        data_av <= '0';

        -- Ciclo S1: Envia Base (ex: endereço 0)
        data <= x"00";
        wait until rising_edge(clk);

        -- Ciclo S2: Envia Len (ex: tamanho 11 = 0x0B)
        data <= x"0B";
        wait until rising_edge(clk);

        -- Ciclo S3: Envia Key (ex: valor procurado 0x05)
        data <= x"05";
        wait until rising_edge(clk);

        -- Aguarda conclusão de ambos
        wait until done1 = '1' and done2 = '1';
        wait;
    end process;

end behavioral;