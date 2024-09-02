#!/bin/bash

LOG_FOLDER=/var/log/expense
SCRIPT_NAME=$(echo $0 | awk -F "." '{print $1}')
TIME_STAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE=$LOG_FOLDER/$SCRIPT_NAME-$TIME_STAMP.log

mkdir -p $LOG_FOLDER


R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"


USERID=$(id -u)

if [ $USERID -ne 0 ]
then 
 echo -e " $R please proceed with root privilages $N" | tee -a $LOG_FILE
 exit 1
 fi


echo "script started executing at : $(date)" | tee -a $LOG_FILE

VALIDATE(){
    if [ $1 -ne 0 ]
    then
    echo -e $2 is $R failure $N | tee -a $LOG_FILE
    exit 1
    else
    echo -e $2 is $G success $N | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling nodejs:18"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs:20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs:20"

id expense &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "expense user not exists... $G Creating $N"
    useradd expense &>>$LOG_FILE
    VALIDATE $? "Creating expense user"
else
    echo -e "expense user already exists...$Y SKIPPING $N"
fi


curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading Application"

mkdir -p /app
cd /app
rm -rf /app/* 
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping Application"

npm install &>>$LOG_FILE

cp /home/ec2-user/expense/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql"

mysql -h mysql.sujithyerra.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Schema loading"
systemctl daemon-reload 


if systemctl is-enabled backend 
then
  echo    -e "Service backend is already enabled... $Y SKIPPING $N" | tee -a $LOG_FILE
  else
VALIDATE $? " Enabling backend"
fi

# systemctl restart backend 
# VALIDATE $? " Restarting backend"

if systemctl is-active backend  &>>$LOG_FILE; then
    echo -e "Service backend is already running... $Y SKIPPING $N" | tee -a $LOG_FILE
else
    systemctl restart backend &>>$LOG_FILE
    VALIDATE $? "Restarting backend"
fi