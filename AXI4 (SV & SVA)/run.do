vlib work
vlog *.*v +cover -covercells
vsim -gui work.TOP -cover
coverage save -onexit cov.ucbd
do wave.do
run -all 
coverage report -details -output cov_report.text

