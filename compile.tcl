
quit -sim
cls

if {![file exists work]} {
    vlib work
}

echo "=== Compilando arquivos do projeto ==="


vcom -93 Util_pkg.vhd
vcom -93 ExponentialSearch_pkg.vhd
vcom -93 RegisterNbits.vhd
vcom -93 Adder_nbits.vhd
vcom -93 Memory.vhd


vcom -93 DataPath.vhd
vcom -93 ControlPath.vhd


vcom -93 ExponentialSearch.vhd
vcom -93 ExponentialSearch_tb.vhd

echo "=== Compilação concluída com sucesso! ==="


vsim -t ns work.ExponentialSearch_tb
add wave *
run 500 ns