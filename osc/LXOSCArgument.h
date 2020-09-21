//
//  LXOSCArgument.h
//  LXConsole
//
//  Created by Claude Heintz on 1/5/16.
//  Copyright 2016-2020 Claude Heintz Design. All rights reserved.
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

#import <Foundation/Foundation.h>

@interface LXOSCArgument : NSObject {
    uint8_t type;
    CGFloat dv;
    NSString* sv;
    NSData* bv;
}

@property (assign) uint8_t type;
@property (assign) CGFloat dv;
@property (retain) NSString* sv;
@property (retain) NSData* bv;


-(id) initWithInt:(int) d;
-(id) initWithFloat:(float) d;
-(id) initWithDouble:(double) d;
-(id) initWithTimestamp:(double) d;
-(id) initWithString:(NSString*) d;
-(id) initWithData:(NSData*) d;
-(id) initWithType:(uint8_t) t;

+(LXOSCArgument*) argumentWithInt:(int) i;
+(LXOSCArgument*) argumentWithFloat:(float) f;
+(LXOSCArgument*) argumentWithDouble:(double) d;
+(LXOSCArgument*) argumentWithTimestamp:(double) d;
+(LXOSCArgument*) argumentWithString:(NSString*) s;
+(LXOSCArgument*) argumentWithData:(NSData*) d;
+(LXOSCArgument*) argumentWithType:(uint8_t) t;

-(BOOL) isIntType;
-(BOOL) isFloatType;
-(BOOL) isDoubleType;
-(BOOL) isTimestampType;
-(BOOL) isNumberType;
-(BOOL) isStringType;
-(BOOL) isBlobType;
-(BOOL) isTrueType;
-(BOOL) isFalseType;
-(BOOL) isImpulseType;
-(BOOL) isNullType;

-(float) floatValue;
-(NSInteger) integerValue;
-(NSNumber*) numberValue;


@end

#define LXOSC_ARGTYPE_INT 0
#define LXOSC_ARGTYPE_FLOAT 1
#define LXOSC_ARGTYPE_DOUBLE 2
#define LXOSC_ARGTYPE_TIMESTAMP 3
#define LXOSC_ARGTYPE_STRING 4
#define LXOSC_ARGTYPE_BLOB 5
#define LXOSC_ARGTYPE_TRUE 6
#define LXOSC_ARGTYPE_FALSE 7
#define LXOSC_ARGTYPE_IMPULSE 8
#define LXOSC_ARGTYPE_NULL 9
