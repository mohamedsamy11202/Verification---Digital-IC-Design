vlib work
vlog *.*v +cover -covercells
coverage save -onexit cov.ucbd
vsim -gui work.Uart_TB
do wave.do
run -all 
coverage report -details -output cov_report.text