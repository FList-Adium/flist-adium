//
//  ESFlistAccount.m
//  F-Chat Adium Plugin
//
//  Created by Maou 10/2012.
//  GPL Goes here
//

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
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_BUSY])
        return "busy";
    else if ([[statusState statusName] isEqualToString:STATUS_NAME_DND])
        return "dnd";
    else
        return "offline";
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