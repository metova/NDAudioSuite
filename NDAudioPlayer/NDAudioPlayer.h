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
/** 
 Notifies delegate that audio is ready to play
 @param sender The NDAudioPlayer object that is ready to play
 */
- (void) NDAudioPlayerIsReady: (NDAudioPlayer * _Nonnull)sender;

/** 
 Called when every track in the playlist has been played
 @param sender The NDAudioPlayer that is done with it's playlist
 */
- (void) NDAudioPlayerPlaylistIsDone: (NDAudioPlayer * _Nonnull)sender;

/** 
 Called when a track is done playing
 @param sender The NDAudioPlayer that was playing the Track
 @param nextTrackIndex The index in the playlist of the next track
 */
- (void) NDAudioPlayerTrackIsDone: (NDAudioPlayer * _Nonnull)sender
                   nextTrackIndex:(NSInteger)index;

/** 
 Gives delegate current time on the track being played
 @param sender The NDAudioPlayer who's time is updated
 @param currentTime The current time of the playing track in seconds
 */
- (void) NDAudioPlayerTimeIsUpdated: (NDAudioPlayer * _Nonnull)sender
                       withCurrentTime:(CGFloat)currentTime;

@end

@interface NDAudioPlayer : NSObject

@property (nullable, nonatomic, weak) id <NDAudioPlayerDelegate> delegate;

@property (assign, nonatomic) BOOL isPlaying;
@property (assign, nonatomic) BOOL isStopped;
@property (assign, nonatomic) BOOL isPaused;

/**
 The time scale for how often NDAudioPlayerTimeIsUpdated:withCurrentTime called
 **/
@property (assign, nonatomic) NSInteger timeScale;

/**
 The audio session category you'd like to use. Default is AVAudioSessionCategoryPlayAndRecord
 **/
@property (nonnull, strong, nonatomic) NSString *audioSessionCategory;

/**
 The audio session category option you'd like to use. Default is AVAudioSessionCategoryOptionDefaultToSpeaker
 **/
@property (assign, nonatomic) NSUInteger audioSessionCategoryOption;

/** 
 This method MUST be called before playAudio
 
 @param playlist An array of string typed urls that point to the audio files to be played
 @param index The index in the playlist to be played first
 @param volume The volume at which the audio is to be played
 */
- (void) prepareToPlay:(NSMutableArray * _Nonnull)playlist
               atIndex:(NSInteger)index
             atVolume:(CGFloat)volume;

/**
 This method should only be called once the delegate fires indicating that audio is ready
 */
- (void) playAudio;

/**
 Pauses the audio stream at it's current point
 */
- (void) pauseAudio;

/**
 Resumes the audio stream from where it was last paused
 */
- (void) resumeAudio;

/** 
 Stops the audio stream. Playing again from here will restart the stream from the beginning of the track
 */
- (void) stopAudio;

/**
Shuffles the tracks in the player's playlist
 @param enable Indicates whether shuffling should be enabled or not
 */
- (void) shuffleTracks:(BOOL)enable;

/**
 Skips to the next track in the playlist. If at the end of the playlist, goes back to the beginning
 
 @return The new current track index
 */
- (NSInteger) skipTrack;

/**
 Skips to the previous track in the playlist. If at the beginning of the playlist, goes to the last track in the playlist
 
 @return The new curremnt track index
*/
- (NSInteger) previousTrack;

/**
 Allows caller to retrieve current plyaing track index
 
@return The index of the currently playing track
 */
- (NSInteger)getCurrentTrackIndex;

/**
    Adjusts the volume to a desired level
 
    @param newVolume The new volume level
 */
- (void) setAudioVolume:(CGFloat)newVolume;

/**
 Allows caller to retrieve the total duration of the currently playing track
 
 @return The total number of seconds in the current track
 */
- (CGFloat) getTotalDuration;

/**
 Allows the caller to retieve the current volume level of the player 
 
 @return The current level of volume
 */
- (CGFloat)getAudioVolume;

/**
  Causes volume to fade out at the intervals passed in
 
  @param interval The intervals at which the fade needs to occur
 */
- (void)fadeOutWithIntervals:(CGFloat)interval;

/**
    FF/RW to time specified by the parameter. Used in conjunction with the audioTimeIsUpdated method, you can FF a certain number of seconds
    @param time The number of seconds to fast forward
 */
- (void)fastForwardToTime:(CGFloat)time;

/**
 RW to time specified by the parameter. Used in conjunction with the audioTimeIsUpdated method, you can RW a certain number of seconds
 
 @param time The number of seconds to rewind
 */
- (void)rewindToTime:(CGFloat) time;

/**
 give the audio player an entirely new playlist
 @param newPlaylist The new playlist the audio player  will play through
 */
- (void)setPlaylistToArray:(NSMutableArray * _Nonnull)newPlaylist;


@end

