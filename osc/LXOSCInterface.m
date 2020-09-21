//
//  LXOSCInterface.m
//  
//
//  Created by Claude Heintz on 6/11/12.
//  Copyright 2009-2020 Claude Heintz Design. All rights reserved.
//
/*
 License is available at https://www.claudeheintzdesign.com/lx/opensource.html
 */

#import "LXOSCInterface.h"
#import "LXOSCTCPInterface.h"
#import "LXOSCMessage.h"
#import "LXOSCArgument.h"
#import "LXOSCConstants.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <arpa/inet.h>

LXOSCInterface* _sharedOSCInterface = NULL;

@implementation LXOSCInterface

@synthesize tcpInterfaces;
@synthesize ipAddress;
@synthesize netServiceName;
@synthesize print_diagnostics;
@synthesize delegate;

-(id) initWithAddress:(NSString*) a port:(int) p serviceName:(NSString*) sn delegate:(id<LXOSCInterfaceDelegate>) d {
	self = [super init];
	if ( self ) {
		_lfd = -1;
        _tcpfd = -1;
		_readpending = NO;
		_readdirty = NO;
		_writing_to_buffer = NO;
		
		self.ipAddress = a;
		ipPort = p;
        self.netServiceName = sn;
        self.delegate = d;
        
		fromlen = (socklen_t) sizeof _clientAddress;
		_netService = NULL;
        self.tcpInterfaces = [[[NSMutableArray alloc] init] autorelease];
        
        self.print_diagnostics = LXOSC_PRINT_DIAGNOSTICS;
        _has_listen_thread = NO;
		
        _pause_listening = NO;
		[self startListening];
	}
	return self;
}

-(void) dealloc {
    [self stopListening];
	self.ipAddress = NULL;
    self.netServiceName = NULL;
    self.tcpInterfaces = NULL;
    self.delegate = NULL;
    [self stopTCPConnections];  //may be redundant but make sure this happens...
	[self closeListenSocket];   //may get here before listening thread ends...
    [super dealloc];
}

#pragma mark class methods

+(LXOSCInterface*) sharedOSCInterface {
	return _sharedOSCInterface;
}

+(void) initSharedInterfaceWithAddress:(NSString*) a port:(int) p serviceName:(NSString*) sn delegate:(id<LXOSCInterfaceDelegate>) d {
	if ( ! _sharedOSCInterface ) {
        _sharedOSCInterface = [[LXOSCInterface alloc] initWithAddress:a port:p serviceName:sn delegate:d];
	}
}

+(void) closeSharedOSCInterface {
	if ( _sharedOSCInterface ) {
        LXOSCInterface* closingInterface = _sharedOSCInterface;
        if ( closingInterface ) {
            _sharedOSCInterface = NULL;
            [closingInterface stopListening];
            [closingInterface release];
        }
	}
}

+(void) resetAddress:(NSString*) ipaddr port:(int) newPort {
    if ( _sharedOSCInterface ) {
        [_sharedOSCInterface resetConnectionWithAddress:ipaddr port:newPort];
    }
}

#pragma mark socket creation and binding methods

-(int) createAndBindSocket {	//used for listen socket
	int fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);	//BSD socket file descriptor AF_INET SOCK_DGRAM
	
	if ( fd > 0 ) {
		struct sockaddr_in serverAddress;
		
		int yes = 1;
		setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, (socklen_t)sizeof(int));
		setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &yes, (socklen_t)sizeof(int));
		
		memset(&serverAddress, 0, sizeof(serverAddress));
		serverAddress.sin_family = AF_INET;

		
		if ( [self.ipAddress isEqualToString:@""] ) {
			serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
		} else {
			serverAddress.sin_addr.s_addr = inet_addr([self.ipAddress UTF8String]);
		}
		
		serverAddress.sin_port = htons(ipPort);

		if(bind(fd, (struct sockaddr *)&serverAddress, (socklen_t)sizeof(serverAddress)) < 0) {
			[self.delegate oscInterfaceError:@"socket bind error" level:LXOSCINTERFACE_MSG_SOCKET_ERROR];
			close(fd);
			return -1;
		}
		
		socklen_t salen = (socklen_t)sizeof(serverAddress);
		if(getsockname(fd, (struct sockaddr *)&serverAddress, &salen) == 0) {	//getsockname name inaccessible??? see man page
			if ( serverAddress.sin_family == AF_INET ) {
				NSString* myAddress = [NSString stringWithCString:inet_ntoa(serverAddress.sin_addr) encoding:NSASCIIStringEncoding];
                [self.delegate oscInterfaceError:[NSString stringWithFormat:@"OSC connected at %s port %i socket %i\n", [myAddress UTF8String], ntohs(serverAddress.sin_port), fd] level:LXOSCINTERFACE_MSG_OK];
			}
		}
		
        if ( self.netServiceName ) {
            NSString* domain = @"";
            if ( [self.ipAddress isEqualToString:@"127.0.0.1"] ) {
                domain = @"local.";
            }
            
            _netService = [[NSNetService alloc] initWithDomain:domain type:@"_osc._udp." name:self.netServiceName port:ipPort];
            [_netService setDelegate:self];
            [_netService removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];    //transfer to main run loop
            [self performSelectorOnMainThread:@selector(publishMyNetService) withObject:nil waitUntilDone:NO];
        }
		
		return fd;	//succeeded in creating
	}
	[self.delegate oscInterfaceError:@"could not create OSC socket" level:LXOSCINTERFACE_MSG_SOCKET_ERROR];
	return -1;
}

-(void) createTCPSocket {
    struct sockaddr_in serverAddress;

    if((_tcpfd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) > 0) {
        memset(&serverAddress, 0, sizeof(serverAddress));
        serverAddress.sin_family = AF_INET;
        serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
        serverAddress.sin_port = htons(ipPort); // allows the kernel to choose the port for us.  0
        
        if(bind(_tcpfd, (struct sockaddr *)&serverAddress, (socklen_t)sizeof(serverAddress)) < 0) {
            close(_tcpfd);
            _tcpfd = -1;
            return;
        }
        
        long flg = 0;
        setsockopt( _tcpfd, SOL_SOCKET, SO_NOSIGPIPE, &flg, (socklen_t)sizeof flg );//prevents SIGPIPE from crashing app
        
        if( listen( _tcpfd, 1) != 0 )  {
            close(_tcpfd);
            _tcpfd = -1;
            return;
        }
    }
}

#pragma mark netservice methods

-(void) publishMyNetService {   //call ONLY on main thread
    [_netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_netService publish];
}

- (void)netServiceWillPublish:(NSNetService *)sender {
    //[sender scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    [self.delegate oscInterfaceError:@"OSC Bonjour did not publish service" level:LXOSCINTERFACE_MSG_SOCKET_ERROR];
    [self.delegate oscInterfaceError:[NSString stringWithFormat:@"OSC Bonjour did not publish service: %@", errorDict] level:LXOSCINTERFACE_MSG_DIAGNOSTIC];
}

- (void)netServiceDidPublish:(NSNetService *)sender {
}

#pragma mark socket fd methods

-(int) createListenSocket {
	if ( _lfd < 0 ) {
		_lfd = [self createAndBindSocket];
	}
    [self createTCPSocket];
	return _lfd;
}

-(void) closeListenSocket {
    if ( _netService ) {
        [_netService removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [_netService stop];
        _netService.delegate = NULL;
        [_netService release];
        _netService = NULL;
    }
    
	if ( _lfd > 0 ) {
		close(_lfd);
		_lfd = -1;
	}
    
    if ( _tcpfd > 0 ) {
        close(_tcpfd);
        _tcpfd = -1;
    }
}

-(int) listenfd {
	return _lfd;
}

-(int) tcpfd {
    return _tcpfd;
}

-(int) connectionSetForRead {
	//[self createListenSocket];	//new 1_3_10
	if ( _lfd > 0 ) {
		fd_set readfds;
        //fd_set writefds,exceptfds;
		struct timeval timeout;
		FD_ZERO(&readfds);	//masks
		FD_SET(_lfd,&readfds);
		
		// Set the timeout - .2 second
		timeout.tv_sec = 0;
		timeout.tv_usec = 200000;
		
		if ( select(_lfd+1,&readfds,nil,nil,&timeout) < 0 ) {
            [self.delegate oscInterfaceError:@"LXOSCInterface select() error" level:LXOSCINTERFACE_MSG_SOCKET_ERROR];
            [NSThread sleepForTimeInterval:1];      //prevent excessive wakes
            return 0;
        }
        
		return FD_ISSET(_lfd, &readfds);
	}
	return 0;
}

-(int) tcpConnectionSetForRead:(int) fd timeout:(int) tout {
    if ( fd > 0 ) {
        fd_set readfds, exceptfds;
        //fd_set writefds,exceptfds;
        struct timeval timeout;
        
        FD_ZERO(&readfds);	// zero and mask
        FD_SET(fd,&readfds);
        FD_ZERO(&exceptfds);
        FD_SET(fd,&exceptfds);
        
        // Set the timeout - .25 second
        timeout.tv_sec = 0;
        timeout.tv_usec = tout;
        
        if ( select(fd+1,&readfds,nil,&exceptfds,&timeout) < 0 ) {
            return -1;
        }
        
        if ( FD_ISSET(fd, &exceptfds) ) {
            [self.delegate oscInterfaceError:@"tcp fd error" level:LXOSCINTERFACE_MSG_SOCKET_ERROR];
        }
        
        return FD_ISSET(fd, &readfds);
    }
    return 0;
}

-(void) resetConnectionWithAddress:(NSString*) ipaddr port:(int) newPort {
    if ( [self isListening] ) {
        @synchronized( self ) {     //blocks if in readMessage see listen.  Needed because socket will be closed.
            _pause_listening = YES;
            [self stopTCPConnections];
        }
        if ( _netService ) {
            [_netService removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [_netService stop];
            [_netService release];
            _netService = NULL;
        }
    }
    
    BOOL openSocket = ( _lfd > 0 );
    if ( openSocket ) {
        [self closeListenSocket];
    }
    
    self.ipAddress = ipaddr;
    ipPort = newPort;
    
    if ( openSocket ) {
        [self createListenSocket];
    }
    
    if ( [self isListening] ) {
        _pause_listening = NO;
    }
}

#pragma mark tcp sub-interface methods

-(void) addTCPConnection {
    @autoreleasepool {  //allows object creation autorelease right away
        LXOSCTCPInterface* ni = [LXOSCTCPInterface oscTCPInterfaceWithParent:self];
        [self.tcpInterfaces addObject:ni];
        [ni acceptAndStartListening];
    }
}

-(void) removeTCPConnection:(LXOSCTCPInterface*) tcpi {
    @autoreleasepool {
        [tcpi stopListening];
        [self.tcpInterfaces removeObject:tcpi];
    }
}

-(void) stopTCPConnections {
    LXOSCTCPInterface* tcpi;
    for ( tcpi in self.tcpInterfaces ) {
        [tcpi stopListening];
    }
    [self.tcpInterfaces removeAllObjects];
}

#pragma mark listen thread methods

-(NSThread*) listeningThread {
	return _listenthread;
}

-(void) setListeningThread:(NSThread*) thread {
	[thread retain];
	[_listenthread release];
	_listenthread = thread;
}

-(BOOL) isListening {
	return _listening;
}

-(void) setListening:(BOOL) l {
	_listening = l;
}

-(void) startListening {
	[self setListening:YES];
	if ( ! _has_listen_thread ) {
        _has_listen_thread = YES;
		[NSThread detachNewThreadSelector:@selector(listen:) toTarget:self withObject:self];
	}
}

-(void) stopListening {
	if ( [self isListening] ) {
		[self setListening:NO];
		if ( [NSThread currentThread] != [self listeningThread] ) {
			//have listen end its loop
		} else {
			[self closeListenSocket];
		}
        [self stopTCPConnections];
	}
}

- (void)listen:(id) anObject {
    id _activity = NULL;
    if ( [[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)] ) {
        NSActivityOptions options = NSActivityLatencyCritical | NSActivityUserInitiated;
        // NSActivityLatencyCritical   NSActivityUserInitiated 0x00FFFFFF  NSActivityUserInitiatedAllowingIdleSystemSleep
        _activity = [[[NSProcessInfo processInfo] beginActivityWithOptions:options
                                                                    reason:@"Listening for OSC"] retain];
    }
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self setListeningThread:[NSThread currentThread]];
    [_listenthread setThreadPriority:0.65];
	[self createListenSocket];

	if ( [self listenfd] > 0 ) {
		while ( [self isListening] ) {
            if ( _pause_listening ) {
                [NSThread sleepForTimeInterval:1];
            } else {
                @synchronized( self ) {
                    [self readAMessage];    // (note has autorelease in process message may want to convert to block)
                }
            }
		}
	}
	
	[self closeListenSocket];
	[self setListeningThread:NULL];
	_has_listen_thread = NO;
	[pool release];
    if ( _activity ) {
        if ( [[NSProcessInfo processInfo] respondsToSelector:@selector(endActivity:) ] ) {
            [[NSProcessInfo processInfo] endActivity:_activity];
        }
        [_activity release];
        _activity = NULL;
    }
}

- (void) readAMessage {
    if ( [self connectionSetForRead] != 0 ) {   // is there a UDP packet to read?
        int len = LXOSC_BUFFER_SIZE;
        int result;
        unsigned int flags = 0;
        
        while ( [self isListening] ) {	//keep reading until buffer is empty
            result =  (int) recvfrom([self listenfd], _messagein, len, flags, (struct sockaddr *)&_clientAddress, &fromlen);
            if ( result > 0 ) {
                _messagelength = result;
                [self packetReceived];
                //[self printMessage];    //comment out for release printf("_
            } else if ( result == 0 ) {
                
            } else {
                [self.delegate oscInterfaceError:@"LXOSCInterface recvfrom error" level:LXOSCINTERFACE_MSG_SOCKET_ERROR];
                [self setListening:NO];
                break;
            }
            if ( [self connectionSetForRead] == 0 ) {   //is there more?  if not, exit loop
                break;
            }
        }
    }

    if ( [self tcpConnectionSetForRead:_tcpfd timeout:100000] > 0 ) {
        [self addTCPConnection];
    }

}


#pragma mark functions

NSInteger nextIndexForString(NSString* s, NSInteger start) {
	NSInteger l = (int) [s length];
	NSInteger ml = l / 4 + 1;
	return start + (ml*4);
}

NSInteger nextIndexForIndex(NSInteger index) {
	NSInteger ml = index / 4 + 1;
	return (ml*4);
}

-(NSInteger) nextZeroLocation:(NSInteger) start {
	NSInteger nn;
	NSInteger zeroloc = LXOSC_BUFFER_SIZE + 10;	//message size must be less than LXOSC_BUFFER_SIZE
	for ( nn=start; nn<_messagelength; nn++) {
		if ( _messagein[nn] == 0 ) {
			zeroloc = nn;
			break;
		}
	}
	return zeroloc;
}

+(int) decodeInt:(const void *) v {
    return decode_bytes2int(v, YES);
}

+(float) decodeFloat:(const void *) v {
    return decode_bytes2float(v, YES);
}

+(double) decodeDouble:(const void *) v {
    return decode_bytes2double(v, YES);
}

#pragma mark packet processing

-(void) packetReceived {
	NSInteger dataindex = 0;
	while ( (dataindex >= 0 ) && ( dataindex < _messagelength ) )   {
        dataindex = [self processMessageAt:(int)dataindex limit:_messagelength];
	}
}

-(NSInteger) processMessageAt:(NSInteger) beginindex limit:(NSInteger) bytelength {
    NSInteger endindex = beginindex + bytelength;
	NSInteger outindex = 0;
	NSInteger dataloc = 0;
	//[self printMessage];	//comment out for release: printf("_
    
    NSInteger start = beginindex;     // _inBundle added 5/6/15
	NSInteger zeroloc = [self nextZeroLocation:start];
	
	if ( zeroloc + 4 < endindex ) {	//insure that cstring will terminate with room for one argument
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		NSString* addressPattern = [NSString stringWithCString:&_messagein[start] encoding:NSASCIIStringEncoding];
		if ( [addressPattern hasPrefix:@"/"] ) {
			
			NSInteger typeloc = nextIndexForString(addressPattern, start);
			dataloc = nextIndexForIndex([self nextZeroLocation:typeloc]);
			
			
			if ( dataloc+4 <= endindex ) {
				if ( _messagein[typeloc] == ',' ) {
					typeloc++;
				}
				BOOL done = NO;
				LXOSCMessage* oscmessage = [LXOSCMessage oscMessageWithAddress:addressPattern];
				
				while (( dataloc + 4 <=  endindex ) && ( ! done )) {
					if ( _messagein[typeloc] == 0 ) {
						done = YES;
					} else if ( _messagein[typeloc] == 'f' ) {
						float data = (float) decode_bytes2float(&_messagein[dataloc], YES);
						[oscmessage addArgument:[LXOSCArgument argumentWithFloat:data]];
						dataloc += 4;
					} else if ( _messagein[typeloc] == 'd' ) {
						double data = decode_bytes2double(&_messagein[dataloc], YES);
						[oscmessage addArgument:[LXOSCArgument argumentWithDouble:data]];
						dataloc += 8;
					} else if ( _messagein[typeloc] == 't' ) {
						double data = decode_bytes2double(&_messagein[dataloc], YES);
						[oscmessage addArgument:[LXOSCArgument argumentWithTimestamp:data]];
						dataloc += 8;
					} else if ( _messagein[typeloc] == 'i' ) {
						int data = (int) decode_bytes2int(&_messagein[dataloc], YES);
						[oscmessage addArgument:[LXOSCArgument argumentWithInt:data]];
						dataloc += 4;
					} else if ( _messagein[typeloc] == 's' ) {
						NSInteger endofstr = [self nextZeroLocation:dataloc];
						if ( endofstr <= endindex ) {
							NSString* data = [NSString stringWithCString:&_messagein[dataloc] encoding:NSASCIIStringEncoding];
							[oscmessage addArgument:[LXOSCArgument argumentWithString:data]];
							dataloc = nextIndexForIndex(endofstr);
						} else {
                     [self.delegate oscInterfaceError:@"OSC string argument error" level:LXOSCINTERFACE_MSG_DIAGNOSTIC];
							done = YES;
							outindex = -1;
						}
					} else if ( _messagein[typeloc] == 'b' ) {
						int dlen = (int) decode_bytes2int(&_messagein[dataloc], YES);
                        dataloc += 4;
						if ( dlen > 0 ) {
                            if ( dlen <= LXOSC_BUFFER_SIZE-dataloc ) {
                            NSData* data = [NSData dataWithBytes:&_messagein[dataloc] length:dlen];
                                [oscmessage addArgument:[LXOSCArgument argumentWithData:data]];
                                dataloc += dlen;
                                int rlen = dlen %4;             //check for padding
                                rlen = (rlen == 0) ? 0 : 4-rlen;
                                dataloc += rlen;
                            } else {
                                [self.delegate oscInterfaceError:@"OSC blob size too large for buffer" level:LXOSCINTERFACE_MSG_DIAGNOSTIC];
                                done = YES;
                                outindex = -1;
                            }
                        }
                    } else if ( _messagein[typeloc] == 'T' ) {
                        [oscmessage addArgument:[LXOSCArgument argumentWithType:LXOSC_ARGTYPE_TRUE]];
                    } else if ( _messagein[typeloc] == 'F' ) {
                        [oscmessage addArgument:[LXOSCArgument argumentWithType:LXOSC_ARGTYPE_FALSE]];
                    } else if ( _messagein[typeloc] == 'I' ) {
                        [oscmessage addArgument:[LXOSCArgument argumentWithType:LXOSC_ARGTYPE_IMPULSE]];
                    } else if ( _messagein[typeloc] == 'N' ) {
                        [oscmessage addArgument:[LXOSCArgument argumentWithType:LXOSC_ARGTYPE_NULL]];
                    } else {
						//unknown data and size
						[pool release];
						return -1;
					}
					
					typeloc ++;
				}
                if ( self.print_diagnostics ) {
                    [self.delegate oscInterfaceError:[NSString stringWithFormat:@"OSC Received-> %@", [oscmessage addressPatternString]] level:LXOSCINTERFACE_MSG_DIAGNOSTIC];
                }
                [self.delegate oscMessageReceived:oscmessage];
                
			} else {                //no arguments, just the message
				outindex = -1;
                if ( dataloc == endindex ) {
                    LXOSCMessage* oscmessage = [LXOSCMessage oscMessageWithAddress:addressPattern];
                    if ( self.print_diagnostics ) {
                        [self.delegate oscInterfaceError:[NSString stringWithFormat:@"OSC Received (No Arguments)-> %@", [oscmessage addressPatternString]] level:LXOSCINTERFACE_MSG_DIAGNOSTIC];
                    }
                    [self.delegate oscMessageReceived:oscmessage];
                } else {
                    [self.delegate oscInterfaceError:@"OSC message format error. (ignored)" level:LXOSCINTERFACE_MSG_INFO];
                }
			}
        } else {                                                // <-address pattern does not begin with /
            if ( [addressPattern isEqualToString:@"#bundle"] ) {
                                                                // recursively process bundle here !
                BOOL bundleDone = NO;
                NSInteger bundleloc = nextIndexForString(addressPattern, start); // should always return start+8
                bundleloc += 8;
                while ( ! bundleDone ) {
                    int bundleMessageSize = ((_messagein[bundleloc]&0xFF)<<24) + ((_messagein[bundleloc+1]&0xFF)<<16) + ((_messagein[bundleloc+2]&0xFF)<<8) + (_messagein[bundleloc+3]&0xFF);
                    bundleloc += 4;
                    bundleloc = [self processMessageAt:bundleloc limit:bundleMessageSize]; //bundleMessageSize reflect index?
                    if ( bundleloc == -1) {
                        bundleDone = YES;
                    } else if ( bundleloc >= endindex ) {
                        bundleDone = YES;
                    }
                }
                dataloc = bundleloc;
            } else {
                if ( self.print_diagnostics ) {
                    [self.delegate oscInterfaceError:[NSString stringWithFormat:@"OSC Warning: address pattern null termination error starting at %i => %@", (int)start, addressPattern] level:LXOSCINTERFACE_MSG_DIAGNOSTIC];
                    [self printMessage];
                } else {
                    [self.delegate oscInterfaceError:@"OSC Warning: address pattern null termination error. (ignored)" level:LXOSCINTERFACE_MSG_INFO];
                }
                outindex = -1;
            }
        }
		
		[pool release];
	} else {
		outindex = -1;
        [self.delegate oscInterfaceError:@"OSC message format error: at least one argument expected. (ignored)" level:LXOSCINTERFACE_MSG_INFO];
	}
	
	if ( outindex != -1 ) {
		outindex = dataloc;
	}
	
	return outindex;
}

#pragma mark utility methods

-(void) printMessage {  //uses printf not NSLog
	int nn;
	NSString* clientAddress = [NSString stringWithCString:inet_ntoa(_clientAddress.sin_addr) encoding:NSASCIIStringEncoding];

	printf(" _____________ received message from %s\n", [clientAddress UTF8String]);
	for ( nn=0; nn<_messagelength; nn++) {
		printf("%i = %i  %c\n", nn, _messagein[nn], _messagein[nn]);
	}
}



@end
