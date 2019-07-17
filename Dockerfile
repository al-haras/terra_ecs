FROM ubuntu
EXPOSE 25565
RUN apt-get update -y
RUN apt-get install git -y
RUN apt-get install wget -y
RUN apt-get install nfs-common -y
RUN apt-get install openjdk-8-jre-headless -y
RUN mkdir /efs
RUN wget https://raw.githubusercontent.com/al-haras/terra_ecs/master/server.sh /tmp
RUN chmod +x /tmp/server.sh
