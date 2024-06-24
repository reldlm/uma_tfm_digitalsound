----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Rodrigo Espejo López de los Mozos
-- 
-- Create Date: 10.02.2024 11:26:02
-- Design Name: 
-- Module Name: tfm_i2s_transceiver - Behavioral
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

-- Instance template
--    i2s_transceiver : entity WORK.tfm_i2s_transceiver
--        generic map(
--            d_width => d_width,
--            sysclk_mclk_ratio => sysclk_mclk_ratio,
--            mclk_sclk_ratio => mclk_ws_ratio/(2*d_width),
--            sclk_ws_ratio => 2*d_width
--        )
--        port map(
--            sysclk => sysclk,
--            reset => grst,
--            mclk => mclk_int,
--            sclk => sclk_int,
--            ws => ws_int,
--            sd_tx => sd_tx,
--            sd_rx => sd_rx,
--            l_rx => l_rx_int,
--            r_rx => r_rx_int,
--            l_tx => l_tx_int,
--            r_tx => r_tx_int,
--            l_rx_valid => l_rx_valid,
--            r_rx_valid => r_rx_valid
--        );

entity tfm_i2s_transceiver is
  Generic(
    d_width : INTEGER :=24;
    sysclk_mclk_ratio : INTEGER := 6;
    mclk_sclk_ratio : INTEGER := 8;     -- (mclk/ws)/(d_width*2)
    sclk_ws_ratio : INTEGER := 48       -- d_width*2
  );
  Port (
    sysclk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    mclk : OUT STD_LOGIC;
    sclk : OUT STD_LOGIC;
    ws : OUT STD_LOGIC;
    sd_tx : OUT STD_LOGIC;
    sd_rx : IN STD_LOGIC;
    l_rx : OUT STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
    r_rx : OUT STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
    l_tx : IN STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
    r_tx : IN STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
    l_rx_valid : OUT STD_LOGIC;
    r_rx_valid : OUT STD_LOGIC
  );

end tfm_i2s_transceiver;

architecture Behavioral of tfm_i2s_transceiver is
    -- i2s clock signals
    signal mclk_int : STD_LOGIC := '0';
    signal sclk_int : STD_LOGIC := '0';
    signal ws_int : STD_LOGIC := '0';
    
    -- Counters
    signal mclk_counter : NATURAL range 0 to (sysclk_mclk_ratio/2 -1) := 0;
    signal sclk_counter : NATURAL range 0 to (mclk_sclk_ratio/2 -1) := 0;
    signal ws_counter : NATURAL range 0 to (sclk_ws_ratio/2 -1) := 0;
    
    -- Aux signals
    signal l_rx_int : STD_LOGIC_VECTOR (d_width-1 downto 0);
    signal r_rx_int : STD_LOGIC_VECTOR (d_width-1 downto 0);
    signal l_tx_int : STD_LOGIC_VECTOR (d_width-1 downto 0);
    signal r_tx_int : STD_LOGIC_VECTOR (d_width-1 downto 0);
    
    -- Debugging signals
--    signal test_counter : NATURAL := 0;
begin
    -- Sync process for generating the clocks
    process(sysclk, reset)
    begin
        if(reset = '1') then
            mclk_counter <= 0;    
            
        -- mclk
        elsif (sysclk'event and sysclk = '0') then          --falling edge sysclk
            if(mclk_counter = sysclk_mclk_ratio/2 -1) then
                mclk_int <= not(mclk_int);
                mclk_counter <= 0;
                
                -- sclk
                if(mclk_int = '1') then                     --falling edge mclk
                    if(sclk_counter = mclk_sclk_ratio/2 -1) then
                        sclk_int <= not(sclk_int);
                        sclk_counter <= 0;
                        
                        -- ws
                        if(sclk_int = '1') then         -- falling edge sclk (clock data OUT)
                            if(ws_counter = sclk_ws_ratio/2 -1) then
                                ws_int <= not(ws_int);
                                ws_counter <= 0;
                            else
                                ws_counter <= ws_counter + 1;
                            end if;
                            if(ws_int = '1') then           -- right channel out
                                sd_tx <= r_tx_int(d_width-1);     
                                r_tx_int <= r_tx_int(d_width-2 downto 0) & '0';
                            else                            -- left channel out
                                sd_tx <= l_tx_int(d_width-1);     
                                l_tx_int <= l_tx_int(d_width-2 downto 0) & '0';    
                            end if;
                            if(ws_counter = 0) then         -- complete package has been received
                                if(ws_int = '1') then       -- left package complete
                                    l_rx <= l_rx_int;
                                else                        -- right package complete
                                    r_rx <= r_rx_int;   
                                end if;                            
                            end if;
                        else                            -- rising edge sclk (clock data IN)
                            if(ws_counter = 0) then         -- LSB IN
                                if(ws_int = '1') then       -- LSB of left channel IN
                                    l_rx_int <= l_rx_int(d_width-2 downto 0) & sd_rx;
                                    r_tx_int <= r_tx;       -- Latch next right channel OUT
                                else                        -- LSB of right channel IN
                                    r_rx_int <= r_rx_int(d_width-2 downto 0) & sd_rx;
                                    l_tx_int <= l_tx;       -- Latch next left channel OUT
                                end if;
                            else
                                if(ws_int = '1') then       -- right channel IN
                                    r_rx_int <= r_rx_int(d_width-2 downto 0) & sd_rx;   
                                else                        -- left channel IN
                                    l_rx_int <= l_rx_int(d_width-2 downto 0) & sd_rx;   
                                end if;    
                            end if;
                        end if;
                    else
                        sclk_counter <= sclk_counter + 1;        
                    end if;
                end if;
            else
                mclk_counter <= mclk_counter + 1;    
            end if; 
        end if;            
    end process;
    
    -- I2S clock signals
    mclk <= mclk_int;
    sclk <= sclk_int;
    ws <= ws_int;
    
    -- RX valid signals
    l_rx_valid <= '1' when (mclk_int = '0' and mclk_counter = 0 and sclk_int = '0' and sclk_counter = 0 and ws_int = '1' and ws_counter = 1) else '0';
    r_rx_valid <= '1' when (mclk_int = '0' and mclk_counter = 0 and sclk_int = '1' and sclk_counter = 0 and ws_counter = 1 and ws_int = '0') else '0';
    
end Behavioral;
