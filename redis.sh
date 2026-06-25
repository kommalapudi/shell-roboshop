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


dnf module disable redis -y &>> "$LOGS_FILE"
VALIDATE $? "disabling redis default version"

dnf module enable redis:7 -y &>> "$LOGS_FILE"
VALIDATE $? "enabling redis module"


dnf install redis -y &>> "$LOGS_FILE"
VALIDATE $? "installing redis"

# sed -i -e 's/127.0.0.1/0.0.0.0/g' -e 's/^protected-mode[[:space:]]*yes/protected-mode no/' /etc/redis/redis.conf &>> "$LOGS_FILE"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>> "$LOGS_FILE"
VALIDATE $? "allowing remote connections"

systemctl enable redis  &>> "$LOGS_FILE"
VALIDATE $? "enabling redis service"    
systemctl start redis  &>> "$LOGS_FILE"
VALIDATE $? "starting redis service"    