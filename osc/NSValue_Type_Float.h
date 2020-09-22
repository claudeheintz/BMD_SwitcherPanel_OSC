//
//  NSValue_Type_Float.h
//  SwitcherPanel
//
//  Created by Claude Heintz on 9/22/20.
//

typedef struct {
    NSInteger type;
    CGFloat value;
} TypeFloatPair;
 
@interface NSValue (TypeFloatPair)
    @property (readonly) TypeFloatPair typeFloatPairValue;

    + (instancetype)valuewithType:(NSInteger) type floatValue:(CGFloat) value;
@end
 

