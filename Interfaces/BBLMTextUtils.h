/*
 *  BBLMTextUtils.h
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
 
#ifndef BBLMTextUtils_h
#define BBLMTextUtils_h

#include "BBLMInterface.h"
#include "BBLMTextIterator.h"

#define isByte(c)			( ( (c) & ~0xFF ) == 0 )
#define isBracket(c)		( ( (c) == '(' ) || ( (c) == '{' ) || ( (c) == '[' ) || ( (c) == ']' ) || ( (c) == '}' ) || ( (c) == ')' ) )
#define isHexChar(c)    	( isByte(c) &&											\
                        	  ( ( ( (c) >= '0' ) && ( (c) <= '9' ) ) ||				\
                        		( ( (c) >= 'a' ) && ( (c) <= 'f' ) ) ||				\
                        		( ( (c) >= 'A' ) && ( (c) <= 'F' ) ) ) )

class BBLMTextUtils
{

#pragma mark -
#pragma mark public
public:
	BBLMTextUtils(			BBLMParamBlock &	params,
					const	BBLMCallbackBlock &	/* bblm_callbacks */,
							BBLMTextIterator &	p );
	
	virtual ~BBLMTextUtils();
	
	
			bool			isBreakChar( UniChar );
			bool			isInlineWhiteChar( UniChar );
			bool			isEOLChar( UniChar );
			bool			isWordChar( const UniChar );
			bool			isIdentifierChar( const UniChar );
			bool			isDigitSeparatorChar (const UniChar );
			
	static
	inline	UniChar			LowerChar( const UniChar c ) {
								return ( ( c >= 'A' ) && ( c <= 'Z' ) ) ? c + ( 'a' - 'A' ) : c;
							}

	
	
	#pragma mark -
	#pragma mark Skippers
	
			bool			skipWhitespace();
			
			bool			skipInlineWhitespace();
			
			bool			skipInlineWhitespace( SInt32 & );
			
			bool			skipInlineWhitespace( BBLMTextIterator & p );
			
			bool			skipInlineWhitespace( SInt32 &, BBLMTextIterator & );
			
			
			bool			skipInlineWhitespaceByIndex( SInt32 & index ) {
								return this->skipInlineWhitespaceByIndex( m_p, index );
							}
			
			bool			skipInlineWhitespaceByIndex( BBLMTextIterator &, SInt32 & index );
			
			
			void			skipPreviousInlineWhitespace();
			
			void			skipPreviousInlineWhitespaceByIndex( SInt32 & index ) {
								return this->skipPreviousInlineWhitespaceByIndex( m_p, index );
							}
			
			void			skipPreviousInlineWhitespaceByIndex( BBLMTextIterator &, SInt32 & );
			
	
			bool			skipLine() {
								return this->skipLine( m_p );
							}
			
			bool			skipLine( BBLMTextIterator & );
			
	inline	bool			skipLineByIndex( SInt32 & index ) {
								return this->skipLineByIndex( m_p, index );
							}
			
			bool			skipLineByIndex( BBLMTextIterator &, SInt32 & );
			
			bool			skipLineWithMaxIndexByIndex( SInt32 &, SInt32 );
			
	inline	bool			skipToEOL() {
								return this->skipToEOL( m_p );
							}
			
			bool			skipToEOL( BBLMTextIterator & p );
			
			SInt32			findLineEndBeforeIndex( SInt32 );
			
			SInt32			findLineEndAfterIndex( SInt32 );
			
							//	this can be overridden, sadly
	virtual	bool			skipWord();
			
			bool			skipWordByIndex( SInt32 & );
			bool			skipWordByIndex( BBLMTextIterator &, SInt32 & );
				
			bool			skipToCharByIndex( UniChar, SInt32 &, bool );
			
			bool			skipToCharSameLineByIndex( UniChar, SInt32 & );
			
	inline	bool			skipGroupByIndexCountingLines( SInt32 & index, const UniChar breakChar, SInt32 & ctLines ) {
								return this->skipGroupByIndexCountingLines( m_p, index, breakChar, ctLines );
							}
	
			bool			skipGroupByIndexCountingLines( BBLMTextIterator &, SInt32 &, const UniChar, SInt32 & );
			
			bool			rightTrimByIndex( SInt32, SInt32 );
			
			bool			skipDelimitedStringByIndex( SInt32 & );
			
			bool			skipDelimitedStringByIndex( SInt32 & /* index */, bool /* flAllowEOL */,
							                            bool /* flAllowEscape */, bool /* flAllowEscapedEOL */ );
			
			SInt32			copyCollapsedRangeToBuffer( SInt32 &, SInt32 &, UniChar *, NSUInteger );
			
			CFStringRef		createCFStringFromOffsets( SInt32 &, SInt32 &, SInt32 );
			
			CFStringRef		createCFStringFromOffsetsWithPrefix( SInt32 &, SInt32 &, SInt32, CFStringRef );
			
			UInt32			countLinesInRange( UInt32 rangeStart, UInt32 rangeEnd, UInt32 maxLinesToFind);
	
	
	typedef enum BBLMTUNumberType {
		kBBLMTUUnknown,
		kBBLMTULong,
		kBBLMTUOctal,
		kBBLMTUBinary,
		kBBLMTUHex,
		kBBLMTUFloat,
		kBBLMTUScientific,
		kBBLMTUImaginary
	} BBLMTUNumberType;
	
	inline	bool			skipBinary() {
								BBLMTUNumberType nt = kBBLMTUUnknown;
								
								return this->skipBinary( nt );
							}
			
			bool			skipBinary( BBLMTUNumberType & );
			
	
	inline	bool			skipHex() {
								BBLMTUNumberType nt = kBBLMTUUnknown;
								
								return this->skipHex( nt );
							}
			
			bool			skipHex( BBLMTUNumberType & );
			
	
	inline	bool			skipFloat() {
								BBLMTUNumberType nt = kBBLMTUUnknown;
								
								return this->skipFloat( nt );
							}
			
			bool			skipFloat( BBLMTUNumberType & );
			
			
	inline	bool			skipOctal() {
								BBLMTUNumberType nt = kBBLMTUUnknown;
								
								return this->skipOctal( nt );
							}
			
			bool			skipOctal( BBLMTUNumberType & );
			
			
	inline	bool			skipNumber() {
								BBLMTUNumberType nt = kBBLMTUUnknown;
								
								return this->skipNumber( nt );
							}

			bool			skipNumber( BBLMTUNumberType & );
			

#pragma mark -
#pragma mark Tests
			bool			matchChars( const char * );
			bool			matchChars( BBLMTextIterator & txt, const char * pat, SInt32 & ct );
			
			bool			imatchCharsByIndex( const char *, SInt32 );
			bool			imatchChars( const char * );
			
	virtual	bool			matchWord( const char * pat );
	
			bool			imatchWord( const char * pat );
			

#pragma mark -
#pragma mark protected
protected:

			BBLMParamBlock &			m_params;
	
			BBLMTextIterator &			m_p;
	
	#pragma mark -
	#pragma mark Character Tests
	
			void			addBreakChar( UniChar c );
			void			addBreakChars( CFStringRef );

							//	subclasses should override this as needed to modify the default
							//	word-break, scan-break, and identifier character sets.
	virtual	void			initCharacterSets();
			
private:
			void			addCharsToSet( CFStringRef, CFMutableCharacterSetRef );
			void			addCharToSet( UniChar, CFMutableCharacterSetRef );

			void			initWhitespace();
			void			initEOLChars();
			void			initWordChars();
			void			initIdentifierChars();
			void			initDigitSeparatorChars(void);

private:
			void			_skipDigitRun(void);
			void			_skipHexDigitRun(void);
			void			_skipBinaryDigitRun(void);
			
#pragma mark -
#pragma mark private
private:
			
			CFMutableCharacterSetRef	m_inlineWhiteCharSet;
			CFMutableCharacterSetRef	m_breakCharSet;
			CFMutableCharacterSetRef	m_EOLCharSet;

protected:
			NSMutableCharacterSet		*m_wordCharSet;
			NSMutableCharacterSet		*m_identifierCharSet;
			NSMutableCharacterSet		*m_digitSeparatorCharSet;
};

#endif  // BBLMTextUtils_h
