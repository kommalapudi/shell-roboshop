#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ "$USERID" -ne 0 ]; then
    echo -e "$R Please run as root $N" | tee -a "$LOGS_FILE"
    exit 1
fi

mkdir -p "$LOGS_FOLDER"

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$R$2... failed.$N" | tee -a "$LOGS_FILE"
        exit 1
    else
        echo -e "$2...$G succeeded.$Y" | tee -a "$LOGS_FILE"
    fi
}


dnf install mysql-server -y &>> "$LOGS_FILE"
VALIDATE $? "installing mysql"

systemctl enable mysqld &>> "$LOGS_FILE"
systemctl start mysqld  
VALIDATE $? "starting mysql service"

# Get the password from the user
mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "setting mysql root password"

