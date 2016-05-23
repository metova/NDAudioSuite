//
//  ViewController.m
//  NDAudioPlayer
//
//  Created by Drew Pitchford on 12/8/14.
//  Copyright (c) 2014 Metova. All rights reserved.
//

#import "ViewController.h"
#import "Constants.h"
#import "NDAudioSuite.h"
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>
#import <MediaPlayer/MediaPlayer.h>


@interface ViewController () <NDAudioPlayerDelegate, NDAudioDownloadManagerDelegate>

@property (strong, nonatomic) NDAudioPlayer *player;
@property (strong, nonatomic) NDAudioDownloadManager *downloadManager;
@property (strong, nonatomic) NSMutableArray *songList;
@property (strong, nonatomic) NSMutableArray *downloadedSongNames;
@property (assign, nonatomic) CGFloat currentTime;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *songTextField;
@property (weak, nonatomic) IBOutlet UIButton *shuffleButton;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (strong, nonatomic) NSString *currentSongName;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *audioTimeLabel;

// options for the demo
@property (assign, nonatomic) BOOL shouldSeamlessSwitchToDiskAfterDownload;
@property (assign, nonatomic) BOOL shouldDownloadCurrentSong;
@property (assign, nonatomic) BOOL shouldShuffle;

@end

@implementation ViewController

NSMutableArray *originals;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.title = @"Audio Player";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playSelectedSong:)
                                                 name:kPlayAudioNotif
                                               object:nil];
    
    // YES allows for song to continue playing from disk after donwload is complete, without user input
    self.shouldSeamlessSwitchToDiskAfterDownload = YES;
    
    // YES only downloads current song that is playing. NO downloads all songs.
    self.shouldDownloadCurrentSong = NO;
    
    // set up audio player
    self.player = [[NDAudioPlayer alloc] init];
    self.player.delegate = self;
    self.player.isStopped = YES;
    self.player.isPlaying = NO;
    self.player.isPaused = NO;
    
    // set up download manager
    self.downloadManager = [[NDAudioDownloadManager alloc] init];
    self.downloadManager.delegate = self;
    
    // set up song list
    self.songList = [NSMutableArray new];
    NSString *song1 = @"https://dl.dropboxusercontent.com/s/4z4fhi9txijauew/02%20Shoot%20to%20Thrill.m4a?dl=0";
    NSString *song2 = @"https://dl.dropboxusercontent.com/s/g6ptcb5l0s15p83/03%20I%20Won%27t%20Stand%20In%20Your%20Way.mp3?dl=0";
    NSString *song3 = @"https://dl.dropboxusercontent.com/s/wwvpfawteseuztv/07%20You%20Shook%20Me%20All%20Night%20Long.m4a?dl=0";
    NSString *song4 = @"https://dl.dropboxusercontent.com/s/ymqpqfqldhmtzlr/09%20Crazy%20Little%20Thing%20Called%20Love.mp3?dl=0";
    
    [self.songList addObject:song4];
    [self.songList addObject:song2];
    [self.songList addObject:song3];
    [self.songList addObject:song1];
    self.downloadedSongNames = [NSMutableArray new];
    originals = self.songList;
    
    if([self isConnectedToTheInternet])
    {
        [self.player prepareToPlay:self.songList
                           atIndex:0
                         atVolume:0.5];
    }
    
    // set up UI things
    self.pauseButton.hidden = YES;
    self.volumeSlider.minimumValue = 0.0;
    self.volumeSlider.maximumValue = 1.0;
    self.progressBar.progress = 0.0;
}

// In a real project, use Reachability. Here, just wanted to prevent a crash in a simple way.
- (BOOL)isConnectedToTheInternet
{
    
    NSArray *subviews = [[[[UIApplication sharedApplication] valueForKey:@"statusBar"] valueForKey:@"foregroundView"]subviews];
    NSNumber *dataNetworkItemView = nil;
    
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
            dataNetworkItemView = subview;
            break;
        }
    }
    
    switch ([[dataNetworkItemView valueForKey:@"dataNetworkType"]integerValue]) {
        case 0:
            NSLog(@"No wifi or cellular");
            return NO;
            break;
            
        default:
            return YES;
            break;
    }
}


- (void)changeLabel
{
    NSMutableString *str = [@"Song: "mutableCopy];
    if(!self.currentSongName)
    {
        self.currentSongName = [self.songList objectAtIndex:[self.player getCurrentTrackIndex]];
    }
    NSString *indexString = [self.songList objectAtIndex:[self.player getCurrentTrackIndex]];
    NSURL *url = [NSURL URLWithString:indexString];
    indexString = [url lastPathComponent];
    indexString = [self.downloadManager removeExtensionFromFile:indexString];
    [str appendString:indexString];
    self.songTextField.text = str;
}

#pragma -mark IBActions
- (IBAction)playPressed:(id)sender
{
    [self.player playAudio];
    self.playButton.hidden = YES;
    self.pauseButton.hidden = NO;
    [self changeLabel];
}

- (IBAction)pausePressed:(id)sender
{
    [self.player pauseAudio];
    self.pauseButton.hidden = YES;
    self.playButton.hidden = NO;
}


- (IBAction)skipToNext:(id)sender
{
    if(self.pauseButton.isHidden)
    {
        [self playPressed:nil];
    }
    [self.player skipTrack];
    [self.player playAudio];
    [self changeLabel];
    self.progressBar.progress = 0.0;
}


- (IBAction)skipToPrevious:(id)sender
{
    if(self.pauseButton.isHidden)
    {
        [self playPressed:nil];
    }
    [self.player previousTrack];
    [self.player playAudio];
    [self changeLabel];
    self.progressBar.progress = 0.0;
}

- (IBAction)downloadPressed:(id)sender
{
    // Download current song/ 1 song
    if([self isConnectedToTheInternet])
    {
        if(self.shouldDownloadCurrentSong)
        {
            NSURL *url = [NSURL URLWithString:[self.songList objectAtIndex:[self.player getCurrentTrackIndex]]];
            NSString *songName = [url lastPathComponent];
            songName = [self.downloadManager removeExtensionFromFile:songName];
            [self.downloadManager downloadFileFromURL:url
                                             withName:songName
                                         andExtension:@"mp3" completion:^(BOOL didDownload) {
                                             
                                         }];
            self.currentSongName = songName;
        }
        else //download multiple files
        {
            int i = 0;
            for(NSString *str in self.songList)
            {
                NSURL *url = [NSURL URLWithString:str];
                NSString *songName = [url lastPathComponent];
                songName = [self.downloadManager removeExtensionFromFile:songName];
                
                NSLog(@"Downloading %@", songName);
                [self.downloadManager downloadFileFromURL:url
                                                 withName:songName
                                             andExtension:@"mp3" completion:^(BOOL didDownload) {
                                                 
                                             }];
                [self.downloadedSongNames addObject:songName];
                self.currentSongName = songName;
                i++;
            }
        }
        
        [self.downloadButton setTitle:@"Downloading..."
                             forState:UIControlStateNormal];
    }
}


- (IBAction)shufflePressed:(id)sender
{
    if(!self.shouldShuffle)
    {
        [self.player shuffleTracks:YES];
        self.shouldShuffle = YES;
        [self.shuffleButton setTitle:@"Shuffle: On"
                            forState:UIControlStateNormal];
    }
    else
    {
        [self.player shuffleTracks:NO];
        self.shouldShuffle = NO;
        [self.shuffleButton setTitle:@"Shuffle: Off"
                            forState:UIControlStateNormal];
    }
}

// how to change volume levels in NDAudioPlayer
- (IBAction)sliderValueChanged:(id)sender
{
    [self.player setAudioVolume:self.volumeSlider.value];
}

// not clean but just need to reset the songlist to originals
- (IBAction)originalLinksPressed:(id)sender
{
    [self.player stopAudio];
    self.player = [[NDAudioPlayer alloc] init];
    self.player.delegate = self;
    self.player.isStopped = YES;
    self.player.isPlaying = NO;
    self.player.isPaused = NO;
    
    // set up song list
    self.songList = nil;
    self.songList = [NSMutableArray new];
    NSString *song1 = @"https://dl.dropboxusercontent.com/s/4z4fhi9txijauew/02%20Shoot%20to%20Thrill.m4a?dl=0";
    NSString *song2 = @"https://dl.dropboxusercontent.com/s/g6ptcb5l0s15p83/03%20I%20Won%27t%20Stand%20In%20Your%20Way.mp3?dl=0";
    NSString *song3 = @"https://dl.dropboxusercontent.com/s/wwvpfawteseuztv/07%20You%20Shook%20Me%20All%20Night%20Long.m4a?dl=0";
    NSString *song4 = @"https://dl.dropboxusercontent.com/s/ymqpqfqldhmtzlr/09%20Crazy%20Little%20Thing%20Called%20Love.mp3?dl=0";
    
    [self.songList addObject:song4];
    [self.songList addObject:song2];
    [self.songList addObject:song3];
    [self.songList addObject:song1];
    
    [self.playButton setSelected:NO];
    [self.player prepareToPlay:self.songList
                       atIndex:0
                     atVolume:self.volumeSlider.value];
    [self playPressed:nil];
}


#pragma -mark AudioDownloadManager delegate method

- (void)NDAudioDownloadManager:(NDAudioDownloadManager *)sender
currentDownloadIsCompleteWithRemainingDownloads:(NSUInteger)count
{
    if(count == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Downloads Complete"
                                                        message:@"All songs have been downloaded."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
        [self.downloadButton setTitle:@"Download"
                             forState:UIControlStateNormal];
    }
}


#pragma -mark NDAudioPlayer delegate methods

- (void)NDAudioPlayerIsReady:(NDAudioPlayer *)sender
{
    self.progressBar.progress = 0.0;
    [self putInformationInSongInfoCenter];
}

- (void)NDAudioPlayerTimeIsUpdated:(NDAudioPlayer *)sender withCurrentTime:(CGFloat)currentTime
{
    NSLog(@"Duration: %f", currentTime);
    self.currentTime = currentTime;
    [self.progressBar setProgress:currentTime/[self.player getTotalDuration]
                         animated:YES];
    
    int totalTime = (int)[self.player getTotalDuration] / 60;
    int currentTimeMinutes = (int)currentTime / 60;
    int totalTimeSeconds = (int)[self.player getTotalDuration] % 60;
    int currentTimeSeconds = (int)currentTime % 60;
    self.audioTimeLabel.text = [NSString stringWithFormat:@"%02i:%02i / %02i:%02i", currentTimeMinutes, currentTimeSeconds, totalTime, totalTimeSeconds];
}


-(void)NDAudioPlayerPlaylistIsDone:(NDAudioPlayer *)sender
{
    // implement this method if you have multiple playlists to go through
}


- (void)NDAudioPlayerTrackIsDone:(NDAudioPlayer *)sender nextTrackIndex:(NSInteger)index
{
    [self.player prepareToPlay:self.songList
                       atIndex:index
                     atVolume:[self.player getAudioVolume]];
    [self.player playAudio];
    [self changeLabel];
}

#pragma -mark Song Info Center

- (void)putInformationInSongInfoCenter
{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    NSURL *url = [self.songList objectAtIndex:[self.player getCurrentTrackIndex]];
    NSString *songName = [url lastPathComponent];
    songName = [songName stringByRemovingPercentEncoding];
    songName = [self.downloadManager removeExtensionFromFile:songName];
    NSMutableDictionary *songInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:songName, MPMediaItemPropertyTitle, @(self.currentTime), MPMediaItemPropertyBookmarkTime, @([self.player getTotalDuration]), MPMediaItemPropertyPlaybackDuration, nil];
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = songInfo;
}


#pragma -mark Notif methods

- (void)playSelectedSong:(NSNotification *)notif
{
    NSDictionary *userInfo = [notif object];
    
    NSString *songName = [userInfo objectForKey:@"songName"];
    NSString *ext = [self.downloadManager getExtensionFromFile:songName];
    songName = [self.downloadManager removeExtensionFromFile:songName];
    
    NSURL *url = [self.downloadManager getDownloadedFileWithName:songName
                                                    andExtension:ext];
    
    if(self.player.isPlaying)
    {
        [self pausePressed:nil];
        [self.player stopAudio];
    }
    if(url)
    {
        NSString *urlString = [url absoluteString];
        [self.songList removeAllObjects];
        [self.songList addObject:urlString];
        [self.player prepareToPlay:self.songList
                           atIndex:0
                         atVolume:[self.player getAudioVolume]];
        [self playPressed:nil];
        NSMutableString *songStr = [@"Song: " mutableCopy];
        [songStr appendString:songName];
        self.songTextField.text = songStr;
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"URL Corrupt"
                                                        message:@"url is nil"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
}


#pragma -mark MPNowPlayingInfoCenter delegate methods
- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if(event.type == UIEventTypeRemoteControl)
    {
        switch (event.subtype)
        {
            case UIEventSubtypeRemoteControlPause:
                [self pausePressed:nil];
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [self skipToNext:nil];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self skipToPrevious:nil];
                break;
            case UIEventSubtypeRemoteControlPlay:
                [self playPressed:nil];
                break;
            default:
                break;
        }
        
    }
}

@end
