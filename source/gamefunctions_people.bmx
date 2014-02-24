Type TPerson
	Field name:string				= ""
	Field sex:Int					= 0	'0=Mann 1=Frau
	Field personType:string			= 0 '0=director, 1=host, 2=actor, 3=musician, 4=intellectual, 5=reporter
	
	Field genreExpertise:TList		= CreateList()	'Die Genre in welcher der Schauspieler, Regisseur Experte ist.
	
	Field professionSkill:Int		= 0 '0 - 100	Für Regisseur, Musiker und Intellektueller: Wie gut kann er sein Handwerk	
	Field fame:Int					= 0 '0 - 100	Kinokasse ++							Wie berühmt ist die Person?
	Field success:Int				= 0 '0 - 100	Kinokasse +		Kritik +	Tempo+		Wie erfolgreich ist diese Person?
		
	'Charakter
	Field power:Int					= 0 '0 - 100	Kinokasse +		Tempo +++		Bonus bei manchen Genre (wie Action)
	Field humor:Int					= 0 '0 - 100	Kinokasse +		Tempo ++		Bonus bei manchen Genre (wie Komödie)
	Field charisma:Int				= 0 '0 - 100	Kinokasse +		Kritik ++		Bonus bei manchen Genre (wie Liebe, Drama, Komödie)
	Field eroticAura:Int			= 0 '0 - 100	Kinokasse +++ 	Tempo +			Bonus bei manchen Genre (wie Erotik, Liebe, Action)
	Field characterSkill:Int		= 0 '0 - 100	Kinokasse +		Kritik +++		Bonus bei manchen Genre (wie Drama)
	
	Field scandalizing:Int			= 0 '0 - 100	Besonders Interessant für Shows und Sonderevents	
	Field priceFactor:Int			= 0 '0 - 100	Für die Manipulation des Preises. Manche sind teurer/günstiger als ihre Leistung erwarten würde.
	
	Method GetActorBaseFee:Int() 'Das Grundhonorar	
		local sum:float = 50 + power + humor + charisma + eroticAura + characterSkill '(50 bis 550)
		Local factor:Float = (fame*0.7 + success*0.3)/50
		
		Return 3000 + Floor(Int(sum * factor * 200 * priceFactor / 50)/100)*100
	End Method
	
	Method GetGuestFee:Int() 'Kosten als Studiogast		
		local sum:float = 50 + fame*2 + success*0.5 + professionSkill		
		Return 100 + Floor(Int(sum * priceFactor / 50)/100)*100
	End Method
End Type