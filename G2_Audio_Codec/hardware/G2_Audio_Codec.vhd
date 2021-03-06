-- Kyle O'Shaughnessy, Nancy Minderman
-- koshaugh@ualberta.ca, nancy.minderman@ualberta.ca

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.VITAL_Primitives.all;
use work.DE2_CONSTANTS.all;

entity G2_Audio_Codec is port
(
   -- SDRAM
   DRAM_ADDR   :  out   DE2_SDRAM_ADDR_BUS;
   DRAM_BA_0   :  out   std_logic;
   DRAM_BA_1   :  out   std_logic;
   DRAM_CAS_N  :  out   std_logic;
   DRAM_CKE    :  out   std_logic;
   DRAM_CLK    :  out   std_logic;
   DRAM_CS_N   :  out   std_logic;
   DRAM_DQ     :  inout DE2_SDRAM_DATA_BUS;
   DRAM_LDQM   :  out   std_logic;
   DRAM_UDQM   :  out   std_logic;
   DRAM_RAS_N  :  out   std_logic;
   DRAM_WE_N   :  out   std_logic;

   -- SRAM
   SRAM_ADDR   :  out   DE2_SRAM_ADDR_BUS;
   SRAM_DQ     :  inout DE2_SRAM_DATA_BUS;
   SRAM_WE_N   :  out   std_logic;
   SRAM_OE_N   :  out   std_logic;
   SRAM_UB_N   :  out   std_logic;
   SRAM_LB_N   :  out   std_logic;
   SRAM_CE_N   :  out   std_logic;

   -- FLASH (non-volatile program flashing)
   FL_ADDR     :  out   DE2_FL_ADDR_BUS;
   FL_CE_N     :  out   std_logic_vector (0 downto 0);
   FL_OE_N     :  out   std_logic_vector (0 downto 0);
   FL_DQ       :  inout DE2_FL_DQ_BUS;
   FL_RST_N    :  out   std_logic_vector (0 downto 0) := (others => '1');
   FL_WE_N     :  out   std_logic_vector (0 downto 0);

   -- LCD
   LCD_BLON    :  out   std_logic;
   LCD_ON      :  out   std_logic;
   LCD_DATA    :  inout DE2_LCD_DATA_BUS;
   LCD_RS      :  out   std_logic;
   LCD_EN      :  out   std_logic;
   LCD_RW      :  out   std_logic;

   -- Switches
   SW          :  in    std_logic_vector (0 downto 0);

   -- Buttons
   KEY         :  in    std_logic_vector (3 downto 0);

   -- AUD (for audio codec)
   AUD_ADCLRCK :  inout std_logic;
   AUD_ADCDAT  :  in    std_logic;
   AUD_DACLRCK :  inout std_logic;
   AUD_DACDAT  :  out   std_logic;
   AUD_BCLK    :  inout std_logic;
   AUD_XCK     :  out   std_logic;

   -- I2C (for audio codec configuration)
   I2C_SDAT    :  inout std_logic;
   I2C_SCLK    :  inout std_logic;

   -- Clocks
   CLOCK_50    :  in    std_logic;
   CLOCK_27    :  in    std_logic
);
end G2_Audio_Codec;

architecture structure of G2_Audio_Codec is

   component niosII_system is port
   (
      sdram_wire_addr                                                      : out    DE2_SDRAM_ADDR_BUS;
      sdram_wire_ba                                                        : out    std_logic_vector(1 downto 0);
      sdram_wire_cas_n                                                     : out    std_logic;
      sdram_wire_cke                                                       : out    std_logic;
      sdram_wire_cs_n                                                      : out    std_logic;
      sdram_wire_dq                                                        : inout  DE2_SDRAM_DATA_BUS            := (others => 'X');
      sdram_wire_dqm                                                       : out    std_logic_vector(1 downto 0);
      sdram_wire_ras_n                                                     : out    std_logic;
      sdram_wire_we_n                                                      : out    std_logic;
      sram_external_interface_DQ                                           : inout  DE2_SRAM_DATA_BUS             := (others => 'X');
      sram_external_interface_ADDR                                         : out    DE2_SRAM_ADDR_BUS;
      sram_external_interface_LB_N                                         : out    std_logic;
      sram_external_interface_UB_N                                         : out    std_logic;
      sram_external_interface_CE_N                                         : out    std_logic;
      sram_external_interface_OE_N                                         : out    std_logic;
      sram_external_interface_WE_N                                         : out    std_logic;
      tristate_conduit_bridge_out_tristate_controller_tcm_read_n_out       : out    std_logic_vector(0 downto 0);
      tristate_conduit_bridge_out_tristate_controller_tcm_address_out      : out    DE2_FL_ADDR_BUS;
      tristate_conduit_bridge_out_tristate_controller_tcm_data_out         : inout  DE2_FL_DQ_BUS                 := (others => 'X');
      tristate_conduit_bridge_out_tristate_controller_tcm_chipselect_n_out : out    std_logic_vector(0 downto 0);
      tristate_conduit_bridge_out_tristate_controller_tcm_write_n_out      : out    std_logic_vector(0 downto 0);
      character_lcd_external_interface_DATA                                : inout  DE2_LCD_DATA_BUS              := (others => 'X');
      character_lcd_external_interface_ON                                  : out    std_logic;
      character_lcd_external_interface_BLON                                : out    std_logic;
      character_lcd_external_interface_EN                                  : out    std_logic;
      character_lcd_external_interface_RS                                  : out    std_logic;
      character_lcd_external_interface_RW                                  : out    std_logic;
      switch_external_connection_export                                    : in     std_logic                     := 'X';
      audio_core_external_interface_ADCDAT                                 : in     std_logic                     := 'X';
      audio_core_external_interface_ADCLRCK                                : in     std_logic                     := 'X';
      audio_core_external_interface_BCLK                                   : in     std_logic                     := 'X';
      audio_core_external_interface_DACDAT                                 : out    std_logic;
      audio_core_external_interface_DACLRCK                                : in     std_logic                     := 'X';
      audio_config_external_interface_SDAT                                 : inout  std_logic                     := 'X';
      audio_config_external_interface_SCLK                                 : out    std_logic;
      main_pll_sdram_clk_clk                                               : out    std_logic;
      main_pll_audio_clk_clk                                               : out    std_logic;
      clock_27mhz_clk_in_clk                                               : in     std_logic                     := 'X';
      clock_27mhz_clk_in_reset_reset_n                                     : in     std_logic                     := 'X';
      clock_50mhz_clk_in_clk                                               : in     std_logic                     := 'X';
      clock_50mhz_clk_in_reset_reset_n                                     : in     std_logic                     := 'X'
   );
   end component niosII_system;

   signal BA         :  std_logic_vector (1 downto 0);
   signal DQM        :  std_logic_vector (1 downto 0);

begin

   DRAM_BA_1   <= BA(1);
   DRAM_BA_0   <= BA(0);
   DRAM_UDQM   <= DQM(1);
   DRAM_LDQM   <= DQM(0);

   u0 : component niosII_system port map
   (
      sdram_wire_addr                                                      => DRAM_ADDR,
      sdram_wire_ba                                                        => BA,
      sdram_wire_cas_n                                                     => DRAM_CAS_N,
      sdram_wire_cke                                                       => DRAM_CKE,
      sdram_wire_cs_n                                                      => DRAM_CS_N,
      sdram_wire_dq                                                        => DRAM_DQ,
      sdram_wire_dqm                                                       => DQM,
      sdram_wire_ras_n                                                     => DRAM_RAS_N,
      sdram_wire_we_n                                                      => DRAM_WE_N,
      sram_external_interface_DQ                                           => SRAM_DQ,
      sram_external_interface_ADDR                                         => SRAM_ADDR,
      sram_external_interface_LB_N                                         => SRAM_LB_N,
      sram_external_interface_UB_N                                         => SRAM_UB_N,
      sram_external_interface_CE_N                                         => SRAM_CE_N,
      sram_external_interface_OE_N                                         => SRAM_OE_N,
      sram_external_interface_WE_N                                         => SRAM_WE_N,
      tristate_conduit_bridge_out_tristate_controller_tcm_read_n_out       => FL_OE_N,
      tristate_conduit_bridge_out_tristate_controller_tcm_address_out      => FL_ADDR,
      tristate_conduit_bridge_out_tristate_controller_tcm_data_out         => FL_DQ,
      tristate_conduit_bridge_out_tristate_controller_tcm_chipselect_n_out => FL_CE_N,
      tristate_conduit_bridge_out_tristate_controller_tcm_write_n_out      => FL_WE_N,
      character_lcd_external_interface_DATA                                => LCD_DATA,
      character_lcd_external_interface_ON                                  => LCD_ON,
      character_lcd_external_interface_BLON                                => LCD_BLON,
      character_lcd_external_interface_EN                                  => LCD_EN,
      character_lcd_external_interface_RS                                  => LCD_RS,
      character_lcd_external_interface_RW                                  => LCD_RW,
      switch_external_connection_export                                    => SW(0),
      audio_core_external_interface_ADCDAT                                 => AUD_ADCDAT,
      audio_core_external_interface_ADCLRCK                                => AUD_ADCLRCK,
      audio_core_external_interface_BCLK                                   => AUD_BCLK,
      audio_core_external_interface_DACDAT                                 => AUD_DACDAT,
      audio_core_external_interface_DACLRCK                                => AUD_DACLRCK,
      audio_config_external_interface_SDAT                                 => I2C_SDAT,
      audio_config_external_interface_SCLK                                 => I2C_SCLK,
      main_pll_sdram_clk_clk                                               => DRAM_CLK,
      main_pll_audio_clk_clk                                               => AUD_XCK,
      clock_27mhz_clk_in_clk                                               => CLOCK_27,
      clock_27mhz_clk_in_reset_reset_n                                     => KEY(0),
      clock_50mhz_clk_in_clk                                               => CLOCK_50,
      clock_50mhz_clk_in_reset_reset_n                                     => KEY(0)
   );

end structure;

library ieee;

use ieee.std_logic_1164.all;

package DE2_CONSTANTS is

   type DE2_SDRAM_ADDR_BUS    is array(11 downto 0)   of std_logic;
   type DE2_SDRAM_DATA_BUS    is array(15 downto 0)   of std_logic;
   type DE2_SRAM_ADDR_BUS     is array(17 downto 0)   of std_logic;
   type DE2_SRAM_DATA_BUS     is array(15 downto 0)   of std_logic;
   type DE2_FL_ADDR_BUS       is array(21 downto 0)   of std_logic;
   type DE2_FL_DQ_BUS         is array( 7 downto 0)   of std_logic;
   type DE2_LCD_DATA_BUS      is array( 7 downto 0)   of std_logic;

end DE2_CONSTANTS;
