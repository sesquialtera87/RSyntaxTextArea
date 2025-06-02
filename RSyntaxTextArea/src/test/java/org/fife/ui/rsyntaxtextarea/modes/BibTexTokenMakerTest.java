package org.fife.ui.rsyntaxtextarea.modes;

import org.fife.ui.rsyntaxtextarea.Token;
import org.fife.ui.rsyntaxtextarea.TokenMaker;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;

class BibTexTokenMakerTest extends AbstractTokenMakerTest {

	private Stream<Token> tokens(Token firstToken, boolean skipWS, boolean skipNulls) {
		var tokens = new ArrayList<Token>();
		Stream<Token> stream;

		while (firstToken != null) {
			tokens.add(firstToken);
			firstToken = firstToken.getNextToken();
		}

		stream = tokens.stream();

		if (skipNulls) {
			stream = stream.filter(t -> t.getType() > 0);
		}

		if (skipWS) {
			stream = stream.filter(t -> !t.isWhitespace());
		}

		return stream;
	}

	@Override
	protected TokenMaker createTokenMaker() {
		return new BibTexTokenMaker();
	}

	@Test
	@Override
	public void testCommon_GetLineCommentStartAndEnd() {
	}

	@Test
	void emptyEntry() {
		var text = """
			@article {articleId,}
			""";
		var tm = new BibTexTokenMaker();
		var s = createSegment(text);
		var tk = tm.getTokenList(s, 0, 0);

		var expected = List.of(Token.VARIABLE, Token.SEPARATOR, Token.DATA_TYPE, Token.IDENTIFIER, Token.SEPARATOR);
		var l = tokens(tk, true, true).map(Token::getType)
			.toList();

		assertEquals(expected, l);
	}

	@Test
	void entry() {
		var text = """
			@book {bookId,
				title = {t}
			}
			""";
		var tm = createTokenMaker();
		var s = createSegment(text);
		var tk = tm.getTokenList(s, 0, 0);

		var expected = List.of(
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_ENTRY],
			Token.SEPARATOR,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_CITATION_KEY],
			Token.IDENTIFIER,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_TAG],
			Token.OPERATOR,
			Token.SEPARATOR,
			Token.IDENTIFIER,
			Token.SEPARATOR,
			Token.SEPARATOR
		);
		var l = tokens(tk, true, true).map(Token::getType)
			.toList();

		assertEquals(expected, l);
	}

	@Test
	void intValue() {
		var text = """
			@book {bookId,
				year = 1987
			}
			""";
		var tm = createTokenMaker();
		var s = createSegment(text);
		var tk = tm.getTokenList(s, 0, 0);

		var expected = List.of(
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_ENTRY],
			Token.SEPARATOR,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_CITATION_KEY],
			Token.IDENTIFIER,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_TAG],
			Token.OPERATOR,
			Token.LITERAL_NUMBER_DECIMAL_INT,
			Token.SEPARATOR
		);
		var l = tokens(tk, true, true).map(Token::getType)
			.toList();

		assertEquals(expected, l);
	}

	@Test
	void latexCommands() {
		var text = """
			@book {bookId,
				title = { \\Tex }
			}
			""";
		var tm = createTokenMaker();
		var s = createSegment(text);
		var tk = tm.getTokenList(s, 0, 0);

		var expected = List.of(
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_ENTRY],
			Token.SEPARATOR,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_CITATION_KEY],
			Token.IDENTIFIER,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_TAG],
			Token.OPERATOR,
			Token.SEPARATOR,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_TEX_COMMAND],
			Token.SEPARATOR,
			Token.SEPARATOR
		);
		var l = tokens(tk, true, true).map(Token::getType)
			.toList();

		assertEquals(expected, l);
	}

	@Test
	void quotedValues() {
		var text = """
			@book {bookId,
				title = "\\Tex"
			}
			""";
		var tm = createTokenMaker();
		var s = createSegment(text);
		var tk = tm.getTokenList(s, 0, 0);

		var expected = List.of(
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_ENTRY],
			Token.SEPARATOR,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_CITATION_KEY],
			Token.IDENTIFIER,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_TAG],
			Token.OPERATOR,
			Token.LITERAL_STRING_DOUBLE_QUOTE,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_TEX_COMMAND],
			Token.LITERAL_STRING_DOUBLE_QUOTE,
			Token.SEPARATOR
		);
		var l = tokens(tk, true, true).map(Token::getType)
			.toList();

		assertEquals(expected, l);
	}

	@Test
	void concatenation() {
		var text = """
			@book {bookId,
				title = "a" # "2"
			}
			""";
		var tm = createTokenMaker();
		var s = createSegment(text);
		var tk = tm.getTokenList(s, 0, 0);

		var expected = List.of(
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_ENTRY],
			Token.SEPARATOR,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_CITATION_KEY],
			Token.IDENTIFIER,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_TAG],
			Token.OPERATOR,
			Token.LITERAL_STRING_DOUBLE_QUOTE,
			Token.LITERAL_STRING_DOUBLE_QUOTE,
			Token.LITERAL_STRING_DOUBLE_QUOTE,
			Token.OPERATOR,
			Token.LITERAL_STRING_DOUBLE_QUOTE,
			Token.LITERAL_STRING_DOUBLE_QUOTE,
			Token.LITERAL_STRING_DOUBLE_QUOTE,
			Token.SEPARATOR
		);
		var l = tokens(tk, true, true).map(Token::getType)
			.toList();

		assertEquals(expected, l);
	}

	@Test
	void multipleBraces() {
		var text = """
			@book {bookId,
				title = {{\\textit{}}}
			}
			""";
		var tm = createTokenMaker();
		var s = createSegment(text);
		var tk = tm.getTokenList(s, 0, 0);

		var expected = List.of(
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_ENTRY],
			Token.SEPARATOR,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_CITATION_KEY],
			Token.IDENTIFIER,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_TAG],
			Token.OPERATOR,
			Token.SEPARATOR,
			Token.SEPARATOR,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_TEX_COMMAND],
			Token.SEPARATOR,
			Token.SEPARATOR,
			Token.SEPARATOR,
			Token.SEPARATOR,
			Token.SEPARATOR
		);
		var l = tokens(tk, true, true).map(Token::getType)
			.toList();

		assertEquals(expected, l);
	}

	@Test
	void inMultilineValue() {
		var text = """
				v},
				year = 1987
			}
			""";
		int type = -(1 + BibTexTokenMaker.ENTRY_BODY + 100 * 1);
		var tm = createTokenMaker();
		var s = createSegment(text);
		var tk = tm.getTokenList(s, type, 0);

		var expected = List.of(
			Token.IDENTIFIER,
			Token.SEPARATOR,
			Token.IDENTIFIER,
			BibTexTokenMaker.tokenTypes[BibTexTokenMaker.TOKEN_TAG],
			Token.OPERATOR,
			Token.LITERAL_NUMBER_DECIMAL_INT,
			Token.SEPARATOR
		);
		var l = tokens(tk, true, true).map(Token::getType)
			.toList();

		assertEquals(expected, l);
	}

}