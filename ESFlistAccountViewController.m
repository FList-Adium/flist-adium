/*
 * ESFlistAccountViewController.m
 * ================
 * Account View controller implementations.
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
    
    NSString *server = [account preferenceForKey:KEY_FLIST_SERVER_HOST group:GROUP_ACCOUNT_STATUS];
    NSString *port = [account preferenceForKey:KEY_FLIST_SERVER_PORT group:GROUP_ACCOUNT_STATUS];
	[textField_connectPort setStringValue:(port ?: [DEFAULT_FLIST_SERVER_PORT stringValue])];
	[textField_connectHost setStringValue:(server ?: DEFAULT_FLIST_SERVER_HOST)];
    
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
    
    [account setPreference:[NSNumber numberWithBool:[checkBox_syncfriends state]]
                    forKey:KEY_FLIST_SYNC_FRIENDS group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithBool:[checkBox_syncbookmarks state]]
                    forKey:KEY_FLIST_SYNC_BOOKMARKS group:GROUP_ACCOUNT_STATUS];
    [account setPreference:[NSNumber numberWithBool:[checkBox_debug state]]
                    forKey:KEY_FLIST_DEBUG group:GROUP_ACCOUNT_STATUS];
    [account setPreference:([[textField_connectHost stringValue] length] ? [textField_connectHost stringValue] : @"chat.f-list.net")
					forKey:KEY_FLIST_SERVER_HOST group:GROUP_ACCOUNT_STATUS];
    [account setPreference:([[textField_connectPort stringValue] length] ? [textField_connectPort stringValue] : @"9799")
					forKey:KEY_FLIST_SERVER_PORT group:GROUP_ACCOUNT_STATUS];
        
}

@end
