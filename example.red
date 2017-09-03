Red []
query [
	; NB! type of default is added after the default definition block
	table 'country [default [name] string! name [string!] population [integer!]]
	table 'place [default [city] string! city [string!] country [table integer!] population [integer!]]
	table 'hotel [default [hotel-name] string! hotel-name [string!] address [table integer!]]
	add ["Beijing Hotel" 5]
	table 'address [
		place 		[table integer!] street [string!] house [integer! string!] index [string!] 
		templates 	[formal-address [rejoin [street space house comma space index space city comma space uppercase country/name]]] 
		default 	[rejoin [city comma space street space house]] string!
	]
	isikud: table 'person [
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
	add countries 	["China" 1379000000 "Estonia" 1316000 "Great Britain" 65640000 "Russia" 144300000]
	; OR 
	add countries name ["China" "Estonia" "Great Britain" "Russia"]
	; OR
	add countries [(name) "China" "Estonia" "Great Britain" "Russia"]
	; on position 2 address id-s
	add places 	[
		"Tallinn" 2 414000 
		"Beijing" 1 21500000 
		"London" 3 8788000 
		"St. Petersburg" 4 4991000
	]
	; on position 1 place id-s
	add addresses 	[
		1 "Sihi" "16-4" "11624" 
		1 "Tulbi" "7-3a" "11624" 
		3 "Trafalgar Sq" "22" "SW1Y 5AY" 
		4 "Sadovaya" "18" "191023" 
		2 "East Chang An Avenue" 33 "100004"
	]
	; on position 4 address id-s
	add persons 	[
		"Timmu" "Tamm" 24/10/1960 2 
		"Oscar" "Brewer" 24/6/1963 3 
		"Ivan" "Bezrodny" 27/1/2004 4 
		"Xia" "Chong" 1/1/1962 5 
		"Edward" "Kinnock" 13/6/1999 3
	]
	; adding by declared field-names before the data-block
	query [add person family-name first-name ["Eller" "Heino" "Brown" "David" "Urantu" "Miguel"]]
	; adding blck of maps
	query [add person [
		#(family-name: "Escriva" 
		  first-name: "Javier") 
		#(first-name: "Marco" 
		  address: [[(city) "Madrid"] "Puerta del Sol" "12" none] 
		  family-name:"Polo")
	]]
	; The following additions are identical in result
	; i.e. records may be added into connected tables without explixit command
	; a) positionally:
	query [add person ["Javier" "Maduro" 14-6-1963 [["Madrid" ["Spain" none] none] "Puerta del Sol" "12" none]]]
	; OR b) naming order of fields in parens (unnamed fields are set to `none` until default field values will be added):
	query [add person ["Javier" "Maduro" 14-6-1963 [[(country city) [(name) "Spain"] "Madrid"] "Puerta del Sol" "12" none]]]
	; OR c) naming fields individually in map:
	query [add person ["Javier" "Maduro" 14-6-1963 [[#(city: "Madrid" country: [#(name: "Spain")])] "Puerta del Sol" "12" none]]]
	; In fields with same values as previous addition, 'same may be used:
	query [add person ["Jacinta" 'same 10-12-1978 'same]]
]
