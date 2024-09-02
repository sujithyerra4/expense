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

dnf list installed mysql-server &>>$LOG_FILE

if [ $? -ne 0 ]
then 
echo  mysql-server is not installed,installing | tee -a $LOG_FILE
  dnf install mysql-server -y &>>$LOG_FILE
  VALIDATE $? "Installing mysql-server"
  else
  echo -e mysql-server is already $Y installed $N | tee -a $LOG_FILE
fi


if systemctl is-enabled mysqld &>>$LOG_FILE; then
    echo -e "Service mysqld is already enabled... $Y SKIPPING $N" | tee -a $LOG_FILE
else
    # If not enabled, enable the service
    systemctl enable mysqld &>>$LOG_FILE
    VALIDATE $? "Enabling mysqld"
fi


if systemctl is-active mysqld  &>>$LOG_FILE; then
    echo -e "Service mysqld is already running... $Y SKIPPING $N" | tee -a $LOG_FILE
else
    systemctl restart mysqld  &>>$LOG_FILE
    VALIDATE $? "Restarting mysqld"
fi

mysql -h mysql.sujithyerra.online -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE
if [ $? -ne 0 ]
then
echo mysql password is not setup,going to set up
mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE
VALIDATE $? "setting up root password" | tee -a $LOG_FILE
else
echo password already setup | tee -a $LOG_FILE
fi


# systemctl restart backend 
# VALIDATE $? " Restarting backend"
# mysql -h <host-address> -u root -p<password>

