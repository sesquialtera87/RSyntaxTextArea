/*
 * June 2025
 *
 * This library is distributed under a modified BSD license.  See the included
 * LICENSE file for details.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;

/**
 * Scanner for BibTex files (.bib)<p>
 *
 * This implementation was created using <a href="https://www.jflex.de/">JFlex</a> 1.9.2 (tweaked for IntelliJ platform).
 *
 * @author Mattia Marelli
 * @version 1.0
 * @since june 2025
 *
 */
%%

%public
%class BibTexTokenMaker
%extends AbstractTokenMaker
%unicode
%type org.fife.ui.rsyntaxtextarea.Token


%{
    public static final int TOKEN_ENTRY = 0;
    public static final int TOKEN_CITATION_KEY = 1;
    public static final int TOKEN_TAG = 2;
    public static final int TOKEN_TEX_COMMAND = 3;

    /**
     * Default {@link org.fife.ui.rsyntaxtextarea.TokenTypes} for some syntax elements of the BibTex file.
     * Customizable elements are:
     * <ul>
     *     <li>entry types, i.e. {@code @xxxxxxx} tokens</li>
     *     <li>citation keys, i.e. the unique identifier of each record</li>
     *     <li>entry tags (author, title...)</li>
     *     <li>LaTex commands ({@code \command})</li>
     * </ul>
     * <p>
     * To change the default {@link org.fife.ui.rsyntaxtextarea.TokenTypes}, set the related entry in the
     * {@code tokenTypes} array: {@code tokenTypes[TOKEN_TAG] = Token.DATA_TYPE}
     *
     * @see BibTexTokenMaker#TOKEN_ENTRY
     * @see BibTexTokenMaker#TOKEN_CITATION_KEY
     * @see BibTexTokenMaker#TOKEN_TAG
     * @see BibTexTokenMaker#TOKEN_TEX_COMMAND
     */
    static final int[] tokenTypes = {Token.VARIABLE, Token.DATA_TYPE, Token.REGEX, Token.FUNCTION};

	boolean propertyValue = false;
	int braceDelta;
	int start;
	Segment s;

	/**
	 * Constructor. This must be here because JFlex does not generate a no-parameter constructor.
	 */
	public BibTexTokenMaker() {
		super();
	}

	protected void addToken(int tokenType) {
		super.addToken(s.array, s.offset + zzStartRead, s.offset + zzMarkedPos - 1, tokenType, start + zzStartRead);
	}

    /**
    * Add a null Token encoding the current lexical state and the number of braces encountered.
    */
	protected void addEndToken() {
		int type = -(1 + yystate() + 100 * Math.max(0, braceDelta));
		super.addToken(s.array, start, start - 1, type, start);
	}

	@Override
	public String[] getLineCommentStartAndEnd(int languageIndex) {
		return new String[]{null, null};
	}

	@Override
	public Token getTokenList(Segment text, int initialTokenType, int startOffset) {
		resetTokenList();

		int state = 0;

		if (initialTokenType < 0) {
			initialTokenType = -initialTokenType;
			braceDelta = initialTokenType / 100;
			state = initialTokenType - 100 * braceDelta - 1;
		} else {
			braceDelta = 0;
		}

		propertyValue = braceDelta > 0;

		try {
			s = text;
			start = startOffset;
			reset(text, 0, text.count, state);
			yylex();
			addEndToken();
		} catch (IOException e) {
			throw new RuntimeException(e);
		}

		return firstToken;
	}

	@Override
	public TokenMap getWordsToHighlight() {
		return null;
	}
%}

Integer             = [0-9]+
Letter              = [a-zA-Z]+
TexCommand          = \\{Letter}+
Tag                 = {Letter}+
Entry               = @{Letter}+
Whitespace			= ([ \t\r\n]+)

%state ENTRY_BODY
%state IDENTIFIER
%state STRING

%%

<YYINITIAL> {
	{Whitespace}		{ addToken(Token.WHITESPACE); }
	{Entry}		        { addToken(tokenTypes[TOKEN_ENTRY]); }
    "{"                 { addToken(Token.SEPARATOR); yybegin(IDENTIFIER); }
    .                   { addToken(Token.IDENTIFIER); }
}

<IDENTIFIER> {
    [^,]+               { addToken(tokenTypes[TOKEN_CITATION_KEY]); }
    ","                 { addToken(Token.IDENTIFIER); yybegin(ENTRY_BODY); braceDelta = 0; }
}

<ENTRY_BODY> {
    "\""                { addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); yybegin(STRING); }
    "{"                 { addToken(Token.SEPARATOR); braceDelta++; }
    "}"                 { addToken(Token.SEPARATOR); braceDelta--; if(braceDelta < 0) yybegin(YYINITIAL); if (braceDelta == 0) propertyValue = false; }
    "="                 { addToken(Token.OPERATOR); propertyValue = true; }
    "#"                 { if(propertyValue && braceDelta == 0) addToken(Token.OPERATOR); else addToken(Token.IDENTIFIER); }
    {TexCommand}        { addToken(tokenTypes[TOKEN_TEX_COMMAND]); }
	{Tag}		        { if(propertyValue) addToken(Token.IDENTIFIER); else addToken(tokenTypes[TOKEN_TAG]); }
	{Integer}		    { if(propertyValue && braceDelta == 0) addToken(Token.LITERAL_NUMBER_DECIMAL_INT); else addToken(Token.IDENTIFIER); }
	{Whitespace}		{ addToken(Token.WHITESPACE); }
	.		            { addToken(Token.IDENTIFIER); }
}

<STRING> {
    "\""                { addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); yybegin(ENTRY_BODY); }
    {Whitespace}		{ addToken(Token.WHITESPACE); }
    {TexCommand}        { addToken(tokenTypes[TOKEN_TEX_COMMAND]); }
    .		            { addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); }
}


