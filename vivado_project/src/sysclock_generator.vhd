----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Rodrigo Espejo López de los Mozos
-- 
-- Create Date: 09.02.2024 19:16:47
-- Design Name: 
-- Module Name: sysclock_generator - Behavioral
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
--    sysclk_gen : entity WORK.sysclock_generator
--        generic map (
--            sampling_freq => sampling_freq
--        )
--        port map (
--            osc_in => clock,
--            reset => reset,
--            sysclk => sysclk,
--            grst => grst
--        );

entity sysclock_generator is
    Generic (
        sampling_freq : NATURAL := 44
    );
    Port ( osc_in : in STD_LOGIC;
           reset : in STD_LOGIC;
           sysclk : out STD_LOGIC;
           grst : out STD_LOGIC);
end sysclock_generator;

architecture Behavioral of sysclock_generator is
    -- Possible sysclck signals
    signal sysclk_44_1kHz : STD_LOGIC;
    signal sysclk_48kHz : STD_LOGIC;
    signal sysclk_96kHz : STD_LOGIC;
    
    -- Signal for clocking wizard
    signal locked : STD_LOGIC;
    
begin
    
    -- Clocking wizard
    clk_wiz : entity WORK.clk_wiz_0
    port map ( 
    -- Clock out ports  
    clk_44_1_kHz => sysclk_44_1kHz,
    clk_48_kHz => sysclk_48kHz,
    clk_96_kHz => sysclk_96kHz,
    -- Status and control signals                
    reset => reset,
    locked => locked,
    -- Clock in ports
    clk_in1 => osc_in
    );
    
    -- GRST signal
    grst <= not(locked);
    
    with sampling_freq select
        sysclk <= sysclk_44_1kHz when 44,
        sysclk_48kHz when 48,
        sysclk_96kHz when others;

end Behavioral;
