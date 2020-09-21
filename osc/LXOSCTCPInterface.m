//
//  LXOSCTCPInterface.m
//  LXConsole
//
//  Created by Claude Heintz on 4/8/16.
//  Copyright 2016-2020 Claude Heintz Design. All rights reserved.
//
/*
 License is available at https://www.claudeheintzdesign.com/lx/opensource.html
 */

#import "LXOSCTCPInterface.h"
#import "LXOSCConstants.h"

@implementation LXOSCTCPInterface

@synthesize parent;


-(id) initWithParent:(LXOSCInterface*) p {
    self = [super init];
    
    if ( self ) {
        self.parent = p;
        self.delegate = p.delegate; //gets notified when message received and errors...
        
        _lfd = -1;
        _tcpfd = -1;
        _readpending = NO;
        _readdirty = NO;
        _writing_to_buffer = NO;
        
        fromlen = (socklen_t) sizeof _clientAddress;
        _netService = NULL;
        
        self.print_diagnostics = NO;
        _has_listen_thread = NO;
        
        _pause_listening = NO;
    }
    
    return self;
}

+(LXOSCTCPInterface*) oscTCPInterfaceWithParent:(LXOSCInterface*) p {
    LXOSCTCPInterface* ni = [[LXOSCTCPInterface alloc] initWithParent:p];
    return [ni autorelease];
}


-(void) acceptAndStartListening {
    _tcpfd = accept([self.parent tcpfd], (struct sockaddr *)&_clientAddress, &fromlen);
    //long flg = 0;
    //int result = setsockopt( _tcpfd, SOL_SOCKET, SO_NOSIGPIPE, &flg, (socklen_t)sizeof flg );//prevents SIGPIPE from crashing app?
    
    [self setListening:YES];
    if ( ! _has_listen_thread ) {
        _has_listen_thread = YES;
        [NSThread detachNewThreadSelector:@selector(listen2tcp:) toTarget:self withObject:NULL];
    }
}

-(void) listen2tcp:(id) anObject {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self setListeningThread:[NSThread currentThread]];
    [_listenthread setThreadPriority:0.65];
    
    if ( _tcpfd > 0 ) {
        while ( [self isListening] ) {
            @synchronized( self ) {
                [self readAMessage];    // (note has autorelease in process message may want to convert to block)
            }
        }
    }
    
    [self closeListenSocket];
    [self setListeningThread:NULL];
    _has_listen_thread = NO;
    [pool release];
}

-(void) readAMessage {
    
    if ( [self tcpConnectionSetForRead:_tcpfd timeout:100000] > 0 ) {
        int len = LXOSC_BUFFER_SIZE;
        int result;
        unsigned int flags = 0;
        unsigned char rc;
        BOOL started = NO;
        BOOL escaped = NO;
        
        
        while ( [self isListening] ) {	//keep reading until buffer is empty
            result =  (int) recvfrom(_tcpfd, &rc, 1, flags, nil, 0);
            if ( result > 0 ) {
                if ( escaped ) {
                    if ( rc == SLIP_ESC_ESC ) {
                        rc = SLIP_ESC;
                    } else if ( rc == SLIP_ESC_END) {
                        rc = SLIP_END;
                    }
                    //note any other character is invalid.  add it anyway?
                    if ( len < LXOSC_BUFFER_SIZE ) {    //escaped only true if started true first, ok to add
                        _messagein[len] = rc;
                        len ++;
                    }
                    escaped = NO;
                } else {                    // not escaped
                    if ( rc == SLIP_END ) {
                        if ( started ) {
                            if ( len > 0 ) {
                                _messagelength = len;
                                [self packetReceived];
                                //[self printMessage];    //comment out for release printf("_
                                started = NO;
                            }
                        } else {
                            started = YES;
                            len = 0;
                        }
                    } else if (started ) {                  //not started, discard
                        if ( rc == SLIP_ESC ) {
                            escaped = YES;
                        } else {
                            if ( len < LXOSC_BUFFER_SIZE ) {
                                _messagein[len] = rc;
                                len ++;
                            }
                        }
                    } else {
                        //printf("_discard %i  %c\n", rc, rc);
                    }
                }
            } else if ( result == 0 ) {
                [self.parent removeTCPConnection:self];//leave it for now that if we get here, the connection is broken
            } else {
                [self.delegate oscInterfaceError:@"LXOSCInterface recvfrom error" level:LXOSCINTERFACE_MSG_SOCKET_ERROR];
                [self setListening:NO];
            }
            
            if ( [self tcpConnectionSetForRead:_tcpfd timeout:200000] <= 0 ) {   // Is there more?
                break;                                           // If not, after .25 sec exit loop closing connection
            }
        }
        //[self.parent removeTCPConnection:self];
    }
}




@end
