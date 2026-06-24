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


dnf module disable nodejs -y &>> "$LOGS_FILE"
VALIDATE $? "disabling nodejs default version" 

dnf module enable nodejs:20 -y &>> "$LOGS_FILE"
VALIDATE $? "enabling nodejs module"

dnf install nodejs -y &>> "$LOGS_FILE"
VALIDATE $? "installing nodejs"

id roboshop &>> "$LOGS_FILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> "$LOGS_FILE"
    VALIDATE $? "creating roboshop user"
else
    echo -e " roboshop user already exists... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "creating /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> "$LOGS_FILE"
VALIDATE $? "downloading catalogue component"

cd /app
VALIDATE $? "changing directory to /app"

rm -rf /app/* &>> "$LOGS_FILE"
VALIDATE $? "removing old catalogue content"

unzip /tmp/catalogue.zip
VALIDATE $? "unzipping catalogue component"

npm install
VALIDATE $? "installing nodejs dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>> "$LOGS_FILE"
VALIDATE $? "copying catalogue systemd service file"

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue
VALIDATE $? "starting and enabling catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>> "$LOGS_FILE"
dnf install mongodb-mongosh -y &>> "$LOGS_FILE"

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    VALIDATE $? "Loading products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "restarting catalogue service"

