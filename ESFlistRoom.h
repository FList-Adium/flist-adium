//
//  ESFlistRoom.h
//  F-Chat
//
//  Created by Daniel Guzman on 3/20/13.
//  Copyright (c) 2013 Colin Muller. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SLPurpleCocoaAdapter.h>
#import "ESFlistAccount.h"

@interface ESFlistRoom : NSObject
{
    NSString *channelName, *channelTitle, *status;
    NSInteger users;
}

@property (readwrite,copy) NSString *channelName;
@property (readwrite,copy) NSString *channelTitle;
@property (readwrite,copy) NSString *status;
@property (readwrite) NSInteger users;

-(id)populateWithRoomListRoom: (PurpleRoomlistRoom *) room;
@end;