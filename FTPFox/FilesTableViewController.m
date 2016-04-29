//
//  FilesTableViewController.m
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import "FilesTableViewController.h"
#import "Constants.h"
#import "FilePreviewViewController.h"

@interface FilesTableViewController ()

@property(nonatomic, strong) NSArray *fileListArray;

@end

@implementation FilesTableViewController
@synthesize fileListArray = _fileListArray;

- (id)init {
    if (self = [super init]) {
        self.fileListArray = [NSArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *hostName = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentHostKey];
    if (nil == hostName) {
        hostName = @"Files";
    }
    
    [self.navigationItem setTitle:hostName];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fileListArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *fileNameReuseIdentifier = @"fileNameReuseIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:fileNameReuseIdentifier forIndexPath:indexPath];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:fileNameReuseIdentifier];
    }
    
    cell.textLabel.text = [self.fileListArray objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UITableViewCell *slectedCell = nil;
    NSIndexPath *indexPath = nil;
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        slectedCell = (UITableViewCell *)sender;
        indexPath = [self.tableView indexPathForCell:slectedCell];
    }
    
    UIViewController *vc = [segue destinationViewController];
    FilePreviewViewController *filePreviewViewController = nil;
    
    if ([vc isKindOfClass:[FilePreviewViewController class]])
    {
        filePreviewViewController = (FilePreviewViewController *)vc;
        filePreviewViewController.filePath = @"";
        
        NSString *hostName = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentHostKey];
        if (nil != hostName) {
            filePreviewViewController.filePath = [NSString stringWithFormat:@"ftp://%@/%@", hostName, [self.fileListArray objectAtIndex:indexPath.row]];
        }
    }
}

- (void)loginCompletedWithInfo:(NSDictionary *) userInfo {
    
    if ((nil != [userInfo objectForKey:kLoginErrorKey]) || (nil != [userInfo objectForKey:kFileListingErrorKey]))
    {
        
    }
    else if (nil != [userInfo objectForKey:kFileListArrayKey])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.fileListArray = [userInfo objectForKey:kFileListArrayKey];
            [self.tableView reloadData];
        });
    }
}

@end
