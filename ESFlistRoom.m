//
//  ESFlistRoom.m
//  F-Chat
//
//  Created by Daniel Guzman on 3/20/13.
//  Copyright (c) 2013 Colin Muller. All rights reserved.
//

#import "ESFlistRoom.h"


@implementation ESFlistRoom
@synthesize channelName, channelTitle, users, status;



-(id) init
{
    self = [super init];
    if(self)
    {
        [self setChannelName:@""];
        [self setChannelTitle:@""];
        [self setStatus:@"Public"];
        users = 0;
    }
    return self;
}

-(id)populateWithRoomListRoom: (PurpleRoomlistRoom *) room
{
    if(self)
    {
        [self setChannelName:[NSString stringWithUTF8String:room->fields->data]];
        [self setChannelTitle:[NSString stringWithUTF8String:room->name]];
        [self setStatus:[NSString stringWithUTF8String:room->fields->next->data]];
        users = GPOINTER_TO_INT(room->fields->next->next->data);
    }
    return self;
}
@end
