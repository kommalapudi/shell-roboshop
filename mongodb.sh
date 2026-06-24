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

cp mongodb.repo /etc/yum.repos.d/mongo.repo &>> "$LOGS_FILE"
VALIDATE $? "copying mongo repo"

dnf install mongodb-org -y &>> "$LOGS_FILE"
VALIDATE $? "mongodb installation"

systemctl enable mongod &>> "$LOGS_FILE"
VALIDATE $? "enabling mongodb service"

systemctl start mongod &>> "$LOGS_FILE"
VALIDATE $? "starting mongodb service"

sed -i -e 's/127.0.0.0/0.0.0.0/g' /etc/mongod.conf &>> "$LOGS_FILE"
VALIDATE $? "allowing remote connections"

systemctl restart mongod &>> "$LOGS_FILE"
VALIDATE $? "restarting mongodb service"