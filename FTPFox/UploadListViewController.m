//
//  UploadListViewController.m
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import "UploadListViewController.h"
#import "Constants.h"
#import "FTPRequestController.h"
#import "MBProgressHUD.h"
#import "Utilities.h"

@interface UploadListViewController ()

@property (nonatomic, strong) NSDictionary *imageInfoToUpload;
@property (nonatomic, strong) NSMutableArray *uploadRequestArray;
@property (nonatomic, strong) MBProgressHUD *hudAnimator;
@property (nonatomic, strong) FTPRequestController *requestController;

@property (nonatomic, weak) id<GRDataExchangeRequestProtocol> request;
@property (nonatomic, weak) IBOutlet UITableView *uploadsTableView;

- (void)showActivity;
- (void)hideActivity;
- (void)startUpload;
- (void)relaodTable;
- (void)updateProgress:(NSDictionary *) userInfo;

- (NSString *)createImageLocallyAndGetPath;
- (NSString*)generateFileNameWithExtension:(NSString *)extensionString;
- (void)deleteRequestController:(FTPRequestController *) manager;

@end

@implementation UploadListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.uploadRequestArray = [NSMutableArray array];

    NSString *hostName = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentHostKey];
    if (nil == hostName) {
        hostName = @"Uploads";
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.uploadRequestArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *uploadReuseIdentifier = @"uploadReuseIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:uploadReuseIdentifier];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:uploadReuseIdentifier];
        UIProgressView *progressView =  [[UIProgressView alloc] initWithFrame:CGRectMake(0, 60 - 2, self.view.frame.size.width, 2)];
        progressView.tag = 321;
        [cell.contentView addSubview:progressView];
    }
    
    UIView *contentView  = [cell contentView];
    UIProgressView *progressView = [contentView viewWithTag:321];
    progressView.progress = 0.0;
    
    NSDictionary *uploadDetails = [self.uploadRequestArray objectAtIndex:indexPath.row];
    NSString *filePath = [uploadDetails valueForKey:@"LocalFilePathKey"];
    
    cell.textLabel.text = [filePath lastPathComponent];
    cell.detailTextLabel.text = filePath;
    
    cell.imageView.image  = [UIImage imageWithContentsOfFile:filePath];
    
//    UIProgressView *progressLocal = [cell.contentView viewWithTag:321];
//    progressLocal.progress = 0.0;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self deleteRequestController:self.requestController];
    }
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    if (nil != info) {
        self.imageInfoToUpload = info;
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        if (nil != self.imageInfoToUpload) {
            [self performSelectorInBackground:@selector(startUpload) withObject:nil];
        }
    }];
}

- (IBAction)uploadFile:(UIBarButtonItem *)sender {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (void)startUpload {
    NSMutableDictionary *uploadDic = [NSMutableDictionary dictionary];

    NSString *localFilePath = [self createImageLocallyAndGetPath];

    if (nil != localFilePath) {
        [uploadDic setValue:localFilePath forKey:@"LocalFilePathKey"];
        FTPRequestController *requestController = [[FTPRequestController alloc] init];
        [uploadDic setValue:requestController forKey:@"FTPRequestController"];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: localFilePath, kFilePathKey, nil];
        
        [self.uploadRequestArray addObject:uploadDic];
        
        id<GRDataExchangeRequestProtocol> request = [requestController uploadFileWithInfo:userInfo withCompletionHandler:^(NSDictionary *complInfo) {
            if (nil != complInfo) {
                NSError *error = [complInfo valueForKey:kFileListingErrorKey];
                
                if (nil == error) {
                    error = [complInfo valueForKey:kLoginErrorKey];
                }
                
                if (nil != error) {
                    FTPRequestController *oldManager = [complInfo objectForKey:kRequestManagerObjKey];
                    [self deleteRequestController:oldManager];
                    
                    NSDictionary *userInfo = [error userInfo];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[userInfo valueForKey:@"message"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                    [alert show];
                }
                else {
                    if ([complInfo objectForKey:kRequestCompleteAlertKey])
                    {
                        FTPRequestController *oldManager = [complInfo objectForKey:kRequestManagerObjKey];
                        [self deleteRequestController:oldManager];
                    }
                    else if (nil != [complInfo objectForKey:kRequestCompletePercentKey])
                    {
                        [self performSelectorOnMainThread:@selector(updateProgress:) withObject:complInfo waitUntilDone:NO];
                    }
                }
            }
        }];
        
        [uploadDic setValue:request forKey:@"UploadRequest"];
        [self relaodTable];
    }
}

- (NSString *)createImageLocallyAndGetPath {
    UIImage *imageToUpload = [self.imageInfoToUpload objectForKey:UIImagePickerControllerOriginalImage];
    NSData *imageData = UIImagePNGRepresentation(imageToUpload);
    NSString *filePath = [[Utilities documentsDirectoryPath] stringByAppendingPathComponent:[self generateFileNameWithExtension:@".png"]];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    BOOL created = [imageData writeToFile:filePath atomically:YES];
    
    if (created) {
        return filePath;
    }
    return nil;
}

- (NSString*)generateFileNameWithExtension:(NSString *)extensionString {
    extensionString = (([extensionString isEqualToString:@""] || (nil == extensionString)) ? @".png" : extensionString);
    NSDate *time = [NSDate date];
    NSDateFormatter* df = [NSDateFormatter new];
    [df setDateFormat:@"dd-MM-yyyy-hh-mm-ss"];
    NSString *timeString = [df stringFromDate:time];
    NSString *fileName = [NSString stringWithFormat:@"newFile-%@%@", timeString, extensionString];
    
    return fileName;
}

- (void)deleteRequestController:(FTPRequestController *) manager {
    
    NSMutableArray *arrayToRemove = [NSMutableArray array];
    
    for (NSDictionary *dict in self.uploadRequestArray) {
        
        FTPRequestController *oldManager = [dict valueForKey:@"FTPRequestController"];

        if ([oldManager isEqual:manager]) {
            NSString *filePath = [dict valueForKey:@"LocalFilePathKey"];
            id<GRDataExchangeRequestProtocol> request = [dict valueForKey:@"UploadRequest"];
            [request cancelRequest];
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            [arrayToRemove addObject:dict];
        }
    }

    [self.uploadRequestArray removeObjectsInArray:arrayToRemove];

    [self relaodTable];
}

- (void)updateProgress:(NSDictionary *) userInfo {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updateProgress:) withObject:userInfo waitUntilDone:NO];
    }
    
    NSDictionary *userInfoLocal = userInfo;
    
    FTPRequestController *manager = [userInfoLocal objectForKey:kRequestManagerObjKey];

    NSNumber *progress = [userInfoLocal objectForKey:kRequestCompletePercentKey];
    CGFloat progressValue = [progress floatValue];
    
    NSInteger progressIndex = -1;

    
    for (int i = 0; i < self.uploadRequestArray.count; i++) {
        NSDictionary *dict = [self.uploadRequestArray objectAtIndex:i];
        FTPRequestController *oldManager = [dict valueForKey:@"FTPRequestController"];
        if ([oldManager isEqual:manager]) {
            progressIndex = i;
        }
    }
    
    if (progressIndex >=0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UITableViewCell *cell = [self.uploadsTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:progressIndex inSection:0]];
            NSArray *cellsArray = [self.uploadsTableView visibleCells];
            
            if ([cellsArray containsObject:cell])
            {
                UIView *contentView  = [cell contentView];
                UIProgressView *progressView = [contentView viewWithTag:321];
                progressView.progress = progressValue;
                self.requestController = manager;
            }
        });
    }
}

- (void)cancelProgress:(id) sender {
    [self deleteRequestController:self.requestController];
}

- (void)showActivity {
    self.hudAnimator = nil;
    self.hudAnimator = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hudAnimator.mode = MBProgressHUDModeDeterminate;
    self.hudAnimator.label.text = NSLocalizedString(@"Loading...", @"HUD loading title");
    [self.hudAnimator.button setTitle:NSLocalizedString(@"Cancel", @"HUD cancel button title") forState:UIControlStateNormal];
    [self.hudAnimator.button addTarget:self action:@selector(cancelLoadList:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)hideActivity {
    if (self.hudAnimator) {
        [self.hudAnimator hideAnimated:YES];
    }
}

- (void)cancelLoadList:(UIButton *) sender {
    [self.request cancelRequest];
    [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:NO];
}

- (void)relaodTable {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(relaodTable) withObject:nil waitUntilDone:NO];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.uploadsTableView reloadData];
    });
}

@end
