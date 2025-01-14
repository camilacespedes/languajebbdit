/*
 *  BBLMTextUtils.cpp
 *
 *  Created by Seth Dillingham on 2/14/2008.
 *  Copyright 2008 Macrobyte Resources.
 *
 *  Generic, UniChar-based, utility functions for language modules.
 *  To use it, a language module has to subclass BBLMTextUtils,
 *  such as with YAMLTextUtils or ScalaTextUtils.
 *
 *  Most text-processing methods use a BBLMTextIterator, which is shared
 *  with another object (such as a Tokenizer). So, for example, calling 
 *  skipInlineWhitespace() will cause the "host's" text iterator to be 
 *  incremented so that it points to the first non-inline-whitespace
 *  character that is found at or after the iterator's current position.
 *
 *  HOWEVER, any method whose name ends with "ByIndex" does NOT increment
 *  the TextIterator. Instead, they accept a reference to an offset from the
 *  BBLMTextIterator's current position, and update that offset (the index)
 *  before returning. For an example, see ::skipLineByIndex
 *
 *
 *  NOTE that this class was originally written for the YAML module, and 
 *  and may still have some non-generic stuff that needs to be either 
 *  refactored or moved to a subclass.
 */

#include "BBLMTextUtils.h"

BBLMTextUtils::BBLMTextUtils(			BBLMParamBlock &	params,
				const	BBLMCallbackBlock &	/* bblm_callbacks */,
						BBLMTextIterator &	p )
	:m_params( params ),
	 m_p( p ),
	 m_inlineWhiteCharSet( CFCharacterSetCreateMutable( kCFAllocatorDefault ) ),
	 m_breakCharSet( CFCharacterSetCreateMutable( kCFAllocatorDefault ) ),
	 m_EOLCharSet( CFCharacterSetCreateMutable( kCFAllocatorDefault ) ),
	 m_wordCharSet( [NSMutableCharacterSet new] ),
	 m_identifierCharSet ( [NSMutableCharacterSet new] ),
	 m_digitSeparatorCharSet( [NSMutableCharacterSet new] )
{
	this->initEOLChars();
	this->initWhitespace();
	this->initWordChars();
	this->initIdentifierChars();
	this->initDigitSeparatorChars();
}

BBLMTextUtils::~BBLMTextUtils()
{
	if ( NULL != m_inlineWhiteCharSet )
	{
		CFRelease( m_inlineWhiteCharSet );
		
		m_inlineWhiteCharSet = NULL;
	}
	
	if ( NULL != m_breakCharSet )
	{
		CFRelease( m_breakCharSet );
		
		m_breakCharSet = NULL;
	}
	
	if ( NULL != m_EOLCharSet )
	{
		CFRelease( m_EOLCharSet );
		
		m_EOLCharSet = NULL;
	}
	
	[m_wordCharSet release];
	[m_identifierCharSet release];
	[m_digitSeparatorCharSet release];
}

#pragma mark Character Tests and Init
#pragma mark -

// private
void
BBLMTextUtils::addCharsToSet( CFStringRef chars, CFMutableCharacterSetRef charSet ) {
	CFCharacterSetAddCharactersInString( charSet, chars );
}

void
BBLMTextUtils::addCharToSet( UniChar c, CFMutableCharacterSetRef charSet ) {
	CFCharacterSetAddCharactersInRange(charSet, CFRangeMake(c, 1));
}

#pragma mark -

// protected
void
BBLMTextUtils::addBreakChar( UniChar c ) {
	this->addCharToSet( c, m_breakCharSet );
}

void BBLMTextUtils::addBreakChars( CFStringRef s ) {
	this->addCharsToSet( s, m_breakCharSet );
}

#pragma mark -

void
BBLMTextUtils::initCharacterSets() {
	//
	//	The default implementation does nothing. We should probably fill this in with
	//	something useful default behavior that covers most subclasses, and let overrides
	//	modify it.
	/*...*/
	
	
}

bool
BBLMTextUtils::isWordChar ( const UniChar c) {
	return [m_wordCharSet characterIsMember: c];
}

bool
BBLMTextUtils::isIdentifierChar ( const UniChar c) {
	return [m_identifierCharSet characterIsMember: c];
}

bool
BBLMTextUtils::isDigitSeparatorChar( const UniChar c )
{
	return [m_digitSeparatorCharSet characterIsMember: c];
}

bool
BBLMTextUtils::isBreakChar( UniChar c ) {
	return CFCharacterSetIsCharacterMember( m_breakCharSet, c );
}

bool
BBLMTextUtils::isInlineWhiteChar( UniChar c ) {
	return CFCharacterSetIsCharacterMember( m_inlineWhiteCharSet, c );
}

void
BBLMTextUtils::initEOLChars() {
	this->addCharsToSet(CFSTR( "\r\n" ), m_EOLCharSet);
	this->addCharToSet(0x0085, m_EOLCharSet);	//	NEXT LINE (NEL)
	this->addCharToSet(0, m_EOLCharSet);		//	null, for EOF cases
}

void
BBLMTextUtils::initWhitespace() {
	this->addCharsToSet(CFSTR( " \t\f\v" ), m_inlineWhiteCharSet);
}

void
BBLMTextUtils::initWordChars() {
	[m_wordCharSet formUnionWithCharacterSet: [NSCharacterSet alphanumericCharacterSet]];
	[m_wordCharSet addCharactersInRange: NSMakeRange('_', 1)];
}

void
BBLMTextUtils::initIdentifierChars()
{
	[m_identifierCharSet formUnionWithCharacterSet: [NSCharacterSet alphanumericCharacterSet]];
	[m_identifierCharSet addCharactersInRange: NSMakeRange('_', 1)];
}

void
BBLMTextUtils::initDigitSeparatorChars()
{
	NSString	*digitSeparators = nil;
	
	if (nil != (digitSeparators = m_params.fLanguageModuleProperties[@"BBLMDigitSeparator"]))
	{
		[m_digitSeparatorCharSet addCharactersInString: digitSeparators];
	}
}

#pragma mark -

bool
BBLMTextUtils::isEOLChar( UniChar c ) {
	return CFCharacterSetIsCharacterMember( m_EOLCharSet, c );
}


#pragma mark -
#pragma mark Skippers
#pragma mark -

bool
BBLMTextUtils::skipWhitespace() {
	while ( m_p.InBounds() )
	{
		if ( isspace( *m_p ) )
			m_p++;
		else
			return true;
	}
	
	return false;
}

bool
BBLMTextUtils::skipInlineWhitespace() {
	SInt32		ct = 0;
	
	return this->skipInlineWhitespace( ct, m_p );
}

bool
BBLMTextUtils::skipInlineWhitespace( SInt32 & ctChars ) {
	return this->skipInlineWhitespace( ctChars, m_p );
}

bool
BBLMTextUtils::skipInlineWhitespace( BBLMTextIterator & p ) {
	SInt32		ct = 0;
	
	return this->skipInlineWhitespace( ct, p );
}


bool
BBLMTextUtils::skipInlineWhitespace( SInt32 & ctChars, BBLMTextIterator & p ) {
	ctChars = 0;
	
	while ( p.InBounds() )
	{
		UniChar c = p[ 0 ];
		
		if ( this->isInlineWhiteChar( c ) )
		{
			++ctChars;
			p++;
		}
		else if ( ( c == '\\' ) && this->isInlineWhiteChar( p[ 1 ] ) )
		{
			ctChars += 2;
			p += 2;
		}
		else
			return true;
	}
	
	return false;
}

bool
BBLMTextUtils::skipInlineWhitespaceByIndex( BBLMTextIterator & p, SInt32 & index ) {
	SInt32		ix = index,
				start = p.Offset(),
				limit = m_params.fTextLength;
	UniChar		c;
	
	while ( start + ix < limit )
	{
		c = p[ ix ];
		
		if ( this->isInlineWhiteChar( c ) )
			++ix;
		else if ( '\\' == c )
		{
			if ( this->isInlineWhiteChar( p[ ix + 1 ] ) )
				ix += 2;
			else
			{
				index = ix;
				return ( start + ix < limit );
			}
		}
		else
		{
			index = ix;
			return true;
		}
	}
	
	index = ix;
	
	return false;
}

void
BBLMTextUtils::skipPreviousInlineWhitespace() {
	SInt32		ix = m_p.Offset();
	UniChar		c = *m_p;
	
	while ( m_p.Offset() >= 0 )
	{
		if ( this->isInlineWhiteChar( c ) )
			m_p--;
		else if ( '\\' == c )
		{
			if ( ( m_p.Offset() < ix ) && this->isInlineWhiteChar( m_p[ 1 ] ) )
				m_p--;
			else
				break;
		}
		else
			break;
	}
}

void
BBLMTextUtils::skipPreviousInlineWhitespaceByIndex( BBLMTextIterator & p, SInt32 & index ) {
	SInt32		ix = index - 1;
	UniChar		c;
	
	while ( ix >= 0 )
	{
		c = p[ ix ];
		
		if ( this->isInlineWhiteChar( c ) )
			--ix;
		else if ( '\\' == c )
		{
			if ( ( ix < index ) && this->isInlineWhiteChar( p[ ix + 1 ] ) )
			{
				--ix;
				continue;
			}
			else
			{
				index = ix;
				return;
			}
		}
		else
		{
			index = ix;
			return;
		}
	}
	
	if ( ix < index )
		index = ix + 1;
	else
		index = ix;
	
	return;
}

bool
BBLMTextUtils::skipLine( BBLMTextIterator & p ) {
	if ( ! this->skipToEOL( p ) )
		return false;
	
	p++;
	
	return p.InBounds();
}

bool
BBLMTextUtils::skipToEOL( BBLMTextIterator & p ) {
	while ( ! this->isEOLChar( *p ) )
		p++;
	
	return p.InBounds();
}

bool
BBLMTextUtils::skipLineByIndex( BBLMTextIterator & p, SInt32 & index ) {
	SInt32		ix = index,
				limit = m_params.fTextLength,
				start = p.Offset();
	
	while ( start + ix < limit )
	{
		if ( this->isEOLChar( p[ ix ] ) )
			break;
		
		++ix;
	}
	
	if ( start + ix < limit )  // skip the \r
		++ix;
	
	index = ix;
	
	return ( start + ix < limit );
}

bool
BBLMTextUtils::skipLineWithMaxIndexByIndex( SInt32 & index, SInt32 maxIndex ) {
	SInt32		ix 		= index,
				limit 	= m_params.fTextLength;
	
	if ( limit > maxIndex )
		limit = maxIndex;
	
	while ( ix < limit )
	{
		if ( BBLMCharacterIsLineBreak(m_p[ ix ]) )
		{
			index = ix;
			return true;
		}
		else
		{
			++ix;
		}
	}
	
	index = ix;
	
	return false;
}

SInt32
BBLMTextUtils::findLineEndBeforeIndex( SInt32 index ) {
	BBLMTextIterator	iter( m_p );
	SInt32				ix = index;
	
	iter.SetOffset( 0 );
	
	while ( ix >= 0 )
	{
		if ( BBLMCharacterIsLineBreak(iter[ ix ]) )
			break;
		
		--ix;
	}
	
	return ix;
}

SInt32
BBLMTextUtils::findLineEndAfterIndex( SInt32 index ) {
	BBLMTextIterator	iter( m_p );
	SInt32				ix = index,
						limit = m_params.fTextLength;
	
	iter.SetOffset( 0 );
	
	while ( ix < limit )
	{
		if ( BBLMCharacterIsLineBreak(iter[ ix ]) )
			break;
		
		++ix;
	}
	
	return ix;
}


bool
BBLMTextUtils::skipToCharByIndex( UniChar seeking, SInt32 & index, bool flAllowEscapes ) {
	SInt32		ix = index,
				limit = m_params.fTextLength,
				pos = m_p.Offset();
	UniChar		c;
	
	while ( pos + ix < limit )
	{
		c = m_p[ ix ];
		
		if ( c == seeking )
		{
			index = ix;
			return true;
		}
		else if ( flAllowEscapes && ( '\\' == c ) && ( pos + ix + 1 < limit ) )
			++ix;
		
		++ix;
	}
	
	return false;
}

bool
BBLMTextUtils::skipToCharSameLineByIndex( UniChar seeking, SInt32 & index ) {
	SInt32		ix = index,
				limit = m_params.fTextLength,
				pos = m_p.Offset();
	UniChar		c;
	
	while ( pos + ix < limit )
	{
		c = m_p[ ix ];
		
		if ( c == seeking )
		{
			index = ix;
			return true;
		}
		else if ( ( '\\' == c ) && ( pos + ix + 1 < limit ) && ( ! BBLMCharacterIsLineBreak(m_p[ ix + 1 ]) ) )
			++ix;
		else if ( BBLMCharacterIsLineBreak(c) )
			return false;
		
		++ix;
	}
	
	return false;
}

bool
BBLMTextUtils::skipGroupByIndexCountingLines( BBLMTextIterator & p, SInt32 & index, const UniChar breakChar, SInt32 & ctLines ) {
	UniChar		startChar = p[ index ],
				closeChar = startChar,
				c;
	SInt32		ix = index + 1,
				max = (SInt32) m_params.fTextLength - p.Offset();
	
	switch ( startChar )
	{
		case '{':
			closeChar = '}';
			break;
		
		case '(':
			closeChar = ')';
			break;
		
		case '[':
			closeChar = ']';
			break;
		
		default:
			break;
	}
	
	for ( ; ix < max; ++ix )
	{
		c = p[ ix ];
		
		if ( ( c == closeChar ) || ( c == breakChar ) )
			break;
		
		switch ( c )
		{
			case '\r':
			case '\n':
				++ctLines;
				
				break;
			
			case '\\':
				++ix;
				
				break;
			
			case '{':
			case '(':
			case '[':
				// not passing the original breakChar here because we're going to be nested in a subgroup
				if ( ! this->skipGroupByIndexCountingLines( p, ix, 0, ctLines ) )
					return false;
				
				break;
			
			default:
				break;
		}
	}
	
	index = ix;
	
	return ( (bool)p[ ix ] );
}

bool
BBLMTextUtils::skipOctal( BBLMTUNumberType & numberType ) {
	if ( '0' != *m_p )
		return true;
	
	SInt32		startIx = m_p.Offset();
	
	while ( isdigit( *m_p ) )
	{
		if ( ( '9' == *m_p ) || ( '8' == *m_p ) )
		{
			m_p--;
			
			return skipFloat( numberType );
		}
		
		m_p++;
	}
	
	if ( ( '.' == *m_p ) || ( 'e' == *m_p ) || ( 'E' == *m_p ) )
	{
		m_p--;
		
		return this->skipFloat( numberType );
	}
	
	if ( m_p.Offset() - startIx > 1 )
		numberType = kBBLMTUOctal;
	else
		numberType = kBBLMTULong;
	
	return ( 0 != *m_p );
}

bool
BBLMTextUtils::skipHex( BBLMTUNumberType & numberType ) {
	SInt32		startIx = m_p.Offset();
	
	numberType = kBBLMTUHex;
	
	if ( ( *m_p == '0' ) && ( ( m_p[1] == 'x' ) || ( m_p[1] == 'X' ) ) )
	{
		m_p += 2;
		
		_skipHexDigitRun();
		
		if ( m_p.Offset() == startIx + 2 )  // no hex chars were found after the 0x
			m_p -= 2;
	}
	
	return ( 0 != *m_p );
}

bool
BBLMTextUtils::skipBinary( BBLMTUNumberType & numberType ) {
	SInt32		startIx = m_p.Offset();
	
	numberType = kBBLMTUBinary;
	
	if ( ( *m_p == '0' ) && ( ( m_p[1] == 'b' ) || ( m_p[1] == 'B' ) ) )
	{
		m_p += 2;
		
		_skipBinaryDigitRun();
		
		if ( m_p.Offset() == startIx + 2 ) // no binary chars were found after the 0b
			m_p -= 2;
	}
	
	return ( 0 != *m_p );
}

bool
BBLMTextUtils::skipFloat( BBLMTUNumberType & numberType ) {
	numberType = kBBLMTULong;

	this->_skipDigitRun();
	
	if ( '.' == *m_p )
	{
		m_p++;
		
		numberType = kBBLMTUFloat;
	}
	
	this->_skipDigitRun();
	
	if ( ( 'e' == *m_p ) || ( 'E' == *m_p ) )
	{
		m_p++;
		
		if ( ( '-' == *m_p ) || ( '+' == *m_p ) )
			m_p++;
		
		if ( ! isdigit( *m_p ) )
		{
			m_p--;
			
			if ( ( '-' == *m_p ) || ( '+' == *m_p ) )
				m_p--;
			
			return true;
		}
		
		numberType = kBBLMTUScientific;
	}
	
	this->_skipDigitRun();

	return ( 0 != *m_p );
}

bool
BBLMTextUtils::skipNumber( BBLMTUNumberType & numberType ) {
	if ( '-' == *m_p )
		m_p++;
		
	if ( '0' == *m_p )
	{
		if ( ( 'x' == m_p[1] ) || ( 'X' == m_p[1] ) )
		{
			this->skipHex( numberType );
		}
		else if ( ( 'b' == m_p[1] ) || ( 'B' == m_p[1] ) )
		{
			this->skipBinary( numberType );
		}
		else if ( ( 'e' == m_p[1] ) || ( 'E' == m_p[1] ) )
		{
			this->skipFloat( numberType );
		}
		else
		{
			this->skipOctal( numberType );
		}
	}
	else  // 1.2345e+3
	{
		this->skipFloat( numberType );
	}
	
	return m_p.InBounds();
}

void
BBLMTextUtils::_skipDigitRun(void)
{
	UniChar	prevChar = 0;
	
	while ( isdigit( *m_p ) )
	{
		prevChar = (*m_p);
		m_p++;
		
		if (isDigitSeparatorChar(*m_p))
		{
			if (! isdigit(m_p[1]))
				break;
				
			if (! isDigitSeparatorChar(prevChar))
				m_p++;
		}
	}
}

void
BBLMTextUtils::_skipHexDigitRun(void)
{
	UniChar	prevChar = 0;
	
	while ( isHexChar( *m_p ) )
	{
		prevChar = (*m_p);
		m_p++;
		
		if (isDigitSeparatorChar(*m_p))
		{
			if (! isHexChar(m_p[1]))
				break;
				
			if (! isDigitSeparatorChar(prevChar))
				m_p++;
		}
	}
}

void
BBLMTextUtils::_skipBinaryDigitRun(void)
{
	static dispatch_once_t	_inited;
	static NSCharacterSet	*_bits;
	
	dispatch_once(&_inited,
		^()
		{
			_bits = [[NSCharacterSet characterSetWithRange: NSMakeRange('0', 2)] retain];
		}
	);
	
	UniChar	prevChar = 0;
	
	while ( [_bits characterIsMember: *m_p] )
	{
		prevChar = (*m_p);
		m_p++;
		
		if (isDigitSeparatorChar(*m_p))
		{
			if (! [_bits characterIsMember: *m_p])
				break;
				
			if (! isDigitSeparatorChar(prevChar))
				m_p++;
		}
	}
}

bool
BBLMTextUtils::skipWord() {
	while ( m_p.InBounds() )
	{
		//	REVIEW this is naive, and we should probably use isWordChar() instead,
		//	but this will require careful regression testing.
		if ( ! isWordChar( *m_p ) )
			break;
		
		m_p++;
	}
	
	return m_p.InBounds();
}

bool
BBLMTextUtils::skipWordByIndex( SInt32 & index ) {
	return this->skipWordByIndex( m_p, index );
}

bool
BBLMTextUtils::skipWordByIndex( BBLMTextIterator & p, SInt32 & index ) {
	SInt32		ix = index,
				start = p.Offset(),
				limit = m_params.fTextLength;
	
	while ( start + ix < limit )
	{
		if ( isalnum( p[ ix ] ) || ( p[ ix ] == '_' ) )
			ix++;
		else
			break;
	}
	
	index = ix;
	
	return ( start + ix < limit );
}

#pragma mark -
#pragma mark Tests

bool
BBLMTextUtils::matchWord( const char * pat ) {
	SInt32				i = 0,
						pos = m_p.Offset();
	
	if ( ! this->matchChars( m_p, pat, i ) )
		return false;
	
	if ( ( pos + i < (SInt32) m_params.fTextLength ) && isWordChar( m_p[ i ] ) )
		return false;
	
	return true;
}

bool
BBLMTextUtils::imatchWord( const char * pat ) {
	SInt32				i,
						pos = m_p.Offset(),
						max = (SInt32) m_params.fTextLength;
	
	for ( i = 0; pat[ i ]; ++i )
	{
		if ( pos + i >= max )
			return false;
		
		if ( LowerChar( m_p[ i ] ) != LowerChar( pat[ i ] ) )
			return false;
	}
	
	if ( ( pos + i < max ) && isWordChar( m_p[ i ] ) )
		return false;
	
	return true;
}

bool
BBLMTextUtils::matchChars( BBLMTextIterator & txt, const char * pat, SInt32 & ct ) {
	SInt32				i,
						pos = txt.Offset(),
						limit = m_params.fTextLength;
	
	for ( i = 0; pat[ i ]; ++i )
	{
		if ( pos + ct + i >= limit )
			return false;
		
		if (BBLMCharacterIsLineBreak(pat[i]))
		{
			//
			//	if there's a line break in the pattern, check the line-break-ness
			//	of the character, rather than doing a literal compare.
			//
			if (BBLMCharacterIsLineBreak(txt[ct + i]))
				continue;
			
			return false;
		}
		
		if ( txt[ ct + i ] != pat[ i ] )
			return false;
	}
	
	ct += i;
	
	return true;
}

bool
BBLMTextUtils::matchChars( const char * pat ) {
	SInt32				ct = 0;
	
	return this->matchChars( m_p, pat, ct );
}

bool
BBLMTextUtils::imatchCharsByIndex( const char * pat, SInt32 index ) {
	SInt32		i,
				pos = m_p.Offset();
	
	for ( i = index; *pat; ++i, pat++ )
	{
		if ( pos + i >= (SInt32) m_params.fTextLength )
			return false;
		
		if (BBLMCharacterIsLineBreak(m_p[i]) && BBLMCharacterIsLineBreak(*pat))
			continue;
			
		if ( LowerChar( m_p[ i ] ) != LowerChar( *pat ) )
			return false;
	}
	
	return true;
}

bool
BBLMTextUtils::imatchChars( const char * pat ) {
	SInt32			i = 0;
	
	return this->imatchCharsByIndex(pat, i);
}



#pragma mark -


/*
 Starting at position rightSide, move to the left until a non-whitespace char is found
 */
bool
BBLMTextUtils::rightTrimByIndex( SInt32 leftIndex, SInt32 rightSide ) {
	SInt32		ix, lastReturn;
	bool		flContinue = true;
	UniChar		c;
	
	ix = lastReturn = rightSide;
	
	for ( ; flContinue && ( ix > leftIndex ); --ix )
	{
		c = m_p[ ix ];
		
		if ( this->isInlineWhiteChar( c ) )
			;
		else if ( this->isEOLChar( c ) )
			lastReturn = ix - 1;
		else
			flContinue = false;
	}
	
	return lastReturn;
}

bool
BBLMTextUtils::skipDelimitedStringByIndex( SInt32 & index, bool flAllowEOL,
										   bool flAllowEscapes, bool flAllowEscapedEOL ) {
	SInt32		ix = index + 1,
				limit = m_params.fTextLength - m_p.Offset();
	UniChar		c,
				delim;
	
	if ( ix < limit )
		delim = m_p[ index ];
	else
		return false;
	
	while ( ix < limit )
	{
		c = m_p[ ix ];
		
		if ( delim == c )
			break;
		else if ( ! flAllowEOL && this->isEOLChar( c ) )
			break;
		else if ( flAllowEscapes && ( '\\' == c ) )
		{
			if ( ! flAllowEscapedEOL && this->isEOLChar( m_p[ ix + 1 ] ) )
				break;
			
			++ix;
		}
		
		++ix;
	}
	
	index = ix + ( ( ix < limit ) ? 1 : 0 );
	
	return index < limit;
}

bool
BBLMTextUtils::skipDelimitedStringByIndex( SInt32 & index ) {
	SInt32		ix = index + 1,
				limit = m_params.fTextLength - m_p.Offset();
	UniChar		c,
				delim;
	
	if ( ix < limit )
	{
		delim = m_p[ index ];
	}
	else
	{
		return false;
	}
	
	while ( ix < limit )
	{
		c = m_p[ ix ];
		
		if ( delim == c )
		{
			break;
		}
		else if ( '\\' == c )
		{
			++ix;
		}
		else if ( BBLMCharacterIsLineBreak(c) )
		{
			break;
		}
		
		++ix;
	}
	
	index = ix;
	
	return ix < limit;
}


UInt32
BBLMTextUtils::countLinesInRange( UInt32 rangeStart, UInt32 rangeStop, UInt32 maxLinesToFind )
{
	if (rangeStop <= rangeStart)
		return 0;
		
	UInt32				i = 0, length = rangeStop - rangeStart,
						ctLines = 0;
	BBLMTextIterator	p( m_params, rangeStart );
	
	while ( p.InBounds() && ( i < length ) )
	{
		if ( BBLMCharacterIsLineBreak(*p) )
		{
			ctLines++;
		}
		
		if ( ctLines >= maxLinesToFind )
		{
			break;
		}
		
		p++;
		++i;
	}
	
	return ctLines;
}

#pragma mark -

SInt32
BBLMTextUtils::copyCollapsedRangeToBuffer( SInt32 & rangeStart, SInt32 & rangeEnd, UniChar * buffer, NSUInteger maxLength ) {
	BBLMTextIterator	p( m_p );
	SInt32				j = 0;
	const NSUInteger	strLength = PIN(static_cast<NSUInteger>(rangeEnd - rangeStart + 1), maxLength);
	bool				flFirstChar = true,
						flNeedSpace = false;

	if ( rangeEnd < rangeStart )
		return 0;
	
	p.SetOffset( rangeStart );
	
	for ( NSUInteger i = 0; i < strLength; i++, p++ )
	{
		const UniChar c = *p;
		
		if ( isspace( c ) )
		{
			if ( flFirstChar )
			{
				rangeStart++;
				continue;
			}
			
			flFirstChar = false;
			flNeedSpace = true;
			continue;
		}
		else if ( flNeedSpace )
		{
			buffer[ j++ ] = ' ';
			flNeedSpace = false;
		}
		
		flFirstChar = false;
		buffer[ j++ ] = c;
	}
	
	p--;
	for ( SInt32 i = rangeEnd; i > rangeStart; i--, p-- )
	{
		if ( isspace( *p ) )
			--rangeEnd;
		else
			break;
	}
	
	return j;
}

CFStringRef
BBLMTextUtils::createCFStringFromOffsets( SInt32 & start, SInt32 & stop, SInt32 maxLength ) {
	enum		{ kMaxStaticLength = 256 };
	CFStringRef	str = NULL;
	SInt32		strLength = PIN((stop - start) + 1, maxLength);
	UniChar		chars[kMaxStaticLength];
	UniChar		*buffer = nil;
	UniChar		*dst = chars;
	
	__Require(stop >= start, errorExitBadParameters);
	
	if (strLength > kMaxStaticLength)
	{
		__Require(nil != (buffer = new UniChar[strLength]), errorExitAllocationFailed);
		dst = buffer;
	}
	
	strLength = this->copyCollapsedRangeToBuffer( start, stop, dst, maxLength );
	
	//	make the string
	str = CFStringCreateWithCharacters( kCFAllocatorDefault, dst, strLength );
	
	__Require(NULL != str, errorExitCFStringCreateFailed);

errorExitAllocationFailed:
errorExitBadParameters:
errorExitCFStringCreateFailed:
	
	delete[] buffer;
	
	return str;
}

CFStringRef
BBLMTextUtils::createCFStringFromOffsetsWithPrefix( SInt32 & start, SInt32 & stop, SInt32 maxLength, CFStringRef prefix ) {
	CFStringRef			str = nil;

	str = this->createCFStringFromOffsets(start, stop, maxLength);
	if ((nil != str) &&
		(nil != prefix) &&
		(0 != CFStringGetLength(prefix)))
	{
		CFMutableStringRef	result = nil;
		
		result = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, prefix);
		__Check(nil != result);
		if (nil != result)
			CFStringAppend(result, str);
			
		CFQRelease(str);
		
		str = result;
	}
	
	return str;
}
