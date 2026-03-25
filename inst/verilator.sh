NAME=${1:-code}
./assemble.sh $NAME

verilator --cc --exe --build -j 0 -y ../srcs -Wno-WIDTH sim.cpp top_for_verilator.v
./obj_dir/Vtop_for_verilator main.hex
echo -e "\n\n"