/* ----- Read_me file begin -----*/

This is the application created for sales company, which can track their sales persons. 

In proposed system, every sales person need to log in into the application then after application runs into background and send their location (latitude and longitude). So Company will see the map of the particular sales person locations, where he/she is going. Sometimes in some of the area internet is not working into sales persons' phone then application will save their locations in the device and after the phone will have internet connectivity then application send all the data.

I have maintaining centralized database. Because of centralized database there will be web service which authenticate the user via authenticate header. After every 1 minute application sends the coordinates. Application will stop gps after the coordinates send. So there will be no early battery dry out. The coordinates will store in centralized database for individual sales persons. A simple web page will show every sales persons' map.

To register new sales person use the following link
http://www.nikulchauhan.com/etrack/create.php

To view map select person name and date on following link
http://www.nikulchauhan.com/etrack/index.php  


/* ----- Read_me file end -----*/