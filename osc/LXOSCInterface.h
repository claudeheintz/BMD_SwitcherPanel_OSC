//
//  LXOSCInterface.h
//  
//
//  Created by Claude Heintz on 6/11/12.
//  Copyright 2012-2020 Claude Heintz Design. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#import "LXOSCInterfaceDelegate.h"


@class LXOSCMessage;
@class LXOSCTCPInterface;

#define LXOSC_BUFFER_SIZE 4096

#define LXOSC_SHOW_DIAGNOSTICS YES
#define LXOSC_HIDE_DIAGNOSTICS NO
#define LXOSC_PRINT_DIAGNOSTICS LXOSC_SHOW_DIAGNOSTICS

@interface LXOSCInterface : NSObject <NSNetServiceDelegate>  {
	
	unsigned char listen_netaddr[4];
	struct sockaddr_in _clientAddress;
	struct sockaddr_in their_addr; // connector's address information
	socklen_t fromlen;

	char _messagein[LXOSC_BUFFER_SIZE];	//message buffer
	int _messagelength;
	
	int _lfd;
    int _tcpfd;
	BOOL _listening;
    BOOL _pause_listening;
	
	BOOL _readpending;
	BOOL _readdirty;
	
	BOOL _writing_to_buffer;
	
	NSThread* _listenthread;
    BOOL _has_listen_thread;
	
	NSString* ipAddress;
	int ipPort;
	
	NSNetService* _netService;
    
    NSMutableArray* tcpInterfaces;
}

@property (retain) NSMutableArray* tcpInterfaces;
@property (retain) NSString* ipAddress;
@property (retain) NSString* netServiceName;
@property (assign) BOOL print_diagnostics;
@property (assign) id<LXOSCInterfaceDelegate> delegate;

-(id) initWithAddress:(NSString*) a port:(int) p serviceName:(NSString*) sn delegate:(id<LXOSCInterfaceDelegate>) d;
-(void) dealloc;
+(LXOSCInterface*) sharedOSCInterface;
+(void) initSharedInterfaceWithAddress:(NSString*) a port:(int) p serviceName:(NSString*) sn delegate:(id<LXOSCInterfaceDelegate>) d;
+(void) closeSharedOSCInterface;
+(void) resetAddress:(NSString*) ipaddr port:(int) newPort;

-(int) createAndBindSocket;
-(void) publishMyNetService;

-(int) createListenSocket;
-(void) closeListenSocket;

-(int) listenfd;
-(int) tcpfd;
-(int) connectionSetForRead;
-(int) tcpConnectionSetForRead:(int) fd timeout:(int) tout;
-(void) resetConnectionWithAddress:(NSString*) ipaddr port:(int) newPort;

-(void) addTCPConnection;
-(void) removeTCPConnection:(LXOSCTCPInterface*) tcpi;
-(void) stopTCPConnections;

-(NSThread*) listeningThread;
-(void) setListeningThread:(NSThread*) thread;
-(BOOL) isListening;
-(void) setListening:(BOOL) l;
-(void) startListening;
-(void) stopListening;
-(void)listen:(id) anObject;
-(void) readAMessage;

CGFloat decode_bytes2double(const void *data , BOOL natural_order);
float decode_bytes2float(const void *data, BOOL natural_order);
int decode_bytes2int (const void *v, BOOL natural_order);
NSInteger nextIndexForString(NSString* s, NSInteger start);
NSInteger nextIndexForIndex(NSInteger index);

-(NSInteger) nextZeroLocation:(NSInteger) start;

NSUInteger unslipData(NSData* indata, char* b, NSUInteger max);

-(void) packetReceived;
-(NSInteger) processMessageAt:(NSInteger) beginindex limit:(NSInteger) endindex;

-(void) printMessage;

@end
