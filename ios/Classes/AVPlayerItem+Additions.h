//
//  AVPlayerItem+Additions.h
//  TestApp2
//
//  Created by Антон on 29.08.13.
//  Copyright (c) 2013 Anthony Ilinykh. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface AVPlayerItem (Additions)

@property (nonatomic, readonly) NSTimeInterval  loadedTimeStart;
@property (nonatomic, readonly) NSTimeInterval  loadedTimeDuration;
@property (nonatomic, readonly) NSTimeInterval  durationInSeconds;
@property (nonatomic, readonly) NSDictionary    *timedMetadataDictionary;

@end
