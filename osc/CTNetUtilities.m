//
//  CTNetUtilities.m
//  LXNet2USBDMX
//
//  Created by Claude Heintz on 12/31/09.
//  Copyright 2009-2020 Claude Heintz Design. All rights reserved.
//
/*
 License is available at https://www.claudeheintzdesign.com/lx/opensource.html
 */

#import "CTNetUtilities.h"
#include "ifaddrs.h"
#include <arpa/inet.h>
#include <netinet/in.h>

//note network byte order reversed so 1st number of written is lsb
int ints2saddr(int d, int c, int b, int a) {
	return (a << 24) + (b << 16) + (c << 8) + d;
}

void packInt16Big(unsigned char* c, int i) {
	c[0] = ((i & 0xff00) >> 8);
	c[1] = i & 0xff;
}

void packInt16Little(unsigned char* c, int i) {
	c[1] = ((i & 0xff00) >> 8);
	c[0] = i & 0xff;
}

uint16_t unpackInt16Big(unsigned char* c) {
    uint16_t rv = c[1];
    rv += (c[0] << 8);
    return rv;
}

uint16_t unpackInt16Little(unsigned char* c) {
    uint16_t rv = c[0];
    rv += (c[1] << 8);
    return rv;
}

void packInt32Big(unsigned char* c, int i) {
	c[0] = ((i & 0xff000000) >> 24);
	c[1] = ((i & 0xff0000) >> 16);
	c[2] = ((i & 0xff00) >> 8);
	c[3] = i & 0xff;
}

void packInt32Little(unsigned char* c, int i) {
	c[3] = ((i & 0xff000000) >> 24);
	c[2] = ((i & 0xff0000) >> 16);
	c[1] = ((i & 0xff00) >> 8);
	c[0] = i & 0xff;
}

uint32_t unpackInt32Big(unsigned char* c) {
    uint32_t rv = c[3];
    rv += (c[2] << 8);
    rv += (c[1] << 16);
    rv += (c[0] << 24);
    return rv;
}

uint32_t unpackInt32Little(unsigned char* c) {
    uint32_t rv = c[0];
    rv += (c[1] << 8);
    rv += (c[2] << 16);
    rv += (c[3] << 24);
    return rv;
}

uint64_t unpackInt64Little(unsigned char* c) {
    uint64_t rv = c[0];
    rv += (c[1] << 8);
    rv += (c[2] << 16);
    rv += (c[3] << 24);
    rv += ((long)c[4] << 32);
    rv += ((long)c[5] << 40);
    rv += ((long)c[6] << 48);
    rv += ((long)c[6] << 56);
    return rv;
}

CGFloat decode_bytes2double(const void *data , BOOL natural_order) {
    const unsigned char *v = data;
    union {
        double d;
        char bytes[sizeof(double)];
    } u;
    if ( natural_order ) {
        u.bytes[7] = v[0];
        u.bytes[6] = v[1];
        u.bytes[5] = v[2];
        u.bytes[4] = v[3];
        u.bytes[3] = v[4];
        u.bytes[2] = v[5];
        u.bytes[1] = v[6];
        u.bytes[0] = v[7];
    } else {
        u.bytes[0] = v[0];
        u.bytes[1] = v[1];
        u.bytes[2] = v[2];
        u.bytes[3] = v[3];
        u.bytes[4] = v[4];
        u.bytes[5] = v[5];
        u.bytes[6] = v[6];
        u.bytes[7] = v[7];
    }
    return u.d;
}

float decode_bytes2float(const void *data, BOOL natural_order) {
    const uint8_t* v = data;
    union {
        float f;
        char bytes[sizeof(float)];
    } u;
    
    if ( natural_order ) {
        u.bytes[3] = v[0];
        u.bytes[2] = v[1];
        u.bytes[1] = v[2];
        u.bytes[0] = v[3];
    } else {
        u.bytes[0] = v[0];
        u.bytes[1] = v[1];
        u.bytes[2] = v[2];
        u.bytes[3] = v[3];
    }
    return u.f;
}

void encodeFloat(float fin, void* data, BOOL natural_order) {
    uint8_t* v = data;
    union {
        float f;
        char bytes[sizeof(float)];
    } u;
    u.f = fin;
    
    if ( natural_order ) {
        v[0] = u.bytes[3];
        v[1] = u.bytes[2];
        v[2] = u.bytes[1];
        v[3] = u.bytes[0];
    } else {
        v[0] = u.bytes[0];
        v[1] = u.bytes[1];
        v[2] = u.bytes[2];
        v[3] = u.bytes[3];
    }
}

int decode_bytes2int (const void *v, BOOL natural_order) {
    if (natural_order) {
        return unpackInt32Big((unsigned char *)v);
    }
    return unpackInt32Little((unsigned char *)v);
}

void *get_in_addr(struct sockaddr *sa) {
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }
    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

BOOL equalSocketAddr(struct sockaddr_in a, struct sockaddr_in b) {
    if ( a.sin_family == b.sin_family) {
        if ( a.sin_port == b.sin_port) {
            if ( a.sin_addr.s_addr == b.sin_addr.s_addr) {
                return YES;
            }
        }
    }
    return NO;
}

// does not check sin_family!!
void extractIPV4FromSockStruct(struct sockaddr_in sadr, uint8_t* result) {
    uint32_t rawip =sadr.sin_addr.s_addr;
    result[0] = ((uint8_t*)(&rawip))[0];
    result[1] = ((uint8_t*)(&rawip))[1];
    result[2] = ((uint8_t*)(&rawip))[2];
    result[3] = ((uint8_t*)(&rawip))[3];
}

NSArray* getNetIPAddresses() {
    NSMutableArray* addrarr=[[NSMutableArray alloc] init];
    struct ifaddrs *ifap, *ifa;
    int fam;
    const char* addr;
    if ( getifaddrs(&ifap) == 0 ) {
        ifa = ifap;
        while ( ifa != NULL ) {
            fam = ((struct sockaddr_in *) ifa->ifa_addr)->sin_family;
            if ( fam == AF_INET ) {
                addr = inet_ntoa(((struct sockaddr_in *) ifa->ifa_addr)->sin_addr);
                [addrarr addObject:[NSString stringWithCString:addr encoding:NSUTF8StringEncoding]];
            }
            ifa = ifa->ifa_next;
        }
    }
    return addrarr;
}

/*
 find a broadcast address for an IP address in the list of available interfaces
 use getifaddrs to retireive a linked list of ifaddrs structures
 find the one with the ip address matching the NSString addr
 and return the struct's broadcast address
*/

NSString* getBroadcastAddressForAddress(NSString* addr) {
    struct ifaddrs *ifap, *ifa;
    int fam;
    const char* ifaddr;
    if ( getifaddrs(&ifap) == 0 ) {
        ifa = ifap;
        while ( ifa != NULL ) {
            fam = ((struct sockaddr_in *) ifa->ifa_addr)->sin_family;
            if ( fam == AF_INET ) {
                ifaddr = inet_ntoa(((struct sockaddr_in *) ifa->ifa_addr)->sin_addr);
                if ( [addr isEqualToString:[NSString stringWithCString:ifaddr encoding:NSUTF8StringEncoding]] ) {
                    ifaddr = inet_ntoa(((struct sockaddr_in *) ifa->ifa_broadaddr)->sin_addr);
                    return [NSString stringWithCString:ifaddr encoding:NSUTF8StringEncoding];
                }
            }
            ifa = ifa->ifa_next;
        }
    }
    return NULL;
}



