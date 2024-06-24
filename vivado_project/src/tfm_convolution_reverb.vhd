----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Rodrigo Espejo López de los Mozos
-- 
-- Create Date: 10.05.2024 20:03:42
-- Design Name: 
-- Module Name: tfm_convolution_reverb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tfm_convolution_reverb is
    Generic (
        bits : INTEGER := 10;                -- Size of the memory blocks = 2^(bits)
        d_width : INTEGER := 24;            -- Bit depth of the sampling (16, 24, 32 bits)
        ir_d_width : INTEGER := 16;         -- Bit depth of the IR
        n_rams : INTEGER := 32;              -- Number of memory blocks
        sampling_freq : NATURAL := 44;      -- Sampling frequency (44.1kHz , 48kHz, 96kHz)
        sysclk_mclk_ratio : INTEGER := 6;   -- SYSCLK/MCLK ratio
        mclk_ws_ratio : NATURAL := 384      -- MCLK/WS ratio    
    );
    Port ( clock : in STD_LOGIC;
           reset : in STD_LOGIC;
           bypass : in STD_LOGIC;
           mclk : out STD_LOGIC_VECTOR (1 downto 0);
           sclk : out STD_LOGIC_VECTOR (1 downto 0);
           ws : out STD_LOGIC_VECTOR (1 downto 0);
           sd_rx : in STD_LOGIC;
           sd_tx : out STD_LOGIC
    );
end tfm_convolution_reverb;

architecture Behavioral of tfm_convolution_reverb is
    -- Clocking signals
    signal sysclk : STD_LOGIC;
    signal mclk_int : STD_LOGIC;
    signal sclk_int : STD_LOGIC;
    signal ws_int : STD_LOGIC;
    
    -- Global reset
    signal grst : STD_LOGIC;
    
    -- RX valid signals
    signal l_rx_valid : STD_LOGIC;
    signal r_rx_valid : STD_LOGIC;
    
    -- Aux signals
    signal l_rx_int : STD_LOGIC_VECTOR (d_width-1 downto 0);
    signal r_rx_int : STD_LOGIC_VECTOR (d_width-1 downto 0);
    signal l_tx_int : STD_LOGIC_VECTOR (d_width-1 downto 0);
    signal r_tx_int : STD_LOGIC_VECTOR (d_width-1 downto 0);
begin
    -- SYSCLK generator
    sysclk_gen : entity WORK.sysclock_generator
        generic map (
            sampling_freq => sampling_freq
        )
        port map (
            osc_in => clock,
            reset => reset,
            sysclk => sysclk,
            grst => grst
        );
        
    -- I2S transceiver
    i2s_transceiver : entity WORK.tfm_i2s_transceiver
        generic map(
            d_width => d_width,
            sysclk_mclk_ratio => sysclk_mclk_ratio,
            mclk_sclk_ratio => mclk_ws_ratio/(2*d_width),
            sclk_ws_ratio => 2*d_width
        )
        port map(
            sysclk => sysclk,
            reset => grst,
            mclk => mclk_int,
            sclk => sclk_int,
            ws => ws_int,
            sd_tx => sd_tx,
            sd_rx => sd_rx,
            l_rx => l_rx_int,
            r_rx => r_rx_int,
            l_tx => l_tx_int,
            r_tx => r_tx_int,
            l_rx_valid => l_rx_valid,
            r_rx_valid => r_rx_valid
        );
        
    -- I2S clocks assignation
    mclk(0) <= mclk_int;
    mclk(1) <= mclk_int;
    sclk(0) <= sclk_int;
    sclk(1) <= sclk_int;
    ws(0) <= ws_int;
    ws(1) <= ws_int;
    
    -- Processor
    tfm_top_processor : entity WORK.tfm_top_processor
        generic map(
            bits => bits,
            d_width => d_width,
            ir_d_width => ir_d_width,
            n_rams => n_rams
        )
        port map (
            sysclk => sysclk,
            reset => grst,
            bypass => bypass,
            l_rx => l_rx_int,
            r_rx => r_rx_int,
            l_tx => l_tx_int,
            r_tx => r_tx_int,
            l_rx_valid => l_rx_valid,
            r_rx_valid => r_rx_valid
        );

end Behavioral;
