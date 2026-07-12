SuperStrict
Import Collections.ObjectList
Import "base.gfx.imagehelper.bmx"
Import "base.util.registry.bmx"
Import "base.util.registry.spriteloader.bmx"
Import "base.util.fastrandom.bmx"

New TRegistryFigureGeneratorPartLoader.Init()

Global FigureGenerator:TFigureGenerator = New TFigureGenerator


Type TFigureGenerator
	Field registeredParts:TObjectList[11]
	Field maxPartDimension:SVec2I

	'draw order:
	'       1,    2,     3,    4,     5,    6,     7,    8,       9,    10, 11
	'hairBack, body, cloth,  ears, face, eyes, mouth, nose, eyebrow, beard, hair
	Global partOrder:Int[] = [ 9,   1,  11,   5,   2,   3,   6,   4,   7,  8,  10]
	Global useChance:Int[] = [100, 100, 100, 100, 100, 100, 100, 100, 100, 25,100]
	Global clothColorPresets:SColor8[]
	Global skinTonePresets:SColor8[][]
	Global hairColorPresets:SColor8[][]

	'indices into TFigureGeneratorFigure.hairColorPresets[x]
	Const HAIR_BLONDE:Int = 0
	Const HAIR_BLACK:Int = 1
	Const HAIR_BROWN:Int = 2
	Const HAIR_RED:Int = 3
	Const HAIR_GREY:Int = 4

	'used eg as indices into TFigureGeneratorFigure.skinTonePresets[x]
	Const ETHNICITY_CAUCASIAN:Int = 0
	Const ETHNICITY_AFRICAN:Int = 1
	Const ETHNICITY_ASIAN:Int = 2 'includes South-America, Mediterranean Sea...
	Const ETHNICITY_ALIEN:Int = 3 'includes Martians, Critters etc


	Method New()
		maxPartDimension = New SVec2I(-1, -1)
	
		If Not clothColorPresets
			clothColorPresets = New SColor8[24]
			clothColorPresets[ 0] = New SColor8(35, 35, 35)	'blackish
			clothColorPresets[ 1] = New SColor8(255, 180, 0)
			clothColorPresets[ 2] = New SColor8(100, 130, 0)
			clothColorPresets[ 3] = New SColor8(215, 210, 0)
			clothColorPresets[ 4] = New SColor8(120, 220, 0)
			clothColorPresets[ 5] = New SColor8(50, 220, 0)
			clothColorPresets[ 6] = New SColor8(250, 50, 120)
			clothColorPresets[ 7] = New SColor8(0, 180, 220)
			clothColorPresets[ 8] = New SColor8(0, 80, 220)
			clothColorPresets[ 9] = New SColor8(100, 80, 200)
			clothColorPresets[10] = New SColor8(220, 0, 40)
			clothColorPresets[11] = New SColor8(40, 190, 70)
			clothColorPresets[12] = New SColor8(40, 0, 220)
			clothColorPresets[13] = New SColor8(200, 100, 90)
			clothColorPresets[14] = New SColor8(40, 70, 130)
			clothColorPresets[15] = New SColor8(170, 70, 90)
			clothColorPresets[16] = New SColor8(255, 140, 0)
			clothColorPresets[17] = New SColor8(70, 170, 130)
			clothColorPresets[18] = New SColor8(0, 105, 255)
			clothColorPresets[19] = New SColor8(230, 90, 60)
			clothColorPresets[20] = New SColor8(230, 130, 70)
			clothColorPresets[21] = New SColor8(100, 100, 100) 'dark gray
			clothColorPresets[22] = New SColor8(230, 230, 230) 'light gray
			clothColorPresets[23] = New SColor8(150, 150, 150) 'mid gray
		EndIf
		
		If Not hairColorPresets Or hairColorPresets.Length = 0
			hairColorPresets = hairColorPresets[..5] '5 hair color base types
			
			hairColorPresets[HAIR_BLONDE] = New SColor8[4]
			hairColorPresets[HAIR_BLONDE][0] = New SColor8(225,200,45)
			hairColorPresets[HAIR_BLONDE][1] = New SColor8(235,210,50)
			hairColorPresets[HAIR_BLONDE][2] = New SColor8(225,180,40)
			hairColorPresets[HAIR_BLONDE][3] = New SColor8(235,220,30)

			hairColorPresets[HAIR_BLACK] = New SColor8[3]
			hairColorPresets[HAIR_BLACK][0] = New SColor8(30,25,20)
			hairColorPresets[HAIR_BLACK][1] = New SColor8(50,35,20)
			hairColorPresets[HAIR_BLACK][2] = New SColor8(30,30,20)

			hairColorPresets[HAIR_BROWN] = New SColor8[5]
			hairColorPresets[HAIR_BROWN][0] = New SColor8(80,30,10)
			hairColorPresets[HAIR_BROWN][1] = New SColor8(90,42,18)
			hairColorPresets[HAIR_BROWN][2] = New SColor8(115,55,35)
			hairColorPresets[HAIR_BROWN][3] = New SColor8(96,53,25)
			hairColorPresets[HAIR_BROWN][4] = New SColor8(125,80,35)

			hairColorPresets[HAIR_RED] = New SColor8[3]
			hairColorPresets[HAIR_RED][0] = New SColor8(255,100,0)
			hairColorPresets[HAIR_RED][1] = New SColor8(245,120,15)
			hairColorPresets[HAIR_RED][2] = New SColor8(250,125,65)

			hairColorPresets[HAIR_GREY] = New SColor8[2]
			hairColorPresets[HAIR_GREY][0] = New SColor8(160,160,160)
			hairColorPresets[HAIR_GREY][1] = New SColor8(130,130,130)
		EndIf

		If Not skinTonePresets Or skinTonePresets.Length = 0
			skinTonePresets = skinTonePresets[..4] '3 skin tone base types
		
			'caucasian
			skinTonePresets[ETHNICITY_CAUCASIAN] = New SColor8[3]
			skinTonePresets[ETHNICITY_CAUCASIAN][0] = New SColor8(255, 226, 207) 'northern
			skinTonePresets[ETHNICITY_CAUCASIAN][1] = New SColor8(255, 207, 173)
			skinTonePresets[ETHNICITY_CAUCASIAN][2] = New SColor8(234, 176, 152)

			'african
			skinTonePresets[ETHNICITY_AFRICAN] = New SColor8[3]
			skinTonePresets[ETHNICITY_AFRICAN][0] = New SColor8(148, 115, 82)
			skinTonePresets[ETHNICITY_AFRICAN][1] = New SColor8(132, 55, 34)
			'skinTonePresets[ETHNICITY_AFRICAN][2] = New SColor8(61, 12, 2) 'sorry, but this is too dark next to bright elements, no offense!
			skinTonePresets[ETHNICITY_AFRICAN][2] = New SColor8(101, 19, 6)

			'asian
			skinTonePresets[ETHNICITY_ASIAN] = New SColor8[4]
			skinTonePresets[ETHNICITY_ASIAN][0] = New SColor8(229, 184, 135)
			skinTonePresets[ETHNICITY_ASIAN][1] = New SColor8(218, 174, 148)
			skinTonePresets[ETHNICITY_ASIAN][2] = New SColor8(205, 127, 50)
			skinTonePresets[ETHNICITY_ASIAN][3] = New SColor8(223, 185, 151)

			'alien
			skinTonePresets[ETHNICITY_ALIEN] = New SColor8[4]
			skinTonePresets[ETHNICITY_ALIEN][0] = New SColor8(229, 80, 90)
			skinTonePresets[ETHNICITY_ALIEN][1] = New SColor8(90, 200, 200)
			skinTonePresets[ETHNICITY_ALIEN][2] = New SColor8(90, 230, 75)
			skinTonePresets[ETHNICITY_ALIEN][3] = New SColor8(85, 100, 210)
		EndIf
	End Method


	Method RegisterPart(part:TFigureGeneratorPart)
		If part.partType < 1 Or part.partType > registeredParts.Length Then Return
		Local index:Int = part.partType -1
		
		If Not registeredParts[index] 
			registeredParts[index] = New TObjectList()
		EndIf
		
		If Not registeredParts[index].contains(part)
			registeredParts[index].Addlast(part)
		EndIf
		
		' update part max dimension cache
		Local s:TSprite = part.GetSprite()
		If s
			maxPartDimension = New SVec2I(Max(maxPartDimension.x, s.GetWidth()), Max(maxPartDimension.y, s.GetHeight()))
		EndIf
	End Method


	Method GetPartsList:TObjectList(partType:Int)
		If partType < 1 Or partType > registeredParts.Length Then Return Null

		Return registeredParts[partType - 1]
	End Method


	Method GetFilteredParts:TFigureGeneratorPart[](partType:Int, gender:Int, age:Int, includeIncompleteParts:Int=False)
		Local partList:TObjectList = GetPartsList(partType)
		If Not partList Then Return Null

		
		' need to filter
		' as there aren't hundreds of parts, it is easier to allocate
		' a bigger array already and most probably save some re-allocs
		Local filteredParts:TFigureGeneratorPart[]
		Local index:Int
		For Local p:TFigureGeneratorPart = EachIn registeredParts[partType -1]
			If p.gender <> 0 And p.gender <> gender Then Continue
			If p.age <> 0 And p.age <> age Then Continue
			If Not includeIncompleteParts And p.incompletePart Then Continue
	
			If index >= filteredParts.Length
				filteredParts = filteredParts[.. filteredParts.Length + 10]
			EndIf

			filteredParts[index] = p
			index :+ 1
		Next
		
		Return filteredParts[.. index]
	End Method


	Method GetRandomPart:TFigureGeneratorPart(partType:Int, gender:Int, age:Int, randomSeed:Int)
		Local potentialParts:TFigureGeneratorPart[] = GetFilteredParts(partType, gender, age)
		
		' return one of the fitting ones (or null if none fitted)
		If potentialParts.Length = 0
			Return Null
		Else
			Return potentialParts[ New SFastRandom(randomSeed).RandomInt(0, potentialParts.Length - 1) ]
		EndIf
	End Method


	Method GetRandomHairPair:TFigureGeneratorPart[](gender:Int, age:Int, randomSeed:Int)
		Local result:TFigureGeneratorPart[]

		'choose a random front hair - and if it requires a specific
		'backhair, fetch it (if possible)
		Local hairFront:TFigureGeneratorPart = GetRandomPart(TFigureGeneratorPart.PART_HAIR_FRONT, gender, age, randomSeed)
		If hairFront
			If hairFront.hairBackSpriteName
				'iterate over all hair backs until sprite name fits (crude but simple)
				For Local p:TFigureGeneratorPart = EachIn GetPartsList(TFigureGeneratorPart.PART_HAIR_BACK)
					If hairFront.hairBackSpriteName.Equals(p.spriteName, False)
						result = New TFigureGeneratorPart[2]
						result[0] = hairFront
						result[1] = p
						Return result
					EndIf
				Next
			EndIf
			
			result = New TFigureGeneratorPart[1]
			result[0] = hairFront
			Return result
		EndIf
		
		Return Null
	End Method


	'return a pair for body/trunk and overlayed clothing
	Method GetRandomClothBodyPair:TFigureGeneratorPart[](gender:Int, age:Int, randomSeed:Int)
		Local result:TFigureGeneratorPart[]

		'choose a random cloth/trunk - and a suiting "body" (trunkSkin)
		'which might be only a small part of the available ones
		Local cloth:TFigureGeneratorPart = GetRandomPart(TFigureGeneratorPart.PART_CLOTH, gender, age, randomSeed)
		If cloth
			'only compatible with certain skins
			If cloth.compatibleBody.Length > 0
				'filter first (maybe age/gender limits even more)
				'do incomplete parts as compatibleBody will either include them or not
				Local potentialBodies:TFigureGeneratorPart[] = GetFilteredParts(TFigureGeneratorPart.PART_BODY, gender, age, True)
				Local compatibleBodies:TFigureGeneratorPart[]

				'iterate over all bodies until sprite name fits (crude but simple)
				For Local p:TFigureGeneratorPart = EachIn potentialBodies
					If StringHelper.InArray(p.spriteName, cloth.compatibleBody, False)
						compatibleBodies :+ [p]
					EndIf
				Next
				
				If compatibleBodies.Length > 0
					result = New TFigureGeneratorPart[2]
					result[0] = cloth
					result[1] = compatibleBodies[ New SFastRandom(randomSeed).RandomInt(0, compatibleBodies.Length - 1) ]
					Return result
				EndIf
				
'Rem
			'compatible to all: means "all" are feasible (or none)
			Else
				result = New TFigureGeneratorPart[2]
				result[0] = cloth
				result[1] = GetRandomPart(TFigureGeneratorPart.PART_BODY, gender, age, randomSeed)
				Return Result
'endrem
			EndIf
			
			result = New TFigureGeneratorPart[1]
			result[0] = cloth
			Return result
		EndIf
		
		Return Null
	End Method


	Method GetPart:TFigureGeneratorPart(partType:Int, index:Int)
		Local partList:TObjectList = GetPartsList(partType)
		If Not partList Then Return Null
		' index out of bounds?
		If index < 0 Or index >= partList.Count() Then Return Null

		Return TFigureGeneratorPart(partList.ValueAtIndex(index))
	End Method


	Method GetPartIndex:Int(partType:Int, part:TFigureGeneratorPart)
		Local partList:TObjectList = GetPartsList(partType)
		If Not partList Then Return -1

		For Local i:Int = 0 Until partList.Count()
			If part = TFigureGeneratorPart(partList.data[i])
				Return i
			EndIf
		Next
		Return -1
	End Method
	

	' generates a figure defined in a code-string
	Method GenerateFigure:TFigureGeneratorFigure(code:String)
		Return GenerateRandomFigure(code, 0)
	End Method


	' generates a figure defined in a code-string
	Method GenerateRandomFigure:TFigureGeneratorFigure(code:String, randomSeed:Int)
		'print "GenerateRandomFigure: code="+code

		Local subCodes:String[] = code.Split(":")
		If subCodes.Length < 4 + TFigureGeneratorFigureConfig.partsCount
			' just seed
			If subCodes.Length = 1
				' (to allow a "error message" as "default" - see end of 
				'  function, we only accept it if the seed is a valid
				'  number!)
				Local seed:Int = Int(subCodes[0])
				If subCodes[0] = String(seed)
					Return GenerateRandomFigure(Int(subCodes[0]))
				EndIf

			' gender:seed -> random skintone, gender, random age, seed
			ElseIf subCodes.Length = 2
				Return GenerateRandomFigure(0, Int(subCodes[0]), 0, Int(subCodes[1]))

			' gender:age:seed -> random skintone, gender, random age, seed
			ElseIf subCodes.Length = 3
				Return GenerateRandomFigure(0, Int(subCodes[0]), Int(subCodes[1]), Int(subCodes[2]))

			' gender:age:skinTone:seed -> skinTone, gender, age
			ElseIf subCodes.Length >= 4
				Return GenerateRandomFigure(Int(subCodes[2]), Int(subCodes[0]), Int(subCodes[1]), Int(subCodes[3]))
			EndIf
		Else
			Local fig:TFigureGeneratorFigure = New TFigureGeneratorFigure
			Local skinTone:TColor
			Local colors:TColor[TFigureGeneratorFigureConfig.partsCount]
			Local partStartIndex:Int = 4
			
			fig.gender = Int(subCodes[0])
			fig.age = Int(subCodes[1])
			'ethnicity and skinTone in one String...
			Local ethnicityAndSkinTone:String[] = subCodes[2].Split("#")
			fig.ethnicity = Int(ethnicityAndSkinTone[0])
			
			If ethnicityAndSkinTone.Length > 1
				skinTone = New TColor.FromHex(ethnicityAndSkinTone[1])
			Else
				skinTone = TColor.clWhite
			EndIf

			Local defaultColor:SColor8 = New SColor8(255,255,255,255) 'full alpha, no tinting

			For Local i:Int = 0 Until Min(subCodes.Length, registeredParts.Length)
				Local partCode:String[] = subCodes[i + partStartIndex].split("#")
				Local partIndex:Int = Int(partCode[0])
				Local partType:Int = i + 1
				If partIndex < 0
					fig.SetPart(partType, Null)
					fig.SetPartColor(partType, defaultColor)
					Continue
				EndIf

				Local part:TFigureGeneratorPart = GetPart(partType, partIndex)
				If Not part
					fig.SetPart(partType, Null)
					fig.SetPartColor(partType, defaultColor)
					Continue
				EndIf
				
				fig.SetPart(partType, part)
				If partCode.Length = 2
					colors[partType -1] = New TColor.FromHex(partCode[1])

					'set skinTone if not done yet (globally or via other skin part)
					If part.IsSkinPart() And Not skinTone
						skinTone = colors[partType -1]
					EndIf
				Else
					fig.SetPartColor(partType, defaultColor)
				EndIf
			Next

			'set base skin tone (also set individual parts)
			fig.SetSkinTone(New SColor8(skinTone.r, skinTone.g, skinTone.b), True)

			'override skincolors if needed
			For Local i:Int = 0 Until colors.Length
				' only set valid colors, all other colors like "explicit null"
				' are set before 
				If colors[i] Then fig.SetPartColor(i+1, New SColor8(colors[i].r, colors[i].g, colors[i].b))
			Next

			Return fig
		EndIf

		Print "GenerateFigureFromCode(): invalid code. Using absolute random params for generator."
		Return GenerateRandomFigure( randomSeed )
	End Method


	' generate a "pure" random figure (depends on seed)
	Method GenerateRandomFigure:TFigureGeneratorFigure(randomSeed:Int)
		Return GenerateRandomFigure(TFigureGenerator.ETHNICITY_CAUCASIAN, 0, 0, randomSeed)
	End Method


	Method GenerateRandomFigure:TFigureGeneratorFigure(ethnicity:Int, gender:Int, age:Int)
		Return GenerateRandomFigure:TFigureGeneratorFigure(ethnicity, gender, age, 0)
	End Method
	

	Method GenerateRandomFigure:TFigureGeneratorFigure(ethnicity:Int, gender:Int, age:Int, randomSeed:Int)
		' fallback to "random" for invalid params
		If ethnicity < 0 Or ethnicity > 4 Then ethnicity = TFigureGenerator.ETHNICITY_CAUCASIAN
		If gender < 0 Or gender > 2 Then gender = 0
		If age < 0 Or age > 2 Then age = 0

		' randomize
		' when removing/adding - keep "seed + x" constant (so results
		' do not change for these attributes)
		If gender = 0 Then gender = New SFastRandom(randomSeed + 1).RandomInt(1,2)
		If ethnicity = 0 Then ethnicity = New SFastRandom(randomSeed + 2).RandomInt(1,3)
		If age = 0 Then age = New SFastRandom(randomSeed + 3).RandomInt(1,2)

		' now gender and age are assured
		Local fig:TFigureGeneratorFigure = New TFigureGeneratorFigure
		fig.gender = gender
		fig.age = age
		fig.ethnicity = ethnicity

		fig.seed = randomSeed

		Return fig
	End Method
	
	
	Method GenerateImage:TImage(config:TFigureGeneratorFigureConfig, createEmptyOnFailure:Int = False)
		Local img:TImage = CreateImage(maxPartDimension.x, maxPartDimension.y, DYNAMICIMAGE | FILTEREDIMAGE, PF_RGBA8888)
		LockImage(img).ClearPixels(0)
		
		For Local partType:Int = EachIn partOrder
			Local p:TFigureGeneratorPart = config.parts[partType - 1]
			If Not p Then Continue

			Local s:TSprite = p.GetSprite()
			If Not s Then Continue
			
			local offset:SVec2I = config.GetPartOffset(p)

			DrawImageOnImageSColor(s.GetImage(0, False), img, 0 + offset.x, 0 + offset.y, config.partsColor[partType -1])
		Next
		
		Return img
	End Method
	
	
	' Get a skinTone variation based on a ethnicity (AFRICAN, ASIAN, CAUCASIAN) 
	Method GetRandomSkinTone:SColor8(ethnicity:Int, randomSeed:Int)
		Local fastRandom:SFastRandom = New SFastRandom(randomSeed + 200)
		Local variation:Int = fastRandom.RandomInt(0, skinTonePresets[ethnicity -1].Length - 1)
		Local mixColor:SColor8 = skinTonePresets[ethnicity -1][variation] 'copy!

		' add variation to the color
		Select ethnicity -1 'compare as index
			Case TFigureGenerator.ETHNICITY_AFRICAN
				'prefer brighter variants to avoid too dark overall images - clothes, hair, skin)
				mixColor = SColor8Helper.AdjustHSL(mixColor, 0, 0, fastRandom.RandomInt(10, 30)/100.0)
			Case TFigureGenerator.ETHNICITY_ASIAN
				mixColor = SColor8Helper.AdjustHSL(mixColor, 0, 0, fastRandom.RandomInt(-5, 10)/100.0)
'			case 3
			Default 'european/caucasian
				'prefer darker variants to avoid too pale overall images - clothes, hair, skin)
				mixColor = SColor8Helper.AdjustHSL(mixColor, 0, 0, fastRandom.RandomInt(-10, -0)/100.0)
		EndSelect
		
		Return mixColor
	End Method
	
	
	Method GetRandomConfig:TFigureGeneratorFigureConfig(ethnicity:Int, gender:Int, age:Int, randomSeed:Int)
		Local config:TFigureGeneratorFigureConfig = New TFigureGeneratorFigureConfig

		' assign the skin tone base, and after body part creation assign
		' it to there too. Doing it twice allows to use the skinTone already
		' during selection
		config.skinTone = GetRandomSkinTone(ethnicity, randomSeed)
	
		' randomize body parts
		Local hairPair:TFigureGeneratorPart[] = GetRandomHairPair(gender, age, randomSeed)
		Local clothBodyPair:TFigureGeneratorPart[] = GetRandomClothBodyPair(gender, age, randomSeed)

		For Local i:Int = 0 Until TFigureGenerator.partOrder.Length
			Local partType:Int = TFigureGenerator.partOrder[i]
			' randomly skip _optional_ elements (eg. glasses)
			If TFigureGenerator.useChance[i] <> 100
				If New SFastRandom(randomSeed + partType).RandomInt(100) > TFigureGenerator.useChance[i] Then Continue
			EndIf


			Local part:TFigureGeneratorPart
			'special handling for body, cloth, hair/hairback
			If partType = TFigureGeneratorPart.PART_BODY 
				If clothBodyPair.Length < 1 Then Throw "no suiting body found and no covering cloth defined"
				If clothBodyPair.Length > 1
					part = clothBodyPair[1]
				EndIf
			ElseIf partType = TFigureGeneratorPart.PART_CLOTH
				If clothBodyPair.Length < 1 Then Throw "no cloth/body found"
				part = clothBodyPair[0]
			ElseIf partType = TFigureGeneratorPart.PART_HAIR_BACK 
				If hairPair.Length >= 2 'only if a hair back is defined
					part = hairPair[1]
				EndIf
			ElseIf partType = TFigureGeneratorPart.PART_HAIR_FRONT 
				If hairPair.Length >= 1 'only if a hair is defined
					part = hairPair[0]
				EndIf
			Else
				part = GetRandomPart(partType, gender, age, randomSeed + partType)
			EndIf


			If part
				'got a gender specific part? use for rest
				If part.gender <> 0 Then gender = part.gender
				If part.age <> 0 Then age = part.age
			EndIf
			
			config.SetPart(partType, part)
		Next


		'hair - base is caucasian
		Local fastRandom:SFastRandom = New SFastRandom(randomSeed + 123)
		Local chanceBlonde:Int = 15
		Local chanceBlack:Int = 10
		Local chanceBrown:Int = 69
		Local chanceRed:Int = 4
		Local chanceCrazy:Int = 2
		
		If ethnicity = ETHNICITY_AFRICAN
			If gender = 2
				chanceBlack = 65
				chanceBrown = 20
				chanceBlonde = 5
				chanceRed = 5
				chanceCrazy = 5
			Else
				chanceBlack = 80
				chanceBrown = 10
				chanceBlonde = 5
				chanceRed = 3
				chanceCrazy = 2
				If age = 2
					chanceBlack = 87
					chanceBrown = 10
					chanceBlonde = 1
					chanceRed = 1
					chanceCrazy = 1
				EndIf
			EndIf
		ElseIf ethnicity = ETHNICITY_ASIAN
			chanceBlonde = 2
			chanceBlack = 75
			chanceBrown = 8
			chanceRed = 5
			If gender = 2
				chanceCrazy = 10
			Else
				chanceBlack = 83
				chanceCrazy = 2
			EndIf
		EndIf
		Local hairColor:SColor8
		Local hairTone:Int = fastRandom.RandomInt(100)
		Local hairColorPreset:Int 

		'blonde
		If hairTone < chanceBlonde
			hairColorPreset = TFigureGenerator.HAIR_BLONDE
		'black
		ElseIf hairTone < chanceBlonde + chanceBlack
			hairColorPreset = TFigureGenerator.HAIR_BLACK
		'brown
		ElseIf hairTone < chanceBlonde + chanceBlack + chanceBrown
			hairColorPreset = TFigureGenerator.HAIR_BROWN
		'red
		Else
			hairColorPreset = TFigureGenerator.HAIR_RED
		EndIf

		Local variation:Int = fastRandom.RandomInt(0, TFigureGenerator.hairColorPresets[hairColorPreset].Length - 1)
		hairColor = TFigureGenerator.hairColorPresets[hairColorPreset][variation] 'copy!

		
		'gray?
		If age = 2 And fastRandom.RandomInt(100) > 75
			'25% chance we fade out the color (does not work for black hair...
			If hairColorPreset <> HAIR_BLACK And fastRandom.RandomInt(100) > 75
				haircolor = SColor8Helper.AdjustHSL(hairColor, 0, - fastRandom.RandomInt(30, 75)/100.0, 0)
			Else
				Local greyVariation:Int = fastRandom.RandomInt(0, hairColorPresets[TFigureGenerator.HAIR_GREY].Length - 1)
				hairColor = hairColorPresets[TFigureGenerator.HAIR_GREY][greyVariation]
			EndIf
		EndIf
		
		hairColor = SColor8Helper.AdjustHSL(hairColor, 0, 0, fastRandom.RandomInt(-15, 15)/100.0)

		config.SetPartColor(TFigureGeneratorPart.PART_HAIR_BACK, hairColor)
		config.SetPartColor(TFigureGeneratorPart.PART_HAIR_FRONT, hairColor)
		config.SetPartColor(TFigureGeneratorPart.PART_BEARD, hairColor)
		config.SetPartColor(TFigureGeneratorPart.PART_EYEBROWS, hairColor)


		'cloth
		Local clothColor:SColor8
		If fastRandom.RandomInt(100) < 20
			If gender = 1
				clothColor = New SColor8(fastRandom.RandomInt(1, 8)*16, fastRandom.RandomInt(1, 8)*31, fastRandom.RandomInt(1, 8)*31)
			ElseIf gender = 2
				clothColor =  New SColor8(fastRandom.RandomInt(0, 8)*31, fastRandom.RandomInt(0, 8)*31, fastRandom.RandomInt(0, 8)*16)
			Else
				clothColor =  New SColor8(fastRandom.RandomInt(0, 8)*31, fastRandom.RandomInt(0, 8)*31, fastRandom.RandomInt(0, 8)*31)
			EndIf

			'minimum brightness
			If fastRandom.RandomInt(100) < 75
				clothColor = SColor8Helper.AdjustBrightness(clothColor, fastRandom.RandomInt(30)/100.0 + 0.3) '30% - 60%
			EndIf
		' select from a preset
		Else
			Local presetIndex:Int = fastRandom.RandomInt(0, clothColorPresets.Length-1)
			clothColor = clothColorPresets[presetIndex] ' copy
			clothColor = SColor8Helper.AdjustHSL(clothColor, 0, 0, fastRandom.RandomInt(-10, 10)/100.0) '-10% - 10%
			
			Local adjustColorOrTint:Int = fastRandom.RandomInt(100)
			If adjustColorOrTint < 25
				Local modifyHue:Int = fastRandom.RandomInt(-10, 10)
				clothColor = SColor8Helper.AdjustHSL(clothColor, modifyHue/100.0, 0, 0)
			ElseIf adjustColorOrTint < 50
				clothColor = SColor8Helper.AdjustHSL(clothColor, 0, 0.2 - fastRandom.RandomInt(50)/100.0, 0)
			EndIf
		EndIf
		config.SetPartColor(TFigureGeneratorPart.PART_CLOTH, clothColor)


		config.SetSkinTone(config.skinTone, True)
		
		Return config
	End Method

End Type





Type TFigureGeneratorFigureConfig
	Field parts:TFigureGeneratorPart[11]
	Field partsColor:SColor8[11]
	' tone/color of visual skin elements (individual overrides possible)
	Field skinTone:SColor8
	
	Global partsCount:Int = 11
	
	
	Method New()
		'default all parts colors to white/untinted and fully visible
		For Local i:Int = 0 Until partsColor.Length
			partsColor[i] = New SColor8(255,255,255,255)
		Next
	End Method


	Method SetPart(partType:Int, part:TFigureGeneratorPart = Null)
		If partType < 1 Or partType > parts.Length Then Return
		
		parts[partType-1] = part
	End Method
	

	Method SetPartColor(partType:Int, color:SColor8)
		If partType < 1 Or partType > parts.Length Then Return
		
		partsColor[partType-1] = color
	End Method
	
	
	' set color to all parts defined as (showing) "skin"
	Method SetSkinTone(tone:SColor8, overrideSkinParts:Int = False)
		skinTone = tone
		
		For Local i:Int = 0 Until parts.Length
			If Not parts[i] Then Continue
			If Not parts[i].IsSkinPart() Then Continue
			partsColor[i] = tone
		Next
	End Method


	Method GetSkinTone:SColor8()
		Return skinTone
	End Method
	
	
	Method GetPart:TFigureGeneratorPart(partType:Int)
		If partType < 1 Or partType > parts.Length Then Return Null
		Return parts[partType - 1]
	End Method
	
	
	Method GetPartOffset:SVec2I(partType:Int)
		If partType < 1 Or partType > parts.Length Then Return Null
		
		Return GetPartOffset(parts[partType - 1])
	End Method
	
	
	Method GetPartOffset:SVec2I(p:TFigureGeneratorPart)
		If Not p Then Return Null
		If Not p.parentType Then Return p.offset 'only "own offset"

		'fetch (recursively) the child offsets of parents
		Local result:SVec2I = p.offset
		Local parent:TFigureGeneratorPart = GetPart(p.parentType)
		While parent
			result = result + parent.childrenOffset

			If Not parent.parentType then exit
			parent = GetPart(parent.parentType)
		Wend
		Return result
	End Method
	
	
	Method SerializeTFigureGeneratorFigureConfigToString:String()
		Local code:String
		Local colString:String
		For Local i:Int = 0 Until parts.Length
			If code Then code :+ ":"
			Local partType:Int = i + 1
			If parts[i]
				Local partIndex:Int = FigureGenerator.GetPartIndex(partType, parts[i])
				If partIndex<>-1
					code :+ partIndex
					If Not parts[i].IsSkinPart() Or partsColor[i] <> skinTone
						colString = Hex(partsColor[i].ToRGBA())
						'strip off alpha (not needed)
						colString = colString[.. colString.Length - 2]
						code :+ "#" + colString
					EndIf
					Continue
				EndIf
			EndIf

			code :+"-1"
		Next
		
		Return code
	End Method
End Type




Type TFigureGeneratorFigure
	Field flags:Int
	Field gender:Int = 0
	Field age:Int = 0
	Field ethnicity:Int = TFigureGenerator.ETHNICITY_CAUCASIAN
	' seed used to generate the figure
	Field seed:Int
	' skintone and individual parts config (if differing to "seed")
	Field config:TFigureGeneratorFigureConfig

	Const PART_BODY:Int = 1        'was 3
	Const PART_FACE:Int = 2        'was 6
	Const PART_EYES:Int = 3        'was 7
	Const PART_NOSE:Int = 4        'was 9
	Const PART_EARS:Int = 5        'was 10
	Const PART_MOUTH:Int = 6       'was 11
	Const PART_EYEBROWS:Int = 7    'was 13
	Const PART_BEARD:Int = 8       'was 14
	Const PART_HAIR_BACK:Int = 9   'was 2
	Const PART_HAIR_FRONT:Int = 10 'was 12
	Const PART_CLOTH:Int = 11      'was 5 

	Const FLAG_IS_CUSTOMIZED:Int = 1

	
	Method SetFlag(flag:Int, enable:Int)
		If enable
			flags :| flag
		Else
			flags :& ~flag
		EndIf
	End Method


	Method HasFlag:Int(flag:Int)
		Return (flags & flag)
	End Method
	
	
	Method IsCustomized:Int()
		Return HasFlag(FLAG_IS_CUSTOMIZED)
	End Method

	
	Method GetFigureCode:String()
		Local code:String = gender+":"+age+":"+ethnicity
		
		If IsCustomized()
			Local skinTone:SColor8 = GetSkinTone()
			Local colString:String = Hex(skinTone.ToRGBA())
			'strip off alpha (not needeD)
			colString = colString[.. colString.Length - 2]
			code :+ "#" + colString
		EndIf
		
		code :+ ":" + seed
			
		If config
			code :+ ":" + config.SerializeTFigureGeneratorFigureConfigToString()
		EndIf
		Return code
	End Method


	Method SetSkinTone(tone:SColor8, overrideSkinParts:Int = False)
		If Not config Then config = New TFigureGeneratorFigureConfig
		config.SetSkinTone(tone)

		SetFlag(FLAG_IS_CUSTOMIZED, True)
	End Method


	Method GetSkinTone:SColor8()
		If Not config Then config = FigureGenerator.GetRandomConfig(ethnicity, gender, age, seed)
		Return config.GetSkinTone()
'
Rem
		If config Then Return config.GetSkinTone()

		GenerateRandomConfig(seed)
		Local tempConfig:TFigureGeneratorFigureConfig = self.config
		config = Null
		SetFlag(FLAG_IS_CUSTOMIZED, False)
		
		Return tempConfig.skinTone
endrem
	End Method


	Method SetPart(partType:Int, part:TFigureGeneratorPart = Null)
		If Not config Then config = New TFigureGeneratorFigureConfig
		config.SetPart(partType, part)

		SetFlag(FLAG_IS_CUSTOMIZED, True)
	End Method
	

	Method SetPartColor(partType:Int, color:SColor8)
		If Not config Then config = New TFigureGeneratorFigureConfig
		config.SetPartColor(partType, color)

		SetFlag(FLAG_IS_CUSTOMIZED, True)
	End Method


	Method Randomize(randomSeed:Int)
		' find a suitable skin tone (set it again at the end so it can
		' override body parts without an individual setting)
'		SetSkinToneBase(ethnicity, randomSeed + 4, False)

		Self.config = FigureGenerator.GetRandomConfig(ethnicity, gender, age, randomSeed)

		'set skin tone again
		'SetSkinToneBase(ethnicity, randomSeed + 4, True)
'		SetSkinTone(config.skinTone, True)
	End Method


	Method GenerateImage:TImage()
		'generate parts config if not done yet
		Local configCreated:Int
		If Not config
			config = FigureGenerator.GetRandomConfig(ethnicity, gender, age, seed)
			configCreated = True
		EndIf
		
		Local img:TImage = FigureGenerator.GenerateImage(config, True)
	
		' clean up config if we just created it for the image generation 
		If configCreated
			config = Null
			SetFlag(FLAG_IS_CUSTOMIZED, False)
		EndIf

		Return img
	End Method
End Type




Type TFigureGeneratorPart
	Field sprite:TSprite {nosave}
	Field spriteName:String
	Field partType:Int
	Field gender:Int = 0
	Field age:Int = 0
	
	'part specific, but to keep things easy, all in one here...
	Field incompletePart:Int 'eg only a throat, not a complete body
	'children of this part will be offset on y for this value
	'(eg facial features like eyes/nose/... are children of heads)
	Field childrenOffset:SVec2I
	'custom individual offset
	Field offset:SVec2I
	Field hairBackSpriteName:String
	Field compatibleBody:String[]
	Field parentType:Int 'eg "PART_FACE" for "PART_EYES"


	Const PART_BODY:Int = 1        'was 3
	Const PART_FACE:Int = 2        'was 6
	Const PART_EYES:Int = 3        'was 7
	Const PART_NOSE:Int = 4        'was 9
	Const PART_EARS:Int = 5        'was 10
	Const PART_MOUTH:Int = 6       'was 11
	Const PART_EYEBROWS:Int = 7    'was 13
	Const PART_BEARD:Int = 8       'was 14
	Const PART_HAIR_BACK:Int = 9   'was 2
	Const PART_HAIR_FRONT:Int = 10 'was 12
	Const PART_CLOTH:Int = 11      'was 5 


	Method Init:TFigureGeneratorPart(sprite:TSprite, partType:Int, gender:Int = 0, age:Int = 0)
		Self.sprite = sprite
		If sprite
			Self.spriteName = sprite.name
		Else
			Self.spriteName = ""
		EndIf
		Self.partType = partType
		Self.gender = gender
		Self.age = age

		Select partType
			Case PART_FACE        Self.parentType = PART_BODY
			Case PART_EYES        Self.parentType = PART_FACE
			Case PART_NOSE        Self.parentType = PART_FACE
			Case PART_EARS        Self.parentType = PART_FACE
			Case PART_MOUTH       Self.parentType = PART_FACE
			Case PART_EYEBROWS    Self.parentType = PART_FACE
			Case PART_BEARD       Self.parentType = PART_FACE
			Case PART_HAIR_BACK   Self.parentType = PART_FACE
			Case PART_HAIR_FRONT  Self.parentType = PART_FACE
			Case PART_CLOTH       Self.parentType = PART_BODY
		End Select
		
		Return Self
	End Method
	

	Method GetGUID:String()
		If sprite Then Return partType + "_" + sprite.name + "_" + gender + "_" +age
		Return partType + "_" + "nosprite" + "_" + gender + "_" +age
	End Method


	Method GetSprite:TSprite()
		If Not sprite
			If spriteName Then sprite = GetSpriteFromRegistry(spriteName)
		EndIf
		Return sprite
	End Method

	Method Draw(x:Int, y:Int)
		If Not GetSprite() Then Return
		
		sprite.Draw(x,y)
	End Method


	Method Draw(x:Int, y:Int, tintColor:SColor8)
		If Not GetSprite() Then Return
		
		Local oldCol:SColor8; GetColor(oldCol)
		SetColor(SColor8Helper.Mix(oldCol, tintColor))
		sprite.Draw(x,y)
		SetColor(oldCol)
	End Method
	
	
	Method IsHairPart:Int()
		Select partType
			Case PART_HAIR_BACK, PART_HAIR_FRONT, PART_BEARD, PART_EYEBROWS
				Return True
			Default
				Return False
		End Select
	End Method
	
	
	Method IsSkinPart:Int()
		Select partType
			Case PART_BODY, PART_FACE, PART_NOSE, PART_EARS
				Return True
			Default
				Return False
		End Select
	End Method
End Type





'===== NEWS GENRE LOADER =====
'loader caring about "<figuregeneratorpart>"
Type TRegistryFigureGeneratorPartLoader Extends TRegistryBaseLoader
	Method Init:Int()
		name = "FigureGeneratorPart"
		resourceNames = "figuregeneratorpart|fgpart"
		If Not registered Then Register()
	End Method


	'creates - modifies default resource
	Method CreateDefaultResource:Int()
		'do nothign
	End Method


	Method GetConfigFromXML:TData(loader:TRegistryLoader, node:TxmlNode)
		Local fieldNames:String[]
		Local data:TData = New TData
		fieldNames :+ ["sprite", "age", "gender", "skin", "partType", "offsetX", "offsetY", "childrenOffsetX", "childrenOffsetY", "hairBack", "compatibleBody", "incompletePart"]
		TXmlHelper.LoadValuesToData(node, data, fieldNames)

		Return data
	End Method


	Method GetNameFromConfig:String(data:TData)
		Return data.GetString("name","unknownfiguregenetatorpart")
	End Method


	Method LoadFromConfig:TFigureGeneratorPart(data:TData, resourceName:String)
		'create the figuregenerator part
		Local spriteName:String = data.GetString("sprite", "")
		'load the sprite
		Local sprite:TSprite = GetSpriteFromRegistry(spriteName)

		Local partType:Int = data.GetInt("partType", 0)
		Local gender:Int = data.GetInt("gender", 0)
		Local age:Int = data.GetInt("age", 0)
		Local part:TFigureGeneratorPart = New TFigureGeneratorPart.Init( sprite, partType, gender, age)
		
		part.incompletePart = data.GetInt("incompletePart", 0)
		
		'(for now) face specific (but could be body-cloth, body-face too
		Local offX:Int = data.GetInt("childrenOffsetX", 0)
		Local offY:Int = data.GetInt("childrenOffsetY", 0)
		part.childrenOffset = New SVec2I(offX, offY)
		
		' invidual offset
		offX = data.GetInt("offsetX", 0)
		offY = data.GetInt("offsetY", 0)
		part.offset = New SVec2I(offX, offY)

		'hair(front) specific ...
		part.hairBackSpriteName = data.GetString("hairBack", "")
		'trunk specific
		Local compatibleBody:String = data.GetString("compatibleBody", "")
		If compatibleBody
			part.compatibleBody = compatibleBody.Split(",")
		EndIf
		
		FigureGenerator.RegisterPart( part )

		Return part
	End Method
End Type
