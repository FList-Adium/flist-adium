/*
 * ESFlistChatJoinViewController.h
 * ================
 * Join Group Chat View controller implementation.
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

#import "ESFlistChatJoinViewController.h"

@interface NSObject (JointChatViewDelegate)
- (void)setJoinChatEnabled:(BOOL)enabled;
@end

@implementation ESFlistChatJoinViewController
- (NSString *)nibName
{
	return @"ESFlistChatJoinView";
}
- (void)awakeFromNib {
    [channelPopupButton setAutoenablesItems:NO];
    [channelPopupButton setEnabled:NO];
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	[[view window] makeFirstResponder:channelPopupButton];
	[self selectionChanged:self];
    isRoomListLoaded = NO;
    [NSThread detachNewThreadSelector:@selector(populateDropDown:) toTarget:self withObject:nil];
}

// Populate the dropdown...
- (void)populateDropDown:(id)param
{
    ESFlistAccount *acc = (ESFlistAccount *) account;
    PurpleAccount *pa = [acc purpleAccount];
    PurpleConnection *pc = purple_account_get_connection(pa);
    roomList = purple_roomlist_get_list(pc);
    usleep(100000);
    while(roomList->in_progress == 1)
    {
        usleep(1000);
    }
    GList *cur = roomList->rooms;
    [channelPopupButton removeAllItems];
    [channelPopupButton addItemWithTitle:@"Public"];
    [[channelPopupButton lastItem] setEnabled:NO];
    while(cur)
    {
        PurpleRoomlistRoom *room = cur->data;
        if(!strcmp(room->fields->next->data, "Public"))
        {
            [channelPopupButton addItemWithTitle:[NSString stringWithUTF8String:room->name]];
        }
        cur = g_list_next(cur);
    }
    cur = roomList->rooms;
    [channelPopupButton addItemWithTitle:@"Private"];
    [[channelPopupButton lastItem] setEnabled:NO];
    while(cur)
    {
        PurpleRoomlistRoom *room = cur->data;
        if(!strcmp(room->fields->next->data, "Private"))
        {
            [channelPopupButton addItemWithTitle:[NSString stringWithUTF8String:room->name]];
        }
        cur = g_list_next(cur);
    }
    isRoomListLoaded = YES;
    [channelPopupButton setEnabled:YES];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{
	NSString			*channel;
	NSMutableDictionary	*chatCreationInfo;
	
	//Obtain room and exchange from the view
	channel = [channelPopupButton titleOfSelectedItem];
	
	if (channel && [channel length] && isRoomListLoaded) {
        
        // Convert channel name into appropriate private name if necessary.
        // First, get the linked list of rooms.
        GList *cur = roomList->rooms;
        while(cur)
        {
            PurpleRoomlistRoom *room = cur->data;
            const char *channelCString = [channel UTF8String];
            // Check if channel name is equal to the current room title.
            if(!strcmp(room->name, channelCString))
            {
                // Check if it's not Public.
                if(strcmp("Public", room->fields->next->data))
                {
                    // It's private, so it has a special name. Get it and set it.
                    channel = [NSString stringWithUTF8String:room->fields->data];
                }
                // We found our name, so we'll bail.
                break;
            }
            cur = g_list_next(cur);
        }
        
		//The chatCreationInfo has keys corresponding to the GHashTable keys and values to match them.
		chatCreationInfo = [NSMutableDictionary dictionaryWithObject:channel
															  forKey:@"channel"];
        
		[self doJoinChatWithName:channel
					   onAccount:inAccount
				chatCreationInfo:chatCreationInfo
				invitingContacts:nil
		   withInvitationMessage:nil];
		
	} else {
		NSLog(@"Error: No channel specified/roomlist not loaded.");
	}
	
}
- (IBAction)selectionChanged:(id)sender {
	if (delegate && [delegate respondsToSelector:@selector(setJoinChatEnabled:)]) {
		NSString	*channel = [channelPopupButton stringValue];
        
		[delegate setJoinChatEnabled:(channel && [channel length])];
	}
    [channelPopupButton synchronizeTitleAndSelectedItem];
}

@end
