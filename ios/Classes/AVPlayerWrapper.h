//
//  RDPlayerWithAVPlayer.h
//  radio2
//
//  Created by Антон on 29.08.13.
//  Copyright (c) 2013 abuharsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef enum : NSUInteger {
    RDPlayerStateLoading,
    RDPlayerStatePlaying,
    RDPlayerStatePaused,
    RDPlayerStateEnded,
    RDPlayerStateError
} RDPlayerState;

@protocol AVPlayerWrapperDelegate;
@interface AVPlayerWrapper : NSObject

@property(nonatomic, weak) id<AVPlayerWrapperDelegate> delegate;

- (void)play:(NSString*)link;
- (void)pause;
- (void)setVolume:(float)volume;

@end

@protocol AVPlayerWrapperDelegate <NSObject>

- (void)playerWrapper:(AVPlayerWrapper*)wrapper didChangeState:(RDPlayerState)newState;

@end
