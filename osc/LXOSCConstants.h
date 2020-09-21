//
//  LXOSCConstants.h
//  LXConsole
//
//  Created by Claude Heintz on 1/8/16.
//  Copyright 2016-2020 Claude Heintz Design. All rights reserved.
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

#define LXOSC_PORT @"osc_port"
#define LXOSC_IN_PREFFERED_IP @"osc_ip_address"
#define LXOSC_PREF_CHANGED @"osc_pref_changed"
#define LXOSC_IGNORE_ZCOMMAND @"osc_ignore_zcommand"
#define LXOSC_OUT_CONNECTION @"osc_out_connection_string"
#define LXOSC_OUT_SEND_DIMMERS @"osc_out_sends_dimmers"
#define LXOSC_RESPOND_TO_QLAB_MESSAGES @"respond_to_qlab"

// notifications

#define LXOSC_OSC_IN_STATUS_CHANGED @"oscChanged"
#define LXOSC_RECEIVED_MESSAGE @"LXOSC_Received"


// SLIP RFC1055

#define SLIP_END             0300    /* indicates end of packet */
#define SLIP_ESC             0333    /* indicates byte stuffing */
#define SLIP_ESC_END         0334    /* ESC ESC_END means END data byte */
#define SLIP_ESC_ESC         0335    /* ESC ESC_ESC means ESC data byte */
