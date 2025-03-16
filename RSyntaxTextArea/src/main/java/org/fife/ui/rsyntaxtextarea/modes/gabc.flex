package org.fife.ui.rsyntaxtextarea.modes;

import org.fife.ui.rsyntaxtextarea.Token;
import org.fife.ui.rsyntaxtextarea.TokenMakerBase;
import org.fife.ui.rsyntaxtextarea.TokenTypes;

import javax.swing.text.Segment;
import java.io.IOException;

%%

%class GabcTokenMaker
%public
%extends TokenMakerBase
%unicode
%int


%{
    public GabcTokenMaker() {
    }

    void addToken(int tokenType) {
        super.addToken(text.array, text.offset + zzStartRead, text.offset + zzMarkedPos - 1, tokenType, startOffset + zzStartRead);
    }

    public static int encodeLexerState(int state) {
        return -(state * 10 + 7);
    }

    public static int decodeLexerState(int encoded) {
        return (-encoded - 7) / 10;
    }

    Segment text;
    int startOffset;

    @Override
    public String[] getLineCommentStartAndEnd(int languageIndex) {
        return new String[]{"% ", null};
    }

    @Override
    public Token getTokenList(Segment text, int initialTokenType, int startOffset) {
        resetTokenList();

        try {
            this.text = text;
            this.startOffset = startOffset;
            reset(text, 0, text.count, initialTokenType < 0 ? decodeLexerState(initialTokenType) : initialTokenType);
            yylex();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

        super.addToken(text, startOffset, startOffset - 1, encodeLexerState(yystate()), startOffset);

        return firstToken;
    }
%}

SignedInt       =  ([+-])?[0-9]+
LineTerminator  = \r|\n|\r\n
Whitespace      = [ \t]+
PropertyName    = [a-zA-Z-]+
TagName         = (clear|c|i|b|ul|sp|tt|sc|eu|e|nlba|alt|v)
Tag             = "<" {TagName} ">"
ClosingTag      = "</" {TagName} ">"
Escape          = "$" [^ \t\r\n]
Spaces          = "!" | \/("0" | "!" | \[{SignedInt}\]|\/+)?

%state PROPERTY_VALUE
%state CODE
%state NOTATION

%%

<YYINITIAL> {
     "%%"                      {  addToken(TokenTypes.REGEX); yybegin(CODE); }
     {Whitespace}              {  addToken(TokenTypes.WHITESPACE); }
     {LineTerminator}          {  addToken(TokenTypes.WHITESPACE); }
     {PropertyName}            {  addToken(TokenTypes.PREPROCESSOR); }
     ":"                       {  addToken(TokenTypes.SEPARATOR); yybegin(PROPERTY_VALUE); }
     "%" " " [^\n]*            {  addToken(TokenTypes.COMMENT_EOL); }
     [^]                       {  addToken(TokenTypes.IDENTIFIER); }
     <<EOF>>                   {  return 0; }
}

<PROPERTY_VALUE> {
    {Whitespace}               { addToken(TokenTypes.WHITESPACE); }
    [^ \t;]+                   { addToken(TokenTypes.MARKUP_CDATA); }
    ";" ";"?                   { addToken(TokenTypes.SEPARATOR); yybegin(YYINITIAL);}
    <<EOF>>                    { return 0; }
}

<CODE> {
    "%" " " [^\n]*             { addToken(TokenTypes.COMMENT_EOL); }
    {Escape}                   { addToken(TokenTypes.REGEX); }
    {Whitespace}               { addToken(TokenTypes.WHITESPACE); }
    {Tag} | {ClosingTag}       { addToken(TokenTypes.MARKUP_DTD); }
    {LineTerminator}           { addToken(TokenTypes.WHITESPACE); }
    "("                        { addToken(TokenTypes.SEPARATOR); yybegin(NOTATION); }
    [{}]                       { addToken(TokenTypes.SEPARATOR); }
    [^]                        { addToken(TokenTypes.IDENTIFIER); }
    <<EOF>>                    { return 0; }
}

<NOTATION> {
    "_" [0-5]?                     { addToken(TokenTypes.OPERATOR); }
    "/"                            { addToken(TokenTypes.SEPARATOR); }
    [a-n|p|A-N|P]                  { addToken(TokenTypes.DATA_TYPE); }
    "r0" | "vvv" | "vv" | "sss"
    | "ss" | [-qovWwVs<>=rR~]      { addToken(TokenTypes.OPERATOR); }
    {Whitespace}                   { addToken(TokenTypes.WHITESPACE); }
    {LineTerminator}               { addToken(TokenTypes.WHITESPACE); }
    ")"                            { addToken(TokenTypes.SEPARATOR); yybegin(CODE); }
    "@"                            { addToken(TokenTypes.ANNOTATION); }
    "##"|"#?"|#|"x?"|x|"y?"|y|X|Y  { addToken(TokenTypes.LITERAL_BOOLEAN); }
    {Spaces}                       { addToken(TokenTypes.RESERVED_WORD); }
    [^]                            { addToken(TokenTypes.IDENTIFIER); }
    <<EOF>>                        { return 0; }
}
