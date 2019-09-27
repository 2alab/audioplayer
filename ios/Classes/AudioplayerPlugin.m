#import "AudioplayerPlugin.h"
#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AVPlayerWrapper.h"

static NSString *const CHANNEL_NAME = @"ru.aalab/radioplayer";

@interface AudioplayerPlugin() <AVPlayerWrapperDelegate>
{
    AVPlayerWrapper *_playerWrapper;
}

@property (nonatomic, strong) FlutterMethodChannel *channel;

@end

@implementation AudioplayerPlugin


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:CHANNEL_NAME
                                     binaryMessenger:[registrar messenger]];
    
    AudioplayerPlugin* instance = [[AudioplayerPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    instance.channel = channel;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

    if ([call.method isEqualToString:@"play"]) {
        
        if (_playerWrapper == nil) {
            _playerWrapper = [[AVPlayerWrapper alloc] init];
            _playerWrapper.delegate = self;
        }
        
        [_playerWrapper play:call.arguments[@"url"]];
        
        result(@YES);
    }
    else if ([call.method isEqualToString:@"stop"]) {
        [_playerWrapper pause];
        
        _playerWrapper.delegate = nil;
        _playerWrapper = nil;
        
        result(@YES);
    }
    else if ([call.method isEqualToString:@"mute"]) {
        
        if ([call.arguments boolValue]) {
            [_playerWrapper setVolume:0.0];
        }
        else {
            [_playerWrapper setVolume:1.0];
        }
        
        result(@YES);
    }

}

- (void)playerWrapper:(AVPlayerWrapper *)wrapper didChangeState:(RDPlayerState)newState {
    
    switch (newState) {
        case RDPlayerStateLoading:
            [_channel invokeMethod:@"audio.onBuffering" arguments:nil];
            break;

        case RDPlayerStatePlaying:
            [_channel invokeMethod:@"audio.onPlay" arguments:nil];
            break;

        case RDPlayerStatePaused:
            [_channel invokeMethod:@"audio.onStop" arguments:nil];
            break;

        case RDPlayerStateError:
            [_channel invokeMethod:@"audio.onError" arguments:nil];
            break;

        case RDPlayerStateEnded:
            [_channel invokeMethod:@"audio.onEnded" arguments:nil];
            break;
    }
}

- (void)playerWrapper:(AVPlayerWrapper *)wrapper didLoadTimedMetadataTitle:(NSString *)title {
    [_channel invokeMethod:@"audio.onMetadata" arguments:title];
}


@end
