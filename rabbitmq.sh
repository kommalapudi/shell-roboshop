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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> "$LOGS_FILE"
VALIDATE $? "copying rabbitmq repo file"

dnf install rabbitmq-server -y &>> "$LOGS_FILE"
VALIDATE $? "installing rabbitmq-server"

systemctl enable rabbitmq-server
systemctl start rabbitmq-server
VALIDATE $? "starting and enabling rabbitmq-server service"

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "adding roboshop user to rabbitmq-server"