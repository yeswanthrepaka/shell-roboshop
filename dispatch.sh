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
    echo -e"$R Please run the script with root user $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE () {
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf install golang -y &>>$LOGS_FILE
VALIDATE $? "Installing golang"

id roboshop &>>$LOGS_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "Adding roboshop user"
    else
        echo -e "$Y User already exists... SKIPPING $N"
    fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip 
VALIDATE $? "Downloading the code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing content if available"

unzip /tmp/dispatch.zip
VALIDATE $? "Unzipping the code"

cd /app 
go mod init dispatch
go get 
go build
VALIDATE $? "Download the dependencies and build"

cp $SCRIPT_NAME/dispatch.service /etc/systemd/system/dispatch.service
VALIDATE $? "Creating systemctl service"

systemctl daemon-reload &>>$LOGS_FILE

systemctl enable dispatch &>>$LOGS_FILE
systemctl start dispatch
VALIDATE $? "Enabling and starting dispatch"