//
//  AudioPlayer.m
//
//  Created by Nick Sinas on 8/6/14.
//  Copyright (c) 2014 Metova. All rights reserved.
//

/* 
 Copyright (c) 2015 Metova
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "NDAudioPlayer.h"
#import "NSMutableArray+Shuffling.h"
#import <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVAudioPlayer.h>

@interface NDAudioPlayer ()
{
    NSInteger currentTrackIndex;
    id timeObserver;
    BOOL shuffled;
}

@property (strong, nonatomic) AVPlayer *audioPlayer;
@property (assign, nonatomic) CGFloat volume;
@property (strong, nonatomic) NSMutableArray *playlist;
@property (strong, nonatomic) NSMutableArray *shuffleTable;
@property (strong, nonatomic) NSMutableArray *toHoldOntoAudioPlayer;

@end

@implementation NDAudioPlayer
@synthesize delegate;

#pragma -mark Audio Player methods


- (id)init
{
    self = [super init];
    if(self)
    {
        _isPlaying = NO;
        _isStopped = YES;
        _isPaused = NO;
        _timeScale = 1;
        _audioSessionCategory = AVAudioSessionCategoryPlayAndRecord;
        _audioSessionCategoryOption = AVAudioSessionCategoryOptionDefaultToSpeaker;
    }
    return self;
}


- (void)setPlaylistToArray:(NSMutableArray *)newPlaylist
{
    self.playlist = newPlaylist;
}

- (void) prepareToPlay:(NSMutableArray *)playlist
               atIndex:(NSInteger)index
             atVolume:(CGFloat)volume
{
    self.playlist = playlist;
    self.volume = volume;
    shuffled = NO;
    
    currentTrackIndex = index;
    
    if(self.audioPlayer)
    {
        [self stopAudio];
    }
    
    [self setupAudioPlayer];
    
    [self setupShuffleTable];
}


- (void) playAudio
{
    [self.audioPlayer play];
    self.isPlaying = YES;
    self.isStopped = NO;
    self.isPaused = NO;
}

- (void) pauseAudio
{
    [self.audioPlayer pause];
    NSLog(@"Pausing audio");
    self.isPlaying = NO;
    self.isStopped = NO;
    self.isPaused = YES;
}

- (void) resumeAudio
{
    [self.audioPlayer play];
    NSLog(@"Resuming audio");
    self.isPlaying = YES;
    self.isStopped = NO;
    self.isPaused = NO;
}

- (void) stopAudio
{
    NSLog(@"Stopping audio");
    [self.audioPlayer pause];
    [self.audioPlayer.currentItem removeObserver:self
                                      forKeyPath:@"status"];
    [self.audioPlayer removeTimeObserver:timeObserver];
    timeObserver = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:nil];
    self.audioPlayer = nil;
    self.isPlaying = NO;
    self.isStopped = YES;
    self.isPaused = NO;
}

- (NSInteger) skipTrack
{
    if(currentTrackIndex >= (self.playlist.count -1))
    {
        currentTrackIndex = 0;
    }
    else
    {
        currentTrackIndex++;
    }
    
    [self stopAudio];
    [self setupAudioPlayer];
    return [self getCurrentTrackIndex];
}

- (NSInteger) previousTrack
{
    if(currentTrackIndex == 0)
    {
        currentTrackIndex = self.playlist.count - 1;
    }
    else
    {
        currentTrackIndex--;
    }
    
    [self stopAudio];
    [self setupAudioPlayer];
    return [self getCurrentTrackIndex];
}

- (void) shuffleTracks:(BOOL)enabled
{    
    if(enabled == NO)
    {
        // If the user stops shuffling, make the current track index equal to the current shuffled index
        currentTrackIndex = [self getCurrentTrackIndex];
    }
    shuffled = enabled;
}

-(CGFloat) getTotalDuration
{
    return CMTimeGetSeconds(self.audioPlayer.currentItem.duration);
}

-(CGFloat) getAudioCurrentTime
{
    return CMTimeGetSeconds(self.audioPlayer.currentItem.currentTime);
}

- (void) setAudioVolume:(CGFloat)newVolume
{
    [self.audioPlayer setVolume:newVolume];
    self.volume = newVolume;
}

- (CGFloat)getAudioVolume
{
    return self.volume;
}

- (void)fastForwardToTime:(CGFloat)time
{
    [self seekToTime:time];
}

- (void)rewindToTime:(CGFloat)time
{
    [self seekToTime:time];
}

- (void)seekToTime:(CGFloat)time
{
    [self.audioPlayer.currentItem seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
}


#pragma -mark Internal Methods

- (void) setupAudioPlayer
{
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:self.audioSessionCategory error:nil];
    [audioSession setCategory:self.audioSessionCategory withOptions:self.audioSessionCategoryOption error:nil];
    
    NSURL *audioURL = [NSURL URLWithString:self.playlist[[self getCurrentTrackIndex]]];
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:audioURL];
    [self.toHoldOntoAudioPlayer addObject:playerItem];
    [self.toHoldOntoAudioPlayer addObject:self.audioPlayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
    self.audioPlayer = [AVPlayer playerWithPlayerItem:playerItem];
    
    [self.audioPlayer.currentItem addObserver:self
                                   forKeyPath:@"status"
                                      options:0
                                      context:nil];
    
    [self setTimeObserverIntervalWithTimeScale:(int)self.timeScale];
    
    self.isPlaying = YES;
}

- (void)setTimeObserverIntervalWithTimeScale:(int)timeScale
{
    [self.audioPlayer removeTimeObserver:timeObserver];
    
    __weak NDAudioPlayer *blockSelf = self;
    timeObserver = [self.audioPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, timeScale) queue:nil usingBlock:^(CMTime time) {
        [blockSelf notifyAudioDurationDelegate];
    }];
}

- (void) setupShuffleTable
{
    self.shuffleTable = [NSMutableArray new];
    for(int count = 0; count < self.playlist.count; count++)
    {
        [self.shuffleTable addObject:[NSNumber numberWithInt:count]];
    }
    [self.shuffleTable shuffle];
}

- (NSInteger) getCurrentTrackIndex
{
    if(shuffled)
    {
        NSInteger trackIndex = [[self.shuffleTable objectAtIndex:currentTrackIndex] integerValue];
        return trackIndex;
    }
    
    return currentTrackIndex;
}

#pragma -mark Notifications

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    NSLog(@"status: %ldd",(long) (long)self.audioPlayer.currentItem.status);
    if (object == self.audioPlayer.currentItem && [keyPath isEqualToString:@"status"])
    {
        if (self.audioPlayer.currentItem.status == AVPlayerStatusReadyToPlay)
        {
            NSLog(@"Playing audio");
            [self setAudioVolume:self.volume];
            [self notifyAudioReadyDelegate];
        }
        else if (self.audioPlayer.status == AVPlayerStatusFailed)
        {
            NSLog(@"Error playing");
        }
        else
        {
            NSLog(@"Status unknown for audio player");
        }
    }
}


-(void)itemDidFinishPlaying:(NSNotification *) notification
{
    self.isPlaying = NO;
    NSLog(@"Song finished");
    currentTrackIndex++;
    if(currentTrackIndex >= self.playlist.count)
    {
        // No more tracks to play
        [self notifyAudioPlaylistDoneDelegate];
    }
    else
    {
        // Pass along the next track that is playing
        [self stopAudio];
        [self setupAudioPlayer];
        [self notifyAudioTrackDoneDelegate];
    }
    
}


- (void)fadeOutWithIntervals:(CGFloat)interval
{
    self.volume -= interval;
}


#pragma -mark Delegate method

// Notifies delegate that audio is ready to play
- (void) notifyAudioReadyDelegate
{
    if([self.delegate respondsToSelector:@selector(NDAudioPlayerIsReady:)])
    {
        [self.delegate NDAudioPlayerIsReady:self];
    }
}

// Playlist Complete - would indicate no other tracks can be played
- (void) notifyAudioPlaylistDoneDelegate
{
    if([self.delegate respondsToSelector:@selector(NDAudioPlayerPlaylistIsDone:)])
    {
        [self.delegate NDAudioPlayerPlaylistIsDone:self];
    }
}

// Track Complete - returns the next index track to be played
- (void) notifyAudioTrackDoneDelegate
{
    if([self.delegate respondsToSelector:@selector(NDAudioPlayerTrackIsDone:nextTrackIndex:)])
    {
        [self.delegate NDAudioPlayerTrackIsDone:self
                                 nextTrackIndex:currentTrackIndex];
    }
}

// gives delegate current time on the track being played
- (void) notifyAudioDurationDelegate
{
    if([self.delegate respondsToSelector:@selector(NDAudioPlayerTimeIsUpdated:withCurrentTime:)])
    {
        [self.delegate NDAudioPlayerTimeIsUpdated:self
                                     withCurrentTime:[self getAudioCurrentTime]];
    }
}


@end
