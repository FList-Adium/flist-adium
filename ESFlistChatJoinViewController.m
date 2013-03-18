//
//  ESFlistChatJoinViewController.M
//  F-Chat Adium Plugin
//
//  Created by Maou 10/2012.
//  GPL Goes here
//

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
