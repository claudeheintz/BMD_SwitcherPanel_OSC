//
//  LXOSCMessage.m
//  LXConsole
//
//  Created by Claude Heintz on 6/12/12.
//  Copyright 2012-2020 Claude Heintz Design. All rights reserved.
//
/*
 License is available at https://www.claudeheintzdesign.com/lx/opensource.html
 */

#import "LXOSCMessage.h"
#import "LXOSCArgument.h"

@implementation LXOSCMessage

@synthesize arguments;
@synthesize addressPattern;

-(id) init {
    self = [super init];
    
    if ( self ) {
        self.addressPattern = [[[NSMutableArray alloc] init] autorelease];
        self.arguments = [[[NSMutableArray alloc] init] autorelease];
    }
    
    return self;
}


-(id) initWithAddress:(NSString*) addr {
	self = [super init];
	
	if ( self ) {
		self.addressPattern = [[[NSMutableArray alloc] init] autorelease];
        [self setAddressPatternWithString:addr];
		self.arguments = [[[NSMutableArray alloc] init] autorelease];
	}
	
	return self;
}

-(id) copy {
    LXOSCMessage* cm = [[LXOSCMessage alloc] init];
    id p;
    for ( p in self.arguments ) {
        [cm addArgument:p];
    }
    for ( p in self.addressPattern ) {
        [cm addAddressPart:p];
    }
    return cm;
}

+(LXOSCMessage*) oscMessageWithAddress:(NSString*) addr {
	LXOSCMessage* m = [[LXOSCMessage alloc] initWithAddress:addr];
	return [m autorelease];
}

-(void) dealloc {
	self.arguments = NULL;
	self.addressPattern = NULL;
	[super dealloc];
}

-(NSUInteger) addressCount {
    return [self.addressPattern count];
}

-(void) setAddressPatternWithString:(NSString*) astr {
    self.addressPattern=[LXOSCMessage addressPartsWithString:astr];
}

+(NSMutableArray*) addressPartsWithString:(NSString*) astr {
    NSMutableArray* rarr = [NSMutableArray array];
    NSArray* parr = [astr componentsSeparatedByString:@"/"];
    NSString* pstr;
    for ( pstr in parr ) {
        if ( [pstr length] > 0 ) {          //remove @"" parts?
            [rarr addObject:pstr];
        }
    }
    return rarr;
}

-(NSString*) addressPatternString {
    NSMutableString* ms = [[NSMutableString alloc] init];
    NSString* estr;
    for ( estr in self.addressPattern ) {
        if ( [estr length] > 0 ) {
            [ms appendFormat:@"/%@", estr];
        }
    }
    return [ms autorelease];
}

-(void) addAddressPart:(NSString*) astr {
    [self.addressPattern addObject:astr];
}

-(NSString*) addressPartAt:(NSUInteger) i {
    if ( i  < [self.addressPattern count] ) {
        return [self.addressPattern objectAtIndex:i];
    }
    return NULL;
}

-(NSString*) firstAddressPart {
    return [self.addressPattern firstObject];
}

-(NSString*) lastAddressPart {
    return [self.addressPattern lastObject];
}

// assumes message holds pattern and matches fixed address
-(BOOL) matchesOSCAddress:(NSArray*) ap {
    NSInteger ac = [self addressCount];
    if ( [ap count] != ac ) {
        return NO;
    }
    
    NSInteger i = 0;
    for(i=0; i<ac; i++) {
        if ( ! [LXOSCMessage patternPart:[self addressPartAt:i] matchesAddressPart:[ap objectAtIndex:i]] ) {
            return NO;
        }
    }
    return YES;
}

// assumes message holds address and matches to pattern
-(BOOL) matchesAddressPattern:(NSArray*) ap {
    NSInteger ac = [self addressCount];
    if ( [ap count] != ac ) {
        return NO;
    }
    
    NSInteger i = 0;
    for(i=0; i<ac; i++) {
        if ( ! [LXOSCMessage patternPart:[ap objectAtIndex:i] matchesAddressPart:[self addressPartAt:i]] ) {
            return NO;
        }
    }
    return YES;
}

// assumes message holds pattern and matches fixed address
-(BOOL) matchesOSCAddressString:(NSString*) astr {
    return [self matchesOSCAddress:[LXOSCMessage addressPartsWithString:astr]];
}

// assumes message holds address and matches to pattern
-(BOOL) matchesAddressPatternString:(NSString*) astr {
    return [self matchesAddressPattern:[LXOSCMessage addressPartsWithString:astr]];
}

-(BOOL) partAtIndex:(NSInteger) pj matchesAddressPart:(NSString*) astr {
    return [LXOSCMessage patternPart:[self.addressPattern objectAtIndex:pj] matchesAddressPart:astr];
}

-(BOOL) firstPatternPartMatchesAddressPart:(NSString*) astr {
    return [LXOSCMessage patternPart:[self.addressPattern firstObject] matchesAddressPart:astr];
}

-(BOOL) lastPatternPartMatchesAddressPart:(NSString*) astr {
    return [LXOSCMessage patternPart:[self.addressPattern lastObject] matchesAddressPart:astr];
}

+(BOOL) patternPart:(NSString*) ppart matchesAddressPart:(NSString*) apart {
    if ( [apart isEqualToString:ppart] ) {
        return YES;
    }
    NSInteger ai = 0;
    NSInteger pj = 0;
    char ac;
    char pc;
    while ( (ai<[apart length]) && (pj<[ppart length])) {
        ac = [apart characterAtIndex:ai];
        pc = [ppart characterAtIndex:pj];
        if ( pc ==  '*' ) {
            pj++;
            if ( pj == [ppart length] ) {
                return YES;				// wildcard matches to end
            }
            pc = [ppart characterAtIndex:pj];
            while ( [apart characterAtIndex:ai] != pc ) {	//match until next pattern char encountered
                ai++;
                if ( ai >= [apart length] ) {
                    return NO;	//ran out of characters
                }
            }
            ai++;
            pj++;
        } else {		// pattern char not *
            if ( pc == ac ) {
                ai++;
                pj++;
            } else if ( pc == '?' ) { // single char wildcard always matches
                ai++;
                pj++;
            } else if ( pc == '[' ) {
                pj++;
                NSRange bracketRange = NSMakeRange(pj, [ppart length] - pj);
                bracketRange = [ppart rangeOfString:@"]" options:NSLiteralSearch range:bracketRange];
                if ( bracketRange.location == NSNotFound ) {
                    return NO;	//invalid list;
                }
                if ( ! [LXOSCMessage addressChar:ac
                           matchesBracketPattern:[ppart substringWithRange:NSMakeRange(pj, bracketRange.location-pj)]] ) {
                    return false;
                }
                ai++;
                pj = bracketRange.location+1;
            } else if ( pc == '{' ) {
                return [LXOSCMessage addressPart:[apart substringFromIndex:ai]
                         matchesBracePatternPart:[ppart substringFromIndex:(pj+1)]];
            } else {			// single character not matched
                return NO;
            }
        }
    }
    
    if (( ai == [apart length] ) && ( pj == [ppart length] )) {
        return YES;
    }
    
    return NO;
}


+(BOOL) addressPart:(NSString*) apart matchesBracePatternPart:(NSString*) ppart {
    NSRange braceRange = [ppart rangeOfString:@"}"];
    if ( braceRange.location == NSNotFound ) {
        return NO;	//invalid list;
    }
    // compare apart to see if it starts with any of the strings inside the braces
    NSString* bstr = [ppart substringWithRange:NSMakeRange(0,braceRange.location)];
    NSArray* sa = [bstr componentsSeparatedByString:@","];
    NSString* astr;
    for ( astr in sa ) {
        if ( [apart hasPrefix:astr] ) {
            if ( [apart length] == [astr length] ) {
                return YES;
            } else if ( [ppart length] > braceRange.location+1 ) {
                return [LXOSCMessage patternPart:[ppart substringFromIndex:braceRange.location+1]
                              matchesAddressPart:[apart substringFromIndex:[astr length]]];
            }
        }
    }
    return NO;	//didn't match
}

+(BOOL) addressChar:(char) ac matchesBracketPattern:(NSString*) blist {
    NSString* mblist = blist;
    BOOL negate = false;
    if ( [mblist hasPrefix:@"!"] ) {
        negate = YES;
        mblist = [blist substringFromIndex:1];
    }
    NSRange acRange = [mblist rangeOfString:[NSString stringWithFormat:@"%c",ac]];
    if ( acRange.location != NSNotFound ) {	 //can be true if start or end of range
        if ( negate ) {
            return false;
        }
        return true;
    }
    // handle ranges (eg. a-f) here
    
    NSInteger dashIndex = 1;
    NSRange dashRange;
    BOOL done = [mblist length] < 3;
    while ( ! done ) {
        dashRange = [mblist rangeOfString:@"-" options:NSLiteralSearch range:NSMakeRange(dashIndex, [mblist length] - dashIndex)];
        if ( dashRange.location == NSNotFound ) {
            done = YES;
        } else {
            if ( [mblist length] == dashRange.location + 1 ) {
                return NO;	//no character after dash, bad pattern is false despite negate
            }
            if (( [mblist characterAtIndex:(dashRange.location-1)] < ac ) && ( ac <  [mblist characterAtIndex:(dashRange.location+1)] )) {
                if ( negate ) {
                    return NO;
                }
                return YES;
            }
            dashIndex = dashRange.location + 1;
            if ( dashIndex+1 >= [mblist length] ) {
                done = YES;
            }
        }
    }
    
    if ( negate ) {
        return YES;
    }
    return NO;
}

#pragma mark argument methods

-(void) addArgument:(LXOSCArgument*) p {
	[self.arguments addObject:p];
}

-(LXOSCArgument*) argumentAtIndex:(NSUInteger) i {
    if ( i < [self.arguments count] ) {
        return [self.arguments objectAtIndex:i];
    }
    return NULL;
}

-(NSUInteger) argumentCount {
    return [self.arguments count];
}

-(void) replaceArgumentAt:(NSUInteger) i withFloat:(float) n {
    if ( i < [self argumentCount] ) {
        LXOSCArgument* arg = [LXOSCArgument argumentWithFloat:n];
        [self.arguments replaceObjectAtIndex:i withObject:arg];
    }
}

-(BOOL) argumentIsStringAtIndex:(NSUInteger) i {
    return [[self argumentAtIndex:i] isStringType];
}

-(BOOL) argumentIsNumberAtIndex:(NSUInteger) i {
    return [[self argumentAtIndex:i] isNumberType];
}

-(float) percentageAtIndex:(NSUInteger) i {
    return [[self argumentAtIndex:i] floatValue] * 100;
}

-(float) floatAtIndex:(NSUInteger) i {
    return [[self argumentAtIndex:i] floatValue];
}

-(NSInteger) integerAtIndex:(NSUInteger) i {
    return [[self argumentAtIndex:i] integerValue];
}

-(float) dmxPercentageAtIndex:(NSUInteger) i {
    return  ( [self floatAtIndex:i]/255.0*100.0 );
}

-(NSString*) stringAtIndex:(NSUInteger) i {
    return [self argumentAtIndex:i].sv;
}

-(NSString*) percentageStringAtIndex:(NSUInteger) i {
    return [NSString stringWithFormat:@"%3.2f", [self percentageAtIndex:i]];
}

-(NSString*) inversePercentageStringAtIndex:(NSUInteger) i {
    return [NSString stringWithFormat:@"%3.2f", 100 - [self percentageAtIndex:i]];
}

-(NSString*) floatStringAtIndex:(NSUInteger) i {
    return [NSString stringWithFormat:@"%4.1f", [self floatAtIndex:i]];
}

-(NSString*) integerStringAtIndex:(NSUInteger) i {
    return [NSString stringWithFormat:@"%i", (int)[self integerAtIndex:i]];
}

-(NSString*) dmxPercentageStringAtIndex:(NSUInteger) i {
    return [NSString stringWithFormat:@"%3.2f", [self dmxPercentageAtIndex:i]];
}

-(NSData*) dataAtIndex:(NSUInteger) i {
    return [self argumentAtIndex:i].bv;
}

@end
