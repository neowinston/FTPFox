//
//  FilePreviewViewController.m
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import "FilePreviewViewController.h"
#import "FTPRequestController.h"
#import "MBProgressHUD.h"
#import "Constants.h"
#import "Utilities.h"

@interface FilePreviewViewController ()

@property (nonatomic, weak) id<GRRequestProtocol> request;
@property (nonatomic, strong) MBProgressHUD *hudAnimator;
@property (nonatomic, strong) UIWebView *contentViewer;

- (void)showActivity;
- (void)hideActivity;
- (void)showFilePreview;

@end

@implementation FilePreviewViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showFilePreview];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.contentViewer = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.contentViewer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)cancelLoadList:(UIButton *) sender {
    [self.request cancelRequest];
    [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:NO];
}

- (void)showFilePreview {
    [self performSelectorOnMainThread:@selector(showActivity) withObject:nil waitUntilDone:NO];
    
    FTPRequestController *requestController = [[FTPRequestController alloc] init];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: self.filePath, kFilePathKey, nil];

    self.request = [requestController downloadFileWithInfo:userInfo withCompletionHandler:^(NSDictionary *complInfo) {
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
                NSString *localFilePath = [[Utilities documentsDirectoryPath] stringByAppendingPathComponent:@"DownloadedFile.txt"];
                NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:localFilePath]];
                [self.contentViewer loadRequest:request];
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

@end