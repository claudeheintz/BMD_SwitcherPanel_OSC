//
//  SwitcherPanelAppDelegate_OSC_Additions.h
//  SwitcherPanel
//
//  Created by Claude Heintz on 9/22/20.
//
/*
 License is available at https://www.claudeheintzdesign.com/lx/opensource.html
 */

#import "SwitcherPanelAppDelegate.h"
#import "LXOSCInterfaceDelegate.h"

@interface SwitcherPanelAppDelegate (OSC_Additions) <LXOSCInterfaceDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate>

- (IBAction) oscStartStop:(id)sender;

-(void) oscDispatchTransition:(NSString*) which arg:(CGFloat)arg;
-(void) oscDispatchPreview:(NSInteger) index;
-(void) oscDispatchProgram:(NSInteger) index;
-(void) oscDispatchMediaSelect:(NSInteger) index;
-(void) oscDispatchStream:(NSString*) action;
-(void) oscDispatchRecord:(NSString*) action;


- (IBAction)recordStartButtonPressed:(id)sender;
- (IBAction)recordStopButtonPressed:(id)sender;
- (IBAction)streamStartButtonPressed:(id)sender;
- (IBAction)streamStopButtonPressed:(id)sender;

-(void) getStreamKey;
- (IBAction) streamKeyChanged:(id)sender;
-(void) getStreamURL;
- (IBAction) streamURLChanged:(id)sender;

- (IBAction) mdnsButtonPressed:(id)sender;
-(void) startSearchingForSwitcher;
-(void) stopSearchingForSwitcher;
-(void) findSenderConnectionForName:(NSString*) dname;

-(void) updateInterfaceForMixAudioOptions;
-(BMDSwitcherAudioMixOption) mixOptionForIndex:(NSInteger) index;
-(void) setMixOption:(NSInteger) index forAudioInput:(NSInteger) input;
- (IBAction) audioInputOptionChanged:(id)sender;

@end

