/*
 * ESFlistAccount.h
 * ================
 * Account class interface definition.
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

#import <Foundation/Foundation.h>
#import <AdiumLibpurple/CBPurpleAccount.h>
#import <Adium/AIUserIcons.h>
#import <Adium/AIListContact.h>
#include <Adium/AIChat.h>
#import  "EGOCache.h"

#define KEY_FLIST_CHARACTER         @"Flist:Character Name"
#define KEY_FLIST_LOGIN             @"Flist:User Name"
#define KEY_FLIST_SYNC_FRIENDS		@"Flist:Sync Friends"
#define KEY_FLIST_SYNC_BOOKMARKS	@"Flist:Sync Bookmarks"
#define KEY_FLIST_SERVER_PORT       @"Flist:Server Port"
#define KEY_FLIST_SERVER_HOST       @"Flist:Server Address"
#define KEY_FLIST_DEBUG             @"Flist:Debug Connection"

@interface ESFlistAccount : CBPurpleAccount {
}

+ (NSData *) getIconFromCache: (AIListContact *)contact;
+ (void) setIconDataInCache: (NSData *)icon forContact: (AIListContact *)contact;

@end
