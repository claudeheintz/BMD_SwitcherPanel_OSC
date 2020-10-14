//
//  SwitcherPanelAppDelegate_OSC_Additions.m
//  SwitcherPanel
//
//  Created by Claude Heintz on 9/22/20.
//
/*
 License is available at https://www.claudeheintzdesign.com/lx/opensource.html
 */

#import "SwitcherPanelAppDelegate_OSC_Additions.h"
#include "CallbackMonitors.h"
#import "LXOSCInterface.h"
#import "LXOSCMessage.h"

@implementation SwitcherPanelAppDelegate (OSC_Additions)

#pragma mark OSC Methods

- (IBAction) oscStartStop:(id)sender {
    if ( [LXOSCInterface sharedOSCInterface] ) {
        [LXOSCInterface closeSharedOSCInterface];
        [mOSCButton setTitle:NSLocalizedString(@"Start", nil)];
        [mOSCStatusField setStringValue:@""];
    } else {
        int port = [mOSCPortTextField intValue];
        [LXOSCInterface initSharedInterfaceWithAddress:@"0.0.0.0" port:port serviceName:@"BMD_Switcher" delegate:self];
        
        [mOSCButton setTitle:NSLocalizedString(@"Stop", nil)];
    }
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender {
    if ( [LXOSCInterface sharedOSCInterface] ) {
        [LXOSCInterface closeSharedOSCInterface];
    }
    return NSTerminateNow;
}

#pragma mark OSCInterface Delegate

-(void) oscMessageReceived:(LXOSCMessage *) msg {
    // always dispatch the messa/Users/claude/develop/Blackmagic_ATEM_Switchers_SDK_8.4/Samples/SwitcherPanel/osc/LXOSCInterface.hge on the main thread
    // note, this can back up the main thread depending on the time it takes...
    [self performSelectorOnMainThread:@selector(processOSCMessage:) withObject:msg waitUntilDone:NO];
}

-(void) processOSCMessage:(LXOSCMessage *) msg {
    NSArray* addressPattern = [msg addressPattern];
    NSInteger apParts = [addressPattern count];
    
    if ( apParts > 2 ) {
        if ( [[addressPattern firstObject] isEqualToString:@"bmd"] ) {
            if ( [[addressPattern objectAtIndex:1] isEqualToString:@"switcher"] ) {
                
                // /bmd/switcher/transition/auto        [1.0],
                // /bmd/switcher/transition/cut         [1.0],
                // /bmd/switcher/transition/ftb         [1.0]
                // /bmd/switcher/transition/position    [P]
                if ( [[addressPattern objectAtIndex:2] isEqualToString:@"transition"] ) {
                    if ( apParts == 4 ) {
                        if ( [msg argumentCount] == 1 ) {
                            [self oscDispatchTransition:[addressPattern objectAtIndex:3] arg:[msg floatAtIndex:0]];
                        }
                    }
                }
                
                // /bmd/switcher/preview/N [1.0]
                // /bmd/switcher/preview   [N]
                else if ( [[addressPattern objectAtIndex:2] isEqualToString:@"preview"] ) {
                    if ( apParts == 4 ) {
                        if ( [msg floatAtIndex:0] == 1.0 ) {
                            [self oscDispatchPreview:[[addressPattern objectAtIndex:3] integerValue]];
                        }
                    } else if ( apParts == 3 ) {
                        [self oscDispatchPreview:[msg integerAtIndex:0]];
                    }
                }
                
                // /bmd/switcher/program/N [1.0]
                // /bmd/switcher/program   [N]
                else if ( [[addressPattern objectAtIndex:2] isEqualToString:@"program"] ) {
                    if ( apParts == 4 ) {
                        if ( [msg floatAtIndex:0] == 1.0 ) {
                            [self oscDispatchProgram:[[addressPattern objectAtIndex:3] integerValue]];
                        }
                    } else if ( apParts == 3 ) {
                        [self oscDispatchProgram:[msg integerAtIndex:0]];
                    }
                }
                
                else if ( [[addressPattern objectAtIndex:2] isEqualToString:@"media"] ) {
                    if ( apParts == 5 ) {
                        if ( [[addressPattern objectAtIndex:3] isEqualToString:@"select"] ) {
                            if ( [msg floatAtIndex:0] == 1.0 ) {
                                [self oscDispatchMediaSelect:[[addressPattern objectAtIndex:4] integerValue]];
                            }
                        }
                    }
                }
                
                else if ( [[addressPattern objectAtIndex:2] isEqualToString:@"go"] ) {
                    if ( apParts == 4 ) {
                        if ( [msg floatAtIndex:0] == 1.0 ) {
                            [self oscDispatchPreview:[[addressPattern objectAtIndex:3] integerValue]];
                            // delay??
                            [self oscDispatchTransition:@"auto" arg:1.0];
                        }
                    }
                }
            }
        }
    }
}

-(void) postOSCStatus:(NSString*) status {
    [mOSCStatusField setStringValue:status];
}

-(void) oscInterfaceError:(NSString*) description level:(int) level {
    NSString* status = description;
    if ( level > LXOSCINTERFACE_MSG_INFO ) {
        status = [NSString stringWithFormat:@"Error: %@", description];
    }
    [self performSelectorOnMainThread:@selector(postOSCStatus:) withObject:status waitUntilDone:NO];
}

-(void) oscDispatchTransition:(NSString*) which arg:(CGFloat)arg {
    if ( mMixEffectBlock != NULL ) {

        if ( [which isEqualToString:@"auto"] ) {
            if ( arg == 1.0 ) {
                mMixEffectBlock->PerformAutoTransition();
            }
        } else if ( [which isEqualToString:@"cut"] ) {
            if ( arg == 1.0 ) {
                mMixEffectBlock->PerformCut();
            }
        } else if ( [which isEqualToString:@"ftb"] ) {
            if ( arg == 1.0 ) {
                mMixEffectBlock->PerformFadeToBlack();
            }
        } else if ( [which isEqualToString:@"position"] ) {
            if (mMoveSliderDownwards) {
                mMixEffectBlock->SetTransitionPosition(1.0-arg);
            } else {
                mMixEffectBlock->SetTransitionPosition(arg);
            }
        }
        
    }
}

-(void) oscDispatchPreview:(NSInteger) index {
    if ( mMixEffectBlock != NULL ) {

        if (( index >= 0 ) && ( index < mNumberOfInputs )) {
            BMDSwitcherInputId previewID = [[mPreviewInputsPopup itemAtIndex:index] tag];
            mMixEffectBlock->SetPreviewInput(previewID);
        }
    
    }   // <- mMixEffectBlock != NULL
}

-(void) oscDispatchProgram:(NSInteger) index {
    if ( mMixEffectBlock != NULL ) {

        if (( index >= 0 ) && ( index < mNumberOfInputs )) {
            BMDSwitcherInputId programID = [[mPreviewInputsPopup itemAtIndex:index] tag];
            mMixEffectBlock->SetProgramInput(programID);
        }
        
    }   // <- mMixEffectBlock != NULL
}

-(void) oscDispatchMediaSelect:(NSInteger) index {
    [self selectMediaPlayerSource:(uint32_t)index]; //uses zero based index
}

@end
