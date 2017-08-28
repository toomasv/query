Red [File: 		%query.red
	Author: 	"Toomas Vooglaid"
	Version: 	"0.1"
	Date:		23/8/2017
]
dbx: object [

	;#####     HELPERS     #####
	
	filter: func [series [series!] fn [any-function!]][
		out: make type? series []
		foreach i series [if fn i [append out i]]
		out
	]
	flatten: func [tree [block!] /level lvl /local rule l][
		(l: -1)
		rule: [(l: l + 1) some [
			ahead block! if (any [not level l < lvl]) into rule (l: l - 1) 
		| 	keep skip
		]] 
		parse tree [collect rule]
	]
	has-key: func [map [map! object!] key][to-logic find words-of map key]
	to-object: func [val /local i spec v][
		case [
			map! = type? val [make object! body-of val] 
			block! = type? val [make object! val]
			find [date! time! email!] v: type?/word val [
				names: system/catalog/accessors/:v
				spec: clear []
				foreach i names [append spec reduce [to-set-word i val/:i]]
				make object! spec
			]
		]
	]
	cons: charset "bcdfghjklmnpqrstvwxz"
	to-alternatives: func [list /local s][
		parse list [
			collect [some [keep change set s skip (to-lit-word s) [end | keep ('|)]]]
		]
	]
	resolve-default: func [t][
		if t/default [
			return switch/default type?/word t/default [
				block? [t/default] 
				any-block? [reduce [t/default]]
			][	
				to-block t/default
			]
		] 
	]
	expand-templates: func [fields t /local rule s tmp tbl join][
		;probe reduce [t/name ": " fields]
		parse fields rule: [any [
			not [any-string! | path!] [ 
				s: set tmp [word! | lit-word!] 
				(case [
					t/templates/:tmp [
						change/only/part s to-paren t/templates/:tmp 1
					]
					tmp = 'default [
						change/only/part s to-paren resolve-default t 1
					]
					find select t/spec tmp 'table [
						change/only/part s to-paren resolve-default tables/:tmp 1
					]
				])
			;|	s: set path path! 
			;	(if tbl: tables/(path/1) [
			;		change/only/part s expand-templates next path tbl 1
			;	])
			|	into rule
			] 
			| 	skip
		]]
		;probe reduce ["flds: " fields]
		foreach join t/joined [expand-templates fields join]
		fields
	]
	get-joins: function [join cols all-fields][; fields search][
		;probe reduce [join/name cols reduce cols fields]
		;jcols: copy join/cols
		;dups: intersect intersect cols join/cols fields
		;forall dups [change/only/part find jcols dups/1 to-path reduce [to-word join/name dups/1] 1]
		join/id: reduce first find cols join/name
		set (words-of join/fields) next find/skip join/records join/id join/width;join/records
		;probe join/fields 
		bind join/cols join/fields
		all-fields: make all-fields append body-of join/fields reduce [
			to-set-word join/name make copy join/fields compose [id: (join/id)]
		]
			
		foreach join2 join/joined [all-fields: get-joins join2 join/cols all-fields]; fields search] 
		;temps: bind body-of join/templates all-fields
		temps: copy []
		unless 0 = length? join/templates [insert temps body-of join/templates]
		if join/default [insert temps compose/deep [default: [(join/default)]]]
		bind temps all-fields
		foreach [key val] temps [put temps key first reduce val] 
		all-fields/(reduce join/name): make all-fields/(reduce join/name) temps
		
		all-fields
	]
	func-rule: [
		'count | 'sum | 'average | 'max | 'min | 'unique ;| 'copy | 'copy/part
	| 	'first | 'second | 'third | 'fourth | 'fifth | 'last 
	| 	'ascending | 'descending | 'form | 'rejoin 
	]
	do-method: function [method returned /tabular col-names col-lengths][
		;probe reduce [method returned]
		either tabular [
			example: returned/1
			num-cols: length? example
			cols: copy []
			templ: copy []
			letters: "abcdefghijklmnopqrstuvwyz" 
			if not empty? col-names [
				repeat n length? col-names [
					poke col-lengths n max length? col-names/:n col-lengths/:n
				]
			]
			repeat n length? example [
				append cols reduce [to-word pick letters n]
				append templ case [
					find [integer! date! float!] type?/word example/:n [
						compose [
							pad/left (to-word pick letters n) (pick col-lengths n) (either n < length? example ["|"][""])
						]
					]
					true [
						compose [
							pad form (to-word pick letters n) (pick col-lengths n) (either n < length? example ["|"][""])
						]
					]
				]
			]
			source: flatten/level returned 1
			unless empty? col-names [
				col-lengths2: reverse copy col-lengths
				;probe reduce [col-lengths col-lengths2]
				repeat n length? col-lengths2 [
					insert source reduce [pad/with copy "" pick col-lengths2 n #"-"];
				]
				insert source col-names;
			]
			print "^/"
			foreach (cols) source [
				print compose templ
			]
			print "^/"
		][
			case [
				method = 'view [
					forall returned [returned/1: form returned/1]
					view/no-wait [text-list data returned]
				]
				;method = 'browse []
				method [forall returned [do reduce [method returned/1]]]
			]
		]
	]
	keyword: ['table | 'get | 'print | 'probe | 'view | 'add | 'db | 'set | 'remove | set-word! | paren!]

	;#####     DBX PROPERTIES     #####
	
	functions: object [
		count: func [blk [block!]] [length? reduce blk]
		sum: func [blk [block!] /local s][
			blk: reduce blk 
			s: 0 
			forall blk [s: s + blk/1]
		]
		average: func [blk [block!] /precise /local avg][
			blk: reduce blk
			avg: (to-float sum blk) / (to-float length? blk) 
			either precise [avg][round/to avg 0.1]
		]
		max: func [blk [block!]][
			first sort/reverse blk
		]
		min: func [blk [block!]][
			first sort blk
		]
		ascending: func [blk [block!]][sort blk]
		descending: func [blk [block!]][sort/reverse blk]
	]
	active: none
	tables: make map! clear []
	tables-rule: none
	
	;#####     MAKE TABLE    #####
	
	make-table: func [tablename tablespec /local plural tbl tmp nam fun obj][
		object [
			name:		tablename
			aliases: 	copy []
			templates: 	make map! copy []
			default:	none
			functions:	object copy []
			joined:		make block! 2
			fields:		object copy [];[id: none]
			id:			none
			params: 	make map! copy []
			put tables tablename self
			spec: parse tablespec [
				collect [
					some [
						'alias set tmp skip 
						(
							either block? tmp [
								forall tmp [put tables tmp/1 self]
							][
								put tables tmp self
							] 
							append aliases tmp
						)
					|	'plural set plural skip 
						(
							put tables plural self 
							append aliases plural
						)
					|	['templates | 'template] set tmp block! (extend templates tmp)
					|	'default set tmp [block! | word!] (default: tmp)
					|	'functions set tmp block! 
						(
							obj: copy [] 
							foreach [nam fun] tmp [
								append obj compose [(to-set-word nam) (fun)]
							]
							functions: make functions obj
						)
					| 	keep skip
					]
				]
			]
			
			unless plural [
				parse tbl: to-string tablename [
					thru [[#"s" | "sh" | "ch" | #"x" | #"o"] end] insert "es" 
				|	to [cons #"y" end] skip change to end "ies"
				|	to end insert #"s"
				]
				plural: to-word tbl
				put tables plural self
			]
			cols: parse spec [collect [
				some [
					keep [set fld [word!] (fields: make fields compose [(to-set-word fld) none])]
					opt [ahead block! into [some [
						'table (insert joined tables/:fld)
					|	skip
					]]]
				]
			]]
			cols-rule: 	to-alternatives copy cols
			insert cols 'id
			records: 	make hash! []
			width: 		length? cols
			length: 	0
			last-id: 	0
			last-by:	none
			last-n:		none
			;selected-fields: none
			selected:	none
			returned: 	none
			method: 	none
			set 'tables-rule to-alternatives keys-of tables
			find-by-id:	func [id /local spec col][
				set cols find/skip records id width
				;probe reduce cols
				;spec: copy []
				;foreach col cols [
				;	append spec reduce [to-lit-word col col]
				;]
				;probe object spec
			]
		]
	]

	;#####     ADD COLUMNS     #####
	
	add-column: func [table col][
		
	]

	;#####     ADD RECORDS     #####
	; Currently:
	;add person ["Firstname" "Familyname" 1-1-1960 1] ; id of existing address
	;TBD:
	;add person ["Firstname" "Familyname" 1-1-1960 "Tallinn, Sihi 16-4"] ; default of existing address
	;add person ["Firstname" "Familyname" 1-1-1960 [1 "Sihi" "16-4" "11624"]] ;new or existing address with (existing) place id
	;add person ["Firstname" "Familyname" 1-1-1960 ["Tallinn" "Sihi" "16-4" "11624"]] ;new or existing address with (existing) place default
	;add person [(first-name family-name) "Firstname1" "Familyname1" "Firstname2" "Familyname2" "Firstname3" "Familyname3"] ;partial regular data
	;add person [#(first-name: "Firstname1"  family-name: "Familyname1") #(family-name: "Familyname2" first-name: "Firstname2" birthdate: 1-1-1960)] ; partial irregular data
	;add person ["Firstname" "Familyname" 1-1-1960 [[(city) "Tallinn" [#(name: "Estonia")]] "Sihi" "16-4" "11624"]] ;new or existing address with (existing or non-existing) place/country default
	add-records: func [
		table records 
		/fields field-names 
		/partial 
		/local t id r d f fspec recs type
	][
		t: 	select tables table
		id: t/last-id + 1
		r: 	reduce [id]
		recs: reduce records
		forall recs [
			fspec: select t/spec f: pick t/cols (((index? recs) - 1) % (t/width - 1) + 2)
			type: type?/word first recs
			;d: first recs
			;probe f probe d print type?/word d print type
			either any [
				not block! = type? fspec
				find fspec type;type?/word d
				none = reduce recs/1
			][
				append/only r first recs;d 
				if (length? r) = t/width [ 
					append t/records copy r 
					t/length: t/length + 1 
					t/last-id: id 
					id: t/last-id + 1 
					r: reduce [id]
				]
			][
				cause-error 'user 'message reduce [rejoin ["Wrong datatype for " f]]
			]
		]
	]
	
	;#####     GET RECORDS     #####
	
	get-from: function [
		table collected fields search criterion limit debug properties collected-by order direction tabular
		/local t fs ss template cols c sw s val sel ret flds n funcs fn i prepared-ret col-names local-prepared prepared field-words tid order-dirs
	][
		n: 0 
		;probe reduce [table fields search criterion limit]
		t: 	select tables table
		bind fields t/functions
		sel: copy [] ret: copy [] 
		if collected [funcs: copy [] prepared-ret: copy []]
		if all [tabular properties] [t/params/col-names: col-names: copy [] t/params/col-lengths: col-lengths: copy []]
		if collected [prepared: either tabular [col-names][prepared-ret]]
		if fields = [] [fields: either properties ['cols]['default]]
		either word? fields [ 
			fields: switch fields [
				all 		[append copy t/cols compose [(keys-of t/templates) default]]
				cols 		[copy t/cols]
				templates 	[keys-of t/templates]
				default		[copy [default]]
			]
			if collected [
				repeat i length? fields	[
					if properties [
						append prepared either tabular [form fields/:i][to-lit-word fields/:i]
					]
					append/only prepared-ret copy []
					append funcs none
				]
				
			]
		][
			if collected [
				value-rule: [
					set val [paren! | path!] (val: mold val)
				| 	set val skip
				] 
				either properties [
					parse fields [some [
						remove set c [set-word! | string!]
						(
							append prepared either set-word? c [either tabular [form c][to-lit-word c]][c]
							append/only prepared-ret copy []
							sw: yes
						) 
					|	[	remove set fn func-rule value-rule (append funcs fn) 
						|	value-rule (append funcs none) 
						](
							either sw [
								sw: no
							][	
								append prepared either fn [
									form reduce [fn val]
								][
									either string? val [val][either tabular [form val][to-lit-word val]]
								]
								append/only prepared-ret copy []
							] 	fn: none
						)
					]] 
				][
					parse fields [some [
						remove set fn func-rule value-rule (append funcs fn) 
					|	value-rule (append funcs none) 
					]] 
					repeat i length? fields [append/only prepared-ret copy []]
				]
				n: 0
			]
		]
		if search = 'default [search: resolve-default t]
		if block? search 	 [expand-templates search t]
		unless any [collected properties] [
			expand-templates fields t 
		]
		if all [tabular properties not collected][
			parse fields [
				some [
					remove set c [
						string!
					| 	set-word! 
					] (append col-names form c)
					[word! | paren! | path!]
				|	set c [word! | paren! | path!]
					(append col-names mold c)
				]
			]
		]
		if order [
			order-dirs: copy []
			if word? order [order: to-block order]
			parse order [some [
				remove [
					['desc | 'descending] (append order-dirs reduce [false])
				|	['asc | 'ascending] (append order-dirs reduce [true])
				] skip
			|	skip (append order-dirs either direction = 'descending [false][true])
			]]
			expand-templates order t
			;probe reduce [order  order-dirs]
		]
		if collected-by [expand-templates collected-by t]
		if debug [probe reduce [
			to-set-word 'table 			table 
			to-set-word 'collected 		collected
			to-set-word 'collected-by 	collected-by
			to-set-word 'properties 	properties 
			to-set-word 'fields 		fields 
			to-set-word 'search 		search 
			to-set-word 'criterion 		criterion 
			to-set-word 'limit  		limit
			to-set-word 'order			order
			to-set-word 'order-dirs		order-dirs
		]]
		if collected [local-ret: copy/deep prepared-ret]
		field-words: compose [tid (words-of t/fields)]
		cols: copy t/cols
		foreach (field-words) t/records [
			t/id: tid
			all-fields: make copy t/fields reduce [
				to-set-word 'id tid 
				to-set-word t/name make copy t/fields compose [id: (tid)]
			]
			bind cols t/fields;t/cols
			foreach join t/joined [
				all-fields: get-joins join cols all-fields; fields search
			]
			unless any [collected-by all [order not collected-by]] [
				temps: copy []
				unless 0 = length? t/templates [insert temps body-of t/templates]
				if t/default [insert temps compose/deep [default: [(t/default)]]]
				bind temps all-fields
				foreach [key val] temps [put temps key first reduce val] 
				;probe temps
				all-fields/(reduce t/name): make all-fields/(reduce t/name) temps
				bind fields all-fields
				;probe reduce fields
			]
			if search [
				bind search all-fields 
			]
			;probe all-fields
			if any [ 
				all [criterion = none search = none]
				all [criterion criterion = do reduce search]
				all [not criterion all reduce search]
			][ 
				either any [collected-by order] [
					append/only sel find/skip t/records reduce cols t/width
				][
					if any [not limit limit >= n: n + 1][
						append/only sel find/skip t/records reduce cols t/width;t/cols
						;cols: copy t/cols 
						either collected [
							expanded: expand-templates copy fields t
							bind expanded all-fields
							flds: copy reduce [reduce expanded]
							repeat i length? flds/1 either all [properties not tabular][
								[j: i - 1 * 2 + 2 append/only local-ret/:j reduce flds/1/:i]
							][
								[append/only local-ret/:i flds/1/:i]
							] 
						][
							either properties [
								parse flds: copy fields either tabular [
									[(n: 0) some [
										change set c [word! | paren! | path!]
										(	
											c: expand-templates copy either paren? c [to-block c][reduce [c]] t 
											bind c all-fields 
											c: reduce c
											n: n + 1
											either n > length? col-lengths [
												append col-lengths length? form c
											][
												poke col-lengths n max length? form c col-lengths/:n
											]
											;to-paren 
											;probe type? first c
											either block? first c [form c][c]
										)
									]]
								][
									[some [
										[
											[	string!
											|	change set c set-word! (to-lit-word c)
											]
											remove set c [word! | paren! | path!]
										|	change set c [word! | paren! | path!]
											(either word? c [to-lit-word c][mold c])
										] 
										insert (
											c: expand-templates copy either paren? c [to-block c][reduce [c]] t 
											bind c all-fields 
											to-paren reduce c
										)
									]]
								]
								append/only ret flds
							][	
								append/only ret reduce fields
							]
						]
					]
				]
			]
		] 
		if any [collected-by all [order not collected-by]] [
			sort/compare sel func [a b][
				a-id: first a
				a-fields: copy t/fields
				set (words-of a-fields) next a
				a-fields: make a-fields reduce [
					to-set-word 'id a-id
					to-set-word t/name make copy a-fields compose [id: a-id]
				]
				a-cols: bind copy t/cols a-fields

				b-id: first b
				b-fields: copy t/fields
				set (words-of b-fields) next b
				b-fields: make b-fields reduce [
					to-set-word 'id b-id
					to-set-word t/name make copy b-fields compose [id: b-id]
				]
				b-cols: bind copy t/cols b-fields

				foreach join t/joined [
					a-fields: copy get-joins join a-cols a-fields
					b-fields: copy get-joins join b-cols b-fields
				]

				temps: copy []
				unless 0 = length? t/templates [insert temps body-of t/templates]
				if t/default [insert temps compose/deep [default: [(t/default)]]]
				bind temps a-fields
				foreach [key val] temps [put temps key first reduce val] 
				a-fields/(reduce t/name): make a-fields/(reduce t/name) temps
				
				temps: copy []
				unless 0 = length? t/templates [insert temps body-of t/templates]
				if t/default [insert temps compose/deep [default: [(t/default)]]]
				bind temps b-fields
				foreach [key val] temps [put temps key first reduce val] 
				b-fields/(reduce t/name): make b-fields/(reduce t/name) temps
				
				ord: either order [order][collected-by]
				
				a-order: reduce bind copy ord a-fields
				b-order: reduce bind copy ord b-fields
				;probe reduce [a-order b-order order-dirs]
				
				repeat n length? a-order [
					either order [
						case [
							(pick a-order n) < (pick b-order n) [return pick order-dirs n];probe reduce [n pick a-order n pick order-dirs n pick b-order n] 
							(pick a-order n) > (pick b-order n) [return not pick order-dirs n]
						] 
					][
						case [
							(pick a-order n) < (pick b-order n) [return true];probe reduce [n pick a-order n pick order-dirs n pick b-order n] 
							(pick a-order n) > (pick b-order n) [return false]
						] 
					]
				] return true
			] 
			if limit [sel: head remove/part at sel limit (length? sel) - limit]
			field-words: compose [tid (words-of t/fields)]
			cols: copy t/cols
			collected-by-compare: none
			forall sel [ 
				set (field-words) sel/1
				t/id: tid
				all-fields: make copy t/fields reduce [
					to-set-word 'id tid 
					to-set-word t/name make copy t/fields compose [id: (tid)]
				]
				bind cols t/fields
				foreach join t/joined [
					all-fields: get-joins join cols all-fields
				]
				temps: copy []
				unless 0 = length? t/templates [insert temps body-of t/templates]
				if t/default [insert temps compose/deep [default: [(t/default)]]]
				bind temps all-fields
				foreach [key val] temps [put temps key first reduce val] 
				all-fields/(reduce t/name): make all-fields/(reduce t/name) temps
				bind fields all-fields
				if search [
					bind search all-fields 
				]

				either collected [
					;if collected-by [probe reduce [collected-by reduce collected-by]]
					expanded: expand-templates copy fields t
					bind expanded all-fields
					flds: copy reduce [reduce expanded]
					if collected-by [
						collected-by-local: reduce bind collected-by all-fields
						unless collected-by-compare [collected-by-compare: collected-by-local]
						if collected-by-compare <> collected-by-local [
							append/only ret copy/deep local-ret
							local-ret: copy/deep prepared-ret
							collected-by-compare: collected-by-local
						]
					]
					repeat i length? flds/1 either all [properties not tabular] [
						[j: i - 1 * 2 + 2 append/only local-ret/:j reduce flds/1/:i]
					][
						[append/only local-ret/:i flds/1/:i]
					]
					;probe reduce [local-ret funcs col-names col-lengths]
				][
					either properties [
						parse flds: copy fields either tabular [
							[(n: 0) some [
								change set c [word! | paren! | path!]
								(	
									c: expand-templates copy either paren? c [to-block c][reduce [c]] t 
									bind c all-fields 
									c: reduce c
									n: n + 1
									either n > length? col-lengths [
										append col-lengths length? form c
									][
										poke col-lengths n max length? form c col-lengths/:n
									]
									to-paren c
								)
							]]
						][
							[some [
								[
									[	string!
									|	change set c set-word! (to-lit-word c)
									]
									remove set c [word! | paren! | path!]
								|	change set c [word! | paren! | path!]
									(either word? c [to-lit-word c][mold c])
								] 
								insert (
									c: expand-templates copy either paren? c [to-block c][reduce [c]] t 
									bind c all-fields 
									to-paren reduce c
								)
							]]
						]
						append/only ret flds
					][	
						append/only ret reduce fields
					]
				]
			]
		]	
		if collected [
			append/only ret local-ret 
			bind funcs functions 
			;probe reduce [prepared-ret ret]
			forall ret [
				repeat i length? prepared-ret either all [properties not tabular] [[
					if even? i [
						j: i / 2
						unless none = pick funcs j [ret/1/:i: do reduce [pick funcs j ret/1/:i]]
					]
				]][[
					unless none = pick funcs i [ret/1/:i: do reduce [pick funcs i ret/1/:i]]
					if tabular [
						either i > length? col-lengths [
							append col-lengths length? form ret/1/:i
						][
							poke col-lengths i max length? form ret/1/:i col-lengths/:i
						]
					]
				]]
			];probe reduce [ret col-names col-lengths]
		]
		t/selected: sel
		t/returned: ret
	]
	
	;#####     CHANGE RECORDS     #####
	
	change-selected: func [changes table /local t recs cols field value cols-rule][
		t: tables/:table
		recs: t/selected
		cols: copy t/cols
		cols-rule: t/cols-rule
		forall recs [
			set cols recs/1 
			parse changes [
				some [(field: value: none)
					set field cols-rule 'to copy value to ['and | end] 
					(change at recs/1 index? find t/cols field reduce value)
					[end | skip]
				]
			]
		]
	]
	
	;#####     REMOVE RECORDS     #####
	
	remove-from: func [table][
		t: tables/:table
		either not empty? t/selected [
			sel: reverse t/selected
			forall sel [remove/part sel/1 t/width t/length: t/length - 1]
		][
			cause-error 'user 'message reduce [
				rejoin ["No records from '" table "' selected!"]]
			]
	]
	
	;#####     MAIN FUNCTION     #####

	set 'query function [
		spec [block!] 
		/debug
		/local word returned tblspec records file limit fields table search code 
			criterion by pos method collected collected-by properties value tmp 
			no-records prop qry tabular;all-records 
	][
		fields-rule: [
			set fields ['all | 'default | block!]
		|	['field | 'fields | 'column | 'columns | 'cols] (fields: 'cols)
		| 	['template | 'templates] (fields: 'templates)
		| 	set tmp word! if (block? get/any tmp)(fields: get tmp)
		] 
		tables-rule2: [
			;opt ['all (search: criterion: none)]
			[	set table tables-rule
			| 	set tmp word! if (find words-of dbx/tables get/any tmp)(table: get tmp)
			]	(active: table)
			;opt search-rule opt by-rule
		]
		search-rule: [;[ 
			'with [set search block! | set tmp word! if (block? get/any tmp)(search: get tmp)]
		;|	not ['by | keyword] set criterion skip (search: 'default)
		|	set criterion skip if (
			all [
				either word? criterion [criterion: get/any criterion][true] 
				either block? criterion [empty? fields][true] 
				(type? criterion) = type? do tables/:active/default
			] 
		) (search: 'default)
		] ;(all-records: no)]
		by-rule: ['by set by integer! (tables/:active/last-by: by)]
		collected-rule: [
			'collected (collected: yes) 
			opt ['by set collected-by [word! | block!]]
		]
		limit-rule: [set limit integer!]
		order-rule: ['in opt [
				['descending | 'desc] (direction: 'descending) 
			| 	['ascending  | 'asc]  (direction: 'ascending)
			]	set order [word! | block! | paren!] 'order
		]
		parse spec [
			some [
				set code paren! (do code)
			|	opt [set word set-word!]
				[
					'table set table skip ;tables-rule2 ;
					opt [
						set tblspec block! (returned: make-table table tblspec)
					;|	set file file! (put tables word do file); load? PROOVIMATA
					] 	(active: table)
				|	['from | 'for] [
						'selected (selected: yes) tables-rule2 
					|	tables-rule2 
					|	'selected (selected: yes)
					]
				|	'db	
				|	['get | set method ['print opt ['tabular (tabular: yes)]| 'probe | 'view ]]; | 'browse | 'do]] 
					(
						fields: clear [] qry: yes direction: 'ascending
						limit: table: search: criterion: collected: collected-by: properties: order: none ;no-records
					)
					any [
						'tables (returned: reduce [keys-of dbx/tables] qry: no)
					|	'table set table tables-rule set prop skip 
						(
							returned: reduce switch/default prop [
								templates [[tables/:table/templates]] 
								default  [[tables/:table/default]]
								cols 	 [[tables/:table/cols]]
								spec	 [[tables/:table/spec]]
							][[tables/:table/templates/:prop]]
							unless returned/1 [returned: reduce [rejoin ["No such template in '" table "!"]]]
							qry: no
						)
					|	tables-rule2 fields-rule ;(no-records: yes)
					|	limit-rule
					|	by-rule
					|	fields-rule
					| 	'properties (properties: yes)
					|	'of opt [limit-rule | 'all (criterion: search: none)] 
					|	tables-rule2
					|	collected-rule
					|	[not [word! | block!] | ahead 'with] search-rule
					|	order-rule
					]
					(
						if qry [;probe dbx/active
							get-from active collected fields search criterion limit debug properties collected-by order direction tabular 
							returned: either not by [
								copy tables/:active/returned
							][
								tables/:active/last-n: by
								tables/:active/last-by: by
								copy/part tables/:active/returned by
							]
						]
						either tabular [
							do-method/tabular method returned either properties [tables/:active/params/col-names][copy []] either properties [tables/:active/params/col-lengths][copy []]
						][
							do-method method returned
						]
						if all [qry method] [tables/:active/method: method]
					)
				|	'next opt [set by integer!] opt [set table tables-rule (active: table)] 
					(
						table: tables/:active 
						returned: copy/part at table/returned table/last-n + 1 table/last-by: any [by table/last-by]
						table/last-n: table/last-n + table/last-by
						method: table/method
						do-method method returned
					)
				|	'remove (scope: 'selected limit: search: criterion: none) 
					opt [set limit integer!] 
					opt [set scope ['all | 'selected]] 
					opt [set table tables-rule (active: table)]
					opt [search-rule]
					(
						if any [scope = 'all search criterion limit][
							get-from active none clear [] search criterion limit
						]
						returned: clear []
						cols: tables/:active/cols
						sel: tables/:active/selected
						forall sel [set cols sel/1 repend returned copy cols]
						remove-from active
					)
				] 	(if word [set :word returned word: none])
			|	'add opt [set table tables-rule (active: table)] 
				;copy fields to block! ; TBD
				set records skip ;(probe records) ;block! 
				(either empty? fields [
					add-records :active records
				][
					add-records/fields :active records fields
				]
				)
			|	'set copy changes to [keyword | end]
				;'set set changes skip 'to copy value to [keyword | end]
				(change-selected changes active); value)
			| 	'show []
			] 
		]
	]
]
comment {}
