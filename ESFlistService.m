//
//  ESFlistService.m
//  F-Chat Adium Plugin
//
//  Created by Maou 10/2012.
//  GPL Goes here
//


#import <AIUtilities/AIImageAdditions.h>
#import <Adium/DCJoinChatViewController.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AISharedAdium.h>


#import "ESFlistAccountViewController.h"
#import "ESFlistChatJoinViewController.h"

#import "ESFlistAccount.h"
#import "ESFlistService.h"
#import "f-list.h"

void extern *purple_init_flist_plugin();

@implementation ESFlistService

- (void) installPlugin
{
    purple_init_flist_plugin();
    [ESFlistService registerService];
}

- (void) installLibpurplePlugin
{
    
}

- (void) loadLibpurplePlugin
{
    
}

- (void) uninstallPlugin
{
}

//Account Creation
- (Class)accountClass{
    return [ESFlistAccount class];
}

- (AIAccountViewController *)accountViewController{
    return [ESFListAccountViewController accountViewController];
}

- (DCJoinChatViewController *)joinChatView{
    return [ESFlistChatJoinViewController joinChatView];
}

- (NSString *)UIDPlaceholder
{
    return @"f-list";
}

//Service Description
- (NSString *)serviceCodeUniqueID{
    return @"libpurple-flist";
}
- (NSString *)serviceID{
    return @"F-List";
}
- (NSString *)serviceClass{
    return @"F-List";
}
- (NSString *)shortDescription{
    return @"F-List";
}
- (NSString *)longDescription{
    return @"F-List Chat";
}

- (NSCharacterSet *)allowedCharacters {
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet alphanumericCharacterSet];
    [allowed formUnionWithCharacterSet:[NSCharacterSet  punctuationCharacterSet]];
    [allowed formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    return allowed;
}

- (NSUInteger)allowedLength{
    return 9999;
}
- (BOOL)caseSensitive{
    return YES;
}
- (AIServiceImportance)serviceImportance{
    return AIServicePrimary;
}
- (BOOL)canCreateGroupChats
{
    return YES;
}

- (void)registerStatuses{
	[adium.statusController registerStatus:STATUS_NAME_AVAILABLE
                           withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AVAILABLE]
                                    ofType:AIAvailableStatusType
                                forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_AWAY
                           withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY]
                                    ofType:AIAwayStatusType
                                forService:self];
	
    // TODO: The "Looking" state is currently tied to Adium's built-in "Free for chat" state
    //       in order to work around a crash caused by Adium trying to find a localized title
    //       for the "Looking" state. This should be rectified sometime, so that we can use
    //       the STATUS_NAME_LOOKING variable without crashing.
    //
    //       Look into possible localization? Everything else here is localized. Adium seems
    //       to have its own localization thing going on though.
    
	[adium.statusController registerStatus:STATUS_NAME_FREE_FOR_CHAT
                           withDescription:@"Looking"
                                    ofType:AIAvailableStatusType
                                forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_DND
                           withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_DND]
                                    ofType:AIAwayStatusType
                                forService:self];
	
	[adium.statusController registerStatus:STATUS_NAME_BUSY
                           withDescription:[adium.statusController localizedDescriptionForCoreStatusName:STATUS_NAME_EXTENDED_AWAY]
                                    ofType:AIAwayStatusType
                                forService:self];
}


/*!
 * @brief Default icon
 *
 * Service Icon packs should always include images for all the built-in Adium services.  This method allows external
 * service plugins to specify an image which will be used when the service icon pack does not specify one.  It will
 * also be useful if new services are added to Adium itself after a significant number of Service Icon packs exist
 * which do not yet have an image for this service.  If the active Service Icon pack provides an image for this service,
 * this method will not be called.
 *
 * The service should _not_ cache this icon internally; multiple calls should return unique NSImage objects.
 *
 * @param iconType The AIServiceIconType of the icon to return. This specifies the desired size of the icon.
 * @return NSImage to use for this service by default
 */
- (NSImage *)defaultServiceIconOfType:(AIServiceIconType)iconType
{
	if ((iconType == AIServiceIconSmall) || (iconType == AIServiceIconList)) {
		return [NSImage imageNamed:@"flist-small" forClass:[self class] loadLazily:YES];
	} else {
		return [NSImage imageNamed:@"flist" forClass:[self class] loadLazily:YES];
	}
}

/*!
 * @brief Path for default icon
 *
 * For use in message views, this is the path to a default icon as described above.
 *
 * @param iconType The AIServiceIconType of the icon to return.
 * @return The path to the image, otherwise nil.
 */
- (NSString *)pathForDefaultServiceIconOfType:(AIServiceIconType)iconType
{
	if ((iconType == AIServiceIconSmall) || (iconType == AIServiceIconList)) {
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"flist-small"];
	} else {
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"flist"];
	}
}

@end
