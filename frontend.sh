#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST="mongodb.kcdevops.online"

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

dnf module disable nginx -y &>> "$LOGS_FILE"
dnf module enable nginx:1.24 -y &>> "$LOGS_FILE"
dnf install nginx -y &>> "$LOGS_FILE"
VALIDATE $? "installing nginx"

systemctl enable nginx &>> "$LOGS_FILE"
systemctl start nginx &>> "$LOGS_FILE"
VALIDATE $? "starting and enabling nginx service"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "removing old nginx content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
VALIDATE $? "Downloading and unzipping frontend content"

rm -rf /etc/nginx/nginx.conf

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "copying nginx.conf file"

systemctl restart nginx &>> "$LOGS_FILE"
VALIDATE $? "restarting nginx service"
