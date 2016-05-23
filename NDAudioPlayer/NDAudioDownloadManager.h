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

/**
 Notifies delegate that current download is complete
 
 @param sender The download manager object that is doing the downloading
 @param count The number of downloads remaining
 */
- (void) NDAudioDownloadManager:(NDAudioDownloadManager *_Nonnull)sender
currentDownloadIsCompleteWithRemainingDownloads:(NSUInteger)count;

@end

@interface NDAudioDownloadManager : NSObject

@property (weak, nonatomic)__nullable id<NDAudioDownloadManagerDelegate> delegate;

/**
 downloadFileFromURL:withName:andExtension allows you specify what to name the file on the disk and what extension you want to give it
 
 @param url The url to download the file from
 @param fileName The name to give the file once it is downloaded
 @param fileExtension The extension to give the file once it is downloaded (in the form of 'mp3' not '.mp3')
 @param completion A completion block to be executed once downloading is finished
 */
- (void)downloadFileFromURL:(NSURL *_Nonnull)url
                   withName:(NSString *_Nonnull)fileName
               andExtension:(NSString *_Nonnull)fileExtension
                 completion:(void(^__nullable)(BOOL didDownload))completion;

/**
 Retrieve a file from the NSDocumentsDirectory
 @param fileName Name of the file to be retrieved from the documents directory
 @param extension The extension of the file to be retrieved from the documents directory
 @return A url to the file requested
 */

- (NSURL *__nullable)getDownloadedFileWithName:(NSString *_Nonnull)fileName
                                andExtension:(NSString *_Nonnull)extension;

/**
 Retrieve all files that have been downloaded
 @param extension The extension of the files to be retrieved
 @return An array of all files stored in the documents directory with the given extension
 */
- (NSArray *__nullable)getAllDownloadedFilesWithExtension:(NSString *_Nonnull)extension;


/**
 Gets the extension of a filename 
 @param fileNameWithExtension The filename with the extension
 @return The extension of the file passed in
 */
- (NSString *_Nonnull)getExtensionFromFile:(NSString *_Nonnull)fileNameWithExtension;

/**
 Removes the extension from a file name string
 @param fileName The filename (with extension)
 @return file name without the extension
 */
- (NSString *_Nonnull)removeExtensionFromFile:(NSString *_Nonnull)fileName;


/**
 Deletes file from the NSDocuemntsDirectory
 @param url URL to the file to be deleted
 */
- (void)deleteFileWithURL:(NSURL *_Nonnull)url;

@end
