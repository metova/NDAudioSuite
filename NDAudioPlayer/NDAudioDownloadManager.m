//
//  NDAudioDownloadManager.m
//  NDAudioPlayer
//
//  Created by Drew Pitchford on 12/16/14.
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

#import "NDAudioDownloadManager.h"



@interface NDAudioDownloadManager()

@property (strong, nonatomic) NSMutableArray *downloadQueue;

@end

@implementation NDAudioDownloadManager


- (id) init
{
    self = [super init];
    if(self)
    {
        _downloadQueue = [NSMutableArray new];
    }
    
    return self;
}

#pragma -mark Download File methods

// download audio file to docuements directory.
- (void)downloadFileFromURL:(NSURL *)url
                   withName:(NSString *)fileName
               andExtension:(NSString *)fileExtension
                 completion:(void(^)(BOOL didDownload))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, (unsigned long)NULL), ^(void)
                   {
                       
                       NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                       NSString *documentsDirectory = [paths objectAtIndex:0];
                       NSMutableString *thisFileName = [fileName mutableCopy];
                       [thisFileName appendString:@"."];
                       [thisFileName appendString:fileExtension];
                       NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, thisFileName];
                       
                       [self.downloadQueue addObject:thisFileName];
                       
                       NSData *urlData = [NSData dataWithContentsOfURL:url];
                       [urlData writeToFile:filePath
                                 atomically:YES];
                       
                       dispatch_async(dispatch_get_main_queue(), ^{
                           [self.downloadQueue removeObject:thisFileName];
                           [self notifyDownloadCompleteDelegate];
                       });
                   });
}

// called to get the file from disk. prepareToPlay would need to be called on the returned object
// will return nil if file requested to get from disk is not on disk
- (NSURL *)getDownloadedFileWithName:(NSString *)fileName
                        andExtension:(NSString *)extension
{
    __block NSMutableArray *arrayOfSongs;
    NSURL *url;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSMutableString *fullFileName = [fileName mutableCopy];
    [fullFileName appendString:@"."];
    [fullFileName appendString:extension];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fullFileName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:filePath])
    {
        arrayOfSongs = [[NSMutableArray alloc] initWithArray:[fileManager contentsOfDirectoryAtPath:documentsDirectory error:nil]];
        NSArray *selectedSongs = [arrayOfSongs pathsMatchingExtensions:@[extension]];
        
        NSString *selectedSongURLString;
        for(NSString *str in selectedSongs)
        {
            if([str isEqualToString:fullFileName])
            {
                selectedSongURLString = str;
                break;
            }
        }
        
        NSString *selectedSound = [documentsDirectory stringByAppendingPathComponent:selectedSongURLString];
        url = [NSURL fileURLWithPath:selectedSound];
        
        return url;
    }
    else
    {
        NSLog(@"File doesn't exist!");
    }
    
    // return nil if the file does not exist.
    return url;
}


// get all files from the disk
- (NSArray *)getAllDownloadedFilesWithExtension:(NSString *)extension
{
    NSMutableArray *arrayOfFiles = [NSMutableArray new];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *filePaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory
                                                                             error:nil];
    
    for(NSString *path in filePaths)
    {
        if([path containsString:extension])
        {
            @try
            {
                if(![arrayOfFiles containsObject:path])
                    [arrayOfFiles addObject:path];
            }
            @catch (NSException *exception)
            {
                NSLog(@"%@", exception);
            }
            @finally {}
        }
    }
    
    return arrayOfFiles;
}

#pragma -mark file helpers

- (NSString *)removeExtensionFromFile:(NSString *)fileName
{
    NSMutableString *dotExt = [@"." mutableCopy];
    [dotExt appendString:[[self getExtensionFromFile:fileName] mutableCopy]];
    NSString *newFilePath = [fileName stringByReplacingOccurrencesOfString:dotExt withString:@""];
    
    return newFilePath;
}

- (NSString *)getExtensionFromFile:(NSString *)fileNameWithExtension
{
    NSArray *filePathParts = [fileNameWithExtension componentsSeparatedByString:@"."];
    NSString *ext = [filePathParts lastObject];
    
    return ext;
}

- (void)deleteFileWithURL:(NSURL *)url
{
    NSError *error;
    
    [[NSFileManager defaultManager] removeItemAtURL:url
                                              error:&error];
    
    if(error)
    {
        NSLog(@"file not available: %@", error);
    }
    
}

#pragma -mark Delegate methods

// Fires off as many times as downloadFromURL: withName: andExtension is called
- (void) notifyDownloadCompleteDelegate
{
    [self.delegate NDAudioDownloadManager:self currentDownloadIsCompleteWithRemainingDownloads:[self.downloadQueue count]];
}


@end
