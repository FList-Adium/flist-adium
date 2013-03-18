//
//  ESFlistAccountViewController.h
//  F-Chat Adium Plugin
//
//  Created by Maou 10/2012.
//  GPL Goes here
//


#import <Adium/AIAccountViewController.h>
#import "ESFlistAccount.h"

@interface ESFListAccountViewController : AIAccountViewController {
    IBOutlet	NSTextField		*textField_character;
    IBOutlet	NSTextField		*textField_flistlogin;
	IBOutlet	NSButton		*checkBox_useWebsocket;
	IBOutlet	NSButton		*checkBox_syncfriends;
	IBOutlet	NSButton		*checkBox_syncbookmarks;
	IBOutlet	NSButton		*checkBox_debug;
    
	NSArray *servers;
}

@end
