#!/bin/sh

SETUP_DONE=/etc/aidos-firstboot

if [ -f "$SETUP_DONE" ]; then
    exit 0
fi

exec < /dev/console > /dev/console 2>&1
echo ""
echo "============================================"
echo "  Welcome to AIDOS - First Time Setup"
echo "============================================"
echo ""
echo "Let's create your user account."
echo ""

while true; do
    printf "Choose a username [aidos]: "
    read USERNAME
    USERNAME=${USERNAME:-aidos}
    if echo "$USERNAME" | grep -qE '^[a-z_][a-z0-9_-]*$'; then
        break
    fi
    echo "Invalid username. Use only lowercase letters."
done

while true; do
    printf "Password: "
    stty -echo
    read PASSWORD1
    stty echo
    echo ""
    if [ -z "$PASSWORD1" ]; then
        echo "Password cannot be empty."
        continue
    fi
    printf "Confirm password: "
    stty -echo
    read PASSWORD2
    stty echo
    echo ""
    if [ "$PASSWORD1" != "$PASSWORD2" ]; then
        echo "Passwords do not match. Try again."
        continue
    fi
    break
done

printf "Full name (optional): "
read FULLNAME
FULLNAME=${FULLNAME:-$USERNAME}

adduser -D -s /bin/bash -g "$FULLNAME" "$USERNAME"
echo "$USERNAME:$PASSWORD1" | chpasswd
adduser "$USERNAME" wheel

mkdir -p "/home/$USERNAME/.ollama/models"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

echo ""
echo "Account created! You can login as '$USERNAME' or root (password: aidos)."
echo ""

touch "$SETUP_DONE"
exit 0
