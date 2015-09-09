---
title: cla poll - monitoring
---

`cla poll`: Monitoring tool. Without any option checks.

* Processes from pid and lock files are running.
* Connection to Clarive Web Server.
* Connection to nginx.
* Connection to mongo.

<br/>
Command options are the following:

* `-h`: displays command help to the screen.

<br/>

    >cla poll -h

    NAME
     poll - check if processes are started

    Clarive Poll Monitoring
      Usage: cla poll

      Options:

          -h               this help
         --url_web        clarive web url
         --url_nginx      nginx web url
         --api_key        api key to login to clarive
         --web            1=try clarive web connection, 0=skip
         --act_nginx     	    1=try nginx connection, 0=skip nginx
         --act_mongo            1=try mongo connection, 0=skip mongo
         --act_redis            1=try redis connection, 0=skip redis status
         --timeout_web    seconds to wait for clarive/nginx web response, 0=no timeout
         --error_rc       return code for fatal errors
         --pid_filter     regular expression to filter in pid files    


<br/>

* `--error_rc`: It defines a custom level for fatal errors. It has to be a number and its defaut value is 10.       
 
* `--web`: If set, try connection to Clarive Web Server, by default its value is set to 1.           

* `--url_web`: Host and port where Web Server is running.  If no value is defined, this option can also be defined through the options                   
`--host <host Web Server> -- port <port where Clarive is listening>`. Host will be set to value ‘localhost’ and port will be set to value ‘3000’.    
    
* `--api_key`: Api key to login to clarive.    

* `--timeout_web`:  Seconds to wait for web response. By default its value is 5 seconds, if this parameter is set to 0, it will be no timeout.  
  
* `--act_nginx`: If set  as well as url_nginx parameter,  try connection to Nginx, by default its value is set to 1.
    
* `--url_nginx`: nginx web url.     

* `--act_mongo`: If set, try mongo  connection to the database defined in the configuration file or database ‘clarive’ if it is not defined. Its default value is 1.    

* `--act_redis`: If set, try connection to Redis server defined in configuration file or on host localhost and port 6379 if not defined. Its default value is 0, so by default , no connection to redis will be executed.    


