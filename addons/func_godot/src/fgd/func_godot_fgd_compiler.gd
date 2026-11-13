@tool
class_name FuncGodotFGDCompiler extends RefCounted

## Monad used to write a FGD file as well as manage errors
## The main purpose of this class is the error management to be able to 
## denote when the final export of a FGD should be aborted entirely
## 
## This type is used both as a string builder as well as a thing for functions
## to return to denote errors

## Configuration settings for the compiler
class Options:
	# leaving this in here in the off chance I actually port this outside 
	var print_messages_to_stdout := true

	# whether to print out 'info' messages
	var verbose := false

	## whether or not to generate models from scene files (see [FuncGodotFGDModelPointClass])
	var generate_models := true

	## comment to add at the very end of the generated output
	var vim_modeline := r"vim:ft=quake:"

	## Compilation target editor
	var target: FuncGodotFGDFile.FuncGodotTargetMapEditors:
		get: return FuncGodotFGDFile.FuncGodotTargetMapEditors.TRENCHBROOM

## Message
enum MessageType {
	FATAL = 0,  # Message denotes a fatal error, the compilation should be aborted
	SEVERE = 1,  # Message denotes a severe error, able to proceed but may produce unwanted / clipped FGD's
	WARN= 2,  # Message denoting a warning that is not critical to fix 
	INFO =3,  # Message denoting standard log / information for the compile process
}

const MESSAGE_TYPE_TO_STRING: PackedStringArray = [
	"FATAL",
	"SEVERE",
	"WARN",
	"INFO",
]

class Message:
	## whether this message is a fatal error
	var type: MessageType

	## contents of the message
	var contents: String

	## tag for where this message came from / name of compiler
	var tag: String

	func _init(type: MessageType, tag: String, args: Array):
		self.contents = "".join(args.map(func(obj): return str(obj)))
		self.type = type
		self.tag = tag

	func print():
		var prefix := "[%s]['%s'][FGDCompiler]:" % [MESSAGE_TYPE_TO_STRING[type], tag]

		match type:
			FuncGodotFGDCompiler.MessageType.FATAL:
				printerr(prefix, '\n', contents)
			FuncGodotFGDCompiler.MessageType.SEVERE:
				printerr(prefix, '\n', contents)
			FuncGodotFGDCompiler.MessageType.WARN:
				push_warning('\n', prefix, '\n', contents)
			FuncGodotFGDCompiler.MessageType.INFO:
				print(prefix, contents)

	# whether or not this message counts as 'verbose' / is not vital to print
	func is_verbose() -> bool:
		return type != MessageType.INFO


enum TokenType {
	INTEGER,
	DECIMAL,
	DECIMAL_LIST,
	INTEGER_LIST,
	WORD,
	STRING,
	JSON,
	PAREN_OPEN,
	PAREN_CLOSE,
	BRACKET_OPEN,
	BRACKET_CLOSE,
	EQUALS,
	COLON,
	COMMA,
	PLUS,
	NEW_LINE,
	COMMENT,
}

class Token:
	## Array of all characters allowed to delimit a word
	static var WORD_DELIMITER := RegEx.create_from_string(r"[ \t\n\r()[\]?;:,=]")

	var type: TokenType
	var text: String

	func _init(type: TokenType, text: String=""):
		self.type = type
		self.text = text

	static func word(text: String) -> Token:
		assert(
			WORD_DELIMITER.search(text) == null,
			"A word cannot have delimiters: '%s'" % text
		)
		assert(not text.is_empty(), "A word cannot be empty")
		return Token.new(TokenType.WORD, text)

	static func string(text: String) -> Token:
		return Token.new(
			TokenType.STRING,
			text.replace('"', "'")
		)

	static func json_string(obj: Variant) -> Token:
		return Token.new(TokenType.JSON, JSON.stringify(obj))

	static func integer(num: int) -> Token:
		return Token.new(TokenType.INTEGER, str(num))

	static func decimal(num: float) -> Token:
		return Token.new(TokenType.DECIMAL, str(num))

	static func decimal_list(array: Array[float]) -> Token:
		return Token.new(TokenType.DECIMAL_LIST, " ".join(array))

	static func integer_list(array: Array[int]) -> Token:
		return Token.new(TokenType.INTEGER_LIST, " ".join(array))

	static func paren_open() -> Token:
		return Token.new(TokenType.PAREN_OPEN)

	static func paren_close() -> Token:
		return Token.new(TokenType.PAREN_CLOSE)

	static func bracket_open() -> Token:
		return Token.new(TokenType.BRACKET_OPEN)

	static func bracket_close() -> Token:
		return Token.new(TokenType.BRACKET_CLOSE)

	static func equals() -> Token:
		return Token.new(TokenType.EQUALS)

	static func colon() -> Token:
		return Token.new(TokenType.COLON)

	static func comma() -> Token:
		return Token.new(TokenType.COMMA)

	static func plus() -> Token:
		return Token.new(TokenType.PLUS)

	static func new_line() -> Token:
		return Token.new(TokenType.NEW_LINE)

	static func comment(text: String) -> Token:
		return Token.new(
			TokenType.COMMENT,
			text.replace("\n", " ").replace("\t", " ")
		)

	## Whether or not this token (when building as text) would require a delimiter afterwards to be
	## grammatically correct (FGD)
	func needs_delimiter() -> bool:
		return type in [
			TokenType.INTEGER,
			TokenType.DECIMAL,
			TokenType.WORD,
			TokenType.STRING,
			TokenType.JSON,
			TokenType.EQUALS,
			TokenType.COLON,
			TokenType.COMMA,
			TokenType.PLUS,
		]

var tokens: Array[Token] = []

## buffer of all emitted messages
var messages: Array[Message] = []

var options: Options

## Tag / identifier for this compiler
var _tag: String

## Target map editor being compiled for. For this project, it will always be trenchbroom
const target_editor := FuncGodotFGDFile.FuncGodotTargetMapEditors.TRENCHBROOM

func _init(tag: String, options):
	assert(not tag.is_empty(), "Empty Tag")
	assert(options != null, "Compiler options cannot be null")
	_tag = tag
	self.options = options

## Constructs a new compiler with its tag (for error handling) set to the path of the resource
static func new_from_resource(resource: Resource, options: Options) -> FuncGodotFGDCompiler:
	var tag := resource.resource_name

	if tag.is_empty(): tag = resource.resource_path.get_file()
	if tag.is_empty(): tag = "<unknown>"

	return FuncGodotFGDCompiler.new(tag, options)


## Stores the message and prints if should_print is set to true
func msg(message: Message):
	messages.append(message)
	if options.print_messages_to_stdout and (options.verbose or message.is_verbose()):
		message.print()

## Emits a warning
func warn(...args: Array):
	return msg(Message.new(MessageType.WARN, _tag, args))

## Emits a simple info log
func info(...args: Array):
	return msg(Message.new(MessageType.INFO, _tag, args))

## Emits a fatal message, fatal messages mean that compilation should be stopped right then and there
func fatal(...args: Array):
	return msg(Message.new(MessageType.FATAL, _tag, args))

## Emits a severe message, severe messages are important errors but can technically be ignored / continue compilation.
## This is for things that are severe but not programmatically dangerous as to crash the compile process. 
##
## Ex. a malformed entity classname might emit a 'severe' warning as it would be inadvisable to continue to build the
## FGD with the malformed entity, but continuing the compilation is still possible and should go on as to collect
## more warnings & messages for the user. 
##
## Syntax checkers don't just stop at the first missing semicolon, they try to get as many present errors as possible.
func severe(...args: Array):
	return msg(Message.new(MessageType.SEVERE, _tag, args))

## Gets all messages with the given type
func get_messages_of_type(type: MessageType) -> Array[Message]:
	return messages.filter(func(msg: Message): return msg.type == type)

## Are there any fatal error messages present
func has_fatal_errors() -> bool:
	return not get_messages_of_type(MessageType.FATAL).is_empty()

## Are there any severe error messages present
func has_severe_errors() -> bool:
	return not get_messages_of_type(MessageType.SEVERE).is_empty()

## Are there any warnings present
func has_warnings() -> bool:
	return not get_messages_of_type(MessageType.WARN).is_empty()

## Gets all messages that are warnings, severe, or fatal. The returned array will be sorted such that 
## more severe messages are brought to the top
func get_errors_and_warnings() -> Array[Message]:
	var errors := messages.filter(func(msg: Message): return msg.type != MessageType.INFO)
	errors.sort_custom(func(a: Message, b: Message): return a.type > b.type)
	return errors

## Write a raw token
func write(token: Token) -> void:
	tokens.append(token)

func write_comment(comment: String) -> void:
	write(Token.comment(comment))

## Writes a integer token
func write_word(word: String) -> void:
	write(Token.word(word))

## Writes a integer token
func write_string(word: String) -> void:
	write(Token.string(word))

## Writes a integer token
func write_json(obj: Variant) -> void:
	write(Token.json_string(obj))

## Writes a integer token
func write_integer(num: int) -> void:
	write(Token.integer(num))

## Writes a float token
func write_float(num: float) -> void:
	write(Token.decimal(num))

## Writes a paren_open token
func write_paren_open() -> void:
	write(Token.paren_open())

## Writes a paren_close token
func write_paren_close() -> void:
	write(Token.paren_close())

## Writes a bracket_open token
func write_bracket_open() -> void:
	write(Token.bracket_open())

## Writes a bracket_close token
func write_bracket_close() -> void:
	write(Token.bracket_close())

## Writes a equals token
func write_equals() -> void:
	write(Token.equals())

## Writes a colon token
func write_colon() -> void:
	write(Token.colon())

## Writes a comma token
func write_comma() -> void:
	write(Token.comma())

## Writes a plus token
func write_plus() -> void:
	write(Token.plus())

## Writes a new_line token
func write_new_line() -> void:
	write(Token.new_line())

## Writes a list of integers
func write_int_list(numbers: Array[int], quotes: bool=false) -> void:
	write(Token.string(" ".join(numbers)) if quotes else Token.integer_list(numbers))

func write_float_list(numbers: Array[float], quotes: bool=false) -> void:
	write(Token.string(" ".join(numbers)) if quotes else Token.decimal_list(numbers))

func write_vector4(vec: Vector4, quotes: bool=false) -> void:
	write_float_list([vec.x, vec.y, vec.z, vec.w], quotes)

func write_vector4i(vec: Vector4i, quotes: bool=false) -> void:
	write_int_list([vec.x, vec.y, vec.z, vec.w], quotes)

func write_vector3(vec: Vector3, quotes: bool=false) -> void:
	write_float_list([vec.x, vec.y, vec.z], quotes)

func write_vector3i(vec: Vector3i, quotes: bool=false) -> void:
	write_int_list([vec.x, vec.y, vec.z], quotes)

func write_vector2(vec: Vector2, quotes: bool=false) -> void:
	write_float_list([vec.x, vec.y], quotes)

func write_vector2i(vec: Vector2i, quotes: bool=false) -> void:
	write_int_list([vec.x, vec.y], quotes)

func write_color(color: Color, quotes: bool=false) -> void:
	write_int_list([color.r8, color.g8, color.b8], quotes)

# Merges the given compiler with this one, adds all of its text contents to this one and
# Inherits all of its messages
func compose(compiler: FuncGodotFGDCompiler) -> void:
	messages.append_array(compiler.messages)
	tokens.append_array(compiler.tokens)

const SIMPLE_TOKEN_STRINGS := {
	TokenType.EQUALS: "=",
	TokenType.COLON: ":",
	TokenType.COMMA: ",",
	TokenType.PLUS: "+",
}

## Builds the written buffer to a single string
func build() -> String:
	var buffer := PackedStringArray()

	var tab_level := 0

	var append_newline := func(tabs: int):
		buffer.append(FuncGodotUtil.newline())
		buffer.append("\t".repeat(tabs))

	# helper function to add a token delimiter
	for i in range(tokens.size()):
		var token := tokens[i]
		var type: TokenType = token.type

		# if previous token needs delimitation
		if i > 0 and tokens[i - 1].needs_delimiter():
			buffer.append(" ")

		# simple one letter tokens
		if SIMPLE_TOKEN_STRINGS.has(type):
			buffer.append(SIMPLE_TOKEN_STRINGS[type])
			continue

		match token.type:
			# these tokens can just be used as-is with their text
			TokenType.INTEGER, TokenType.WORD, TokenType.INTEGER_LIST, TokenType.DECIMAL_LIST, TokenType.JSON:
				# already baked in for us
				buffer.append(token.text)

			# both strings and single floats are required to be quoted
			TokenType.STRING, TokenType.DECIMAL:
				buffer.append('"')
				buffer.append(token.text)
				buffer.append('"')

			TokenType.PAREN_OPEN:
				buffer.append('(')

			TokenType.PAREN_CLOSE:
				buffer.append(')')

			TokenType.BRACKET_OPEN:
				append_newline.call(tab_level)
				buffer.append('[')

				tab_level += 1
				append_newline.call(tab_level)

			TokenType.BRACKET_CLOSE:
				tab_level -= 1
				append_newline.call(tab_level)

				buffer.append(']')

				append_newline.call(tab_level)

			TokenType.NEW_LINE:
				append_newline.call(tab_level)

			TokenType.COMMENT:
				append_newline.call(tab_level)
				buffer.append("// ")
				buffer.append(token.text)
				append_newline.call(tab_level)
			_:
				assert(false, "Unreachable / unexpected token " + str(token))

	if not options.vim_modeline.is_empty():
		append_newline.call(tab_level)
		buffer.append_array(["// ", options.vim_modeline])

	return "".join(buffer)

## Saves the compiled output into the file
func save_to_file(file: FileAccess):
	assert(file.is_open(), "Cannot save to unopened file")
	file.store_string(build())