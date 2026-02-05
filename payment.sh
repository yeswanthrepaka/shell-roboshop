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

dnf install python3 gcc python3-devel -y &>>$LOGS_FILE
VALIDATE $? "Installing python"

id roboshop &>>$LOGS_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "Created roboshop user"
    else
        echo -e "$Y Roboshop user already exists... SKIPPING $N"
    fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
VALIDATE $? "Downloading the code"

cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing content if available"

unzip /tmp/payment.zip
VALIDATE $? "Unzipping the code"

cd /app 
pip3 install -r requirements.txt &>>$LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_NAME/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Adding systemctl service"

systemctl daemon-reload &>>$LOGS_FILE

systemctl enable payment &>>$LOGS_FILE
systemctl start payment
VALIDATE $? "Enabling and adding payment"