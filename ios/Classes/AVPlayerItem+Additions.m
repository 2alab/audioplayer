//
//  AVPlayerItem+Additions.m
//  TestApp2
//
//  Created by Антон on 29.08.13.
//  Copyright (c) 2013 Anthony Ilinykh. All rights reserved.
//

#import "AVPlayerItem+Additions.h"

@implementation AVPlayerItem (Additions)

- (NSTimeInterval)loadedTimeStart
{
    NSArray *times = self.loadedTimeRanges;
    NSValue *value = (times.count > 0) ? times[0] : nil;
    
    if(value == nil)
        return 0;
    
    CMTimeRange range;
    [value getValue:&range];
    
    return CMTimeGetSeconds(range.start);
}

- (NSTimeInterval)loadedTimeDuration
{
    NSArray *times = self.loadedTimeRanges;
    NSValue *value = (times.count > 0) ? times[0] : nil;
    
    if(value == nil)
        return 0;
    
    CMTimeRange range;
    [value getValue:&range];
    
    return CMTimeGetSeconds(range.duration);
}

- (NSTimeInterval)durationInSeconds
{
    return CMTimeGetSeconds(self.duration);
}

- (NSDictionary *)timedMetadataDictionary
{    
    NSString *artist    = nil;
    NSString *songName  = nil;
    NSString *title     = nil;
    
    for (AVMetadataItem *metadataItem in self.timedMetadata)
    {
        // we must reencode string from ISOLatin1 to UTF8
        NSString *stringValue = metadataItem.stringValue;
        
        stringValue = [[NSString alloc] initWithData:[stringValue dataUsingEncoding:NSISOLatin1StringEncoding]
                                            encoding:NSUTF8StringEncoding];
        
        if([stringValue componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"ÐÐ°ÑÐ¾Ð½ÐÐµÐÐ¿ÑÐ°Ð²Ð°Ð½Ð°Ð¾ÑÐ¸Ð±ÐºÑ"]].count > 5)
        {
            stringValue = [[NSString alloc] initWithData:[stringValue dataUsingEncoding:NSISOLatin1StringEncoding]
                                                encoding:NSUTF8StringEncoding];
        }
        
        // get metadata values
        if([metadataItem.keySpace isEqualToString:AVMetadataKeySpaceCommon])
        {
            if([metadataItem.key isEqual:AVMetadataCommonKeyTitle])
                title = stringValue;
            else if([metadataItem.key isEqual:AVMetadataCommonKeyArtist])
                artist = stringValue;
            else if([metadataItem.key isEqual:AVMetadataCommonKeyAuthor])
                artist = stringValue;
        }
    }
    
    // when title longer than ' - ', try to split it
    if(title.length > 4)
    {
        if(artist == nil && songName == nil)
        {
            NSArray *titleComponents = [title componentsSeparatedByString:@" - "];
            if(titleComponents.count == 1)
                titleComponents = [title componentsSeparatedByString:@":"];
            if(titleComponents.count == 1)
                titleComponents = [title componentsSeparatedByString:@"-"];
            if(titleComponents.count > 1)
            {
                artist   = titleComponents[0];
                songName = titleComponents[1];
            }
        }
        else if(songName == nil)
        {
            songName = title;
        }
    }
    
    if (artist == nil && songName == nil)
        return nil;

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:2];
    
    if (artist)
        [dict setObject:artist forKey:@"artist"];
    
    if (songName)
        [dict setObject:songName forKey:@"title"];
    
    return dict;
}

@end
