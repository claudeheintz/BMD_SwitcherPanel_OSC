//
//  LXOSCMessage.h
//  LXConsole
//
//  Created by Claude Heintz on 6/12/12.
//  Copyright 2012-2020 Claude Heintz Design. All rights reserved.
//
/*
 See https://www.claudeheintzdesign.com/lx/opensource.html
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 * Neither the name of LXNet2USBDMX nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 -----------------------------------------------------------------------------------
 */

#import <Cocoa/Cocoa.h>

@class LXOSCArgument;

@interface LXOSCMessage : NSObject {
	NSMutableArray* arguments;
	NSMutableArray* addressPattern;
}

@property (retain) NSMutableArray* arguments;
@property (retain) NSMutableArray* addressPattern;

-(id) initWithAddress:(NSString*) addr;
-(id) copy;
+(LXOSCMessage*) oscMessageWithAddress:(NSString*) addr;
-(void) dealloc;

-(NSUInteger) addressCount;
-(void) setAddressPatternWithString:(NSString*) astr;
+(NSMutableArray*) addressPartsWithString:(NSString*) astr;
-(NSString*) addressPatternString;
-(void) addAddressPart:(NSString*) astr;
-(NSString*) addressPartAt:(NSUInteger) i;
-(NSString*) firstAddressPart;
-(NSString*) lastAddressPart;

-(BOOL) matchesOSCAddress:(NSArray*) ap;
-(BOOL) matchesAddressPattern:(NSArray*) ap;
-(BOOL) matchesOSCAddressString:(NSString*) astr;
-(BOOL) matchesAddressPatternString:(NSString*) astr;
-(BOOL) partAtIndex:(NSInteger) pj matchesAddressPart:(NSString*) astr;
-(BOOL) firstPatternPartMatchesAddressPart:(NSString*) astr;
-(BOOL) lastPatternPartMatchesAddressPart:(NSString*) astr;
+(BOOL) patternPart:(NSString*) apart matchesAddressPart:(NSString*) ppart;
+(BOOL) addressPart:(NSString*) apart matchesBracePatternPart:(NSString*) ppart;
+(BOOL) addressChar:(char) ac matchesBracketPattern:(NSString*) ppart;

-(void) addArgument:(LXOSCArgument*) p;
-(LXOSCArgument*) argumentAtIndex:(NSUInteger) i;
-(NSUInteger) argumentCount;
-(void) replaceArgumentAt:(NSUInteger) i withFloat:(float) n;

-(BOOL) argumentIsStringAtIndex:(NSUInteger) i;
-(BOOL) argumentIsNumberAtIndex:(NSUInteger) i;

-(float) percentageAtIndex:(NSUInteger) i;
-(float) floatAtIndex:(NSUInteger) i;
-(NSInteger) integerAtIndex:(NSUInteger) i;
-(float) dmxPercentageAtIndex:(NSUInteger) i;
-(NSString*) stringAtIndex:(NSUInteger) i;
-(NSString*) percentageStringAtIndex:(NSUInteger) i;
-(NSString*) inversePercentageStringAtIndex:(NSUInteger) i;
-(NSString*) floatStringAtIndex:(NSUInteger) i;
-(NSString*) integerStringAtIndex:(NSUInteger) i;
-(NSString*) dmxPercentageStringAtIndex:(NSUInteger) i;
-(NSData*) dataAtIndex:(NSUInteger) i;

@end
