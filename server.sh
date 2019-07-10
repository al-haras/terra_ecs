#/bin/bash
search_dir=/efs
filename=server.jar
cd /efs
if [ $(find "$search_dir" -name "$filename") ]; then 
  :
else
  wget -O server.jar https://launcher.mojang.com/v1/objects/d0d0fe2b1dc6ab4c65554cb734270872b72dadd6/server.jar
  echo "eula=true" > eula.txt
fi

java -Xmx1024M -Xms1024M -jar server.jar nogui
