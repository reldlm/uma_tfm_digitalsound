----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Rodrigo Espejo López de los Mozos
-- 
-- Create Date: 27.02.2024 18:31:05
-- Design Name: 
-- Module Name: one_hot_encoder - Behavioral
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
--    onehot_encoder : entity WORK.one_hot_encoder
--    generic map(
--        n_rams => n_rams
--    )
--    port map(
--        ramID =>ramID_signal,
--        write_enable =>write_enable
--    );

entity one_hot_encoder is
    Generic (
        n_rams : INTEGER := 2
    );
    Port ( 
        ramID : in NATURAL;
        write_enable : out STD_LOGIC_VECTOR(n_rams-1 downto 0)
    );
end one_hot_encoder;

architecture Behavioral of one_hot_encoder is

begin
    process(ramID)
    begin
        write_enable <= (others => '0');    
        if (ramID <= n_rams) then
            write_enable(ramID) <= '1';    
        else
            report "Error. The ramID is bigger than the ouput value";
        end if;
    end process;
    
end Behavioral;
