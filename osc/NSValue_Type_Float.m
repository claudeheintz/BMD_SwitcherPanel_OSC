//
//  NSValue_Type_Float.m
//  SwitcherPanel
//
//  Created by Claude Heintz on 9/22/20.
//

#import "NSValue_Type_Float.h"

@implementation NSValue (TypeFloatPair)

+ (instancetype)valuewithType:(NSInteger) type floatValue:(CGFloat) value {
    TypeFloatPair pair;
    pair.type = type;
    pair.value = value;
    return [self valueWithBytes:&pair objCType:@encode(TypeFloatPair)];
}

- (TypeFloatPair) typeFloatPairValue {
    TypeFloatPair pair;
    [self getValue:&pair];
    return pair;
}
@end
