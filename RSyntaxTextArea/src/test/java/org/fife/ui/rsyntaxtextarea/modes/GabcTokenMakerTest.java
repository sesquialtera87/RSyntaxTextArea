package org.fife.ui.rsyntaxtextarea.modes;

import org.fife.ui.rsyntaxtextarea.Token;
import org.fife.ui.rsyntaxtextarea.TokenMaker;
import org.fife.ui.rsyntaxtextarea.TokenTypes;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;

import static org.junit.jupiter.api.Assertions.*;

class GabcTokenMakerTest extends AbstractJFlexTokenMakerTest {

	private Token[] tokenList(Token firstToken) {
		var list = new ArrayList<Token>();

		while (firstToken != null) {
			list.add(firstToken);
			firstToken = firstToken.getNextToken();
		}

		return list.toArray(Token[]::new);
	}

	@Override
	protected TokenMaker createTokenMaker() {
		return new GabcTokenMaker();
	}

	@Test
	@Override
	public void testCommon_GetLineCommentStartAndEnd() {
		var tm = createTokenMaker();
		var comm = new String[]{"% ", null};
		assertArrayEquals(comm, tm.getLineCommentStartAndEnd(0));
	}

	@Test
	void testFileHeader() {
		var code = """
			name: incipit;
			score-copyright:2024;""";
		var seg = createSegment(code);
		var tm = createTokenMaker();
		var token = tm.getTokenList(seg, TokenTypes.NULL, 0);
		var tokens = tokenList(token);

		assertEquals(11, tokens.length);
		assertEquals("name", tokens[0].getLexeme());
		assertEquals(":", tokens[1].getLexeme());
		assertTrue(tokens[2].isWhitespace());
		assertEquals("incipit", tokens[3].getLexeme());
		assertEquals(";", tokens[4].getLexeme());

	}

	@Test
	void testComments() {
		// comment in header
		var code = "name: incipit; % comment";
		var seg = createSegment(code);
		var tm = createTokenMaker();
		var token = tm.getTokenList(seg, TokenTypes.NULL, 0);
		var tokens = tokenList(token);

		assertEquals(8, tokens.length);
		assertEquals("name", tokens[0].getLexeme());
		assertEquals(";", tokens[4].getLexeme());
		assertTrue(tokens[5].isWhitespace());
		assertTrue(tokens[6].isComment());


		code = """
			name: incipit;
			% full line comment
			%%""";
		seg = createSegment(code);
		token = tm.getTokenList(seg, TokenTypes.NULL, 0);
		tokens = tokenList(token);

		assertEquals(10, tokens.length);
		assertEquals("name", tokens[0].getLexeme());
		assertEquals(";", tokens[4].getLexeme());
		assertTrue(tokens[5].isWhitespace());
		assertTrue(tokens[6].isComment());
		assertEquals("%%", tokens[8].getLexeme());


		// comment in notation
		code = """
			name: incipit;
			%%
			(c4)
			% full line comment""";
		seg = createSegment(code);
		token = tm.getTokenList(seg, TokenTypes.NULL, 0);
		tokens = tokenList(token);

		assertEquals(15, tokens.length);
		assertEquals("name", tokens[0].getLexeme());
		assertEquals("%%", tokens[6].getLexeme());
		assertTrue(tokens[13].isComment());
	}
}