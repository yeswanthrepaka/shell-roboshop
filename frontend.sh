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

dnf module disable nginx -y &>>$LOGS_FILE
VALIDATE $? "Disabling nginx default version"

dnf module enable nginx:1.24 -y &>>$LOGS_FILE
VALIDATE $? "Enabling nginx 1.24 version"

dnf install nginx -y &>>$LOGS_FILE
VALIDATE $? "Installing ngnix"

systemctl enable nginx &>>$LOGS_FILE
systemctl start nginx 
VALIDATE $? "Enabling and starting nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloading the code"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip
VALIDATE $? "Unzipping the content"

rm -rf /etc/nginx/nginx.conf

cp $SCRIPT_NAME/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copied the nginx conf file"

systemctl restart nginx 
VALIDATE $? "Restarting nginx"