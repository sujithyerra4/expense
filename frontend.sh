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

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

# systemctl enable nginx  &>>$LOG_FILE
# VALIDATE $? "Enabling Nginx"
if systemctl is-enabled nginx 
then
  echo    -e "Service nginx is already enabled... $Y SKIPPING $N" | tee -a $LOG_FILE
  else
VALIDATE $? " Enabling nginx"
fi

# systemctl start nginx  &>>$LOG_FILE
# VALIDATE $? "Starting Nginx"



curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip  &>>$LOG_FILE
VALIDATE $? "Downloading frontend code "



cd /usr/share/nginx/html

rm -rf /usr/share/nginx/html/*  &>>$LOG_FILE
VALIDATE $? "Removing default Nginx"


unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzippingz frontend code"

cp /home/ec2-user/expense/expense.conf /etc/nginx/default.d/expense.conf  &>>$LOG_FILE
VALIDATE $? "copied expense conf"

if systemctl is-active nginx  &>>$LOG_FILE; then
    echo -e "Service nginx is already running... $Y SKIPPING $N" | tee -a $LOG_FILE
else
    systemctl restart nginx  &>>$LOG_FILE
    VALIDATE $? "Restarting nginx"
fi
