#!/bin/bash

# create a repository to store the docker image in docker hub

# Lunch an ec2 instance open port 80 and 22

# install and configure docker on the ec2 instance 
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo systemctl enable docker
sudo systemctl status docker

# create a dockerfile

# build the docker image 
sudo docker build -t myimg .

# login to your docker hub account
cat ~/my_password.txt | sudo docker login --username ssah6694 --password-stdin

#use the docker tag command to give the image a new name 
sudo docker tag myimg ssah6694/my_img

# push the image to our docker hub repository
sudo docker push ssah6694/my_img

# start the container to test the image 
sudo docker run -d -p 80:80 ssah6694/my_img