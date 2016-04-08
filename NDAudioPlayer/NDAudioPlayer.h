//
//  AudioPlayer.h
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

#import <Foundation/Foundation.h>
#import <AVFoundation/AVPlayer.h>
#import <AVFoundation/AVPlayerItem.h>
#import <AVFoundation/AVAsset.h>

@class NDAudioPlayer;

typedef NS_ENUM(NSInteger, PlaybackStatus)
{
    Paused,
    Playing,
    Stopped
} ;

@protocol NDAudioPlayerDelegate <NSObject>

@optional
// Notifies delegate that audio is ready to play
- (void) NDAudioPlayerIsReady: (NDAudioPlayer * _Nonnull)sender;

// Playlist Complete - would indicate no other tracks can be played
- (void) NDAudioPlayerPlaylistIsDone: (NDAudioPlayer * _Nonnull)sender;

// Track Complete - returns the next index track to be played
- (void) NDAudioPlayerTrackIsDone: (NDAudioPlayer * _Nonnull)sender
                   nextTrackIndex:(NSInteger)index;

// gives delegate current time on the track being played
- (void) NDAudioPlayerTimeIsUpdated: (NDAudioPlayer * _Nonnull)sender
                       withDuration:(CGFloat)duration;

@end

@interface NDAudioPlayer : NSObject

@property (nullable, nonatomic, weak) id <NDAudioPlayerDelegate> delegate;

@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL isStopped;
@property (assign, nonatomic) BOOL isPaused;
@property (assign, nonatomic) NSInteger timeScale;

/* prepareToPlay must be called before playAudio is called */
- (void) prepareToPlay:(NSMutableArray * _Nonnull)playlist
               atIndex:(NSInteger)index
             atVolumne:(CGFloat)volumne;

/*  
    playAudio should only be called once the delegate fires indicating that audio is ready
    pauseAudio/resumeAudio are self explanatory
    stopAudio stops music and deallocates the music player. prepareToPlay would have to be called after stopAudio is called in order to 
        play more songs
 */
- (void) playAudio;
- (void) pauseAudio;
- (void) resumeAudio;
- (void) stopAudio;

/*
    Basic functions of music plahying. Shuffle, skip 1 ahead, skip 1 back
 */
- (void) shuffleTracks:(BOOL)enable;
- (NSInteger) skipTrack;
- (NSInteger) previousTrack;

// returns the current index that is playing in the song table
- (NSInteger)getCurrentTrackIndex;

/*
    setAudioVolume adjust the volume to a desired level
    getAudioDuration returns the total number of seconds in the current track
    getAudioVolume returns the current level of volume
    fadeOutWithIntervals causes volume to fade out at the intervals passed in
 */
- (void) setAudioVolume:(CGFloat)newVolume;
- (CGFloat) getTotalDuration;
- (CGFloat)getAudioVolume;
- (void)fadeOutWithIntervals:(CGFloat)interval;

/*
    FF/RW to time specified by the parameter. Used in conjunction with the audioTimeIsUpdated method, you can FF/RW a certain number of seconds
 */
- (void)fastForwardToTime:(CGFloat)time;
- (void)rewindToTime:(CGFloat) time;

// give the audio player an entirely new playlist
- (void)setPlaylistToArray:(NSMutableArray * _Nonnull)newPlaylist;


@end

