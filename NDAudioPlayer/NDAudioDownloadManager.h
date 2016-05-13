//
//  NDAudioDownloadManager.h
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

#import <Foundation/Foundation.h>

@class NDAudioDownloadManager;

@protocol NDAudioDownloadManagerDelegate <NSObject>

// Fires off as many times as downloadFromURL: withName: andExtension: is called
- (void) NDAudioDownloadManager:(NDAudioDownloadManager *_Nonnull)sender
currentDownloadIsCompleteWithRemainingDownloads:(NSUInteger)count;

@end

@interface NDAudioDownloadManager : NSObject

@property (weak, nonatomic)__nullable id<NDAudioDownloadManagerDelegate> delegate;

/*
 downloadFileFromURL:withName:andExtension allows you specify what to name the file on the disk and what extension you want to give it
 NOTE: the extension parameter is just like standard Apple parameters for extensions. i.e. @"mp3" not @".mp3"
 
 getDownloadedFileFromDiskWithName:andExtension returns a url to the object on disk with the specified name
 NOTE: the extension parameter is just like standard Apple parameters for extensions. i.e. @"mp3" not @".mp3"
 NOTE: will return nil if the file requested is not on disk. Best practice is to do a nil check on the object housing the return before use
 
 getAllDownloadedFilesFromDiskWithExtension returns an array of files of the type of the specified extension
 */
- (void)downloadFileFromURL:(NSURL *_Nonnull)url
                   withName:(NSString *_Nonnull)fileNameOnDisk
               andExtension:(NSString *_Nonnull)fileExtension
                 completion:(void(^_Nonnull)(BOOL didDownload))completion;

- (NSURL *__nullable)getDownloadedFileFromDiskWithName:(NSString *_Nonnull)fileToBePlayed
                                andExtension:(NSString *_Nonnull)extension;

- (NSArray *__nullable)getAllDownloadedFilesFromDiskWithExtension:(NSString *_Nonnull)extension;


/*
 File helper methods to remove or get the extension of a file and delete a file
 */
- (NSString *_Nonnull)getExtensionFromFile:(NSString *_Nonnull)fileNameWithExtension;

- (NSString *_Nonnull)removeExtensionFromFile:(NSString *_Nonnull)fileName;

- (void)deleteFromDiskFileWithURL:(NSURL *_Nonnull)url;

@end
