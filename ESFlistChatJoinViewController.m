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

@interface ESFlistChatJoinViewController ()
- (void)validateEnteredText;
@end

@interface NSObject (JointChatViewDelegate)
- (void)setJoinChatEnabled:(BOOL)enabled;
@end

@implementation ESFlistChatJoinViewController
- (NSString *)nibName
{
	return @"ESFlistChatJoinView";
}

- (void)configureForAccount:(AIAccount *)inAccount
{
	[super configureForAccount:inAccount];
	
	[[view window] makeFirstResponder:textField_channel];
	[self validateEnteredText];
}

- (void)joinChatWithAccount:(AIAccount *)inAccount
{
	NSString			*channel;
	NSMutableDictionary	*chatCreationInfo;
	
	//Obtain room and exchange from the view
	channel = [textField_channel stringValue];
	
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
	
}

//Entered text is changing
- (void)controlTextDidChange:(NSNotification *)notification
{
	if ([notification object] == textField_channel) {
		[self validateEnteredText];
	}
}

- (void)validateEnteredText
{
	if (delegate && [delegate respondsToSelector:@selector(setJoinChatEnabled:)]) {
		NSString	*channel = [textField_channel stringValue];
        
		[delegate setJoinChatEnabled:(channel && [channel length])];
	}
}

@end
