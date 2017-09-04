Red []
query [
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
	query [add person ["Jacinta" same 10-12-1978 same]]
]
