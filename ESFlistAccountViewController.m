//
//  ESFlistAccountViewController.m
//  F-Chat Adium Plugin
//
//  Created by Maou 10/2012.
//  GPL Goes here
//

#import "ESFlistAccountViewController.h"
#import "ESFlistAccount.h"

@implementation ESFListAccountViewController

- (NSString *)nibName{
    return @"ESFlistAccountView";
}


//Configure our controls
- (void)configureForAccount:(AIAccount *)inAccount
{
    [super configureForAccount:inAccount];
	
	//Options
	NSString *character = [account preferenceForKey:KEY_FLIST_CHARACTER group:GROUP_ACCOUNT_STATUS];
	[textField_character setStringValue:(character ?: @"")];
    [textField_accountUIDLabel setStringValue: (character ?: @"")];
    
    
    NSString *login = [account preferenceForKey:KEY_FLIST_LOGIN group:GROUP_ACCOUNT_STATUS];
	[textField_flistlogin setStringValue:(login ?: @"")];
    
	[checkBox_useWebsocket setState:[[account preferenceForKey:KEY_FLIST_USE_WEBSOCKET group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_syncfriends setState:[[account preferenceForKey:KEY_FLIST_SYNC_FRIENDS group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_syncbookmarks setState:[[account preferenceForKey:KEY_FLIST_SYNC_BOOKMARKS group:GROUP_ACCOUNT_STATUS] boolValue]];
	[checkBox_debug setState:[[account preferenceForKey:KEY_FLIST_DEBUG group:GROUP_ACCOUNT_STATUS] boolValue]];
}

     //Save controls
- (void)saveConfiguration
{
    [super saveConfiguration];
    
	NSString *newUID;
    
    newUID = [NSString stringWithFormat:@"%@:%@",[textField_flistlogin stringValue], [textField_character stringValue] ];

    [account filterAndSetUID:newUID];

    //Connection security
    [account setPreference:([[textField_character stringValue] length] ? [textField_character stringValue] : nil)
					forKey:KEY_FLIST_CHARACTER group:GROUP_ACCOUNT_STATUS];
    [account setPreference:([[textField_flistlogin stringValue] length] ? [textField_flistlogin stringValue] : nil)
					forKey:KEY_FLIST_LOGIN group:GROUP_ACCOUNT_STATUS];
    
    [account setPreference:[NSNumber numberWithBool:[checkBox_useWebsocket state]]
                    forKey:KEY_FLIST_USE_WEBSOCKET group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithBool:[checkBox_syncfriends state]]
                    forKey:KEY_FLIST_SYNC_FRIENDS group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithBool:[checkBox_syncbookmarks state]]
                    forKey:KEY_FLIST_SYNC_BOOKMARKS group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithBool:[checkBox_debug state]]
                    forKey:KEY_FLIST_DEBUG group:GROUP_ACCOUNT_STATUS];
        
}

@end
