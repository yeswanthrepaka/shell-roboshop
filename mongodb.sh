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
    echo -e " $R PleasSe run the script with root user $N " | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE (){
    if [ $1 -ne 0 ]; then
        echo -e "$R $2 ... FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$R $2 ... SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo repo"

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing mongodb"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enabling mongodb"

systemctl start mongod 
VALIDATE $? "Starting mongodb"

sed -i s/127.0.0.1/0.0.0.0/g /etc/mongod.conf 
VALIDATE $? "Allowing remote connection"

systemctl restart mongod
VALIDATE $? "Restarting mongodb"
