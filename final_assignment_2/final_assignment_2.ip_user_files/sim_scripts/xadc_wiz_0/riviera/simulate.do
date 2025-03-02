onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+xadc_wiz_0 -L xil_defaultlib -L secureip -O5 xil_defaultlib.xadc_wiz_0

do {wave.do}

view wave
view structure

do {xadc_wiz_0.udo}

run -all

endsim

quit -force
