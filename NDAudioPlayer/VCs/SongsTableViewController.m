//
//  SongsTableViewController.m
//  NDAudioPlayer
//
//  Created by Drew Pitchford on 12/16/14.
//  Copyright (c) 2014 Metova. All rights reserved.
//

#import "SongsTableViewController.h"
#import "NDAudioSuite.h"
#import "SongTableViewCell.h"

@interface SongsTableViewController ()

@property (weak, nonatomic) IBOutlet UITableView *songsTableView;

@property (strong, nonatomic) NSMutableArray *songList;
@property (strong, nonatomic) NDAudioDownloadManager *downloadManager;
@property (strong, nonatomic) UIRefreshControl *refresh;

@end

@implementation SongsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.downloadManager = [[NDAudioDownloadManager alloc] init];
    self.navigationItem.title = @"Downloads";
    // Do any additional setup after loading the view.
    
    UIRefreshControl *refreshControl = [UIRefreshControl new];
    refreshControl.backgroundColor = [UIColor clearColor];
    refreshControl.tintColor = [UIColor blackColor];
    [refreshControl addTarget:self
                       action:@selector(getNewDownloads)
             forControlEvents:UIControlEventValueChanged];

    UITableViewController *tableController = [[UITableViewController alloc] init];
    tableController.tableView = self.songsTableView;
    tableController.refreshControl = refreshControl;
    self.refresh = refreshControl;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.songList = [[self.downloadManager getAllDownloadedFilesWithExtension:@"mp3"] mutableCopy];
    NSLog(@"Song list: %@", self.songList);
}


- (void)getNewDownloads
{
    self.songList = [[self.downloadManager getAllDownloadedFilesWithExtension:@"mp3"] mutableCopy];
    [self.songsTableView reloadData];
    [self.refresh endRefreshing];
}


#pragma -mark UITableViewDelegate methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.songList count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 52;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SongTableViewCell *songCell = [tableView dequeueReusableCellWithIdentifier:@"songCell"];
    
    if(!songCell)
    {
        songCell = [[[NSBundle mainBundle] loadNibNamed:@"SongTableViewCell"
                                                  owner:self
                                                options:nil] objectAtIndex:0];
    }
    
    songCell.songLabel.text = [self.songList objectAtIndex:indexPath.row];
    
    return songCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath
                             animated:NO];
    
    SongTableViewCell *cell = (SongTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSString *songName = cell.songLabel.text;
    NSDictionary *userInfo = @{@"songName":songName};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPlayAudioNotif
                                                        object:userInfo];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        @try {
            // fill in with infor manipulation here
            NSString *fileName = [self.songList objectAtIndex:indexPath.row];
            NSString *ext = [self.downloadManager getExtensionFromFile:[self.songList objectAtIndex:indexPath.row]];
            
            NSString *newFileName = [self.downloadManager removeExtensionFromFile:fileName];        
                                     
            NSURL *url = [self.downloadManager getDownloadedFileWithName:newFileName
                                                            andExtension:ext];
            
            [self.downloadManager deleteFileWithURL:url];
            
            [self.songList removeObjectAtIndex:indexPath.row];
            [self.songsTableView deleteRowsAtIndexPaths:@[indexPath]
                                            withRowAnimation:YES];
        }
        @catch (NSException *exception) {
            NSLog(@"Error: %@", exception);
        }
        @finally {}
    }
}

#pragma mark - Navigation
/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
