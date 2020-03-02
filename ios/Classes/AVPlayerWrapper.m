//
//  RDPlayerWithAVPlayer.m
//  radio2
//
//  Created by Антон on 29.08.13.
//  Copyright (c) 2013 abuharsky. All rights reserved.
//

#import "AVPlayerWrapper.h"
#import "AVPlayerItem+Additions.h"
#import <AVFoundation/AVFoundation.h>

//#define PLAYER_DEBUG

#ifdef PLAYER_DEBUG
#   define PLog(fmt, ...) NSLog(@"[PLAYER] " fmt, ##__VA_ARGS__);
#else
#   define PLog(...)
#endif

@interface AVPlayerWrapper ()
{
    UIBackgroundTaskIdentifier _bgTaskId;
    RDPlayerState _state;
    AVPlayer  *_avPlayer;
    NSString *_link;
}

@end

@implementation AVPlayerWrapper

- (id)init
{
    if (self = [super init])
    {
        _bgTaskId = UIBackgroundTaskInvalid;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidFinishedPlaying:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
        
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
   
    [self _removeObservers];
    [self _endBackgroundTask];
}

#pragma mark - common

- (void)play:(NSString*)link
{
    if ([link isEqualToString:_link]
        && (self.state == RDPlayerStatePlaying || self.state == RDPlayerStateLoading))
    {
        return;
    }
    
    if (_avPlayer != nil) {
        [self _removeObservers];

        // pause player
        [_avPlayer pause];
        _avPlayer = nil;
    }
    
    _link = link;


    // create new player
    _avPlayer = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:link]];
    
    // subscribe
    [self _addObservers];
    self.state = RDPlayerStateLoading;
    
    [_avPlayer play];
}

- (void)pause
{
    // update state
    self.state = RDPlayerStatePaused;
    [self _removeObservers];

    // pause player
    [_avPlayer pause];
    _avPlayer = nil;
}

- (void)setVolume:(float)volume
{
    _avPlayer.volume = volume;
}

- (float)volume
{
    return _avPlayer.volume;
}

- (void)setState:(RDPlayerState)state {
    _state = state;
    
    if (state == RDPlayerStateLoading) {
        [self _beginBackgroundTask];
    }
    else {
        [self _endBackgroundTask];
    }
    
    if ([_delegate respondsToSelector:@selector(playerWrapper:didChangeState:)])
        [_delegate playerWrapper:self didChangeState:state];
}

- (RDPlayerState)state {
    return _state;
}

#pragma mark - Private

- (void)_addObservers
{
    // avplayer
    [_avPlayer addObserver:self
                forKeyPath:@"rate"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];
    
    [_avPlayer addObserver:self
                forKeyPath:@"status"
                   options:NSKeyValueObservingOptionNew
                   context:NULL];
    
    // avplayer item
    [[_avPlayer currentItem] addObserver:self
                              forKeyPath:@"loadedTimeRanges"
                                 options:NSKeyValueObservingOptionNew
                                 context:nil];
    
    [[_avPlayer currentItem] addObserver:self
                              forKeyPath:@"status"
                                 options:NSKeyValueObservingOptionNew
                                 context:nil];
    
    [[_avPlayer currentItem] addObserver:self
                              forKeyPath:@"timedMetadata"
                                 options:NSKeyValueObservingOptionNew
                                 context:NULL];
    
    [[_avPlayer currentItem] addObserver:self
                              forKeyPath:@"playbackBufferEmpty"
                                 options:NSKeyValueObservingOptionNew
                                 context:NULL];
    
    [[_avPlayer currentItem] addObserver:self
                              forKeyPath:@"playbackBufferFull"
                                 options:NSKeyValueObservingOptionNew
                                 context:NULL];
    
    [[_avPlayer currentItem] addObserver:self
                              forKeyPath:@"playbackLikelyToKeepUp"
                                 options:NSKeyValueObservingOptionNew
                                 context:NULL];
    
    [[_avPlayer currentItem] addObserver:self
                              forKeyPath:@"tracks"
                                 options:NSKeyValueObservingOptionNew
                                 context:NULL];
}

- (void)_removeObservers
{
    // avplayer
    [_avPlayer removeObserver:self forKeyPath:@"rate"];
    [_avPlayer removeObserver:self forKeyPath:@"status"];
    
    // avplayer status
    [[_avPlayer currentItem] removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[_avPlayer currentItem] removeObserver:self forKeyPath:@"status"];
    [[_avPlayer currentItem] removeObserver:self forKeyPath:@"timedMetadata"];
    [[_avPlayer currentItem] removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [[_avPlayer currentItem] removeObserver:self forKeyPath:@"playbackBufferFull"];
    [[_avPlayer currentItem] removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [[_avPlayer currentItem] removeObserver:self forKeyPath:@"tracks"];
}

- (void)_beginBackgroundTask
{
    // we don't need to start multiple background tasks
    if(_bgTaskId == UIBackgroundTaskInvalid)
    {
        // start new task
        _bgTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            // end last bg task
            [[UIApplication sharedApplication] endBackgroundTask:self->_bgTaskId];
            PLog(@"background task expired %lu", (unsigned long)self->_bgTaskId);
            self->_bgTaskId = UIBackgroundTaskInvalid;
        }];
        PLog(@"start backgroung task %lu", (unsigned long)_bgTaskId);
    }
}

- (void)_endBackgroundTask
{
    if(_bgTaskId != UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:_bgTaskId];
        PLog(@"stop background task %lu", (unsigned long)_bgTaskId);
        _bgTaskId = UIBackgroundTaskInvalid;
    }
}

#pragma mark - Notifications

- (void)playerItemDidFinishedPlaying:(NSNotification *)notification
{
    AVPlayerItem *item = notification.object;
    
    if (item == _avPlayer.currentItem)
    {
        self.state = RDPlayerStateEnded;
    }
}

#pragma mark - AVPlayer and AVPlayerItem Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    PLog(@"observeValueForKeyPath %@", keyPath);
    // ----------------------
    // MARK: AVPlayer observing
    // ----------------------
    if([object isKindOfClass:[AVPlayer class]])
    {
        AVPlayer *player = (AVPlayer*)object;
        
        //--------
        if ([keyPath isEqualToString:@"rate"])
        {
            PLog(@"rate -> %f", player.rate);
            
            // do not set state to Paused here
            // some times player can set its rate to 0.0f because of no buffered data
            // so we can only set state to Paused in method "pause"
            if (player.rate > 0.0f)
            {
                if(player.currentItem.loadedTimeDuration > 0)
                    self.state = RDPlayerStatePlaying;
                else
                    self.state = RDPlayerStateLoading;
            }
        }
        else if([keyPath isEqualToString:@"status"])
        {
            PLog(@"player status -> %d", (int)player.status);
            
            if(player.status == AVPlayerStatusFailed)
            {
                PLog(@"AVPlayerError %@", _avPlayer.error);
                self.state = RDPlayerStateError;
            }
        }
        //--------
    }
    // ----------------------
    // MARK: AVPlayerItem observing
    // ----------------------
    else if ([object isKindOfClass:[AVPlayerItem class]])
    {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;
        
        //--------
        if([keyPath isEqualToString:@"loadedTimeRanges"])
        {
            PLog(@"loadedTimeRanges -> %f / %f", playerItem.loadedTimeStart, playerItem.loadedTimeDuration);
        }
        else if ([keyPath isEqualToString:@"timedMetadata"])
        {
            PLog(@"timedMetadata -> %@ - %@", playerItem.timedMetadataDictionary[@"artist"], playerItem.timedMetadataDictionary[@"title"]);
            
            if (playerItem.timedMetadataTitle != nil) {
                if ([self.delegate respondsToSelector:@selector(playerWrapper:didLoadTimedMetadataTitle:)])
                    [self.delegate playerWrapper:self didLoadTimedMetadataTitle:playerItem.timedMetadataTitle];
            }
        }
        else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
        {
            PLog(@"playbackLikelyToKeepUp");
            
            if (playerItem.playbackLikelyToKeepUp)
            {
                // some times player may change its rate to 0.0f, so restart playing
                // it automatically change the rate of player and self.state to Playing
                if(self.state == RDPlayerStateLoading)
                    [_avPlayer play];
            }
            else if(self.state == RDPlayerStatePlaying)
            {
                self.state = RDPlayerStateLoading;
            }
        }
        else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
        {
            PLog(@"playbackBufferEmpty");
            
            if(self.state == RDPlayerStatePlaying)
            {
                self.state = RDPlayerStateLoading;
            }
        }
        else if ([keyPath isEqualToString:@"playbackBufferFull"])
        {
            PLog(@"playbackBufferFull");
        }
        else if([keyPath isEqualToString:@"status"])
        {
            PLog(@"player item status -> %d", (int)playerItem.status);
            
            if(playerItem.status == AVPlayerItemStatusFailed)
            {
                PLog(@"AVPlayerItemError %@", playerItem.error);
                
                self.state = RDPlayerStateError;
            }
            else if(playerItem.status == AVPlayerItemStatusReadyToPlay)
            {
                if(self.state == RDPlayerStateLoading)
                    self.state = RDPlayerStatePlaying;
            }
            
        }
    }
}


@end
