/*
 * ESFlistAccount.m
 * ================
 * Account class implementation.
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

#import <AIUtilities/AIImageAdditions.h>
#import <Adium/DCJoinChatViewController.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AISharedAdium.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIStatus.h>
#import <Adium/AIService.h>


#import "f-list.h"
#import "ESFlistAccount.h"
#import "ESFlistService.h"

@interface CBPurpleAccount ()
- (void)_receivedMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(PurpleMessageFlags)flags date:(NSDate *)date;
@end

@implementation ESFlistAccount

#pragma mark - Local Locks

static NSObject *lock;
NSObject *instanceLock;

#pragma mark - Protocol Info

- (const char*)protocolPlugin
{
    return "prpl-flist";
}

- (BOOL)disconnectOnFastUserSwitch
{
    return YES;
}

- (BOOL)groupChatsSupportTopic
{
    return YES;
}

/*!
 * @brief Return the purple status type to be used for a status
 *
 * Most subclasses should override this method; these generic values may be appropriate for others.
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * statusState.statusType for a general idea of the status's type.
 *
 * @param statusState The status for which to find the purple status ID
 * @param arguments Prpl-specific arguments which will be passed with the state. Message is handled automatically.
 *
 * @result The purple status ID
 */
- (const char *)purpleStatusIDForStatus:(AIStatus *)statusState
                              arguments:(NSMutableDictionary *)arguments
{
    // TODO: The "Looking" state is currently tied to Adium's built-in "Free for chat" state
    //       in order to work around a crash caused by Adium trying to find a localized title
    //       for the "Looking" state. This should be rectified sometime, so that we can use
    //       the STATUS_NAME_LOOKING variable without crashing. (See ESFlistService.m)
    
    if ([[statusState statusName] isEqualToString:STATUS_NAME_AVAILABLE])
        return "online";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_ONLINE])
        return "online";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_FREE_FOR_CHAT])
        return "looking";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_AWAY])
        return "away";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_STEPPED_OUT])
        return "away";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_VACATION])
        return "away";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_EXTENDED_AWAY])
        return "away";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_DND])
        return "dnd";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_PHONE])
        return "dnd";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_OFFLINE])
        return "offline";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_OCCUPIED])
        return "dnd";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_AWAY_FRIENDS_ONLY])
        return "away";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_BUSY])
        return "dnd";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_LUNCH])
        return "away";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_NOT_AT_DESK])
        return "away";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_NOT_AT_HOME])
        return "away";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_NOT_AVAILABLE])
        return "away";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_NOT_IN_OFFICE])
        return "away";
    else
        return "online";
}

- (void)autoReconnectAfterDelay:(NSTimeInterval)delay
{
    [super autoReconnectAfterDelay:20];
}

#pragma mark - Formatting/Parsing

- (NSAttributedString *)statusMessageForPurpleBuddy:(PurpleBuddy *)buddy
{
    char *msg = (char *)flist_get_status_text(buddy);
    if (msg != NULL)
    {
        return [[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:msg]] autorelease];
    }
    else
        return nil;
}

- (NSString *)explicitFormattedUID
{

    return [self preferenceForKey:KEY_FLIST_CHARACTER group:GROUP_ACCOUNT_STATUS];
    
}

#pragma mark - Setup

-(void)configurePurpleAccount{
    [super configurePurpleAccount];
    
    PurpleAccount *acct = [self purpleAccount];

    id pref = nil;
    pref = ([self preferenceForKey:KEY_FLIST_SERVER_HOST group:GROUP_ACCOUNT_STATUS] ?: DEFAULT_FLIST_SERVER_HOST);
    const char *flist_server_address = [pref UTF8String];
    purple_account_set_string(acct, "server_address", flist_server_address);
    pref = ([self preferenceForKey:KEY_FLIST_SERVER_PORT group:GROUP_ACCOUNT_STATUS] ?: DEFAULT_FLIST_SERVER_PORT);
    int flist_server_port = (int) [pref integerValue];
    purple_account_set_int(acct, "server_port", flist_server_port);
    
    BOOL flist_sync_friends = [[self preferenceForKey:KEY_FLIST_SYNC_FRIENDS group:GROUP_ACCOUNT_STATUS] boolValue];
    purple_account_set_bool(acct, "sync_friends", flist_sync_friends);
    
    BOOL flist_sync_bookmarks = [[self preferenceForKey:KEY_FLIST_SYNC_BOOKMARKS group:GROUP_ACCOUNT_STATUS] boolValue];
    purple_account_set_bool(acct, "sync_bookmarks", flist_sync_bookmarks);
    // I don't think I'll enable this any time soon.
    BOOL flist_debug = [[self preferenceForKey:KEY_FLIST_DEBUG group:GROUP_ACCOUNT_STATUS] boolValue];
    purple_account_set_bool(acct, "debug_mode", flist_debug);

}

#pragma mark - Icon Methods

- (NSData *)serversideIconDataForContact:(AIListContact *)contact
{
    /*NSString *contactNameKey = [NSString stringWithFormat:@"ContactIcon: %@", [[[contact displayName] lowercaseString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if ([[EGOCache globalCache] hasCacheForKey:contactNameKey]) {
        return [[EGOCache globalCache] dataForKey:contactNameKey];
    }else{*/
    [contact retain];
    [NSThread detachNewThreadSelector:@selector(actuallyGetIconForContact:) toTarget:self withObject:contact];
    return nil;
    //}
}

- (void)actuallyGetIconForContact: (AIListContact *)contact
{
    @synchronized(instanceLock)
    {
        NSString *contactName = [[[contact displayName] lowercaseString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSData *icon = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://static.f-list.net/images/avatar/%@.png", contactName]]];
        [contact setServersideIconData:icon notify:NotifyNow];
        usleep(100000);
    }
}

- (NSData *) getIconForContact: (AIListContact *)contact
{
    NSString *contactName = [[[contact displayName] lowercaseString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://static.f-list.net/images/avatar/%@.png", contactName]]];
}

#pragma mark - Command Echo Override

- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{
	NSString	*messageString = inContentMessage.message.string;
    
	BOOL didCommand = [self.purpleAdapter attemptPurpleCommandOnMessage:messageString
                                                             fromAccount:(AIAccount *)inContentMessage.source
                                                                  inChat:inContentMessage.chat];
    
    // Returns true if this is sending a /ad command
    BOOL isAd = ([messageString rangeOfString:@"/ad " options:(NSCaseInsensitiveSearch | NSAnchoredSearch)].location == 0);
	
    // If it's an ad, we gotta write it manually.
	if (isAd) {
        /*NSString *name = [inContentMessage.chat name];
        PurpleAccount *purpleAccount = [(CBPurpleAccount *) inContentMessage.source purpleAccount];
        PurpleConversation *conv = purple_find_conversation_with_account(PURPLE_CONV_TYPE_CHAT, [name cStringUsingEncoding:NSUTF8StringEncoding], purpleAccount);
        PurpleConnection *pc = purple_account_get_connection(purpleAccount);
        FListAccount *fla = pc->proto_data;
        gchar *full_message = g_strdup_printf("[b](Roleplay Ad)[/b] %s", [[messageString substringWithRange:NSMakeRange([@"/ad " length], messageString.length - [@"/ad " length])] cStringUsingEncoding:NSUTF8StringEncoding]);
        char *formatted = flist_bbcode_to_html(fla, conv, full_message);
        serv_got_chat_in(pc, purple_conv_chat_get_id(PURPLE_CONV_CHAT(conv)), fla->character, PURPLE_MESSAGE_RECV, formatted, time(NULL));
        free(formatted);
        free(full_message);*/
        /*NSString *formattedString = [NSString stringWithCString:formatted encoding:NSUTF8StringEncoding];
        NSAttributedString *messageAttributedString = [AIHTMLDecoder decodeHTML:formattedString];
        g_free(formatted);
        
        // (to be bolded) string that's prepended to an ad.
		NSMutableAttributedString *prep = [[AIHTMLDecoder decodeHTML:@"<b>(Roleplay Ad)</b> "] mutableCopy];
        
        
        // Slap the ad on.
        [prep appendAttributedString:messageAttributedString];
        
        // Manually write to client window
        [self _receivedMessage:prep
                            inChat:inContentMessage.chat
                   fromListContact:inContentMessage.source
                             flags:PURPLE_MESSAGE_SEND
                              date:inContentMessage.date];
        [prep release];*/
	}
	return (didCommand ? nil : [super encodedAttributedStringForSendingContentMessage:inContentMessage]);
}

- (void)_receivedMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(PurpleMessageFlags)flags date:(NSDate *)date
{
    [super _receivedMessage:(NSAttributedString *)attributedMessage inChat:(AIChat *)chat fromListContact:(AIListContact *)sourceContact flags:(PurpleMessageFlags)flags date:(NSDate *)date];
}


// Show progress in the account window
- (NSString *)connectionStringForStep:(NSInteger)step
{
    switch (step) {
        case 0:
            return @"Getting ticket";
            break;
        case 1:
            return @"Opening secure connection";
            break;
        case 2:
            return @"Performing opening handshake";
            break;
        case 3:
            return @"Identifying";
            break;
    }
    return nil;
}

// This enables the roll and dice commands to work properly.
- (BOOL)shouldDisplayOutgoingMUCMessages
{
	return NO;
}
@end