//
//  CTNetUtilities.h
//  LXNet2USBDMX
//
//  Created by Claude Heintz on 12/31/09.
//  Copyright 2009-2020 Claude Heintz Design. All rights reserved.
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

#include "Foundation/Foundation.h"
#include "CoreGraphics/CoreGraphics.h"
#include <netinet/in.h>


int ints2saddr(int d, int c, int b, int a);

void packInt16Big(unsigned char* c, int i);
void packInt16Little(unsigned char* c, int i);

uint16_t unpackInt16Big(unsigned char* c);
uint16_t unpackInt16Little(unsigned char* c);

void packInt32Big(unsigned char* c, int i);
void packInt32Little(unsigned char* c, int i);

uint32_t unpackInt32Big(unsigned char* c);
uint32_t unpackInt32Little(unsigned char* c);

uint64_t unpackInt64Little(unsigned char* c);

CGFloat decode_bytes2double(const void *data , BOOL natural_order);
void encodeFloat(float fin, void* data, BOOL natural_order);
float decode_bytes2float(const void *data, BOOL natural_order);
int decode_bytes2int (const void *v, BOOL natural_order);

void *get_in_addr(struct sockaddr *sa);

BOOL equalSocketAddr(struct sockaddr_in a, struct sockaddr_in b);

void extractIPV4FromSockStruct(struct sockaddr_in sadr, uint8_t* result);

NSArray* getNetIPAddresses(void);
NSString* getBroadcastAddressForAddress(NSString* addr);

NSTimeInterval NTP2TimeInterval(long ntptime);
