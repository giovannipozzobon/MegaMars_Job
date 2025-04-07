(define memories
'(
	(memory zeroPage (address (#x2 . #xff)) (type ram) (qualifier zpage)
		(section (registers #x2))
	)
	
	(memory stackPage (address (#x100 . #x1ff))
		(type ram)
	)

	(memory prog (address (#x1200 . #x5fff)) (type any)
		(section
			(programStart #x1200)
			startup
			code
			data
			switch
			cdata
			data_init_table
		)
	)

	(memory hzd (address (#x6000 . #x6fff)) (type any)
		(section
			heap
			zdata
		)
	)
))
