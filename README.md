# query
A toy database/query DSL

# Some query examples
First, 
```
do %query.red
do %examples.red
``` 
Then try these:
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
query [print [address] of "Edward Kinnock"]
query [print [street house] of person with [first-name = "Oscar"]]
query [print [index] of address "Tallinn, Sihi 16-4"]
query [print [first name age] of persons]	; 'first is normal Red function, 'name is template of type block! with first-name and last-name, 'age is also template
query [print [rejoin [person/default comma space person/age ", " person/birthdate]] person with [address = "London, Trafalgar Sq 22"]]   ; fields, templates, ids cam be accessed by path notation and in Red expressions 
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
```
