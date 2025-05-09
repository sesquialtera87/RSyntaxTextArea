/*
 * 7/28/2009
 *
 * DelphiTokenMaker.java - Scanner for the Delphi programming language.
 * 
 * This library is distributed under a modified BSD license.  See the included
 * LICENSE file for details.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * Scanner for the Delphi programming language.<p>
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
 *   <li>The generated <code>DelphiTokenMaker.java</code> file will contain two
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
%class DelphiTokenMaker
%extends AbstractJFlexTokenMaker
%unicode
%type org.fife.ui.rsyntaxtextarea.Token


%{


	/**
	 * Token type specific to DelphiTokenMaker; denotes a line ending
	 * with an unterminated "(*" comment.
	 */
	public static final int INTERNAL_MLC2			= -1;

	/**
	 * Token type specific to DelphiTokenMaker; denotes a line ending
	 * with an unterminated "{$" compiler directive.
	 */
	public static final int INTERNAL_COMPILER_DIRECTIVE	= -2;

	/**
	 * Token type specific to DelphiTokenMaker; denotes a line ending
	 * with an unterminated "(*$" compiler directive.
	 */
	public static final int INTERNAL_COMPILER_DIRECTIVE2	= -3;


	/**
	 * Constructor.  This must be here because JFlex does not generate a
	 * no-parameter constructor.
	 */
	public DelphiTokenMaker() {
	}


	/**
	 * Adds the token specified to the current linked list of tokens as an
	 * "end token;" that is, at <code>zzMarkedPos</code>.
	 *
	 * @param tokenType The token's type.
	 */
	private void addEndToken(int tokenType) {
		addToken(zzMarkedPos,zzMarkedPos, tokenType);
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
	 * @see #addHyperlinkToken(int, int, int)
	 */
	private void addToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so, false);
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
	 * @param hyperlink Whether this token is a hyperlink.
	 */
	@Override
	public void addToken(char[] array, int start, int end, int tokenType,
						int startOffset, boolean hyperlink) {
		super.addToken(array, start,end, tokenType, startOffset, hyperlink);
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
			case Token.COMMENT_MULTILINE:
				state = MLC;
				start = text.offset;
				break;
			case INTERNAL_MLC2:
				state = MLC2;
				start = text.offset;
				break;
			case INTERNAL_COMPILER_DIRECTIVE:
				state = COMPILER_DIRECTIVE;
				start = text.offset;
				break;
			case INTERNAL_COMPILER_DIRECTIVE2:
				state = COMPILER_DIRECTIVE2;
				start = text.offset;
				break;
			default:
				state = Token.NULL;
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

Letter							= [A-Za-z]
LetterOrUnderscore				= ({Letter}|"_")
NonzeroDigit						= [1-9]
Digit							= ("0"|{NonzeroDigit})
HexDigit							= ({Digit}|[A-Fa-f])
OctalDigit						= ([0-7])
NonSeparator						= ([^\t\f\r\n\ \(\)\{\}\[\]\;\,\.\=\>\<\!\~\?\:\+\-\*\/\&\|\^\%\"\']|"#"|"\\")
IdentifierStart					= ({LetterOrUnderscore}|"$")
IdentifierPart						= ({IdentifierStart}|{Digit})

LineTerminator				= (\n)
WhiteSpace				= ([ \t\f])

UnclosedStringLiteral		= ([\'][^\']*)
StringLiteral				= ({UnclosedStringLiteral}[\'])
EscapeSequence				= ("#"{Digit}*)

MLCBegin					= "{"
MLCEnd						= "}"
MLC2Begin					= "(*"
MLC2End						= "*)"
CompilerDirective1Begin		= ({MLCBegin}"$")
CompilerDirective2Begin		= ({MLC2Begin}"$")
LineCommentBegin			= "//"

IntegerHelper1				= (({NonzeroDigit}{Digit}*)|"0")
IntegerHelper2				= ("0"(([xX]{HexDigit}+)|({OctalDigit}*)))
IntegerLiteral				= ({IntegerHelper1}[lL]?)
HexLiteral				= ({IntegerHelper2}[lL]?)
FloatHelper1				= ([fFdD]?)
FloatHelper2				= ([eE][+-]?{Digit}+{FloatHelper1})
FloatLiteral1				= ({Digit}+"."({FloatHelper1}|{FloatHelper2}|{Digit}+({FloatHelper1}|{FloatHelper2})))
FloatLiteral2				= ("."{Digit}+({FloatHelper1}|{FloatHelper2}))
FloatLiteral3				= ({Digit}+{FloatHelper2})
FloatLiteral				= ({FloatLiteral1}|{FloatLiteral2}|{FloatLiteral3}|({Digit}+[fFdD]))
ErrorNumberFormat			= (({IntegerLiteral}|{HexLiteral}|{FloatLiteral}){NonSeparator}+)
BooleanLiteral				= ("true"|"false")

Separator					= ([\(\)\[\]])
Separator2					= ([\;,.])

Operator					= ([\^\@\:\=\<\>\+\-\/\*])

Identifier				= ({IdentifierStart}{IdentifierPart}*)
ErrorIdentifier			= ({NonSeparator}+)

URLGenDelim				= ([:\/\?#\[\]@])
URLSubDelim				= ([\!\$&'\(\)\*\+,;=])
URLUnreserved			= ({LetterOrUnderscore}|{Digit}|[\-\.\~])
URLCharacter			= ({URLGenDelim}|{URLSubDelim}|{URLUnreserved}|[%])
URLCharacters			= ({URLCharacter}*)
URLEndCharacter			= ([\/\$]|{Letter}|{Digit})
URL						= (((https?|f(tp|ile))"://"|"www.")({URLCharacters}{URLEndCharacter})?)


%state MLC
%state MLC2
%state COMPILER_DIRECTIVE
%state COMPILER_DIRECTIVE2
%state EOL_COMMENT

%%

<YYINITIAL> {

	/* Keywords */
	"array" |
	"as" |
	"at" |
	"asm" |
	"begin" |
	"case" |
	"class" |
	"const" |
	"constructor" |
	"destructor" |
	"dispinterface" |
	"div" |
	"do" |
	"downto" |
	"else" |
	"end" |
	"except" |
	"exports" |
	"file" |
	"final" |
	"finalization" |
	"finally" |
	"for" |
	"function" |
	"goto" |
	"if" |
	"implementation" |
	"in" |
	"inherited" |
	"initialization" |
	"inline" |
	"interface" |
	"is" |
	"label" |
	"mod" |
	"not" |
	"object" |
	"of" |
	"on" |
	"or" |
	"out" |
	"packed" |
	"procedure" |
	"program" |
	"property" |
	"raise" |
	"record" |
	"repeat" |
	"resourcestring" |
	"set" |
	"sealed" |
	"shl" |
	"shr" |
	"static" |
	"string" |
	"then" |
	"threadvar" |
	"to" |
	"try" |
	"type" |
	"unit" |
	"unsafe" |
	"until" |
	"uses" |
	"var" |
	"while" |
	"with" |
	"xor" 					{ addToken(Token.RESERVED_WORD); }

	/* Directives. */
	"absolute" |
	"abstract" |
	"assembler" |
	"automated" |
	"cdecl" |
	"contains" |
	"default" |
	"deprecated" |
	"dispid" |
	"dynamic" |
	"export" |
	"external" |
	"far" |
	"forward" |
	"implements" |
	"index" |
	"library" |
	"local" |
	"message" |
	"name" |
	"namespaces" |
	"near" |
	"nil" |
	"nodefault" |
	"overload" |
	"override" |
	"package" |
	"pascal" |
	"platform" |
	"private" |
	"protected" |
	"public" |
	"published" |
	"read" |
	"readonly" |
	"register" |
	"reintroduce" |
	"requires" |
	"resident" |
	"safecall" |
	"self" |
	"stdcall" |
	"stored" |
	"varargs" |
	"virtual" |
	"write" |
	"writeonly"				{ addToken(Token.FUNCTION); }

	/* Data types. */
	"shortint" |
	"byte" |
	"char" |
	"smallint" |
	"integer" |
	"word" |
	"longint" |
	"cardinal" |
	"boolean" |
	"bytebool" |
	"wordbool" |
	"longbool" |
	"real" |
	"single" |
	"double" |
	"extended" |
	"comp" |
	"currency" |
	"pointer"					{ addToken(Token.DATA_TYPE); }

	{BooleanLiteral}			{ addToken(Token.LITERAL_BOOLEAN); }

	{LineTerminator}				{ addNullToken(); return firstToken; }

	{Identifier}					{ addToken(Token.IDENTIFIER); }

	{WhiteSpace}+					{ addToken(Token.WHITESPACE); }

	/* String/Character literals. */
	{StringLiteral}				{ addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); }
	{UnclosedStringLiteral}			{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }
	{EscapeSequence}				{ addToken(Token.PREPROCESSOR); }

	/* Comment literals. */
	{CompilerDirective1Begin}	{start = zzMarkedPos-2; yybegin(COMPILER_DIRECTIVE); }
	{CompilerDirective2Begin}	{start = zzMarkedPos-3; yybegin(COMPILER_DIRECTIVE2); }
	{MLCBegin}					{ start = zzMarkedPos-1; yybegin(MLC); }
	{MLC2Begin}						{ start = zzMarkedPos-2; yybegin(MLC2); }
	{LineCommentBegin}				{ start = zzMarkedPos-2; yybegin(EOL_COMMENT); }

	{Separator}					{ addToken(Token.SEPARATOR); }
	{Separator2}					{ addToken(Token.IDENTIFIER); }
	{Operator}					{ addToken(Token.OPERATOR); }

	{IntegerLiteral}				{ addToken(Token.LITERAL_NUMBER_DECIMAL_INT); }
	{HexLiteral}					{ addToken(Token.LITERAL_NUMBER_HEXADECIMAL); }
	{FloatLiteral}					{ addToken(Token.LITERAL_NUMBER_FLOAT); }
	{ErrorNumberFormat}				{ addToken(Token.ERROR_NUMBER_FORMAT); }

	{ErrorIdentifier}				{ addToken(Token.ERROR_IDENTIFIER); }

	/* Ended with a line not in a string or comment. */
	<<EOF>>						{ addNullToken(); return firstToken; }

	/* Catch any other (unhandled) characters. */
	.							{ addToken(Token.IDENTIFIER); }

}


<MLC> {

	[^hwf\n\}]+				{}
	{URL}					{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); addHyperlinkToken(temp,zzMarkedPos-1, Token.COMMENT_MULTILINE); start = zzMarkedPos; }
	[hwf]					{}

	\n						{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); return firstToken; }
	{MLCEnd}					{ yybegin(YYINITIAL); addToken(start,zzStartRead, Token.COMMENT_MULTILINE); }
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); return firstToken; }

}


<MLC2> {

	[^hwf\n\*]+				{}
	{URL}					{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); addHyperlinkToken(temp,zzMarkedPos-1, Token.COMMENT_MULTILINE); start = zzMarkedPos; }
	[hwf]					{}

	\n						{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); addEndToken(INTERNAL_MLC2); return firstToken; }
	{MLC2End}					{ yybegin(YYINITIAL); addToken(start,zzStartRead+1, Token.COMMENT_MULTILINE); }
	\*						{}
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.COMMENT_MULTILINE); addEndToken(INTERNAL_MLC2); return firstToken; }

}


<COMPILER_DIRECTIVE> {
	[^\n\}]+				{}
	\n						{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_COMPILER_DIRECTIVE); return firstToken; }
	{MLCEnd}					{ yybegin(YYINITIAL); addToken(start,zzStartRead, Token.PREPROCESSOR); }
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_COMPILER_DIRECTIVE); return firstToken; }
}


<COMPILER_DIRECTIVE2> {
	[^\n\*]+				{}
	\n						{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_COMPILER_DIRECTIVE2); return firstToken; }
	{MLC2End}					{ yybegin(YYINITIAL); addToken(start,zzStartRead+1, Token.PREPROCESSOR); }
	\*						{}
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.PREPROCESSOR); addEndToken(INTERNAL_COMPILER_DIRECTIVE2); return firstToken; }
}



<EOL_COMMENT> {
	[^hwf\n]+				{}
	{URL}					{ int temp=zzStartRead; addToken(start,zzStartRead-1, Token.COMMENT_EOL); addHyperlinkToken(temp,zzMarkedPos-1, Token.COMMENT_EOL); start = zzMarkedPos; }
	[hwf]					{}
	\n						{ addToken(start,zzStartRead-1, Token.COMMENT_EOL); addNullToken(); return firstToken; }
	<<EOF>>					{ addToken(start,zzStartRead-1, Token.COMMENT_EOL); addNullToken(); return firstToken; }
}
