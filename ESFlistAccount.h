//
//  ESFlistAccount.h
//  F-Chat Adium Plugin
//
//  Created by Maou 10/2012.
//  GPL Goes here
//

#import <AdiumLibpurple/CBPurpleAccount.h>

#define KEY_FLIST_CHARACTER         @"Flist:Character Name"
#define KEY_FLIST_LOGIN             @"Flist:User Name"
#define KEY_FLIST_USE_WEBSOCKET		@"Flist:Use Websockets"
#define KEY_FLIST_SYNC_FRIENDS		@"Flist:Sync Friends"
#define KEY_FLIST_SYNC_BOOKMARKS	@"Flist:Sync Bookmarks"
#define KEY_FLIST_DEBUG             @"Flist:Debug Connection"

@interface ESFlistAccount : CBPurpleAccount {

}

@end
