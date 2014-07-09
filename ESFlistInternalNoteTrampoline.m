//
//  ESFlistInternalNoteTrampoline.m
//  F-Chat
//
//

#import "ESFlistInternalNoteTrampoline.h"
#import "ESFlistAccount.h"
#import <Adium/ESTextAndButtonsWindowController.h>
#import <Adium/AISharedAdium.h>
#import <Adium/AIDockControllerProtocol.h>
#import <Adium/AIContactAlertsControllerProtocol.h>
#import <Adium/AISoundControllerProtocol.h>
#import <Adium/AISoundSet.h>

@implementation ESFlistInternalNoteTrampoline
static NSMutableSet *completed = nil;
+ (void)initialize
{
    [super initialize];
    completed = [[NSMutableSet alloc] init];
}
void SendFlistNote(char *message, char *url, PurpleConnection *pc, int noteID)
{
    AIAccount *account = (PURPLE_CONNECTION_IS_VALID(pc) ?
                          accountLookup(purple_connection_get_account(pc)) :
                          nil);
    [ESFlistInternalNoteTrampoline showNewNoteWithMessage:message withURL:url withAccount:account withID:noteID];
}

+ (void) showNewNoteWithMessage:(char *)inCStringMessage withURL:(char *)inURLCString withAccount:(AIAccount *)account withID:(int)noteID
{
    @synchronized(completed) {
        if ([completed containsObject:[NSNumber numberWithInt:noteID]]) {
            return;
        }else{
            [completed addObject:[NSNumber numberWithInt:noteID]];
        }
    }
    NSAttributedString *inMessage = [[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:inCStringMessage]];
    
    ESTextAndButtonsWindowController *textAndButtonsWindowController =
        [[ESTextAndButtonsWindowController alloc] initWithTitle:@"New Note"
            defaultButton:nil
            alternateButton:(inURLCString ?
            @"Open Note" :
            nil)
            otherButton:nil
            withMessageHeader:nil
            andMessage:inMessage
            target:self
            userInfo:[NSString stringWithUTF8String:inURLCString]];
    [textAndButtonsWindowController showOnWindow:nil];
    [adium.dockController performBehavior:AIDockBehaviorBounceRepeatedly];
    if(![account soundsAreMuted])
    {
        NSBeep();
    }
}

/*!
 * @brief Window was closed, either by a button being clicked or the user closing it
 */
+ (BOOL)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode suppression:(BOOL)suppression userInfo:(id)userInfo
{
	switch (returnCode) {
		case AITextAndButtonsAlternateReturn:
			if (userInfo) [self openURLString:userInfo];
			break;
        default:
            break;
	}
	
	return YES;
}

/*!
 * @brief Open a URL string from the open mail window
 *
 * The urlString could either be a web address or a path to a local HTML file we are supposed to load.
 * The local HTML file will be in the user's temp directory, which Purple obtains with g_get_tmp_dir()...
 * so we will, too.
 */
+ (void)openURLString:(NSString *)urlString
{
	if ([urlString rangeOfString:[NSString stringWithUTF8String:g_get_tmp_dir()]].location != NSNotFound) {
		//Local HTML file
		CFURLRef	appURL = NULL;
		OSStatus	err;
		
		/* Obtain the default http:// handler. We don't care what would handle _this file_ (its extension doesn't matter)
		 * nor what normally happens when the user opens a .html file since that is, on many systems, an HTML editor.
		 * Instead, we want to know what application to use for viewing web pages... and then open this file in it.
		 */
		err = LSGetApplicationForURL((CFURLRef)[NSURL URLWithString:@"http://www.adium.im"],
									 kLSRolesViewer,
									 /*outAppRef*/ NULL,
									 &appURL);
		if (err == noErr) {
			[[NSWorkspace sharedWorkspace] openFile:[urlString stringByExpandingTildeInPath]
									withApplication:[(NSURL *)appURL path]];
		} else {
			NSURL		*url;
			
			//Web address
			url = [NSURL URLWithString:urlString];
			[[NSWorkspace sharedWorkspace] openURL:url];
		}
		
		if (appURL) {
			//LSGetApplicationForURL() requires us to release the appURL when we are done with it
			CFRelease(appURL);
		}
		
	} else {
		NSURL		*emailURL;
		
		//Web address
		emailURL = [NSURL URLWithString:urlString];
		[[NSWorkspace sharedWorkspace] openURL:emailURL];
	}
}
@end
