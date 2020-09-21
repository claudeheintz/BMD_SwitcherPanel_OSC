//
//  LXOSCArgument.m
//  LXConsole
//
//  Created by Claude Heintz on 1/5/16.
//  Copyright 2016-2020 Claude Heintz Design. All rights reserved.
//
/*
 License is available at https://www.claudeheintzdesign.com/lx/opensource.html
 */

#import "LXOSCArgument.h"

@implementation LXOSCArgument

@synthesize type;
@synthesize dv;
@synthesize sv;
@synthesize bv;

-(id) initWithInt:(int) d {
    self = [super init];
    
    if ( self ) {
        self.type = LXOSC_ARGTYPE_INT;
        self.dv = d;
        self.sv = [NSString stringWithFormat:@"%i", d];
        self.bv = NULL;
    }
    
    return self;
}

-(id) initWithFloat:(float) d {
    self = [super init];
    
    if ( self ) {
        self.type = LXOSC_ARGTYPE_FLOAT;
        self.dv = d;
        self.sv = [NSString stringWithFormat:@"%f", d];
        self.bv = NULL;
    }
    
    return self;
}

-(id) initWithDouble:(double) d {
    self = [super init];
    
    if ( self ) {
        self.type = LXOSC_ARGTYPE_DOUBLE;
        self.dv = d;
        self.sv = [NSString stringWithFormat:@"%f", d];
        self.bv = NULL;
    }
    
    return self;
}

-(id) initWithTimestamp:(double) d {
    self = [super init];
    
    if ( self ) {
        self.type = LXOSC_ARGTYPE_TIMESTAMP;
        self.dv = d;
        self.sv = [NSString stringWithFormat:@"%f", d];
        self.bv = NULL;
    }
    
    return self;
}

-(id) initWithString:(NSString*) d {
    self = [super init];
    
    if ( self ) {
        self.type = LXOSC_ARGTYPE_STRING;
        self.dv = [d floatValue];
        self.sv = d;
        self.bv = NULL;
    }
    
    return self;
}

-(id) initWithData:(NSData*) d {
    self = [super init];
    
    if ( self ) {
        self.type = LXOSC_ARGTYPE_BLOB;
        self.bv = d;
        self.dv = 0;
        self.sv = NULL;
    }
    
    return self;
}

-(id) initWithType:(uint8_t) t {
    self = [super init];
    
    if ( self ) {
        self.type = t;
        switch (t) {
            case LXOSC_ARGTYPE_TRUE:
                self.dv = 1;
                self.sv = @"true";
                break;
            case LXOSC_ARGTYPE_FALSE:
                self.dv = 0;
                self.sv = @"false";
                break;
            case LXOSC_ARGTYPE_IMPULSE:
                self.dv = 1;
                self.sv = @"";
                break;
            default:
                self.dv = 0;
                self.sv = @"null";
                break;
        }
        self.bv = NULL;
    }
    
    return self;
}

+(LXOSCArgument*) argumentWithInt:(int) i {
    return [[[LXOSCArgument alloc] initWithInt:i] autorelease];
}

+(LXOSCArgument*) argumentWithFloat:(float) f {
    return [[[LXOSCArgument alloc] initWithFloat:f] autorelease];
}

+(LXOSCArgument*) argumentWithDouble:(double) d {
    return [[[LXOSCArgument alloc] initWithDouble:d] autorelease];
}

+(LXOSCArgument*) argumentWithTimestamp:(double) d {
    return [[[LXOSCArgument alloc] initWithTimestamp:d] autorelease];
}

+(LXOSCArgument*) argumentWithString:(NSString*) s {
    return [[[LXOSCArgument alloc] initWithString:s] autorelease];
}

+(LXOSCArgument*) argumentWithData:(NSData*) d {
    return [[[LXOSCArgument alloc] initWithData:d] autorelease];
}

+(LXOSCArgument*) argumentWithType:(uint8_t) t {
    return [[[LXOSCArgument alloc] initWithType:t] autorelease];
}

-(void) dealloc {
    self.sv = NULL;
    self.bv = NULL;
    [super dealloc];
}

#pragma mark type testing

-(BOOL) isIntType {
    return self.type == LXOSC_ARGTYPE_INT;
}

-(BOOL) isFloatType {
    return self.type == LXOSC_ARGTYPE_FLOAT;
}

-(BOOL) isDoubleType {
    return self.type == LXOSC_ARGTYPE_DOUBLE;
}

-(BOOL) isTimestampType {
    return self.type == LXOSC_ARGTYPE_TIMESTAMP;
}

-(BOOL) isNumberType {
    return self.type < LXOSC_ARGTYPE_STRING;
}

-(BOOL) isStringType {
    return self.type == LXOSC_ARGTYPE_STRING;
}

-(BOOL) isBlobType {
    return self.type == LXOSC_ARGTYPE_BLOB;
}

-(BOOL) isTrueType {
    return self.type == LXOSC_ARGTYPE_TRUE;
}

-(BOOL) isFalseType {
    return self.type == LXOSC_ARGTYPE_FALSE;
}

-(BOOL) isImpulseType {
    return self.type == LXOSC_ARGTYPE_IMPULSE;
}

-(BOOL) isNullType {
    return self.type == LXOSC_ARGTYPE_NULL;
}

#pragma mark value retrieval

-(float) floatValue {
    return (float) self.dv;
}

-(NSInteger) integerValue {
    return (NSInteger) self.dv;
}

-(NSNumber*) numberValue {
    return [NSNumber numberWithDouble:self.dv];
}

@end
