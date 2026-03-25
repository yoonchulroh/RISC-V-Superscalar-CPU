NAME=${1:-code}
./assemble.sh $NAME

./host main.hex
echo -e "\n\n"