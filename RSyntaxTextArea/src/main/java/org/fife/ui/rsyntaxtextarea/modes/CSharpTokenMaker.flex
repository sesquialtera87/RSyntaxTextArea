/*
 * 11/13/2004
 *
 * CSharpTokenMaker.java - An object that can take a chunk of text and return
 * a linked list of tokens representing it in the C# programming language.
 * 
 * This library is distributed under a modified BSD license.  See the included
 * LICENSE file for details.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * A lexer for the C# programming language.
 *
 * This implementation was created using
 * <a href="https://www.jflex.de/">JFlex</a> 1.4.1; however, the generated file
 * was modified for performance.  Memory allocation needs to be almost
 * completely removed to be competitive with the handwritten lexers (subclasses
 * of <code>AbstractTokenMaker</code>), so this class has been modified so that
 * Strings are never allocated (via yytext()), and the scanner never has to
 * worry about refilling its buffer (needlessly copying chars around).
 * We can achieve this because RText always scans exactly 1 line of tokens at a
 * time, and hands the scanner this line as an array of characters (a Segment
 * really).  Since tokens contain pointers to char arrays instead of Strings
 * holding their contents, there is no need for allocating new memory for
 * Strings.<p>
 *
 * The actual algorithm generated for scanning has, of course, not been
 * modified.<p>
 *
 * If you wish to regenerate this file yourself, keep in mind the following:
 * <ul>
 *   <li>The generated <code>CSharpTokenMaker.java</code> file will contain two
 *       definitions of both <code>zzRefill</code> and <code>yyreset</code>.
 *       You should hand-delete the second of each definition (the ones
 *       generated by the lexer), as these generated methods modify the input
 *       buffer, which we'll never have to do.</li>
 *   <li>You should also change the declaration/definition of zzBuffer to NOT
 *       be initialized.  This is a needless memory allocation for us since we
 *       will be pointing the array somewhere else anyway.</li>
 *   <li>You should NOT call <code>yylex()</code> on the generated scanner
 *       directly; rather, you should use <code>getTokenList</code> as you would
 *       with any other <code>TokenMaker</code> instance.</li>
 * </ul>
 *
 * @author Robert Futrell
 * @version 0.5
 *
 */
%%

%public
%class CSharpTokenMaker
%extends AbstractJFlexCTokenMaker
%unicode
%type org.fife.ui.rsyntaxtextarea.Token


%{


	/**
	 * Constructor.  This must be here because JFlex does not generate a
	 * no-parameter constructor.
	 */
	public CSharpTokenMaker() {
		super();
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 * @see #addToken(int, int, int)
	 */
	private void addHyperlinkToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so, true);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int tokenType) {
		addToken(zzStartRead, zzMarkedPos-1, tokenType);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param array The character array.
	 * @param start The starting offset in the array.
	 * @param end The ending offset in the array.
	 * @param tokenType The token's type.
	 * @param startOffset The offset in the document at which this token
	 *                    occurs.
	 */
	@Override
	public void addToken(char[] array, int start, int end, int tokenType, int startOffset) {
		super.addToken(array, start,end, tokenType, startOffset);
		zzStartRead = zzMarkedPos;
	}


	@Override
	public String[] getLineCommentStartAndEnd(int languageIndex) {
		return new String[] { "//", null };
	}


	/**
	 * Returns the first token in the linked list of tokens generated
	 * from <code>text</code>.  This method must be implemented by
	 * subclasses so they can correctly implement syntax highlighting.
	 *
	 * @param text The text from which to get tokens.
	 * @param initialTokenType The token type we should start with.
	 * @param startOffset The offset into the document at which
	 *        <code>text</code> starts.
	 * @return The first <code>Token</code> in a linked list representing
	 *         the syntax highlighted text.
	 */
	public Token getTokenList(Segment text, int initialTokenType, int startOffset) {

		resetTokenList();
		this.offsetShift = -text.offset + startOffset;

		// Start off in the proper state.
		int state;
		switch (initialTokenType) {
			case Token.LITERAL_STRING_DOUBLE_QUOTE:
				state = VERBATIMSTRING;
				start = text.offset;
				break;
			case Token.COMMENT_MULTILINE:
				state = DELIMITEDCOMMENT;
				start = text.offset;
				break;
			default:
				state = YYINITIAL;
		}

		s = text;
		try {
			yyreset(zzReader);
			yybegin(state);
			return yylex();
		} catch (IOException ioe) {
			ioe.printStackTrace();
			return new TokenImpl();
		}

	}


	/**
	 * Refills the input buffer.
	 *
	 * @return      <code>true</code> if EOF was reached, otherwise
	 *              <code>false</code>.
	 */
	private boolean zzRefill() {
		return zzCurrentPos>=s.offset+s.count;
	}


	/**
	 * Resets the scanner to read from a new input stream.
	 * Does not close the old reader.
	 *
	 * All internal variables are reset, the old input stream 
	 * <b>cannot</b> be reused (internal buffer is discarded and lost).
	 * Lexical state is set to <tt>YY_INITIAL</tt>.
	 *
	 * @param reader   the new input stream 
	 */
	public final void yyreset(Reader reader) {
		// 's' has been updated.
		zzBuffer = s.array;
		/*
		 * We replaced the line below with the two below it because zzRefill
		 * no longer "refills" the buffer (since the way we do it, it's always
		 * "full" the first time through, since it points to the segment's
		 * array).  So, we assign zzEndRead here.
		 */
		//zzStartRead = zzEndRead = s.offset;
		zzStartRead = s.offset;
		zzEndRead = zzStartRead + s.count - 1;
		zzCurrentPos = zzMarkedPos = zzPushbackPos = s.offset;
		zzLexicalState = YYINITIAL;
		zzReader = reader;
		zzAtBOL  = true;
		zzAtEOF  = false;
	}


%}

/* C1.1 - Line terminators. */
NewlineCharacter						= ([\n])

/* C.1.2 - Whitespace. */
Whitespace							= ([\t ]+)

/* C.1.3 - Comments */
InputCharacter							= ([^\n])
InputCharacters						= ({InputCharacter}+)
DocumentationCommentStart				= ("///")
SingleLineComment						= ("//"([^/]{InputCharacters}?)?)
DelimitedCommentStart					= ("/*")
DelimitedCommentEnd						= ("*/")

/* C.1.5 - Unicode character escape sequences. */
UnicodeEscape1							= ("\\u"{HexDigit}{HexDigit}{HexDigit}{HexDigit})
UnicodeEscape2							= ("\\U"{HexDigit}{HexDigit}{HexDigit}{HexDigit}{HexDigit}{HexDigit}{HexDigit}{HexDigit})
UnicodeEscapeSequence					= ({UnicodeEscape1}|{UnicodeEscape2})

/* C1.6 - Identifiers. */
LetterCharacter						= ([A-Za-z])  /* Not accurate - many more Unicode letters, Unicode escapes */
/*
CombiningCharacter						= ()
*/
DecimalDigitCharacter					= ([0-9])
ConnectingCharacter						= ([_\-])
/*
FormattingCharacter						= ()
*/
/*
IdentifierPartCharacter					= ({LetterCharacter}|{DecimalDigitCharacter}|{ConnectingCharacter}|{CombiningCharacter}|{FormattingCharacter})
*/
IdentifierPartCharacter					= ({LetterCharacter}|{DecimalDigitCharacter}|{ConnectingCharacter})
IdentifierPartCharacters					= ({IdentifierPartCharacter}+)
IdentifierStartCharacter					= ({LetterCharacter}|[_])
IdentifierOrKeyword						= ({IdentifierStartCharacter}{IdentifierPartCharacters}?)
Identifier							= ("@"?{IdentifierOrKeyword})
/* NOTE:  The two below aren't from the C# spec, but we add them so we can */
/* highlight errors.                                                       */
NonSeparator		= (([^\t\f\r\n\ \(\)\{\}\[\]\;\,\.\=\>\<\!\~\?\:\+\-\*\/\&\|\^\%\"\']|"#"|"\\"))
ErrorIdentifier						= ({NonSeparator}+)

/* C1.8 - Literals. */
BooleanLiteral							= ("true"|"false")
DecimalDigit							= ([0-9])
DecimalDigits							= ({DecimalDigit}+)
IntegerTypeSuffix						= (([uU][lL]?)|([lL][uU]?))
DecimalIntegerLiteral					= ({DecimalDigits}{IntegerTypeSuffix}?)
HexDigit								= ([0-9A-Fa-f])
HexDigits								= ({HexDigit}+)
HexadecimalIntegerLiteral				= ("0"[xX]{HexDigits}{IntegerTypeSuffix}?)
Sign									= ([+\-])
ExponentPart							= ([eE]{Sign}?{DecimalDigits})
RealTypeSuffix							= ([fFdDmM])
RealHelper1							= ({DecimalDigits}"."{DecimalDigits}{ExponentPart}?{RealTypeSuffix}?)
RealHelper2							= ("."{DecimalDigits}{ExponentPart}?{RealTypeSuffix}?)
RealHelper3							= ({DecimalDigits}{ExponentPart}{RealTypeSuffix}?)
RealHelper4							= ({DecimalDigits}{RealTypeSuffix})
RealLiteral							= ({RealHelper1}|{RealHelper2}|{RealHelper3}|{RealHelper4})
ErrorNumberFormat						= (({DecimalIntegerLiteral}|{HexadecimalIntegerLiteral}|{RealLiteral}){NonSeparator}+)
SingleCharacter						= ([^\'\\\n])
SimpleEscapeSequence					= ("\\"[\'\"\\0abfnrtv])
HexadecimalEscapeSequence				= ("\\x"{HexDigit}{HexDigit}?{HexDigit}?{HexDigit}?)
Character								= ({SingleCharacter}|{SimpleEscapeSequence}|{HexadecimalEscapeSequence}|{UnicodeEscapeSequence})
UnclosedCharacterLiteral					= ("'"{Character})
CharacterLiteral						= ({UnclosedCharacterLiteral}"'")
ErrorUnclosedCharacterLiteral				= ("'"[^\'\n]*)
ErrorCharacterLiteral					= ("''"|{ErrorUnclosedCharacterLiteral}[\'])
QuoteEscapeSequence						= ("\"\"")
SingleVerbatimStringLiteralCharacter		= ([^\"])
VerbatimStringLiteralStart				= ("@\"")
SingleRegularStringLiteralCharacter		= ([^\"\\\n])
RegularStringLiteralCharacter				= ({SingleRegularStringLiteralCharacter}|{SimpleEscapeSequence}|{HexadecimalEscapeSequence}|{UnicodeEscapeSequence})
RegularStringLiteralCharacters			= ({RegularStringLiteralCharacter}+)
RegularStringLiteral					= ([\"]{RegularStringLiteralCharacters}?[\"])
UnclosedRegularStringLiteral				= ([\"]([\\].|[^\\\"])*[^\"]?)
ErrorRegularStringLiteral				= ({UnclosedRegularStringLiteral}[\"])

/* C.1.9 - Operators and Punctuators. */
OOPHelper1							= (":")
OOPHelper2							= ("+"|"-"|"*"|"/"|"%"|"&"|"|"|"^"|"!"|"~")
OOPHelper3							= ("="|"<"|">"|"?"|"++"|"--"|"&&"|"||"|"<<"|">>")
OOPHelper4							= ("=="|"!="|"<="|">="|"+="|"-="|"*="|"/="|"%="|"&=")
OOPHelper5							= ("|="|"^="|"<<="|">>="|"->")
OperatorOrPunctuator					= ({OOPHelper1}|{OOPHelper2}|{OOPHelper3}|{OOPHelper4}|{OOPHelper5})
/* NOTE:  We distinguish between operators and separators (punctuators), but */
/* the C# spec doesn't, so the stuff below isn't in the spec.                */
Separator								= ([\{\}\[\]\(\)])
Separator2							= ([,;.])

/* C.1.10 - Pre-processing Directives. */
/* NOTE:  We don't do ALL of the PP stuff here as it's unnecessary  */
/* for us to know the difference between declarations, diagnostics, */
/* regions, etc.                                                    */
ConditionalSymbol						= ({IdentifierOrKeyword})	/* Not correct - excludes "true" and "false". */
PPNewLine								= ({Whitespace}?{SingleLineComment}?{NewlineCharacter})
PPPrimaryExpression						= ({IdentifierOrKeyword}|({Whitespace}?{PPExpression}{Whitespace}?))
PPUnaryExpression						= ({PPPrimaryExpression}|("!"{Whitespace}?{PPUnaryExpression}))
PPEqualityExpression					= ({PPUnaryExpression}|({Whitespace}?"=="{Whitespace}?{PPUnaryExpression})|({Whitespace}?"!="{Whitespace}?{PPUnaryExpression}))
PPAndExpression						= ({PPEqualityExpression}|({Whitespace}?"&&"{Whitespace}?{PPEqualityExpression}))
PPOrExpression							= ({PPAndExpression}|({Whitespace}?"||"{Whitespace}?{PPAndExpression}))
PPExpression							= ({Whitespace}?{PPOrExpression}{Whitespace}?)
PPWord								= ("define"|"undef"|"if"|"elif"|"else"|"endif"|"line"|"error"|"warning"|"region"|"endregion")
PPDirective							= ({Whitespace}?"#"{Whitespace}?{PPWord}{InputCharacter}*)

/* URL matching, for comments (not in C# spec) */
URLGenDelim				= ([:\/\?#\[\]@])
URLSubDelim				= ([\!\$&'\(\)\*\+,;=])
URLUnreserved			= ([A-Za-z_]|{DecimalDigitCharacter}|[\-\.\~])
URLCharacter			= ({URLGenDelim}|{URLSubDelim}|{URLUnreserved}|[%])
URLCharacters			= ({URLCharacter}*)
URLEndCharacter			= ([\/\$]|[A-Za-z0-9])
URL						= (((https?|f(tp|ile))"://"|"www.")({URLCharacters}{URLEndCharacter})?)


%state DELIMITEDCOMMENT
%state DOCUMENTCOMMENT
%state VERBATIMSTRING

%%

<YYINITIAL> {

	/* Keywords */
	"abstract" |
	"as" |
	"base" |
	"break" |
	"case" |
	"catch" |
	"checked" |
	"class" |
	"const" |
	"continue" |
	"decimal" |
	"default" |
	"delegate" |
	"do" |
	"else" |
	"enum" |
	"event" |
	"explicit" |
	"extern" |
	"finally" |
	"fixed" |
	"for" |
	"foreach" |
	"goto" |
	"if" |
	"implicit" |
	"in" |
	"interface" |
	"internal" |
	"is" |
	"lock" |
	"namespace" |
	"new" |
	"null" |
	"object" |
	"operator" |
	"out" |
	"override" |
	"params" |
	"private" |
	"protected" |
	"public" |
	"readonly" |
	"ref" |
	"return" |
	"sealed" |
	"sizeof" |
	"stackalloc" |
	"static" |
	"string" |
	"struct" |
	"switch" |
	"this" |
	"throw" |
	"try" |
	"typeof" |
	"unchecked" |
	"unsafe" |
	"using" |
	"virtual" |
	"void" |
	"volatile" |
	"while"								{ addToken(Token.RESERVED_WORD); }

	/* Data types. */
	"bool" |
	"byte" |
	"char" |
	"double" |
	"float" |
	"int" |
	"long" |
	"object" |
	"sbyte" |
	"short" |
	"string" |
	"uint" |
	"ulong" |
	"ushort"							{ addToken(Token.DATA_TYPE); }


	{NewlineCharacter}					{ addNullToken(); return firstToken; }

	{BooleanLiteral}					{ addToken(Token.LITERAL_BOOLEAN); }

	{Identifier}						{ addToken(Token.IDENTIFIER); }

	{Whitespace}						{ addToken(Token.WHITESPACE); }

	/* String/Character Literals. */
	{CharacterLiteral}					{ addToken(Token.LITERAL_CHAR); }
	{UnclosedCharacterLiteral}			{ addToken(Token.ERROR_CHAR); /*addNullToken(); return firstToken;*/ }
	{ErrorUnclosedCharacterLiteral}		{ addToken(Token.ERROR_CHAR); addNullToken(); return firstToken; }
	{ErrorCharacterLiteral}				{ addToken(Token.ERROR_CHAR); }
	{VerbatimStringLiteralStart}			{ start = zzMarkedPos-2; yybegin(VERBATIMSTRING); }
	{RegularStringLiteral}				{ addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); }
	{UnclosedRegularStringLiteral}		{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }
	{ErrorRegularStringLiteral}			{ addToken(Token.ERROR_STRING_DOUBLE); }

	/* Comments. */
	{DelimitedCommentStart}				{ start = zzMarkedPos-2; yybegin(DELIMITEDCOMMENT); }
	{DocumentationCommentStart}			{ start = zzMarkedPos-3; yybegin(DOCUMENTCOMMENT); }
	{SingleLineComment}					{ addToken(Token.COMMENT_EOL); addNullToken(); return firstToken; }

	/* Separators. */
	{Separator}						{ addToken(Token.SEPARATOR); }
	{Separator2}						{ addToken(Token.IDENTIFIER); }

	/* Operators. */
	{OperatorOrPunctuator}				{ addToken(Token.OPERATOR); }

	/* Numbers */
	{DecimalIntegerLiteral}				{ addToken(Token.LITERAL_NUMBER_DECIMAL_INT); }
	{HexadecimalIntegerLiteral}			{ addToken(Token.LITERAL_NUMBER_HEXADECIMAL); }
	{RealLiteral}						{ addToken(Token.LITERAL_NUMBER_FLOAT); }
	{ErrorNumberFormat}					{ addToken(Token.ERROR_NUMBER_FORMAT); }

	/* Preprocessor directives. */
	{PPDirective}						{ addToken(Token.PREPROCESSOR); }

	/* Pretty-much anything else. */
	{ErrorIdentifier}					{ addToken(Token.ERROR_IDENTIFIER); }

	/* Ended with a line not in a string or comment. */
	<<EOF>>							{ addNullToken(); return firstToken; }

	/* Catch any other (unhandled) characters and flag them as bad. */
	.								{ addToken(Token.ERROR_IDENTIFIER); }

}


<DELIMITEDCOMMENT> {

	[^hwf\n\*]+						{}
	{URL}						{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); addHyperlinkToken(temp,zzMarkedPos-1, Token.COMMENT_MULTILINE); start = zzMarkedPos; }
	[hwf]						{}
	\n							{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); return firstToken; }
	{DelimitedCommentEnd}			{ yybegin(YYINITIAL); addToken(start,zzStartRead+1, Token.COMMENT_MULTILINE); }
	\*							{}
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); return firstToken; }

}


<DOCUMENTCOMMENT> {

	[^hwf\<\n]*						{}
	{URL}						{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_DOCUMENTATION); addHyperlinkToken(temp,zzMarkedPos-1, Token.COMMENT_DOCUMENTATION); start = zzMarkedPos; }
	[hwf]						{}
	\n							{ addToken(start,zzStartRead-1, Token.COMMENT_DOCUMENTATION); addNullToken(); return firstToken; }
	"<"[^\>]*">"					{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_DOCUMENTATION); addToken(temp,zzMarkedPos-1, Token.PREPROCESSOR); start = zzMarkedPos; }
	"<"							{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_DOCUMENTATION); addToken(temp,zzEndRead, Token.PREPROCESSOR); addNullToken(); return firstToken; }
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.COMMENT_DOCUMENTATION); addNullToken(); return firstToken; }

}


<VERBATIMSTRING> {

	[^\"\n]*						{}
	{QuoteEscapeSequence}			{}
	\"							{ yybegin(YYINITIAL); addToken(start,zzStartRead, Token.LITERAL_STRING_DOUBLE_QUOTE); }
	\n							{ addToken(start,zzStartRead-1, Token.LITERAL_STRING_DOUBLE_QUOTE); return firstToken; }
	<<EOF>>						{ addToken(start,zzStartRead-1, Token.LITERAL_STRING_DOUBLE_QUOTE); return firstToken; }

}
