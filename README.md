To build:
docker build -t s2i-centos7-regis:0.1 .

To run:
docker run -d --name s2i-regis -v /${PWD}:/wkDir:ro -p 80:80 s2i-centos7-regis:0.1
#docker exec -it s2i-regis bash

#docker rmi $(docker images -f "dangling=true" -q)

URLs:
localhost/phpinfo.php
localhost/drupal

MariaDB/mySQL DB:
DBName=drupal, user=regis, pwd=mypassword