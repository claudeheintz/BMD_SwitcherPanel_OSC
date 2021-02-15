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

#include <netinet/in.h>
#include <netdb.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <arpa/inet.h>

#include <string>

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
        
        [self disconnectService];
        [self stopBrowser];
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
                
                else if ( [[addressPattern objectAtIndex:2] isEqualToString:@"stream"] ) {
                    if ( apParts == 4 ) {
                        if ( [msg floatAtIndex:0] == 1.0 ) {
                            [self oscDispatchStream:[addressPattern objectAtIndex:3]];
                        }
                    }
                }
                
                else if ( [[addressPattern objectAtIndex:2] isEqualToString:@"record"] ) {
                    if ( apParts == 4 ) {
                        if ( [msg floatAtIndex:0] == 1.0 ) {
                            [self oscDispatchRecord:[addressPattern objectAtIndex:3]];
                        }
                    }
                }
                
                else if ( [[addressPattern objectAtIndex:2] isEqualToString:@"streamkey"] ) {
                    if ( apParts == 4 ) {
                        [self oscDispatchStreamKey:[addressPattern objectAtIndex:3]
                                               key:[msg stringAtIndex:0]];
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

-(void) oscDispatchStream:(NSString*) action {
    if ( mSwitcherStream != NULL ) {
        
        if ( [action isEqualToString:@"start"] )
        {
            mSwitcherStream->StartStreaming();
        }
        
        else if ( [action isEqualToString:@"stop"] )
        {
            mSwitcherStream->StopStreaming();
        }
        
    }
}

-(void) oscDispatchRecord:(NSString*) action {
    if ( mSwitcherRecord != NULL ) {
        
        HRESULT result;
        
        if ( [action isEqualToString:@"start"] )
        {
            result = mSwitcherRecord->StartRecording();
            if (FAILED(result)) {
                [self oscInterfaceError:@"Record start failed" level:LXOSCINTERFACE_MSG_DIAGNOSTIC];
            }
        }
        
        else if ( [action isEqualToString:@"stop"] )
        {
            result = mSwitcherRecord->StopRecording();
            if (FAILED(result)) {
                [self oscInterfaceError:@"Record start failed" level:LXOSCINTERFACE_MSG_DIAGNOSTIC];
            }
        }
        
    }
}

-(void) oscDispatchStreamKey:(NSString*) action key:(NSString*) skey {
    if ( mSwitcherStream != NULL ) {
        if ( [skey length] > 0 ) {
            [mStreamKeyTextField setStringValue:skey];
            mSwitcherStream->SetKey((CFStringRef)skey);
        }
    }
}

#pragma mark record/stream

- (IBAction)recordStartButtonPressed:(id)sender {
    if ( mSwitcherRecord != NULL ) {
        mSwitcherRecord->StartRecording();
    }
}

- (IBAction)recordStopButtonPressed:(id)sender {
    if ( mSwitcherRecord != NULL ) {
        mSwitcherRecord->StopRecording();
    }
    mStartRecordButton.state = NSOffState;
}

- (IBAction)streamStartButtonPressed:(id)sender {
    if ( mSwitcherStream != NULL ) {
        mSwitcherStream->StartStreaming();
    }
}

- (IBAction)streamStopButtonPressed:(id)sender {
    if ( mSwitcherStream != NULL ) {
        mSwitcherStream->StopStreaming();
    }
    mStartStreamButton.state = NSOffState;
}

-(void) getStreamKey {
    if ( mSwitcherStream != NULL ) {
        NSString* keystring;
        mSwitcherStream->GetKey((CFStringRef*)&keystring);
        [mStreamKeyTextField setStringValue:keystring];
    }
}

- (IBAction) streamKeyChanged:(id)sender {
    if ( mSwitcherStream != NULL ) {
        NSString* keystring = [mStreamKeyTextField stringValue];
        mSwitcherStream->SetKey((CFStringRef)keystring);
    }
}


#pragma mark bonjour menthods

- (IBAction) mdnsButtonPressed:(id)sender {
    if ( self.browser ) {
        [self stopSearchingForSwitcher];
    } else {
        [self startSearchingForSwitcher];
    }
}

-(void) startSearchingForSwitcher {
    [self findSenderConnectionForName:@"*"];
    [mOSCStatusField setStringValue:@"searching for switcher..."];
    [mMDNSButton setTitle:@"Stop Search"];
}

-(void) stopSearchingForSwitcher {
    [self disconnectService];
    [self stopBrowser];
    [mMDNSButton setTitle:@"Search with Bonjour"];
    if ( [[mOSCStatusField stringValue] isEqualToString:@"searching for switcher..."] ) {
        [mOSCStatusField setStringValue:@""];
    }
}

-(void) findSenderConnectionForName:(NSString*) dname {
    self.desiredName = dname;
    if ( ! self.browser ) {
        self.browser = [[[NSNetServiceBrowser alloc] init] autorelease];
        [self.browser setDelegate:self];
        [self.browser searchForServicesOfType:@"_blackmagic._tcp" inDomain:@""];
       
    }
}

-(void) stopBrowser {
    [self.browser setDelegate:NULL];
    [self.browser stop];
    self.browser = NULL;
}

-(void) disconnectService {
    [self.service setDelegate:NULL];
    self.service = NULL;
    self.desiredName = NULL;
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    NSRange rng = [[aNetService name] rangeOfString:self.desiredName];
    if ( rng.location != NSNotFound ) {
        [self attemptToResolveNetService:aNetService];
    } else if ( [self.desiredName isEqualToString:@"*"] ) {
        [self attemptToResolveNetService:aNetService];
    }
    
    if ( ! moreComing ) {
        //[self stopBrowser];
    }
}

-(void) attemptToResolveNetService:(NSNetService *)aNetService {
    self.service = aNetService;
    [aNetService setDelegate:self];
    [aNetService resolveWithTimeout:1.0];
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    [self stopBrowser];
    [self.service setDelegate:NULL];
    self.service = NULL;
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    self.service = sender;
    
    NSData* d;
    NSString* addrstr = NULL;
    NSString* msg = @"MDNS returned";
    struct sockaddr_in rv_addr;
    for ( d in [sender addresses] ) {
        if ( [d length] == sizeof(rv_addr) ) {
            rv_addr = *(struct sockaddr_in *)[d bytes];
            
            addrstr = [NSString stringWithCString:inet_ntoa(rv_addr.sin_addr) encoding:NSUTF8StringEncoding];
            
            msg = [NSString stringWithFormat:@"%@, %@", msg, addrstr];
            
            [mAddressTextField setStringValue:addrstr];
        }
    }
    
    if ( addrstr ) {
        [mAddressTextField setStringValue:addrstr];
    }
    [mOSCStatusField setStringValue:msg];

    //[self disconnectService];
    //[self stopBrowser];
}


- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict {
    NSLog(@"NSNetServiceBrowser did not search.");
    self.desiredName = NULL;
}
@end
