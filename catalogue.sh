#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"
SCRIPT_NAME=$PWD

if [ $USERID -ne 0 ]; then
    echo -e " $R Please run the script with root user $N " | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE (){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling nodejs old version"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling nodejs version 20"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing nodejs"

id roboshop &>>$LOGS_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "Adding roboshop user"
    else
        echo -e "$Y Roboshop user already exits... SKIPPING $N"
    fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Dowloading code"

cd /app
VALIDATE $? "Moving to app directiory"

rm -rf /app/*
VALIDATE $? "Removing older files"

unzip /tmp/catalogue.zip
VALIDATE $? "Unzipping the code"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_NAME/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl enable catalogue &>>$LOGS_FILE
VALIDATE $? "Enabling catalogue"

systemctl start catalogue
VALIDATE $? "Starting catalogue"

cp $SCRIPT_NAME/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "Installing mongodb"

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

    if [ $INDEX -le 0 ]; then
        mongosh --host $MONGODB_HOST </app/db/master-data.js
        VALIDATE $? "Loading products"
    else
        echo -e "$Y Products already loaded... SKIPPING $N"
    fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"