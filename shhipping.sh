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

dnf install maven -y &>> "$LOGS_FILE"
VALIDATE $? "installing maven"

d roboshop &>> "$LOGS_FILE"
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> "$LOGS_FILE"
    VALIDATE $? "creating roboshop user"
else
    echo -e " roboshop user already exists... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "creating /app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> "$LOGS_FILE"
VALIDATE $? "downloading shipping component"

cd /app 
VALIDATE $? "changing directory to /app"

rm -rf /app/* &>> "$LOGS_FILE"
VALIDATE $? "removing old shipping content"

unzip /tmp/shipping.zip &>> "$LOGS_FILE"
VALIDATE $? "unzipping shipping component"

cd /app 
mvn clean package &>>$LOGS_FILE
VALIDATE $? "building shipping component"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "renaming shipping jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>> "$LOGS_FILE"
VALIDATE $? "copying shipping systemd service file"

dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "installing mysql client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e "use cities" &>> "$LOGS_FILE"
if [ $? -ne 0 ]; then
   mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>> "$LOGS_FILE"
   mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>> "$LOGS_FILE"
   mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>> "$LOGS_FILE"
else
    echo -e "cities database already exists... $Y SKIPPING $N"
fi

systemctl enable shipping 
systemctl start shipping
VALIDATE $? "starting and enabling shipping service"

