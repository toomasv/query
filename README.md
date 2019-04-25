# query
A toy database/query DSL

It's still very raw, expect to meet some bugs.

# Some query examples

First, 
```
do %query.red
``` 
Then create a file `address-book.rdb` with following content:
```
Red []
query [
	table 'country [default [name] string! name [string!] population [integer!]]
	table 'place [default [city] string! city [string!] country [table integer!] population [integer!]]
	table 'address [
		place 		[table integer!] street [string!] house [integer! string!] index [string!] 
		templates 	[formal-address [rejoin [street space house comma space index space city comma space uppercase country/name]]] 
		default 	[rejoin [city comma space street space house]] string!
	]
	table 'person [
		alias		[people peoples]
		first-name 	[string!] family-name [string!] birthdate [date!] ;sex [choice ['male | 'female] word!] 
		address 	[table integer!] ;father [table 'person defaults [sex 'male] integer!]
		functions	[formal	[func [nam][rejoin [last nam comma space first nam]]]]
		templates	[
			age 		[now - birthdate / 365] 
			birthday 	[copy/part n: to-string birthdate/date find/last n "-"]
			formal-name [rejoin [family-name comma space first-name]]
			name		[reduce [first-name family-name]]
		]
		default 	[rejoin [first-name space family-name]] string!
	] 
]
```
Then use your address-book:
```
query [use address-book]
```
Add some records to the address-book:
```
query [
	add countries 	[
		"China" 1379000000 
		"Estonia" 1316000 
		"Great Britain" 65640000 
		"Russia" 144300000
	]
	add places 		[
		"Tallinn" 2 414000 
		"Beijing" 1 21500000 
		"London" 3 8788000 
		"St. Petersburg" 4 4991000
	]
	add addresses 	[
		1 "Sakala" "16-4" "11624" 
		1 "Tulbi" "7-3a" "11624" 
		3 "Trafalgar Sq" "22" "SW1Y 5AY" 
		4 "Sadovaya" "18" "191023" 
		2 "East Chang An Avenue" 33 "100004"
	]
	add persons 	[
		"Timmu" "Tamm" 24/10/1960 2 
		"Oscar" "Brewer" 24/6/1963 3 
		"Ivan" "Bezrodny" 27/1/2004 4 
		"Xia" "Chong" 1/1/1962 5 
		"Edward" "Kinnock" 13/6/1999 3
	]
]
```
Now check your working directory. Some `*.rec` files should be there.
Then try these (I didn't check for some time, something may be broken):
```
;---- Reflection ----
query [probe tables]						; which tables there are?
query [probe table person templates]		; to see all templates defined for the table
query [probe table person age]				; to see individual template
query [probe table person cols]				; which cols does table have?
query [probe table person default]			; how 'default is defined?
query [probe table person spec]				; to see tables' col spec
;---- Queries ----
query [print [address] of person "Timmu Tamm"] ; here 'default is used as criterion
query [from persons print [address] of "Edward Kinnock"]
query [print [street house] of person with [first-name = "Oscar"]]
query [print [index] of address "Tallinn, Sakala 16-4"]
query [print [(first name) age] of persons]	; 'first is normal Red function, 'name is template of type block! with first-name and last-name, 'age is also template
query [print [(rejoin [person/default comma space person/age ", " person/birthdate])] person with [address = "London, Trafalgar Sq 22"]]   ; fields, templates, ids can be accessed by path notation and in Red expressions 
query [probe properties [name: person/name city population: place/population country: country/name population: country/population] of persons]
query [probe all persons]					; 'all gets whole records (cols, templates, default) as blocks
query [probe template properties of persons with [city = "London"]] ; filtered
query [print all of person "Xia Chong"]
query [probe all properties of persons with [age < 20]] ; 'all + 'properties gets records as property / value blocks, 
query [out: get persons] probe out; gets 'default' of person
;---- Collecting (grouping) of records ----
query [probe collected [country default age] of persons in [country family-name] order]
query [probe properties [person: ([default age]) average age age-group: unique (age / 10 * 10)] of persons collected by [(age / 10)]]
;---- Setting properties ----
query [get person "Timmu Tamm" set first-name to "Tom" probe persons] ; 'set operates on selection
query [get person with [family-name = "Tamm"] set first-name to "Taniel" and birthdate to birthdate + 1 probe [default birthdate] of persons]
;---- Removing selected records ----
query [get persons with [city = "London"] remove]
;---- Tabular print ----
query [print tabular properties [first-name average age age-group: unique (rejoin ["" a: age / 10 * 10 "-" a + 9])] of person collected by [(age / 10)]]

first-name      | average age | age-group 
--------------- | ----------- | --------- 
Edward Ivan     |        15.5 | 10-19     
Xia Oscar Timmu |        55.0 | 50-59     

== true
query [print tabular properties [first-name age] of person]

first-name | age 
---------- | --- 
Timmu      |  56 
Oscar      |  54 
Ivan       |  13 
Xia        |  55 
Edward     |  18 

== true
```
See some data-adding examples in %example.red

Next time do:
```
do %query.red
query [use address-book]
```
... and your data are there.
