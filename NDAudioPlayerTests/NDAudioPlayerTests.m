//
//  NDAudioPlayerTests.m
//  NDAudioPlayerTests
//
//  Created by Drew Pitchford on 12/8/14.
//  Copyright (c) 2014 Metova. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "NDAudioSuite.h"

@interface NDAudioPlayer (UnitTest)

@property (strong, nonatomic) NSMutableArray *playlist;
@property (assign, nonatomic) CGFloat volume;
@property (strong, nonatomic) AVPlayer *audioPlayer;

-(void)itemDidFinishPlaying:(NSNotification *) notification;
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context;
- (void) notifyAudioReadyDelegate;
- (void) notifyAudioPlaylistDoneDelegate;
- (void) notifyAudioTrackDoneDelegate;
- (void) notifyAudioDurationDelegate;
- (NSInteger)getCurrentTrackIndex;
- (void) playAudio;
- (void) pauseAudio;
- (void) resumeAudio;
- (void) stopAudio;
- (NSInteger) skipTrack;
- (NSInteger) previousTrack;
- (void) setAudioVolume:(CGFloat)newVolume;
- (CGFloat) getAudioDuration;
-(CGFloat) getAudioCurrentTime;
- (CGFloat)getAudioVolume;
- (void)fadeOutWithIntervals:(CGFloat)interval;
- (void)fastForwardToTime:(CGFloat)time;
- (void)rewindToTime:(CGFloat) time;
- (void) shuffleTracks:(BOOL)enable;

@end

@interface NDAudioDownloadManager (UnitTest)

- (NSString *)getExtensionFromFile:(NSString *)fileNameWithExtension;

- (NSString *)removeExtensionFromFile:(NSString *)fileName;

- (NSArray *)getAllDownloadedFilesFromDiskWithExtension:(NSString *)extension;

- (void)deleteFromDiskFileWithURL:(NSURL *)url;

@end

@interface NDAudioPlayerTests : XCTestCase <NDAudioPlayerDelegate>

@property (strong, nonatomic) NDAudioPlayer *fakePlayer;
@property (strong, nonatomic) NDAudioDownloadManager *fakeManager;
@property (strong, nonatomic) NSMutableArray *playlist;
@property (assign, nonatomic) BOOL notHit;

@end

@implementation NDAudioPlayerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.fakePlayer = [NDAudioPlayer new];
    self.playlist = [@[@"song1", @"song2", @"song3, song4, song5, song6, song7, song8, song9, song10"] mutableCopy];
    self.notHit = YES;
    
    self.fakeManager = [[NDAudioDownloadManager alloc] init];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.fakePlayer = nil;
}

- (void)testSetAudioVolume
{
    [self.fakePlayer setAudioVolume:2.0];
    XCTAssertTrue([self.fakePlayer getAudioVolume] == 2);
    
    [self.fakePlayer setAudioVolume:10.0];
    XCTAssertTrue([self.fakePlayer getAudioVolume] == 10);
}

- (void)testGetCurrentIndex
{
    [self.fakePlayer prepareToPlay:[@[@"whatever"] mutableCopy]
                           atIndex:0
                         atVolume:1.0];
    
    XCTAssertTrue([self.fakePlayer getCurrentTrackIndex] == 0);
}

- (void)testFFRW
{
    // doesn't work, come back to this.
    [self.fakePlayer prepareToPlay:[@[@"https://dl.dropboxusercontent.com/s/npcc781ahkyxkoh/01%20Sunny%20Afternoon.mp3?dl=0"] mutableCopy]
                           atIndex:0
                          atVolume:1.0];
    
    [self.fakePlayer playAudio];
    
    [self.fakePlayer fastForwardToTime:15];
    XCTAssertEqual([self.fakePlayer getAudioCurrentTime], 15);
    
    [self.fakePlayer rewindToTime:6];
    XCTAssertEqual([self.fakePlayer getAudioCurrentTime], 6);
}

- (void)testNewPlaylist
{
    [self.fakePlayer prepareToPlay:[@[@"Song1", @"Song2", @"Song3"] mutableCopy] atIndex:0 atVolume:1.0];
    XCTAssertTrue(self.fakePlayer.playlist.count == 3);
    
    [self.fakePlayer setPlaylistToArray:[@[@"Song1"] mutableCopy]];
    XCTAssertTrue(self.fakePlayer.playlist.count == 1);
}

- (void)testPrepareToPlay
{
    [self.fakePlayer prepareToPlay:self.playlist
                           atIndex:0
                         atVolume:1.0];
    
    XCTAssertTrue([self.fakePlayer.playlist isEqualToArray:self.playlist]);
}

- (void)testAudioThings
{
    [self.fakePlayer prepareToPlay:self.playlist
                           atIndex:0
                         atVolume:1.0];
    
    [self.fakePlayer playAudio];
    
    XCTAssertTrue(self.fakePlayer.isPlaying);
    XCTAssertFalse(self.fakePlayer.isPaused);
    XCTAssertFalse(self.fakePlayer.isStopped);
    
    [self.fakePlayer pauseAudio];
    XCTAssertFalse(self.fakePlayer.isPlaying);
    XCTAssertTrue(self.fakePlayer.isPaused);
    XCTAssertFalse(self.fakePlayer.isStopped);
    
    [self.fakePlayer resumeAudio];
    XCTAssertTrue(self.fakePlayer.isPlaying);
    XCTAssertFalse(self.fakePlayer.isPaused);
    XCTAssertFalse(self.fakePlayer.isStopped);
    
    [self.fakePlayer stopAudio];
    XCTAssertFalse(self.fakePlayer.isPlaying);
    XCTAssertFalse(self.fakePlayer.isPaused);
    XCTAssertTrue(self.fakePlayer.isStopped);
}

- (void)testSkipAndPrevious
{
    [self.fakePlayer prepareToPlay:self.playlist
                           atIndex:0
                         atVolume:1.0];
    
    [self.fakePlayer playAudio];
    XCTAssertTrue([self.fakePlayer getCurrentTrackIndex] == 0);
    
    [self.fakePlayer skipTrack];
    XCTAssertTrue([self.fakePlayer getCurrentTrackIndex] == 1);
    
    [self.fakePlayer previousTrack];
    XCTAssertTrue([self.fakePlayer getCurrentTrackIndex] == 0);
    
    [self.fakePlayer previousTrack];
    XCTAssertTrue([self.fakePlayer getCurrentTrackIndex] == self.playlist.count - 1);
}

- (void)testVolumeThings
{
    [self.fakePlayer prepareToPlay:self.playlist
                           atIndex:0
                         atVolume:1.0];
    
    [self.fakePlayer playAudio];
    [self.fakePlayer setVolume:0.5];
    XCTAssertTrue(self.fakePlayer.volume == 0.5);
    XCTAssertTrue([self.fakePlayer getAudioVolume] == 0.5);
    
    [self.fakePlayer setVolume:1.0];
    
    CGFloat previousVolume = self.fakePlayer.volume;
    for(double i = 1.0; i > 0.0; i = i - 0.2)
    {
        [self.fakePlayer fadeOutWithIntervals:0.2];
        XCTAssertTrue(self.fakePlayer.volume = previousVolume - 0.2);
        previousVolume = self.fakePlayer.volume;
    }
}

- (void)testShuffleTracks
{
    [self.fakePlayer prepareToPlay:self.playlist atIndex:0 atVolume:1.0];
    
    XCTAssertTrue([[self.fakePlayer.playlist objectAtIndex:0] isEqual:[self.playlist objectAtIndex:0]]);
    XCTAssertTrue([[self.fakePlayer.playlist objectAtIndex:1] isEqual:[self.playlist objectAtIndex:1]]);
    XCTAssertTrue([[self.fakePlayer.playlist objectAtIndex:2] isEqual:[self.playlist objectAtIndex:2]]);
    
    [self.fakePlayer skipTrack];
    XCTAssertTrue([self.fakePlayer getCurrentTrackIndex] == 1);
    
    [self.fakePlayer previousTrack];
    XCTAssertTrue([self.fakePlayer getCurrentTrackIndex] == 0);
    
    [self.fakePlayer shuffleTracks:YES];
    
    // may fail sometimes because once shuffled, 3 skips could land on index 1;
    [self.fakePlayer skipTrack];
    [self.fakePlayer skipTrack];
    [self.fakePlayer skipTrack];
    
    
    NSInteger current = [self.fakePlayer getCurrentTrackIndex];
    [self.fakePlayer shuffleTracks:NO];
    XCTAssertTrue(current == [self.fakePlayer getCurrentTrackIndex]); // test that shuffle set to no sets current track
}

- (void)testDelegates
{
    [self.fakePlayer prepareToPlay:[@[@"what"] mutableCopy]
                           atIndex:0
                          atVolume:1.0];
    
    self.fakePlayer.delegate = self;
    [self.fakePlayer notifyAudioReadyDelegate];
    
    [self.fakePlayer notifyAudioPlaylistDoneDelegate];
    [self.fakePlayer notifyAudioTrackDoneDelegate];
    [self.fakePlayer fastForwardToTime:10];
    [self.fakePlayer notifyAudioDurationDelegate];
}

- (void)testItemDidFinishPlaying
{
    [self.fakePlayer prepareToPlay:[@[@"h", @"e", @"l"] mutableCopy]
                           atIndex:0
                          atVolume:1.0];
    NSNotification *notif = [[NSNotification alloc] initWithName:@"Test" object:nil userInfo:nil];
    [self.fakePlayer itemDidFinishPlaying:notif];
    XCTAssertEqual([self.fakePlayer getCurrentTrackIndex], 1);
    
    [self.fakePlayer prepareToPlay:[@[@"h", @"e"] mutableCopy] atIndex:1 atVolume:1.0];
    [self.fakePlayer itemDidFinishPlaying:notif];
    XCTAssertEqual([self.fakePlayer getCurrentTrackIndex], 2);
}

- (void)testKeyPath
{
    NSString * keyPath = @"status";
    
    [self.fakePlayer prepareToPlay:[@[@"https://dl.dropboxusercontent.com/s/npcc781ahkyxkoh/01%20Sunny%20Afternoon.mp3?dl=0"] mutableCopy]
                           atIndex:0
                          atVolume:1.0];
    [self.fakePlayer playAudio];
    [self.fakePlayer observeValueForKeyPath:keyPath ofObject:self.fakePlayer.audioPlayer.currentItem change:nil context:nil];
    //need to figure out this test
    
}

#pragma -mark Audio Player delegates
-(void)NDAudioPlayerIsReady:(NDAudioPlayer *)sender
{
    XCTAssertEqual(sender, self.fakePlayer);
}

-(void)NDAudioPlayerPlaylistIsDone:(NDAudioPlayer *)sender
{
    XCTAssertEqual(sender, self.fakePlayer);
}

-(void)NDAudioPlayerTrackIsDone:(NDAudioPlayer *)sender nextTrackIndex:(NSInteger)index
{
    XCTAssertEqual(sender, self.fakePlayer);
    XCTAssertEqual(index, 0);
}

-(void)NDAudioPlayerTimeIsUpdated:(NDAudioPlayer *)sender withCurrentTime:(CGFloat)currentTime
{
    XCTAssertEqual(sender, self.fakePlayer);
    XCTAssertEqual(currentTime, 10);
}

#pragma -mark NDDownloadManager tests
//
//- (void)testGetDownloadedFileFromDiskIfNotThere
//{
//    [self.fakePlayer prepareToPlay:self.playlist
//                           atIndex:0
//                         atVolumne:1.0];
//    
//    XCTAssertNil([self.fakeManager getDownloadedFileFromDiskWithName:@"test"
//                                                        andExtension:@"mp3"]);
//    
//    NSURL *fakeURL = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/s/npcc781ahkyxkoh/01%20Sunny%20Afternoon.mp3?dl=0"];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, @"testFile.mp3"];
//    
//    NSData *data = [NSData dataWithContentsOfURL:fakeURL];
//    [data writeToFile:filePath
//           atomically:YES];
//    
//    // file is there
//    XCTAssertNotNil([self.fakeManager getDownloadedFileFromDiskWithName:@"testFile" andExtension:@"mp3"]);
//    
//}

- (void)testGetExtensionFromFile
{
    NSString *musicFile = @"testName.mp3";
    NSString *extension = [self.fakeManager getExtensionFromFile:musicFile];
    
    XCTAssertTrue([extension isEqualToString:@"mp3"]);
    
    musicFile = @"testVideo.mp4";
    extension = [self.fakeManager getExtensionFromFile:musicFile];
    
    XCTAssertTrue([extension isEqualToString:@"mp4"]);
}

- (void)testRemoveExtensionFromFile
{
    NSString *musicFile = @"testName.mp3";
    NSString *musicFileWithoutExtension = [self.fakeManager removeExtensionFromFile:musicFile];
    
    XCTAssertTrue([musicFileWithoutExtension isEqualToString:@"testName"]);
    XCTAssertFalse([musicFileWithoutExtension isEqualToString:musicFile]);
}

//- (void)testDeleteFromDisk
//{
//    NSURL *fakeURL = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/s/npcc781ahkyxkoh/01%20Sunny%20Afternoon.mp3?dl=0"];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, @"testFile.mp3"];
//    
//    NSData *data = [NSData dataWithContentsOfURL:fakeURL];
//    [data writeToFile:filePath
//           atomically:YES];
//    
//    // file is there
//    XCTAssertNotNil([self.fakeManager getDownloadedFileFromDiskWithName:@"testFile" andExtension:@"mp3"]);
//    
//    // delete
//    [self.fakeManager deleteFromDiskFileWithURL:[self.fakeManager getDownloadedFileFromDiskWithName:@"testFile" andExtension:@"mp3"]];
//    
//    // file isn't there
//    XCTAssertNil([self.fakeManager getDownloadedFileFromDiskWithName:@"testFile" andExtension:@"mp3"]);
//    
//}

//- (void)testGetAllFiles
//{
//    NSURL *fakeURL = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/s/npcc781ahkyxkoh/01%20Sunny%20Afternoon.mp3?dl=0"];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, @"testFile.mp3"];
//    
//    NSData *data = [NSData dataWithContentsOfURL:fakeURL];
//    [data writeToFile:filePath
//           atomically:YES];
//    
//    fakeURL = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/s/npcc781ahkyxkoh/01%20Sunny%20Afternoon.mp3?dl=0"];
//    
//    paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    documentsDirectory = [paths objectAtIndex:0];
//    filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, @"testFile2.mp3"];
//    
//    data = [NSData dataWithContentsOfURL:fakeURL];
//    [data writeToFile:filePath
//           atomically:YES];
//    
//    
//    NSArray *arrayOfFiles = [self.fakeManager getAllDownloadedFilesFromDiskWithExtension:@"mp3"];
//    XCTAssertTrue([arrayOfFiles count] > 0);
//}


@end
