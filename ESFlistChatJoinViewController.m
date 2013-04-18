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
- (id) init
{
    self = [super init];
    if(self)
    {
        roomListArray = [[NSMutableArray alloc] init];
    }
    return self;
}
- (NSString *)nibName
{
	return @"ESFlistChatJoinView";
}

- (void)awakeFromNib {
    [roomListProgressIndicator setDisplayedWhenStopped:NO];
    [channelListTable setDoubleAction:@selector(joinChat:)];
}

- (void) setRoomListArray:(NSMutableArray *)a
{
    if(a==roomListArray)
        return;
    [roomListArray release];
    [a retain];
    roomListArray = a;
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	[[view window] makeFirstResponder:channelTextField];
    ESFlistAccount *acc = (ESFlistAccount *) account;
    PurpleAccount *pa = [acc purpleAccount];
    PurpleConnection *pc = purple_account_get_connection(pa);
    roomList = purple_roomlist_get_list(pc);
    purple_roomlist_ref(roomList);
    [NSThread detachNewThreadSelector:@selector(populateRoomList:) toTarget:self withObject:nil];
}

// Populate the dropdown...
- (void)populateRoomList:(id)param
{
    [roomListProgressIndicator startAnimation:self];
    while(roomList->in_progress == 1)
    {
        usleep(1000);
    }
    GList *cur = roomList->rooms;
    NSMutableArray *roomsToAdd = [[NSMutableArray alloc] init];
    while(cur)
    {
        PurpleRoomlistRoom *room = cur->data;
        ESFlistRoom *fListRoom = [[ESFlistRoom alloc] init];
        if(fListRoom)
        {
            [fListRoom populateWithRoomListRoom:room];
            [roomsToAdd addObject:fListRoom];
            [fListRoom release];
        }else{
            NSLog(@"fListRoom was null!");
        }
        cur = g_list_next(cur);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [roomListController addObjects:roomsToAdd];
        [roomListController rearrangeObjects];
    });
    [roomsToAdd release];
    [roomListProgressIndicator stopAnimation:self];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{
	NSString			*channel;
	NSMutableDictionary	*chatCreationInfo;
	
	//Obtain room and exchange from the view
	channel = [channelTextField stringValue];
    [channel retain];
	
	if (channel && [channel length]) {
		//The chatCreationInfo has keys corresponding to the GHashTable keys and values to match them.
		chatCreationInfo = [NSMutableDictionary dictionaryWithObject:channel
															  forKey:@"channel"];
        
		[self doJoinChatWithName:channel
					   onAccount:inAccount
				chatCreationInfo:chatCreationInfo
				invitingContacts:nil
		   withInvitationMessage:nil];
		
	} else {
		NSLog(@"Error: No channel specified.");
	}
    [channel release];
	
}

//Entered text is changing
- (void)controlTextDidChange:(NSNotification *)notification
{
	if ([notification object] == channelTextField) {
		[self validateEnteredText];
	}
}

-(void)tableViewSelectionDidChange: (NSNotification *)notification
{
    if([notification object] == channelListTable)
    {
        ESFlistRoom *room = [[roomListController selectedObjects] objectAtIndex:0];
        NSString *channel = [room valueForKey:@"channelName" ];
        [channelTextField setStringValue:channel];
        [delegate setJoinChatEnabled:(channel && [channel length])];
    }
}


- (void)validateEnteredText
{
	if (delegate && [delegate respondsToSelector:@selector(setJoinChatEnabled:)]) {
		NSString	*channel = [channelTextField stringValue];
        
		[delegate setJoinChatEnabled:(channel && [channel length])];
	}
}

- (void)joinChat:(id)param
{
    // Actually just sends the enter key code.
    CGWindowID windowNumber = 0;
    [delegate performKeyEquivalent: [NSEvent keyEventWithType:NSKeyDown location:NSZeroPoint modifierFlags:(NSControlKeyMask | NSCommandKeyMask) timestamp:[[NSProcessInfo processInfo] systemUptime] windowNumber:windowNumber context:[NSGraphicsContext currentContext] characters:'\n' charactersIgnoringModifiers:'\n' isARepeat:NO keyCode:36]];
}

-(void) dealloc
{
    if(roomList)
        purple_roomlist_unref(roomList);
    [roomListArray release];
    [super dealloc];
}
@end
