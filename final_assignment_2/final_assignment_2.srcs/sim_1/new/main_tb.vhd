----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/05/2024 10:34:48 PM
-- Design Name: 
-- Module Name: test - Behavioral
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
use IEEE.std_logic_unsigned.all;
use ieee.NUMERIC_STD.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main_tb is
end main_tb;

architecture Behavioral of main_tb is


component main is
    Port ( clk : in STD_LOGIC;
           j4 : in STD_LOGIC_VECTOR (1 downto 0);
           LED_out : out STD_LOGIC_VECTOR (7 downto 0);
           Anode_Activate : out STD_LOGIC_VECTOR (7 downto 0);
           LED_rgb : out STD_LOGIC_VECTOR (3 downto 0);
           reset : in STD_LOGIC
         );
end component;


component xadc_wiz_0 is
    port
(
       daddr_in        : in  STD_LOGIC_VECTOR (6 downto 0);     -- Address bus for the dynamic reconfiguration port
       den_in          : in  STD_LOGIC;                         -- Enable Signal for the dynamic reconfiguration port
       di_in           : in  STD_LOGIC_VECTOR (15 downto 0);    -- Input data bus for the dynamic reconfiguration port
       dwe_in          : in  STD_LOGIC;                         -- Write Enable for the dynamic reconfiguration port
       do_out          : out  STD_LOGIC_VECTOR (15 downto 0);   -- Output data bus for dynamic reconfiguration port
       drdy_out        : out  STD_LOGIC;                        -- Data ready signal for the dynamic reconfiguration port
       dclk_in         : in  STD_LOGIC;                         -- Clock input for the dynamic reconfiguration port
       reset_in        : in  STD_LOGIC;                         -- Reset signal for the System Monitor control logic
       vauxp10         : in  STD_LOGIC;                         -- Auxiliary Channel 10
       vauxn10         : in  STD_LOGIC;
       busy_out        : out  STD_LOGIC;                        -- ADC Busy signal
       channel_out     : out  STD_LOGIC_VECTOR (4 downto 0);    -- Channel Selection Outputs
       eoc_out         : out  STD_LOGIC;                        -- End of Conversion Signal
       eos_out         : out  STD_LOGIC;                        -- End of Sequence Signal
       alarm_out       : out STD_LOGIC;                         -- OR'ed output of all the Alarms
       vp_in           : in  STD_LOGIC;                         -- Dedicated Analog Input Pair
       vn_in           : in  STD_LOGIC
   );
end component;

component binary_to_bcd is
    generic(N: positive := 12);
    port(
        clk, reset: in std_logic;
        binary_in: in std_logic_vector(N-1 downto 0);
        bcd_output: out std_logic_vector(15 downto 0)
    );
end component;
    
signal clk_tb, vp, vn : std_logic;
signal LED_out_tb: STD_LOGIC_VECTOR (7 downto 0);
constant clock_period_tb: time := 10 ns;
signal ADCValidData : std_logic_vector(11 downto 0);
signal do : std_logic_vector(15 downto 0);
signal ADCValidData_divided_tb : std_logic_vector(11 downto 0);
signal bcd_output_tb : std_logic_vector(15 downto 0);
signal LED_rgb_tb : std_logic_vector(3 downto 0);
signal Anode_Activate_tb: STD_LOGIC_VECTOR (7 downto 0);
signal ADCNonValidData : std_logic_vector(3 downto 0);
signal EnableInt : std_logic := '1';
signal reset_tb : std_logic := '0';
signal eight: STD_LOGIC_VECTOR (11 downto 0):= "000000001000";
begin
dut1 : xadc_wiz_0 port map
(
    daddr_in        => "0011010",           -- 10th drp port address is 0x1A
    den_in          => EnableInt,           -- set enable drp port
    di_in           => (others => '0'),     -- set input data as 0 
    dwe_in          => '0',                 -- disable write to drp
    do_out    => do, -- because we use unipolar xadc
    drdy_out        => open,                    
    dclk_in         => clk_tb,           -- 125 Mhz system clock wires to drp
    reset_in        => '0',
    vauxp10         => vp,               -- xadc positive pin                                      
    vauxn10         => vn,               -- xadc negative pin
    busy_out        => open,                   
    channel_out    => open,    
    eoc_out         => EnableInt,          -- enable int                   
    eos_out         => open,                      
    alarm_out       => open,                         
    vp_in           => '0',                        
    vn_in           => '0'
);  

ADCValidData <= do(15 downto 4);
ADCNonValidData <= do(3 downto 0);
      
clk_process: process
begin
        clk_tb <= '0';
        wait for 10 ns; 
        clk_tb <= '1';
        wait for 10 ns;
end process;
vp<='0';
vn<='0';


dut2: entity work.main(Behavioral)
    port map(
         clk => clk_tb,
         reset => reset_tb,
         j4(0) => '0',
         j4(1) => '0',
         LED_rgb => LED_rgb_tb,
         Anode_Activate => Anode_Activate_tb,
         LED_out => LED_out_tb
         );
Divide_by_8: process(ADCValidData)
             begin
        ADCValidData_divided_tb <=std_logic_vector(to_unsigned(to_integer(unsigned(ADCValidData)) / to_integer(unsigned(eight)),12));
             
             end process;
dut3: entity work.binary_to_bcd(rtl)
    generic map(N => 12)
    port map(
        clk => clk_tb,
        reset => reset_tb,
        binary_in => ADCValidData_divided_tb,
        bcd_output => bcd_output_tb
);
end Behavioral;
