onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_usb_config/clk_r
add wave -noupdate /tb_usb_config/reset_r
add wave -noupdate /tb_usb_config/clk
add wave -noupdate /tb_usb_config/reset
add wave -noupdate /tb_usb_config/enable
add wave -noupdate /tb_usb_config/o_shift_request_enable
add wave -noupdate /tb_usb_config/o_request_byte
add wave -noupdate /tb_usb_config/i_request
add wave -noupdate /tb_usb_config/i_receive_data
add wave -noupdate /tb_usb_config/i_receive_busy
add wave -noupdate /tb_usb_config/i_receive_hold
add wave -noupdate /tb_usb_config/o_transmit_end
add wave -noupdate /tb_usb_config/o_transmit_request
add wave -noupdate /tb_usb_config/o_transmit_pid
add wave -noupdate /tb_usb_config/o_transmit_data
add wave -noupdate /tb_usb_config/i_transmit_busy
add wave -noupdate /tb_usb_config/o_lut_address
add wave -noupdate /tb_usb_config/i_lut_data
add wave -noupdate /tb_usb_config/i_ulpi
add wave -noupdate /tb_usb_config/o_ulpi
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {2654050 ps} {2655961 ps}
