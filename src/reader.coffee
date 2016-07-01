type = require "./type"
{Prim, Symbol, Keyword, StringObj, Char, Discard, BigInt, char, kw, sym ,bigInt} = require "./atoms"
{Iterable, List, Vector, Set, Pair, Map} = require "./collections"
{Tag, Tagged, tagActions} = require "./tags"
{encodeHandlers, encode, encodeJson} = require "./encode"
{handleToken, tokenHandlers} = require "./tokens"

typeClasses = {Map, List, Vector, Set, Discard, Tag, Tagged, StringObj}
parens = '()[]{}'
specialChars = parens + ' \t\n\r,'
escapeChar = '\\'
parenTypes = 
	'(' : closing: ')', class: "List"
	'[' : closing: ']', class: "Vector"
	'{' : closing: '}', class: "Map"

#based on the work of martin keefe: http://martinkeefe.com/dcpl/sexp_lib.html
lex = (string) ->
	list = []
	lines = []
	line = 1
	token = ''
	col = 1
	
	lastToken = 0
	
	newToken = (name, line, col) ->
		temp = {token: name, lineStart: line, colStart: col, lineEnd: line, colEnd: col}
		if lastToken != 0
			temp.lineStart = lastToken.lineEnd
			temp.colStart = lastToken.colEnd
		lastToken = temp
		list.push(temp)
	
	for c in string
		if c in ["\n", "\r"] then line++; col = 1

		if not in_string? and c is ";" and not escaping?
			in_comment = true
			
		if in_comment
			if c is "\n"
				in_comment = undefined
				if token
					newToken token, line, col
					token = ''
			col++
			continue
			
		if c is '"' and not escaping?
			if in_string?
				newToken (new StringObj in_string), line, col
				in_string = undefined
			else
				in_string = ''
			col++
			continue

		if in_string?
			if c is escapeChar and not escaping?
				escaping = true
				col++
				continue

			if escaping? 
				escaping = undefined
				if c in ["t", "n", "f", "r"] 
					in_string += escapeChar

			in_string += c
		else if c in specialChars and not escaping?
			if token
				newToken token, line, col
				token = ''
			if c in parens
				newToken c, line, col
		else
			if escaping
				escaping = undefined
			else if c is escapeChar
				escaping = true
			
			if token is "#_"
				newToken token, line, col
				token = ''
			token += c
		col++

	if token
		newToken token, line, col
	{tokens: list, tokenLines: lines}

#based roughly on the work of norvig from his lisp in python
read = (ast) ->
	{tokens, tokenLines} = ast

	expectedParen = 0

	read_ahead = (token, tokenIndex = 0, expectSet = false) ->
		if token.token is undefined then return

		if (not (token.token instanceof StringObj)) and paren = parenTypes[token.token]
			closeParen = paren.closing
			L = []
			startLine = token.lineStart
			startCol = token.colStart
			outerToken = token

			while true
				token = tokens.shift()
				if token.token is undefined then throw "unexpected end of list at line #{token.lineStart}:#{token.colStart}-#{token.lineEnd}:#{token.colEnd}"
				expectedParen = closeParen
				tokenIndex++
				if token.token is paren.closing
					newObj = new typeClasses[if expectSet then "Set" else paren.class] L
					newObj.setPos startLine, startCol, token.lineEnd, token.lineEnd
					return newObj
				else 
					L.push read_ahead token, tokenIndex

		else if token.token in ")]}"
			throw "expected #{expectedParen} but got unexpected #{token.token} at line #{token.lineStart}:#{token.colStart}-#{token.lineEnd}:#{token.colEnd}"
		else
			handledToken = handleToken token.token
			if handledToken instanceof Tag
				token = tokens.shift()
				tokenIndex++

				if token.token is undefined then throw "was expecting something to follow a tag at line #{token.lineStart}:#{token.colStart}-#{token.lineEnd}:#{token.colEnd}"

				tagged = new typeClasses.Tagged handledToken, read_ahead token, tokenIndex, handledToken.dn() is ""
				tagged.setPos token.lineStart, token.colStart, token.lineEnd, token.colEnd

				if handledToken.dn() is ""
					if tagged.obj() instanceof typeClasses.Set
						return tagged.obj()
					else
						throw "Exepected a set but did not get one at line #{token.lineStart}:#{token.colStart}-#{token.lineEnd}:#{token.colEnd}"
					
				if tagged.tag().dn() is "_"
					return new typeClasses.Discard
				
				if tagActions[tagged.tag().dn()]?
					return tagActions[tagged.tag().dn()].action tagged.obj()
				
				return tagged
			else
				if handledToken.setPos
					handledToken.setPos token.lineStart, token.colStart, token.lineEnd, token.colEnd
				return handledToken

	token1 = tokens.shift()
	if token1.token is undefined
		return undefined 
	else
		result = read_ahead token1
		if result instanceof typeClasses.Discard 
			return ""
		#result.setPos token1.line, 0, 7, 7
		return result
		
parse = (string) -> read lex string 

module.exports = 
	Char: Char
	char: char
	Iterable: Iterable
	Symbol: Symbol
	sym: sym	
	Keyword: Keyword
	kw: kw
	BigInt: BigInt
	bigInt: bigInt 
	List: List
	Vector: Vector
	Pair: Pair
	Map: Map
	Set: Set
	Tag: Tag
	Tagged: Tagged

	setTypeClass: (typeName, klass) -> 
		if typeClasses[typeName]?
			module.exports[typeName] = klass 
			typeClasses[typeName] = klass
			
	setTagAction: (tag, action) -> tagActions[tag.dn()] = tag: tag, action: action
	setTokenHandler: (handler, pattern, action) -> tokenHandlers[handler] = {pattern, action}
	setTokenPattern: (handler, pattern) -> tokenHandlers[handler].pattern = pattern
	setTokenAction: (handler, action) -> tokenHandlers[handler].action = action
	setEncodeHandler: (handler, test, action) -> encodeHandlers[handler] = {test, action}
	setEncodeTest: (type, test) -> encodeHandlers[type].test = test
	setEncodeAction: (type, action) -> encodeHandlers[type].action = action
	parse: parse
	encode: encode
	encodeJson: encodeJson
	toJS: (obj) -> if obj?.jsEncode? then obj.jsEncode() else obj
	atPath: require "./atPath"
	unify: require("./unify")(parse)
	compile: require "./compile"

if typeof window is "undefined"
	fs = require "fs"
	module.exports.readFile = (file, cb) -> 
		fs.readFile file, "utf-8", (err, data) -> 
			if err then throw err
			cb parse data

	module.exports.readFileSync = (file) -> 
		parse fs.readFileSync file, "utf-8"
