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

@implementation ESFlistAccount

- (const char*)protocolPlugin
{
    return "prpl-flist";
}

- (BOOL)disconnectOnFastUserSwitch
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

- (NSAttributedString *)statusMessageForPurpleBuddy:(PurpleBuddy *)buddy
{
    char *msg = (char *)flist_get_status_text(buddy);
    if (msg != NULL)
    {
        return [[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:msg]];
    }
    else
        return nil;
}

- (NSString *)explicitFormattedUID
{

    return [self preferenceForKey:KEY_FLIST_CHARACTER group:GROUP_ACCOUNT_STATUS];
    
}

-(void)configurePurpleAccount{
    [super configurePurpleAccount];
    
    PurpleAccount *acct = [self purpleAccount];
    
    BOOL flist_use_websocket = [[self preferenceForKey:KEY_FLIST_USE_WEBSOCKET group:GROUP_ACCOUNT_STATUS] boolValue];
    purple_account_set_bool(acct, "use_websocket_handshake", flist_use_websocket);
    
    BOOL flist_sync_friends = [[self preferenceForKey:KEY_FLIST_SYNC_FRIENDS group:GROUP_ACCOUNT_STATUS] boolValue];
    purple_account_set_bool(acct, "sync_friends", flist_sync_friends);
    
    BOOL flist_sync_bookmarks = [[self preferenceForKey:KEY_FLIST_SYNC_BOOKMARKS group:GROUP_ACCOUNT_STATUS] boolValue];
    purple_account_set_bool(acct, "sync_bookmarks", flist_sync_bookmarks);
    // I don't think I'll enable this any time soon.
    BOOL flist_debug = [[self preferenceForKey:KEY_FLIST_DEBUG group:GROUP_ACCOUNT_STATUS] boolValue];
    purple_account_set_bool(acct, "debug_mode", flist_debug);

}

- (BOOL)groupChatsSupportTopic
{
    return YES;
}

@end