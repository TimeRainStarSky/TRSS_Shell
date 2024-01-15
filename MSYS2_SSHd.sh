#!/bin/env bash
UNPRIV_USER=sshd
UNPRIV_NAME="Privilege separation user for sshd"
EMPTY_DIR=/var/empty
pacman -Syu --needed --noconfirm cygrunsrv openssh
ssh-keygen -A
add="$(if ! net user "${UNPRIV_USER}" >/dev/null; then echo "//add"; fi)"
if ! net user "${UNPRIV_USER}" ${add} //fullname:"${UNPRIV_NAME}" //homedir:"$(cygpath -w ${EMPTY_DIR})" //active:no; then
  echo "ERROR: Unable to create Windows user ${UNPRIV_USER}"
  exit 1
fi
if test -f /etc/passwd; then
  sed -i -e '/^'"${UNPRIV_USER}"':/d' /etc/passwd
  SED='/^'"${UNPRIV_USER}"':/s?^\(\([^:]*:\)\{5\}\).*?\1'"${EMPTY_DIR}"':/bin/false?p'
  mkpasswd -l -u "${UNPRIV_USER}" | sed -e 's/^[^:]*+//' | sed -ne "${SED}" >> /etc/passwd
  mkgroup.exe -l > /etc/group
fi
cygrunsrv -R msys2_sshd
cygrunsrv -I msys2_sshd -d "MSYS2 sshd" -p /usr/bin/sshd.exe -a "-D -e" -y tcpip
if ! net start msys2_sshd; then
  echo "ERROR: Unable to start msys2_sshd service"
  exit 1
fi
touch /var/log/lastlog