#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"

if [ $USERID -ne 0 ]; then
    echo -e"$R Please run the script with root user $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE () {
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 ... FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$R $2... SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling nodejs default version"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling nodejs version 20"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE$? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding roboshop user"
else
    echo -e "$Y Roboshop user already available... SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Adding app directory"

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "Downloading the code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing default data if exists"

unzip /tmp/user.zip
VALIDATE $? "Unzipping the code"
