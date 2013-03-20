/*
 * ESFlistChatJoinViewController.h
 * ================
 * Join Group Chat View controller interface definition.
 *
 * F-List Adium - F-List Pidgin ported to Adium
 *
 * Copyright 2013 Maou, F-List Adium developers.
 *
 * This file is part of F-List Adium.
 *
 * F-List Adium is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * F-List Adium is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with F-List Adium.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Adium/DCJoinChatViewController.h>
#import <SLPurpleCocoaAdapter.h>
#import "ESFlistAccount.h"

@interface ESFlistChatJoinViewController : DCJoinChatViewController {
    IBOutlet NSPopUpButton *channelPopupButton;
    PurpleRoomlist *roomList;
    BOOL isRoomListLoaded;
    
}
- (IBAction)selectionChanged:(id)sender;
@end
