#!/bin/env bash
NAME=v1.0.0;VERSION=202302120
R="[1;31m" G="[1;32m" Y="[1;33m" C="[1;36m" B="[1;m" O="[m"
echo "$B————————————————————————————
$R TRSS$Y SWAP$G Configure$C Script$O
     $G$NAME$C ($VERSION)$O
$B————————————————————————————
      $G作者：$C时雨🌌星空$O

$Y- 正在检查环境$O
"
abort(){ echo "
$R! $@$O";exit 1;}
df -Th
echo
free -h
echo
swapon
zramctl

echo -n "$C- 请输入 ZRAM 大小：$O"
read ZRAM
[ -n "$ZRAM" ]&&[ "$ZRAM" -ge 0 ]||ZRAM=0

echo -n "
$C- 请输入 SWAP 大小：$O"
read SWAP
[ -n "$SWAP" ]&&[ "$SWAP" -ge 0 ]||SWAP=0

echo -n "
$C- 请确认你的输入：$O

  ZRAM：$C${ZRAM}G$O
  SWAP：$C${SWAP}G$O

  $C按回车键继续$O"
read -s ENTER
echo

[ "$ZRAM" -gt 0 ]&&{
  echo "
$Y- 正在配置 ZRAM$O
"
  echo zram>/etc/modules-load.d/zram.conf&&
  echo 'options zram num_devices=1'>/etc/modprobe.d/zram.conf&&
  echo 'KERNEL=="zram0",ATTR{comp_algorithm}="zstd",ATTR{disksize}="'$ZRAM'G",TAG+="systemd"'>/etc/udev/rules.d/99-zram.rules&&
  echo '[Unit]
Description=ZRAM
BindsTo=dev-zram0.device
After=dev-zram0.device

[Service]
Type=oneshot
RemainAfterExit=true
ExecStartPre=/sbin/mkswap /dev/zram0
ExecStart=/sbin/swapon -p2 /dev/zram0
ExecStop=/sbin/swapoff /dev/zram0

[Install]
WantedBy=multi-user.target'>/etc/systemd/system/zram.service&&
  systemctl enable zram||abort "ZRAM 配置失败"
  echo "
$G- ZRAM 配置完成，重启后生效$O"
}

[ "$SWAP" -gt 0 ]&&{
  echo "
$Y- 正在配置 SWAP$O
"
  dd if=/dev/zero of=/swap bs=1G count=$SWAP&&
  chmod 600 /swap&&
  mkswap /swap&&
  swapon /swap&&
  echo '/swap	none	swap	sw,pri=1	0	0'>>/etc/fstab||abort "SWAP 配置失败"
  echo "
$G- SWAP 配置完成$O"
}