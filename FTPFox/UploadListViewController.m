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

@property(nonatomic, strong) NSDictionary *imageInfoToUpload;
@property (nonatomic, weak) id<GRRequestProtocol> request;
@property (nonatomic, strong) MBProgressHUD *hudAnimator;
@property (nonatomic, strong) NSMutableArray *uploadingImagesArray;
@property (weak, nonatomic) IBOutlet UITableView *uploadsTableView;

- (void)showActivity;
- (void)hideActivity;
- (void)startUpload;

@end

@implementation UploadListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.uploadingImagesArray = [NSMutableArray array];
    
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.uploadingImagesArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *uploadReuseIdentifier = @"uploadReuseIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:uploadReuseIdentifier];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:uploadReuseIdentifier];
    }
    
    NSDictionary *imageInfo = [self.uploadingImagesArray objectAtIndex:indexPath.row];
    UIImage *imageToUpload = [imageInfo objectForKey:UIImagePickerControllerOriginalImage];
    NSURL *imageURLToUpload = [imageInfo objectForKey:UIImagePickerControllerMediaURL];

    cell.textLabel.text = [imageURLToUpload lastPathComponent];
    cell.imageView.image = imageToUpload;
    cell.detailTextLabel.text = [imageURLToUpload absoluteString];
    [cell.detailTextLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progressView.frame = CGRectMake(0, 34, self.view.frame.size.width, 10);
    progressView.tag = 101;
    progressView.progress = 0.33;
    [cell.contentView addSubview:progressView];
    
    return cell;
}


#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    if (nil != info) {
        self.imageInfoToUpload = info;
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        if (nil != self.imageInfoToUpload) {
            [self startUpload];
        }
    }];
}

- (IBAction)uploadFile:(UIBarButtonItem *)sender {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (void)startUpload {
    [self performSelectorOnMainThread:@selector(showActivity) withObject:nil waitUntilDone:NO];
    
    UIImage *imageToUpload = [self.imageInfoToUpload objectForKey:UIImagePickerControllerOriginalImage];
    NSURL *imageURLToUpload = [self.imageInfoToUpload objectForKey:UIImagePickerControllerMediaURL];
    
    [self.uploadingImagesArray  addObject:self.imageInfoToUpload];
    [self.uploadsTableView reloadData];

    FTPRequestController *requestController = [[FTPRequestController alloc] init];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: [imageURLToUpload absoluteString], kFilePathKey, nil];
    
    self.request = [requestController uploadFileWithInfo:userInfo withCompletionHandler:^(NSDictionary *complInfo) {
        [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:NO];
        
        if (nil != complInfo) {
            NSError *error = [complInfo valueForKey:kFileListingErrorKey];
            
            if (nil == error) {
                error = [complInfo valueForKey:kLoginErrorKey];
            }
            
            if (nil != error) {
                NSDictionary *userInfo = [error userInfo];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[userInfo valueForKey:@"message"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
            }
            else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Upload completed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
                
                [self.uploadingImagesArray removeObject:self.imageInfoToUpload];
                [self.uploadsTableView reloadData];
            }
        }
    }];
}

- (void)showActivity {
    self.hudAnimator = nil;
    self.hudAnimator = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    self.hudAnimator.mode = MBProgressHUDModeIndeterminate;
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


@end
