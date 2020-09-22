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

@interface SwitcherPanelAppDelegate (OSC_Additions) <LXOSCInterfaceDelegate>

- (IBAction) oscStartStop:(id)sender;

@end

