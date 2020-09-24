/* -LICENSE-START-
** Copyright (c) 2012 Blackmagic Design
**
** Permission is hereby granted, free of charge, to any person or organization
** obtaining a copy of the software and accompanying documentation covered by
** this license (the "Software") to use, reproduce, display, distribute,
** execute, and transmit the Software, and to prepare derivative works of the
** Software, and to permit third-parties to whom the Software is furnished to
** do so, all subject to the following:
** 
** The copyright notices in the Software and this entire statement, including
** the above license grant, this restriction and the following disclaimer,
** must be included in all copies of the Software, in whole or in part, and
** all derivative works of the Software, unless such copies or derivative
** works are solely in the form of machine-executable object code generated by
** a source language processor.
** 
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
** FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
** SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
** FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
** ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
** DEALINGS IN THE SOFTWARE.
** -LICENSE-END-
*/

#include "CallbackMonitors.h"
#include <os/atomic.h>

// IIDs are defined in a way that prevents us from using CFEqual, so we overload the == operator
static inline bool operator== (const REFIID& iid1, const REFIID& iid2)
{ 
	return CFEqual(&iid1, &iid2);
}

// ----------------------------------------------------------

MediaPlayerCallback::MediaPlayerCallback(SwitcherPanelAppDelegate* uiDelegate)
 :	mUIDelegate(uiDelegate),
	mRefCount(1)
{
}

HRESULT MediaPlayerCallback::QueryInterface(REFIID iid, LPVOID *ppv)
{
	if (!ppv)
		return E_POINTER;
	
	if (iid == IID_IBMDSwitcherMediaPlayerCallback)
	{
		*ppv = static_cast<IBMDSwitcherMediaPlayerCallback*>(this);
		AddRef();
		return S_OK;
	}
	
	if (CFEqual(&iid, IUnknownUUID))
	{
		*ppv = static_cast<IUnknown*>(this);
		AddRef();
		return S_OK;
	}
	
	*ppv = NULL;
	return E_NOINTERFACE;
}

ULONG MediaPlayerCallback::AddRef(void)
{
    return os_atomic_std(atomic_fetch_add_explicit)(
                                                     os_cast_to_atomic_pointer(&mRefCount), 1,
                                                     os_atomic_std(memory_order_relaxed));
	//return ::OSAtomicIncrement32(&mRefCount);
}

ULONG MediaPlayerCallback::Release(void)
{
    int newCount = os_atomic_std(atomic_fetch_sub_explicit)(
                                                            os_cast_to_atomic_pointer(&mRefCount), 1,
                                                            os_atomic_std(memory_order_relaxed));
	//int newCount = ::OSAtomicDecrement32(&mRefCount);
	if (newCount == 0)
		delete this;
	return newCount;
}

HRESULT MediaPlayerCallback::SourceChanged(void)
{
	[mUIDelegate performSelectorOnMainThread:@selector(onMediaPlayerSourceChanged) withObject:nil waitUntilDone:NO];
	return S_OK;
}

HRESULT MediaPlayerCallback::PlayingChanged(void)
{
	[mUIDelegate performSelectorOnMainThread:@selector(onMediaPlayerPlayingChanged) withObject:nil waitUntilDone:NO];
	return S_OK;
}

HRESULT MediaPlayerCallback::LoopChanged(void)
{
	[mUIDelegate performSelectorOnMainThread:@selector(onMediaPlayerLoopChanged) withObject:nil waitUntilDone:NO];
	return S_OK;
}  

HRESULT MediaPlayerCallback::AtBeginningChanged(void)
{
	[mUIDelegate performSelectorOnMainThread:@selector(onMediaPlayerBeginChanged) withObject:nil waitUntilDone:NO];
	return S_OK;
}  

HRESULT MediaPlayerCallback::ClipFrameChanged(void)
{
	return S_OK;
}

MediaPlayerCallback::~MediaPlayerCallback()
{
}

// ----------------------------------------------------------

MediaPlayerMonitor::MediaPlayerMonitor(SwitcherPanelAppDelegate* uiDelegate)
 :	mMediaPlayer(NULL)
{
	mCallback = new MediaPlayerCallback(uiDelegate);
}

MediaPlayerMonitor::~MediaPlayerMonitor()
{
	setMediaPlayer(NULL);
	mCallback->Release();
}

void MediaPlayerMonitor::setMediaPlayer(IBMDSwitcherMediaPlayer* mediaPlayer)
{
	if (mMediaPlayer)
	{
		mMediaPlayer->RemoveCallback(mCallback);
		mMediaPlayer->Release();
	}

	mMediaPlayer = mediaPlayer;
	if (mMediaPlayer)
	{
		mMediaPlayer->AddRef();
		mMediaPlayer->AddCallback(mCallback);

		// we flush callbacks here to update the state of the listeners
		flush();
	}
}

void MediaPlayerMonitor::flush()
{
	mCallback->SourceChanged();
	mCallback->PlayingChanged();
	mCallback->LoopChanged();
	mCallback->AtBeginningChanged();
}

// ----------------------------------------------------------

StillsCallback::StillsCallback(SwitcherPanelAppDelegate* uiDelegate)
 :	mUIDelegate(uiDelegate),
	mRefCount(1)
{
}

HRESULT StillsCallback::QueryInterface(REFIID iid, LPVOID *ppv)
{
	if (!ppv)
		return E_POINTER;

	if (iid == IID_IBMDSwitcherStillsCallback)
	{
		*ppv = static_cast<IBMDSwitcherStillsCallback*>(this);
		AddRef();
		return S_OK;
	}

	if (CFEqual(&iid, IUnknownUUID))
	{
		*ppv = static_cast<IUnknown*>(this);
		AddRef();
		return S_OK;
	}

	*ppv = NULL;
	return E_NOINTERFACE;
}

ULONG StillsCallback::AddRef(void)
{
    return os_atomic_std(atomic_fetch_add_explicit)(
                                                     os_cast_to_atomic_pointer(&mRefCount), 1,
                                                     os_atomic_std(memory_order_relaxed));
	//return ::OSAtomicIncrement32(&mRefCount);
}

ULONG StillsCallback::Release(void)
{
    int newCount = os_atomic_std(atomic_fetch_sub_explicit)(
                                                            os_cast_to_atomic_pointer(&mRefCount), 1,
                                                            os_atomic_std(memory_order_relaxed));
	//int newCount = ::OSAtomicDecrement32(&mRefCount);
	if (newCount == 0)
		delete this;
	return newCount;
}

HRESULT StillsCallback::Notify(BMDSwitcherMediaPoolEventType eventType, IBMDSwitcherFrame* /*frame*/, int32_t index)
{
	// This example supports uploading only so we don't use the frame.
	// If you need to use the frame outside of the scope of this method then you must
	// add a reference to it to prevent it from being released.

	switch (eventType)
	{
		// when a still becomes invalid we need to clear the name, so we post both together
		case bmdSwitcherMediaPoolEventTypeValidChanged:
		case bmdSwitcherMediaPoolEventTypeNameChanged:
		{
			[mUIDelegate performSelectorOnMainThread:@selector(onStillClipNameValidChanged) withObject:nil waitUntilDone:NO];
		}
		break;

		case bmdSwitcherMediaPoolEventTypeTransferCompleted:
		case bmdSwitcherMediaPoolEventTypeTransferCancelled:
		case bmdSwitcherMediaPoolEventTypeTransferFailed:
		{
			// we can't assume there is an auto release pool because we don't know which thread this callback is executed on
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			BOOL success = (eventType == bmdSwitcherMediaPoolEventTypeTransferCompleted);

			[mUIDelegate performSelectorOnMainThread:@selector(onStillsTransferEnded:) withObject:[NSNumber numberWithBool:success] waitUntilDone:NO];
			[pool drain];
		}
		break;
	}

	return S_OK;
}

StillsCallback::~StillsCallback()
{
}

// ----------------------------------------------------------

StillsMonitor::StillsMonitor(SwitcherPanelAppDelegate* uiDelegate)
	:	mStills(NULL)
{
	mCallback = new StillsCallback(uiDelegate);
}

StillsMonitor::~StillsMonitor()
{
	setStills(NULL);
	mCallback->Release();
}

void StillsMonitor::setStills(IBMDSwitcherStills* stills)
{
	if (mStills)
	{
		mStills->RemoveCallback(mCallback);
		mStills->Release();
	}

	mStills = stills;
	if (mStills)
	{
		mStills->AddRef();
		mStills->AddCallback(mCallback);

		// we flush callbacks here to update the state of the listeners
		flush();
	}
}

void StillsMonitor::flush()
{
	// flushing one still is sufficient because our callback will update all
	// the callbacks update for either NameChanged or ValidChanged so we only flush name changed
	mCallback->Notify(bmdSwitcherMediaPoolEventTypeNameChanged, NULL, 0);
}

// ----------------------------------------------------------

ClipCallback::ClipCallback(SwitcherPanelAppDelegate* uiDelegate)
 :	mUIDelegate(uiDelegate),
	mRefCount(1)
{
}

HRESULT ClipCallback::QueryInterface(REFIID iid, LPVOID *ppv)
{
	if (!ppv)
		return E_POINTER;

	if (iid == IID_IBMDSwitcherClipCallback)
	{
		*ppv = static_cast<IBMDSwitcherClipCallback*>(this);
		AddRef();
		return S_OK;
	}

	if (CFEqual(&iid, IUnknownUUID))
	{
		*ppv = static_cast<IUnknown*>(this);
		AddRef();
		return S_OK;
	}

	*ppv = NULL;
	return E_NOINTERFACE;
}

ULONG ClipCallback::AddRef(void)
{
    return os_atomic_std(atomic_fetch_add_explicit)(
                                                     os_cast_to_atomic_pointer(&mRefCount), 1,
                                                     os_atomic_std(memory_order_relaxed));
	//return ::OSAtomicIncrement32(&mRefCount);
}

ULONG ClipCallback::Release(void)
{
    int newCount = os_atomic_std(atomic_fetch_sub_explicit)(
                                                            os_cast_to_atomic_pointer(&mRefCount), 1,
                                                            os_atomic_std(memory_order_relaxed));
	//int newCount = ::OSAtomicDecrement32(&mRefCount);
	if (newCount == 0)
		delete this;
	return newCount;
}

HRESULT ClipCallback::Notify(BMDSwitcherMediaPoolEventType eventType,
							 IBMDSwitcherFrame *frame,
							 int32_t frameIndex,
							 IBMDSwitcherAudio *audio,
							 int32_t clipIndex)
{
	// This example supports uploading only so we don't use the frame.
	// If you need to use the frame outside of the scope of this method then you must
	// add a reference to it to prevent it from being released.

	switch (eventType)
	{
		// when a clip becomes invalid we need to clear the name, so we post both together
		case bmdSwitcherMediaPoolEventTypeNameChanged:
		case bmdSwitcherMediaPoolEventTypeValidChanged:
			[mUIDelegate performSelectorOnMainThread:@selector(onStillClipNameValidChanged) withObject:nil waitUntilDone:NO];
			break;

		case bmdSwitcherMediaPoolEventTypeTransferCompleted:
		case bmdSwitcherMediaPoolEventTypeTransferCancelled:
		case bmdSwitcherMediaPoolEventTypeTransferFailed:
		{
			// we can't assume there is an auto release pool because we don't know which thread this callback is executed on
			NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
			bool success = (eventType == bmdSwitcherMediaPoolEventTypeTransferCompleted);
			NSArray* args = [NSArray arrayWithObjects:[NSNumber numberWithBool:success], [NSNumber numberWithInt:clipIndex], nil];
			
			[mUIDelegate performSelectorOnMainThread:@selector(onClipTransferEnded:) withObject:args waitUntilDone:NO];
			[pool drain];
		}
		break;
	}

	return S_OK;
}

ClipCallback::~ClipCallback()
{
}

// ----------------------------------------------------------

ClipMonitor::ClipMonitor(SwitcherPanelAppDelegate* uiDelegate)
	:	mClip(NULL)
{
	mCallback = new ClipCallback(uiDelegate);
}

ClipMonitor::~ClipMonitor()
{
	setClip(NULL);
	mCallback->Release();
}

void ClipMonitor::setClip(IBMDSwitcherClip* clip)
{
	if (mClip)
	{
		mClip->RemoveCallback(mCallback);
		mClip->Release();
	}

	mClip = clip;
	if (mClip)
	{
		mClip->AddRef();
		mClip->AddCallback(mCallback);

		// we flush callbacks here to update the state of the listeners
		flush();
	}
}

void ClipMonitor::flush()
{
	// we can't flush if we don't have a clip interface
	if (! mClip)
		return;

	uint32_t clipIndex;
	HRESULT result = mClip->GetIndex(&clipIndex);
	if (FAILED(result))
	{
		NSLog(@"Could not get clip index\n");
		return;
	}

	// the callbacks update for either NameChanged or ValidChanged so we only flush name changed
	mCallback->Notify(bmdSwitcherMediaPoolEventTypeNameChanged, NULL, -1, NULL, clipIndex);
}

// ----------------------------------------------------------

LockCallback::LockCallback(SwitcherPanelAppDelegate* uiDelegate, int clipIndex)
 :	mUIDelegate(uiDelegate),
	mRefCount(1),
	mClipIndex(clipIndex)
{
}

// IUnknown
HRESULT LockCallback::QueryInterface(REFIID iid, LPVOID *ppv)
{
	if (!ppv)
		return E_POINTER;

	if (iid == IID_IBMDSwitcherLockCallback)
	{
		*ppv = static_cast<IBMDSwitcherLockCallback*>(this);
		AddRef();
		return S_OK;
	}

	if (CFEqual(&iid, IUnknownUUID))
	{
		*ppv = static_cast<IUnknown*>(this);
		AddRef();
		return S_OK;
	}

	*ppv = NULL;
	return E_NOINTERFACE;
}

ULONG LockCallback::AddRef(void)
{
    return os_atomic_std(atomic_fetch_add_explicit)(
                                                     os_cast_to_atomic_pointer(&mRefCount), 1,
                                                     os_atomic_std(memory_order_relaxed));
	//return ::OSAtomicIncrement32(&mRefCount);
}

ULONG LockCallback::Release(void)
{
    int newCount = os_atomic_std(atomic_fetch_sub_explicit)(
                                                            os_cast_to_atomic_pointer(&mRefCount), 1,
                                                            os_atomic_std(memory_order_relaxed));
	//int newCount = ::OSAtomicDecrement32(&mRefCount);
	if (newCount == 0)
		delete this;
	return newCount;
}

HRESULT LockCallback::Obtained()
{
	// this callback is used for both the stills and clip interfaces
	// perform the appropriate stills or clip method on the main thread
	if (mClipIndex >= 0)
	{
		// we can't assume there is an auto release pool because we don't know which thread this callback is executed on
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		[mUIDelegate performSelectorOnMainThread:@selector(onClipLockObtained:) withObject:[NSNumber numberWithInt:mClipIndex] waitUntilDone:NO];
		[pool drain];
	}
	else
	{
		[mUIDelegate performSelectorOnMainThread:@selector(onStillsLockObtained) withObject:nil waitUntilDone:NO];
	}
	
	return S_OK;
}

// ----------------------------------------------------------
/*
SwitcherCallback::SwitcherCallback(SwitcherPanelAppDelegate* uiDelegate)
 :	mUIDelegate(uiDelegate),
	mRefCount(1)
{
}

// IBMDSwitcherCallback interface
HRESULT SwitcherCallback::QueryInterface(REFIID iid, LPVOID *ppv)
{
	if (!ppv)
		return E_POINTER;

	if (iid == IID_IBMDSwitcherCallback)
	{
		*ppv = static_cast<IBMDSwitcherCallback*>(this);
		AddRef();
		return S_OK;
	}

	if (CFEqual(&iid, IUnknownUUID))
	{
		*ppv = static_cast<IUnknown*>(this);
		AddRef();
		return S_OK;
	}

	*ppv = NULL;
	return E_NOINTERFACE;
}

ULONG SwitcherCallback::AddRef(void)
{
    return os_atomic_std(atomic_fetch_add_explicit)(
                                                  os_cast_to_atomic_pointer(&mRefCount), 1,
                                                  os_atomic_std(memory_order_relaxed));
	//return ::OSAtomicIncrement32(&mRefCount);
}

ULONG SwitcherCallback::Release(void)
{
	int newCount = ::OSAtomicDecrement32(&mRefCount);
	if (newCount == 0)
		delete this;
	return newCount;
}

HRESULT SwitcherCallback::Notify(BMDSwitcherEventType eventType, BMDSwitcherVideoMode coreVideoMode)
{
	if (eventType == bmdSwitcherEventTypeDisconnected)
	{
		[mUIDelegate performSelectorOnMainThread:@selector(switcherDisconnected) withObject:nil waitUntilDone:NO];
	}
	return S_OK;
}

SwitcherCallback::~SwitcherCallback()
{
}

// ----------------------------------------------------------

SwitcherMonitor::SwitcherMonitor(SwitcherPanelAppDelegate* uiDelegate)
:	mSwitcher(NULL)
{
	mCallback = new SwitcherCallback(uiDelegate);
}

SwitcherMonitor::~SwitcherMonitor()
{
	setSwitcher(NULL);
	mCallback->Release();
}

void SwitcherMonitor::setSwitcher(IBMDSwitcher* switcher)
{
	if (mSwitcher)
	{
		mSwitcher->RemoveCallback(mCallback);
		mSwitcher->Release();
	}
	
	mSwitcher = switcher;
	if (mSwitcher)
	{
		mSwitcher->AddRef();
		mSwitcher->AddCallback(mCallback);
	}
}
*/
