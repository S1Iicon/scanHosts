#!/bin/bash

function ctrl_c(){
	echo -e "\n[x] Saliendo...\n"
	tput cnorm
	exit 1
}

trap ctrl_c SIGINT

if [ $# -ne 2 ] || [ ! $(echo $2 | grep '^[0-9]*$') ]; then
	echo -e "\nUso: $0 <ip_address> <mask>\n"
fi

function parse_to_binary(){
	binary=$(echo "obase=2; $1" | bc)
	if [ ${#binary} -lt 8 ]; then
		binary=$(echo $binary | rev)
		for i in $(seq 1 $((8 - ${#binary}))); do
			binary+="0"
		done
		binary=$(echo $binary | rev)
	fi
	echo $binary
}

ip=$1
mask=$2
hosts=$((2**$((32 - $mask)) - 2))
declare -a ip_bi
declare -a mask_bi
declare -a id_net
tput civis
for i in $(echo $ip | tr '.' ' '); do
	ip_bi+=($(parse_to_binary $i))
done

for i in $(seq 0 3); do
	octet=""
	for j in $(seq 1 8); do
		if [ $(($j + $((8*$i)))) -le $mask ]; then
			octet+="1"
			continue
		fi
		octet+="0"
	done
	mask_bi+=($octet)
done

for i in $(seq 0 3); do
	octet=""
	ip_binary_split=($(echo ${ip_bi[$i]} | grep -o . | tr '\n' ' '))
	mask_binary_split=($(echo ${mask_bi[$i]} | grep -o . | tr '\n' ' '))
	for j in $(seq 0 7); do
		octet+=$((${ip_binary_split[$j]} * ${mask_binary_split[$j]}))
	done
	id_net+=($(echo $octet))
done


id_net_join=$(echo ${id_net[*]} | tr -d ' ')

for i in $(seq 1 $hosts); do
	id_net_join=$(echo "ibase=2; obase=2; $id_net_join + 1" | bc)
	ip_target=()
	octet=""
	for j in $(echo $id_net_join | grep -o . | tr '\n' ' '); do
		octet+=$j
		if [ ${#octet} -eq 8 ]; then
			ip_target+=($(echo "obase=10; ibase=2; $octet" | bc))
			octet=""
		fi
	done
	ip_target=$(echo ${ip_target[*]} | tr ' ' '.')
	timeout 0.3 bash -c "ping -c1 $ip_target &>/dev/null" && echo -e "[*] Host $ip_target on" &
done

wait
tput cnorm
