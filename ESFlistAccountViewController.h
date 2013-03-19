/*
 * ESFlistAccountViewController.h
 * ================
 * Account View controller interface definition.
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
