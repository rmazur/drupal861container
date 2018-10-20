To build:  
docker build -t drupal861:0.1 .

To run:  
docker run -d --name drupal8 -v /${PWD}:/wkDir:ro -p 80:80 drupal861:0.1
#docker exec -it drupal8 bash

#docker rmi $(docker images -f "dangling=true" -q)

URLs:  
localhost/phpinfo.php
localhost/drupal

MariaDB/mySQL DB:  
DBName=drupal, user=regis, pwd=mypassword