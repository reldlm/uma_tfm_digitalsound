----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Rodrigo Espejo López de los Mozos
-- 
-- Create Date: 10.05.2024 20:11:06
-- Design Name: 
-- Module Name: tfm_top_processor - Behavioral
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
--    tfm_top_processor : entity WORK.tfm_top_processor
--        generic map(
--            bits => bits,
--            d_width => d_width,
--            ir_d_width => ir_d_width,
--            n_rams => n_rams
--        )
--        port map (
--            sysclk => sysclk,
--            reset => grst,
--            bypass => bypass,
--            l_rx => l_rx_int,
--            r_rx => r_rx_int,
--            l_tx => l_tx_int,
--            r_tx => r_tx_int,
--            l_rx_valid => l_rx_valid,
--            r_rx_valid => r_rx_valid
--        );

entity tfm_top_processor is
    Generic (
        bits : INTEGER := 2;
        d_width : INTEGER := 24;
        ir_d_width : INTEGER := 16;
        n_rams : INTEGER := 2
    );
    Port ( sysclk : in STD_LOGIC;
           reset : in STD_LOGIC;
           bypass : in STD_LOGIC;
           l_rx : in STD_LOGIC_VECTOR (d_width - 1 downto 0);
           r_rx : in STD_LOGIC_VECTOR (d_width - 1 downto 0);
           l_tx : out STD_LOGIC_VECTOR (d_width - 1 downto 0);
           r_tx : out STD_LOGIC_VECTOR (d_width - 1 downto 0);
           l_rx_valid : in STD_LOGIC;
           r_rx_valid : in STD_LOGIC);
end tfm_top_processor;

architecture Behavioral of tfm_top_processor is
    signal start_tick : STD_LOGIC;
    signal shift_tick : STD_LOGIC;
    signal sample_done_tick : STD_LOGIC;
    signal ir_done_tick : STD_LOGIC;
    
    signal sample_input : STD_LOGIC_VECTOR (d_width - 1 downto 0);
    signal sample_ouput : STD_LOGIC_VECTOR ((d_width*n_rams)-1 downto 0);
    signal ir_output : STD_LOGIC_VECTOR ((ir_d_width*n_rams)-1 downto 0);
    signal dsp_output : STD_LOGIC_VECTOR (d_width - 1 downto 0);
    
    signal ramID : NATURAL range 0 to n_rams-1;
begin
    -- Signals mapping
    sample_input <= l_rx;
    start_tick <= l_rx_valid;
    
    -- Effect bypass
    process(bypass, dsp_output, l_rx)
    begin
        if bypass = '1' then
            l_tx <= dsp_output;
        else
            l_tx <= l_rx;
        end if;
    end process;
        
    -- Right channel processing
    right_channel_process : process(sysclk)
    begin
        if(rising_edge(sysclk)) then
            if(reset = '1') then
                r_tx <= (others => '0');
            elsif(r_rx_valid = '1') then
                r_tx <= r_rx;
            end if;
        end if;    
    end process;

    -- DSP Processor
    tfm_dsp_processor : entity WORK.tfm_dsp_processor
        generic map(
            bits => bits,
            d_width => d_width,
            ir_d_width => ir_d_width,
            n_rams => n_rams
        )
        port map(
            sysclk => sysclk,
            reset => reset,
            start_tick => start_tick,
            shift_tick => shift_tick,
            done_tick => sample_done_tick,
            ramID => ramID,
            samplein => sample_ouput,
            coeffin => ir_output,
            dout => dsp_output
        );
    
    -- Samples ring FIFO buffer
    tfm_ring_fifo_buffer : entity WORK.tfm_ring_fifo_buffer
        generic map (
            bits => bits,
            d_width => d_width,
            n_rams => n_rams
        )
        port map (
            sysclk => sysclk,
            reset => reset,
            din => sample_input,
            push => start_tick,
            read_done_tick => sample_done_tick,
            shift_tick => shift_tick,
            ramID => ramID,
            dout => sample_ouput    
        );
    
    --- IR buffer
    tfm_ir_coeff_buffer : entity WORK.tfm_ir_coeff_buffer
        generic map (
            bits => bits,
            ir_d_width => ir_d_width,
            n_rams => n_rams
        )
        port map (
            sysclk => sysclk,
            reset => reset,
            start_tick => start_tick,
            done_tick => ir_done_tick,
            dout => ir_output
        );
end Behavioral;
