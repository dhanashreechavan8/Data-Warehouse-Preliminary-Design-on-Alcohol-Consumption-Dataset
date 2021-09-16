# Created table to store survey data
CREATE TABLE `brfss`.`brfss_ok`
  (
     `question`           VARCHAR(300),
     `response`           VARCHAR(10),
     `break_out`          VARCHAR(100), /* stored all the required attributes as per the flat file*/
     `break_out_category` VARCHAR(100),
     `sample_size`        INT,
     `data_value`         VARCHAR(50),
     `zipcode`            VARCHAR(5)
  );
  
# Created table to store zip code and city details in Oklahoma state
CREATE TABLE `brfss`.`demographics_ok`
  (
     `zipcode` VARCHAR(5),
     `city`    VARCHAR(50), /* stored all the required attributes as per the flat file*/
     `county`  VARCHAR(100)
  ); 
  
# Created table to store county details  
CREATE TABLE `brfss`.`County` (
  `County_ID` INT NOT NULL AUTO_INCREMENT, #set this value to auto-increment
  `County` VARCHAR(100) ,
  PRIMARY KEY (`County_ID`)); # county_id is the primary key for this table
  
# Created table to store city details    
CREATE TABLE `brfss`.`city`
  (
     `city_id` INT NOT NULL auto_increment, #set this value to auto-increment
     `city`    VARCHAR(100),
     `County_ID` INT, 
     PRIMARY KEY (`city_id`), # city_id is the primary key for this table
     FOREIGN KEY (`County_ID`) REFERENCES `brfss`.`County` (`County_ID`) # county_id is the foreign key for this table
  ); 
   
# Created table to store zip details    
CREATE TABLE `brfss`.`zipdetails`
  (
     `zipcode` VARCHAR(5),
     `city_id` INT,
     PRIMARY KEY (`zipcode`), # zipcode is the primary key for this table
     FOREIGN KEY (`city_id`) REFERENCES `brfss`.`city` (`city_id`) # city_id is the foreign key for this table
  );

# Created table to store breakout category details    
CREATE TABLE `brfss`.`break_out_category`
  (
     `break_catid`        INT NOT NULL auto_increment,  #set this value to auto-increment
     `break_out_category` VARCHAR(100),
     PRIMARY KEY (`break_catid`)  # break_catid is the primary key for this table
  );

# Created table to store breakout details    
CREATE TABLE `brfss`.`break_out`
  (
     `break_id`    INT NOT NULL auto_increment,  #set this value to auto-increment
     `break_out`   VARCHAR(100),
     `break_catid` INT,
     PRIMARY KEY (`break_id`), # break_id is the primary key for this table
     FOREIGN KEY (`break_catid`) REFERENCES `brfss`.`break_out_category` (`break_catid`) # break_catid is the foreign key for this table
  ); 
  
# Created table to store survey details      
CREATE TABLE `brfss`.`brfss_survey`
  (
     `survey_id`   INT NOT NULL auto_increment, #set this value to auto-increment
     `question`    VARCHAR(300),
     `response`    VARCHAR(10),
     `break_id`    INT,
     `sample_size` INT, /* stored all the required attributes as per the flat file*/
     `data_value`  DECIMAL(10, 1),
     `zipcode`     VARCHAR(5),
     PRIMARY KEY (`survey_id`), # survey_id is the primary key for this table
     FOREIGN KEY (`break_id`) REFERENCES `brfss`.`break_out` ( `break_id`),  # break_id is the foreign key for this table
    FOREIGN KEY (`zipcode`) REFERENCES `brfss`.`zipdetails` ( `zipcode`)  # zipcode is the foreign key for this table
  ); 
  
# Insert data in county table
INSERT INTO `brfss`.`county`
            (county)
SELECT DISTINCT county #extracted unique county names 
FROM   `brfss`.demographics_ok; 
  
# Insert data in city table
INSERT INTO `brfss`.`city`
            (city,
             county_id)
SELECT DISTINCT city,  #extracted unique city, county_id 
                county_id
FROM   `brfss`.demographics_ok ok
       INNER JOIN `brfss`.county C # added joins to fetch the data required data 
               ON ok.county = c.county; 
               
# Insert data in zipdetails table
INSERT INTO `brfss`.`zipdetails`
            (zipcode,
             city_id)
SELECT DISTINCT zipcode, #extracted unique zipcode, city_id  
                city_id
FROM   `brfss`.demographics_ok ok
       INNER JOIN `brfss`.city C
               ON ok.city = c.city # added joins to fetch the data required data 
       INNER JOIN`brfss`.county Ct
               ON ok.county = ct.county
                  AND c.county_id = ct.county_id; 
  
# Insert data in break_out_category table
INSERT INTO `brfss`.`break_out_category`
            (break_out_category)
SELECT DISTINCT break_out_category #extracted unique break_out_category names
FROM   `brfss`.brfss_ok; 

# Insert data in break_out table
INSERT INTO `brfss`.`break_out`
            (break_out,
             break_catid)
SELECT DISTINCT break_out, #extracted unique break_out, break_catid
                bc.break_catid
FROM   `brfss`.brfss_ok ok
       INNER JOIN `brfss`.break_out_category bc # added joins to fetch the data required data 
               ON ok.break_out_category = bc.break_out_category; 
               
# Insert data in brfss_survey table
INSERT INTO `brfss`.`brfss_survey`
            (question,
             response,
             break_id,
             sample_size,
             data_value,
             zipcode)
SELECT DISTINCT question,
                response,
                break_id,
                sample_size,
                Cast(IF(data_value='' OR data_value IS NULL, '0.0', data_value) AS
                DECIMAL(10, 1)), # as few values in data_value contained null values so first stored the data in string format to import data successfully later typecasted the data to decimal
                zipcode
FROM   `brfss`.brfss_ok ok
       INNER JOIN `brfss`.break_out bc # added joins to fetch the data required data 
               ON ok.break_out = bc.break_out;
               
# Display Demographic Survey data:
SELECT question,
       response,
       break_out,
       break_out_category,
       sample_size,# show required columns
       data_value,
       zipcode
FROM   `brfss`.brfss_survey bc
       INNER JOIN `brfss`.break_out bo
               ON bc.break_id = bc.break_id
       # added joins to fetch the data required data 
       INNER JOIN `brfss`.break_out_category b
               ON bo.break_catid = b.break_catid;
               
# Store Demographic Survey data in a view:
CREATE VIEW `brfss`.Survey 
AS
SELECT question,
       response,
       break_out,
       break_out_category,
       sample_size,# show required columns
       data_value,
       zipcode
FROM   `brfss`.brfss_survey bc
       INNER JOIN `brfss`.break_out bo
               ON bc.break_id = bo.break_id
       # added joins to fetch the data required data 
       INNER JOIN `brfss`.break_out_category b
               ON bo.break_catid = b.break_catid;               

# Display zip data:
SELECT zipcode,
       city,
       county
FROM   `brfss`.zipdetails zd
       INNER JOIN `brfss`.city bc # added joins to fetch the data required data 
               ON zd.city_id = bc.city_id
       INNER JOIN `brfss`.`county` c
               ON c.county_id = bc.county_id; 
               
# Store Zip code and city data in a view:
CREATE VIEW `brfss`.ZipCodeDetails 
AS
SELECT zipcode,
       city,
       county
FROM   `brfss`.zipdetails zd
       INNER JOIN `brfss`.city bc # added joins to fetch the data required data 
               ON zd.city_id = bc.city_id
       INNER JOIN `brfss`.`county` c
               ON c.county_id = bc.county_id; 
               
# Calculating percentage of people in a particular group who consumes alcohol                              
SELECT DISTINCT break_out,
                sample_size, # fetched required columns
                data_value,
                Concat(Floor(( data_value / sample_size ) * 100), '%') AS # fetched only integer part out of decimal and used concat function to add %
                'PercentData',
                zipcode
FROM   `brfss`.survey
WHERE  break_out_category = 'Age Group' #fetched only 'Age Group' category data
ORDER  BY break_out; # ordered data by breakout in ascending order


select A.zipcode, sum(A.data_value) #finding the total number of alcohol abuse respondents
from `brfss`.`brfss_ok` as A #A acts as alias for the table
join #joining the tables
`brfss`.`demographics_ok` as B #joining table with second table 
ON(A.zipcode = B.zipcode) #table join condition
where break_out = 'Less than H.S.' or break_out = '18-24'or break_out = 'H.S. or G.E.D.' #selecting only the adolescent groups
group by A.zipcode #grouping based on the zipcode
order by county; #sorting the query based on county

# Highest and Lowest respondant by city:
SELECT z.city,
       Sum(data_value) AS TotalRespondants # summed the number of respondants
FROM   `brfss`.zipcodedetails Z
       INNER JOIN `brfss`.survey S  # added joins to fetch the data required data 
               ON Z.zipcode = S.zipcode
WHERE  break_out = '18-24'
        OR break_out = 'Less than H.S.' # added conditions to filter only adolscent population
        OR break_out = 'H.S. or G.E.D.'
GROUP  BY Z.city # Grouped data on city
ORDER  BY TotalRespondants DESC; # Ordered data in descending order of Total Respondants

# Highest and Lowest respondant by county:
SELECT z.county,
       Sum(data_value) AS TotalRespondants # summed the number of respondants
FROM   `brfss`.zipcodedetails Z
       INNER JOIN `brfss`.survey S
               ON Z.zipcode = S.zipcode # added joins to fetch the data required data 
WHERE  break_out = '18-24'
        OR break_out = 'Less than H.S.' # added conditions to filter only adolscent population
        OR break_out = 'H.S. or G.E.D.'
GROUP  BY Z.county # Grouped data on county
ORDER  BY TotalRespondants DESC; # Ordered data in descending order of Total Respondants


               
