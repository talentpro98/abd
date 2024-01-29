#!/bin/bash

RED="\e[41m"
Green="\e[42m"
Yellow="\e[33m"
NC='\033[0m' # No Color

echo -e "\n\n${RED}Script ho tro debian 11.6 & iptables 1.8.7${NC}"

is_valid_ip() {
  local ip=$1
  if [[ "$ip" =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ]]; then
    return 0
  else
    return 1
  fi
}

# Ham kiem tra tinh hop le cua cong
is_valid_port() {
  local port=$1
  if [[ $port =~ ^[0-9]+$ && $port -ge 1 && $port -le 65535 ]]; then
    return 0
  else
    return 1
  fi
}


# Duong dan toi file cau hinh SSH
ssh_config_file="/etc/ssh/sshd_config"
# Kiem tra xem file cau hinh ton tai khong
if [ ! -e "$ssh_config_file" ]; then
  echo "File cau hinh SSH khong ton tai."
  exit 1
fi

current_ssh_connection=$(echo $SSH_CONNECTION | awk '{print $1}')
# Kiem tra neu khong co ket noi SSH
if [ -z "$current_ssh_connection" ]; then
  echo "Khong co ket noi SSH hien tai."
  exit 1
fi

# Lay dong trong file cau hinh SSH chua thong tin ve cong
ssh_port=$(grep -E '^Port' "$ssh_config_file" | awk '{print $2}')


# Ham de cau hinh iptables cho SSH
configure_ssh() {
if [ -z "$ssh_port" ]; then
	echo "Co phai ban dang dung SSH port 22 khong? (y/n):"
	read m
	if [[( $m == 'y' || $m == 'Y' )]]; then
		echo -e "\n${Green}Da them quy tac iptables cho ket noi SSH tu IP $current_ssh_connection va port 22.${NC}\n"
		iptables -A INPUT -p tcp -s $current_ssh_connection --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
		iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
		iptables -A INPUT -i lo -j ACCEPT
		iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
		iptables -A OUTPUT -o lo -j ACCEPT
	else
		echo -e "\nbye bye\n"
		exit 1
   	fi

else
	echo "Co phai ban dang dung ip $current_ssh_connection SSH port: $ssh_port dung khong? (y/n):"
	read  m
    if [[( $m == 'y' || $m == 'Y' )]]; then
		echo -e "\n${Green}Da them quy tac iptables cho ket noi SSH tu IP $current_ssh_connection va port $ssh_port.${NC}\n"
		iptables -A INPUT -p tcp -s $current_ssh_connection --dport "$ssh_port" -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
		iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
		iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
		iptables -A OUTPUT -o lo -j ACCEPT
	else
		echo -e "\nbye bye\n"
		exit
	fi
fi

}

# Ham de cau hinh iptables cho chain INPUT
configure_input_chain() {
    read -p "Nhap dia chi IP INPUT: " ip_address
    if ! is_valid_ip "$ip_address"; then
      echo "Dia chi IP khong hop le. Ket thuc script."
      exit 3
    fi

    # Nhap danh sach cong tu ban phim (co the la mot cong duy nhat hoac mot danh sach, vi du: 80 hoac 80,443,22)
    read -p "Nhap danh sach cong (co the la mot cong duy nhat hoac mot danh sach, vi du: 80 hoac 80,443,22): " ports

    # Chuyen danh sach cong thanh mang
    IFS=',' read -ra port_array <<< "$ports"
    for port in "${port_array[@]}"; do
      if ! is_valid_port "$port"; then
        echo "Cong khong hop le. Ket thuc script."
        exit 4
      fi
    done


    # Them quy tac iptables
    if [[ ${#port_array[@]} -gt 1 ]]; then
      # Neu co nhieu cong, su dung -m multiport --dports
      iptables -A INPUT -p tcp -s $ip_address -m multiport --dports ${ports} -j ACCEPT
      echo -e "${Green} Da them quy tac cho $chain_input tu IP $ip_address den cac cong $ports va giu cac ket noi hien tai va lien quan. ${NC} "
    else
      # Neu chi co mot cong, su dung --dport
      iptables -A INPUT -p tcp -s $ip_address --dport $ports -j ACCEPT
      echo -e "${Green} Da them quy tac cho $chain_input tu IP $ip_address den cong $ports va giu cac ket noi hien tai va lien quan. ${NC}"
    fi
}

# Ham de cau hinh iptables cho chain OUTPUT
configure_output_chain() {
    read -p "Nhap dia chi IP: " ip_address
    if ! is_valid_ip "$ip_address"; then
      echo "Dia chi IP khong hop le. Ket thuc script."
      exit 3
    fi

    # Nhap danh sach cong tu ban phim (co the la mot cong duy nhat hoac mot danh sach, vi du: 80 hoac 80,443)
    read -p "Nhap danh sach cong (co the la mot cong duy nhat hoac mot danh sach, vi du: 80 hoac 80,443,22): " ports

    # Chuyen danh sach cong thanh mang
    IFS=',' read -ra port_array <<< "$ports"
    for port in "${port_array[@]}"; do
      if ! is_valid_port "$port"; then
        echo "Cong khong hop le. Ket thuc script."
        exit 4
      fi
    done

    # Them quy tac iptables
    if [[ ${#port_array[@]} -gt 1 ]]; then
      # Neu co nhieu cong, su dung -m multiport --dports
      iptables -A OUTPUT -p tcp -s $ip_address -m multiport --sport ${ports} -j ACCEPT
      echo -e "${Green}Da them rule cho $chain_input tu IP $ip_address den cac cong $ports va giu cac ket noi hien tai va lien quan.${NC}"
    else
      # Neu chi co mot cong, su dung --dport
      iptables -A OUTPUT -p tcp -s $ip_address --sport $ports -j ACCEPT
      echo -e "${Green}Da them quy tac cho $chain_input tu IP $ip_address den cong $ports va giu cac ket noi hien tai va lien quan.${NC}"
    fi
}

configure_dns_for_internet()
{
  iptables -A OUTPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT
  iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT
  iptables -A OUTPUT -p udp --dport 53 -m state --state NEW -j ACCEPT
}

configure_drop_all()
{
  read -p "Ban co muon drop tat ca cac ket noi khong? (y/n): " drop_all_choice
   case $drop_all_choice in
        y|Y)
            configure_ssh
            iptables -D INPUT -j DROP  # Xoa quy tac hien tai
            iptables -A INPUT -j DROP  # them lai rule xuong cuoi chain INPUT
            iptables -D OUTPUT -j DROP  # Xoa quy tac hien tai
            iptables -A OUTPUT -j DROP  # Them lai rule xuong cuoi chain OUTPUT
            echo "Da cau hinh iptables cho SSH."
            ;;
        *)
            echo "Khong drop tat ca cac ket noi."
            ;;
    esac
  
}

configure_delete_rule()
{
  # Function to display rules with line numbers for a specific chain
  display_rules() {
    local chain=$1
    local rule_number=1

    iptables-save | grep -E "^\-A $chain" | while read -r line; do
      echo "$rule_number: $line"
      ((rule_number++))
    done
  }

  # Function to delete a rule by chain and rule number
  delete_rule() {
    local chain=$1
    local rule_number=$2

    iptables -D $chain $rule_number
  }

  # Main script

  # Display rules with line numbers for each chain
  echo -e "${Green}Rules for INPUT chain:${NC}"
  display_rules INPUT

  echo -e "${Green}\nRules for OUTPUT chain:${NC}"
  display_rules OUTPUT

  echo -e "${Green}\nRules for FORWARD chain:${NC}"
  display_rules FORWARD

  # Ask user for input
  read -p "Enter the chain (i for INPUT, o for OUTPUT, f for FORWARD): " chain_input

  # Convert input to uppercase
  chain_input=$(echo "$chain_input" | tr '[:lower:]' '[:upper:]')

  # Case statement to determine the chain
  case "$chain_input" in
    I) chain=INPUT ;;
    O) chain=OUTPUT ;;
    F) chain=FORWARD ;;
    *) echo "Invalid input. Exiting."; exit 1 ;;
  esac

  # Display rules with line numbers for the selected chain
  echo -e "\nRules for $chain chain:"
  display_rules $chain

  # Ask user for the rule number to delete
  read -p "Enter the rule number to delete: " rule_number

  # Delete the specified rule
  delete_rule $chain $rule_number

  # Display updated rules with line numbers
  echo -e "\nRules after deletion:"
  display_rules $chain

}


# Hien thi menu lua chon
echo "Menu cau hinh iptables:"
echo "1) Cau hinh iptables cho chain INPUT"
echo "2) Cau hinh iptables cho chain OUTPUT"
echo "3) Cau hinh iptables cho SSH"
echo "4) Cau hinh DNS internet"
echo "5) Cau hinh DROP ALL ket noi(ngoai tru SSH hien tai)"
echo "6) Xoa 1 rule"
echo "0) Thoat"

# Nhap lua chon tu nguoi dung
read -p "Chon mot so (0-6): " choice

# Xu ly lua chon
case $choice in
    1)
        configure_input_chain
        ;;
    2)
        configure_output_chain
        ;;
    3)
        configure_ssh
        ;;
    4)
        configure_dns_for_internet
        ;;
    5)
        configure_drop_all
        ;;
    6)
        configure_delete_rule
        ;;
    0)
        echo "Thoat khoi chuong trinh."
        exit
        ;;
    *)
        echo "Lua chon khong hop le. Thoat khoi chuong trinh."
        exit 1
        ;;
esac


#xoa rule bi trung
/sbin/iptables-save | awk '/^COMMIT$/ { delete x; }; !x[$0]++' > /tmp/iptables.conf
iptables -F
/sbin/iptables-restore < /tmp/iptables.conf