#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MYSQL_HOST="mysql.kcdevops.online"

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

dnf install python3 gcc python3-devel -y &>> "$LOGS_FILE"
VALIDATE $? "installing python dependencies"

id roboshop &>> "$LOGS_FILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> "$LOGS_FILE"
    VALIDATE $? "creating roboshop user"
else
    echo -e " roboshop user already exists... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "creating /app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> "$LOGS_FILE"
VALIDATE $? "downloading payment component"

cd /app 
VALIDATE $? "changing directory to /app"

rm -rf /app/* &>> "$LOGS_FILE"
VALIDATE $? "removing old payment content"

unzip /tmp/payment.zip &>> "$LOGS_FILE"
VALIDATE $? "unzipping payment component"

cd /app 
pip3 install -r requirements.txt &>> "$LOGS_FILE"
VALIDATE $? "installing payment dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>> "$LOGS_FILE"
VALIDATE $? "copying payment systemd service file"

systemctl daemon-reload
systemctl enable payment &>> "$LOGS_FILE"
systemctl start payment
VALIDATE $? "starting and enabling payment service"