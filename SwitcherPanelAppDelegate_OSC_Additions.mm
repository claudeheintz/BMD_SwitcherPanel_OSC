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

// switcherConnected from SwitcherMediaPool example
- (void)switcherConnected_SwitcherMediaPool
{
    HRESULT result;
    REFIID mediaPoolIID = IID_IBMDSwitcherMediaPool;
    IBMDSwitcherMediaPlayerIterator* mediaPlayerIterator = NULL;
    uint32_t clipCount;
    
    // update UI enabled states
    [mMediaPlayerSourcePopup setEnabled:YES];
    [self enableMediaPlayerButtons:true];
    
    // get the media player iterator
    result = mSwitcher->CreateIterator(IID_IBMDSwitcherMediaPlayerIterator, (void**)&mediaPlayerIterator);
    if (FAILED(result))
    {
        NSLog(@"Could not create IBMDSwitcherMediaPlayerIterator iterator\n");
        goto finish;
    }
    
    // get all media players
    while (true)
    {
        IBMDSwitcherMediaPlayer* mediaPlayer = NULL;
        result = mediaPlayerIterator->Next(&mediaPlayer);
        if (result != S_OK)
            break;
        
        mMediaPlayers.push_back(mediaPlayer);
    }
    
    if (FAILED(result))
    {
        NSLog(@"Could not iterate media players\n");
        goto finish;
    }
    
    // get media pool
    result = mSwitcher->QueryInterface(mediaPoolIID, (void**)&mMediaPool);
    if (FAILED(result))
    {
        NSLog(@"Could not get IBMDSwitcherMediaPool interface\n");
        goto finish;
    }
    
    // get stills interface
    result = mMediaPool->GetStills(&mStills);
    if (FAILED(result))
    {
        NSLog(@"Could not get IBMDSwitcherStills interface\n");
        goto finish;
    }
    
    // get number of clips
    result = mMediaPool->GetClipCount(&clipCount);
    if (FAILED(result))
    {
        NSLog(@"Could not get clip count\n");
        goto finish;
    }
    
    // get all clip interfaces
    for (unsigned long clipIndex = 0; clipIndex < clipCount; ++clipIndex)
    {
        IBMDSwitcherClip* clip = NULL;
        
        result = mMediaPool->GetClip(clipIndex, &clip);
        if (FAILED(result))
        {
            NSLog(@"Could not get clip interface\n");
            goto finish;
        }
        
        mClips.push_back(clip);
    }
    
    // check we have media player 1
    if (mMediaPlayers.size() < 1)
    {
        NSLog(@"No media player 1\n");
        goto finish;
    }
    
    // set monitors, which will flush the callbacks and update the GUI
    
    mMediaPlayer1Monitor->setMediaPlayer(mMediaPlayers[0]);
    mStillsMonitor->setStills(mStills);
    
    if (mClipMonitors.size() > 0)
        NSLog(@"Clip monitors have not been deleted\n");
    
    // create clip monitors here because we don't know clip count on initialization
    for (unsigned long clipIndex = 0; clipIndex < mClips.size(); ++clipIndex)
    {
        ClipMonitor* clipMonitor = new ClipMonitor(self);
        clipMonitor->setClip(mClips[clipIndex]);
        mClipMonitors.push_back(clipMonitor);
    }
    /*
    // create still transfer
    mStillTransfer = new StillTransfer(self, window, mSwitcher, mMediaPool, mStills);
    
    // create clip transfers
    for (unsigned long clipIndex = 0; clipIndex < mClips.size(); ++clipIndex)
    {
        ClipTransfer* clipTransfer = new ClipTransfer(self, window, mSwitcher, mMediaPool, mClips[clipIndex]);
        mClipTransfers.push_back(clipTransfer);
    }
    */
finish:
    if (mediaPlayerIterator)
        mediaPlayerIterator->Release();
}

- (void)enableMediaPlayerButtons:(bool)enabled
{
    // sets the media player button widgets enabled state
    
    [mMediaPlayerBeginButton setEnabled:enabled];
    [mMediaPlayerPreviousButton setEnabled:enabled];
    [mMediaPlayerPlayButton setEnabled:enabled];
    [mMediaPlayerNextButton setEnabled:enabled];
    [mMediaPlayerLoopButton setEnabled:enabled];
    
}

- (void)onMediaPlayerSourceChanged
{
    // the source has changed
    
    // update the selected source
    [self updateMediaPlayerPopupSelection];
}

- (void)onMediaPlayerPlayingChanged
{
    // the switcher has notified us that the playing property has changed
    
    bool playing;
    HRESULT result;
    
    // check we have media player 1
    if (mMediaPlayers.size() < 1)
    {
        NSLog(@"No media player 1\n");
        return;
    }
    
    // get the playing property
    result = mMediaPlayers[0]->GetPlaying(&playing);
    if (FAILED(result))
    {
        NSLog(@"Could not get playing\n");
        return;
    }
    
    // update the state of the button
    [mMediaPlayerPlayButton setState:playing];
}

- (void)onMediaPlayerBeginChanged
{
    // the switcher has notified us that the 'at beginning' property has changed
    
    bool atBegining;
    HRESULT result;
    
    // check we have media player 1
    if (mMediaPlayers.size() < 1)
    {
        NSLog(@"No media player 1\n");
        return;
    }
    
    // get the 'at beginning' property
    result = mMediaPlayers[0]->GetAtBeginning(&atBegining);
    if (FAILED(result))
    {
        NSLog(@"Could not get 'at beginning'\n");
        return;
    }
    
    // update the state of the button
    [mMediaPlayerBeginButton setState:atBegining];
}

- (void)onMediaPlayerLoopChanged
{
    // the switcher has notified us that the loop property has changed
    
    bool loop;
    HRESULT result;
    
    // check we have media player 1
    if (mMediaPlayers.size() < 1)
    {
        NSLog(@"No media player 1\n");
        return;
    }
    
    // get the loop property
    result = mMediaPlayers[0]->GetLoop(&loop);
    if (FAILED(result))
    {
        NSLog(@"Could not get loop\n");
        return;
    }
    
    // update the state of the button
    [mMediaPlayerLoopButton setState:loop];
}

- (void)onStillClipNameValidChanged
{
    // We could update only the item that has changed, but this is simpler
    [self updateMediaPopupItems:mMediaPlayerSourcePopup];
}

- (void)updateMediaPopupItems:(NSPopUpButton*)comboBox;
{
    HRESULT result;
    uint32_t stillCount;
    int comboIndex = [comboBox indexOfSelectedItem]; // save current index
    
    // check we have the media pool
    if (! mMediaPool)
    {
        NSLog(@"No media pool\n");
        return;
    }
    
    // clear existing combo box items
    [comboBox removeAllItems];
    
    // append a combox box item for each clip
    for (unsigned long clipIndex = 0; clipIndex < mClips.size(); ++clipIndex)
    {
        NSString* clipName = NULL;
        IBMDSwitcherClip* clip = mClips[clipIndex];
        
        // if the clip is invalid, the clip name will be blank
        result = clip->GetName((CFStringRef*)&clipName);
        if (FAILED(result))
        {
            NSLog(@"Could not get clip name\n");
            return;
        }
        
        // add the clip item
        NSString* itemText = [NSString stringWithFormat:@"Clip %lu: %@", clipIndex + 1, clipName];
        [comboBox addItemWithTitle:itemText];
        
        [clipName release];
    }
    
    // check we have stills
    if (! mStills)
    {
        NSLog(@"No stills\n");
        return;
    }
    
    // get the number of stills
    result = mStills->GetCount(&stillCount);
    if (FAILED(result))
    {
        NSLog(@"Could not get still count\n");
        return;
    }
    
    // append a combo box item for each still
    for (unsigned long stillIndex = 0; stillIndex < stillCount; ++stillIndex)
    {
        NSString* stillName = NULL;
        
        // if the still is invalid, the still name will be blank
        result = mStills->GetName(stillIndex, (CFStringRef*)&stillName);
        if (FAILED(result))
        {
            NSLog(@"Could not get still name\n");
            return;
        }
        
        // add the still item
        NSString* itemText = [NSString stringWithFormat:@"Still %lu: %@", stillIndex + 1, stillName];
        [comboBox addItemWithTitle:itemText];
        
        [stillName release];
    }
    
    // restore previously selected index
    [comboBox selectItemAtIndex:comboIndex];
}

- (void)updateMediaPlayerPopupSelection;
{
    // This method sets the media player combo box selected
    // item to the source of the media player and sets the
    // media player buttons enabled if the selected item is a clip.
    
    HRESULT result;
    BMDSwitcherMediaPlayerSourceType sourceType;
    uint32_t sourceIndex;
    bool valid = false;
    
    // check we have the media pool
    if (! mMediaPool)
    {
        NSLog(@"No media pool\n");
        return;
    }
    
    // check we have media player 1
    if (mMediaPlayers.size() < 1)
    {
        NSLog(@"No media player 1\n");
        return;
    }
    
    // get the source
    result = mMediaPlayers[0]->GetSource(&sourceType, &sourceIndex);
    if (FAILED(result))
    {
        NSLog(@"Could not get media player source\n");
        return;
    }
    
    // set the combo to the media player source
    if (sourceType == bmdSwitcherMediaPlayerSourceTypeClip)
    {
        int popupIndex = sourceIndex; // clip items are listed first in the combo box
        
        // check the clip index is valid
        if (sourceIndex >= (int)mClips.size())
        {
            NSLog(@"Invalid clip selection\n");
            return;
        }
        
        // only enable media player buttons if the clip is valid
        result = mClips[sourceIndex]->IsValid(&valid);
        if (FAILED(result))
        {
            NSLog(@"Could not get clip validity\n");
            return;
        }
        
        [mMediaPlayerSourcePopup selectItemAtIndex:popupIndex];
    }
    else if (sourceType == bmdSwitcherMediaPlayerSourceTypeStill)
    {
        uint32_t popupIndex = (uint32_t)mClips.size() + sourceIndex; // still items are listed second in the combo box
        uint32_t stillCount;
        
        // get the number of stills
        result = mStills->GetCount(&stillCount);
        if (FAILED(result))
        {
            NSLog(@"Could not get still count\n");
            return;
        }
        
        // check the still index is valid
        if (sourceIndex >= stillCount)
        {
            NSLog(@"Invalid still selection\n");
            return;
        }
        
        [mMediaPlayerSourcePopup selectItemAtIndex: popupIndex];
    }
    else
    {
        NSLog(@"Unknown media player source type\n");
        return;
    }
    
    [self enableMediaPlayerButtons:valid];
}

- (IBAction)mediaPlayerSourcePopupChanged:(id)sender
{
    uint32_t comboIndex = (uint32_t)[mMediaPlayerSourcePopup indexOfSelectedItem];
    [self selectMediaPlayerSource:comboIndex];
}

- (void) selectMediaPlayerSource:(uint32_t) mpIndex
{
    HRESULT result;
    uint32_t clipCount;
    BMDSwitcherMediaPlayerSourceType sourceType;
    int sourceIndex;
    
    // check we have the media pool
    if (! mMediaPool)
    {
        NSLog(@"No media pool\n");
        return;
    }
    
    // get the clip count
    result = mMediaPool->GetClipCount(&clipCount);
    if (FAILED(result))
    {
        NSLog(@"Could not get clip count\n");
        return;
    }
    
    // determine if source is clip or still
    if (mpIndex < clipCount)
    {
        // source is a clip
        sourceType = bmdSwitcherMediaPlayerSourceTypeClip;
        sourceIndex = mpIndex;
    }
    else
    {
        // source is a still
        sourceType = bmdSwitcherMediaPlayerSourceTypeStill;
        sourceIndex = mpIndex - clipCount;
    }
    
    // check we have media player 1
    if (mMediaPlayers.size() < 1)
    {
        NSLog(@"No media player 1\n");
        return;
    }
    
    // set media player 1 source
    result = mMediaPlayers[0]->SetSource(sourceType, sourceIndex);
    if (FAILED(result))
    {
        NSLog(@"Could not set media player 1 source\n");
        return;
    }
}

- (IBAction)beginButtonClicked:(id)sender
{
    if (mMediaPlayers.size() < 1)
    {
        NSLog(@"No media player 1\n");
        return;
    }
    
    // toggle the 'at beginning' property, the button state will change upon notification from the switcher
    HRESULT result = mMediaPlayers[0]->SetAtBeginning();
    if (FAILED(result))
    {
        NSLog(@"Could not set 'at beginning'\n");
        return;
    }
}

- (IBAction)previousButtonClicked:(id)sender
{
    HRESULT result;
    uint32_t clipFrameIndex;
    uint32_t clipIndex = [mMediaPlayerSourcePopup indexOfSelectedItem];
    
    // check we have media player 1
    if (mMediaPlayers.size() < 1)
    {
        NSLog(@"No media player 1\n");
        return;
    }
    
    // check we have the clip
    if (clipIndex > mClips.size())
    {
        NSLog(@"No valid clip selected\n");
        return;
    }
    
    // get the clip frame index
    result = mMediaPlayers[0]->GetClipFrame(&clipFrameIndex);
    if (FAILED(result))
    {
        NSLog(@"Could not get clip frame index\n");
        return;
    }
    
    // we can't goto the previous frame if we are on the first frame
    if (clipFrameIndex > 0)
    {
        // set clip frame index to previous frame
        result = mMediaPlayers[0]->SetClipFrame(clipFrameIndex - 1);
        if (FAILED(result))
        {
            NSLog(@"Could not set clip frame index\n");
            return;
        }
    }
}

- (IBAction)playButtonClicked:(id)sender
{
    HRESULT result;
    bool playing;
    
    // check we have media player 1
    if (mMediaPlayers.size() < 1)
    {
        NSLog(@"No media player 1\n");
        return;
    }
    
    // get the playing property
    result = mMediaPlayers[0]->GetPlaying(&playing);
    if (FAILED(result))
    {
        NSLog(@"Could not get playing\n");
        return;
    }
    
    // toggle the playing property, the button state will change upon notification from the switcher
    result = mMediaPlayers[0]->SetPlaying(! playing);
    if (FAILED(result))
    {
        NSLog(@"Could not set playing\n");
        return;
    }
}

- (IBAction)nextButtonClicked:(id)sender
{
    HRESULT result;
    uint32_t clipFrameCount;
    uint32_t clipFrameIndex;
    uint32_t clipIndex = [mMediaPlayerSourcePopup indexOfSelectedItem];
    
    // check we have media player 1
    if (mMediaPlayers.size() < 1)
    {
        NSLog(@"No media player 1\n");
        return;
    }
    
    // check we have the clip
    if (clipIndex > mClips.size())
    {
        NSLog(@"No valid clip selected\n");
        return;
    }
    
    // check we have the clip
    result = mClips[clipIndex]->GetFrameCount(&clipFrameCount);
    if (FAILED(result))
    {
        NSLog(@"Could not get clip frame count\n");
        return;
    }
    
    // get the clip frame index
    result = mMediaPlayers[0]->GetClipFrame(&clipFrameIndex);
    if (FAILED(result))
    {
        NSLog(@"Could not get clip frame index\n");
        return;
    }
    
    // we can't goto the next frame if we are on the last frame
    if (++clipFrameIndex < clipFrameCount)
    {
        // set clip frame index to previous frame
        result = mMediaPlayers[0]->SetClipFrame(clipFrameIndex);
        if (FAILED(result))
        {
            NSLog(@"Could not set clip frame index\n");
            return;
        }
    }
}

- (IBAction)loopButtonClicked:(id)sender
{
    HRESULT result;
    bool loop;
    
    // check we have media player 1
    if (mMediaPlayers.size() < 1)
    {
        NSLog(@"No media player 1\n");
        return;
    }
    
    // get the loop property
    result = mMediaPlayers[0]->GetLoop(&loop);
    if (FAILED(result))
    {
        NSLog(@"Could not get loop\n");
        return;
    }
    
    // toggle the loop property, the button state will change upon notification from the switcher
    result = mMediaPlayers[0]->SetLoop(! loop);
    if (FAILED(result))
    {
        NSLog(@"Could not set loop\n");
        return;
    }
}

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
                        [self oscDispatchPreview:[[addressPattern objectAtIndex:3] integerValue]];
                    } else if ( apParts == 4 ) {
                        [self oscDispatchPreview:[msg integerAtIndex:0]];
                    }
                }
                
                // /bmd/switcher/program/N [1.0]
                // /bmd/switcher/program   [N]
                else if ( [[addressPattern objectAtIndex:2] isEqualToString:@"program"] ) {
                    if ( apParts == 4 ) {
                        [self oscDispatchProgram:[[addressPattern objectAtIndex:3] integerValue]];
                    } else if ( apParts == 3 ) {
                        [self oscDispatchProgram:[msg integerAtIndex:0]];
                    }
                }
                
                else if ( [[addressPattern objectAtIndex:2] isEqualToString:@"media"] ) {
                    if ( apParts == 4 ) {
                        [self oscDispatchMediaSelect:[[addressPattern objectAtIndex:3] integerValue]];
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

-(void) oscDispatchPreview:(NSInteger) which {
    if ( mMixEffectBlock != NULL ) {

        NSInteger index = which - 1;
        if (( which > 0 ) && ( index < mNumberOfInputs )) {
            BMDSwitcherInputId previewID = [[mPreviewInputsPopup itemAtIndex:index] tag];
            NSLog(@"_preview id %i", previewID);
            mMixEffectBlock->SetPreviewInput(previewID);
        }
    
    }   // <- mMixEffectBlock != NULL
}

-(void) oscDispatchProgram:(NSInteger) which {
    if ( mMixEffectBlock != NULL ) {

        NSInteger index = which - 1;
        if (( which > 0 ) && ( index < mNumberOfInputs )) {
            BMDSwitcherInputId programID = [[mPreviewInputsPopup itemAtIndex:index] tag];
            mMixEffectBlock->SetProgramInput(programID);
        }
        
    }   // <- mMixEffectBlock != NULL
}

-(void) oscDispatchMediaSelect:(NSInteger) which {
    [self selectMediaPlayerSource:(uint32_t)(which-1)]; //uses zero based index
}

@end
