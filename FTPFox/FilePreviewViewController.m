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

@property (nonatomic, weak) id<GRDataExchangeRequestProtocol> request;
@property (nonatomic, strong) MBProgressHUD *hudAnimator;
@property (nonatomic, strong) FTPRequestController *requestController;
@property (weak, nonatomic) IBOutlet UIWebView *contentViewerWebView;

- (void)showActivity;
- (void)hideActivity;
- (void)updateProgress:(NSNumber *) progress;
- (void)showFilePreview;

@end

@implementation FilePreviewViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSString *hostName = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentHostKey];
    
    if (nil == hostName) {
        hostName = @"Files";
    }
    
    if (nil != self.filePath) {
        hostName = [NSString stringWithFormat:@"%@: %@", hostName, [self.filePath lastPathComponent]];
    }
    
    [self.navigationItem setTitle:hostName];

    [self showFilePreview];
}


- (void)viewDidLoad {
    [super viewDidLoad];
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
    
    self.requestController = [[FTPRequestController alloc] init];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: self.filePath, kFilePathKey, nil];

    self.request = [self.requestController downloadFileWithInfo:userInfo withCompletionHandler:^(NSDictionary *complInfo) {
        if (nil != complInfo) {
            NSError *error = [complInfo valueForKey:kFileListingErrorKey];
            
            if (nil == error) {
                error = [complInfo valueForKey:kLoginErrorKey];
            }
            
            if (nil != error) {
                [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:NO];
                NSDictionary *userInfo = [error userInfo];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[userInfo valueForKey:@"message"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
            }
            else {
                if ([complInfo objectForKey:kRequestCompleteAlertKey])
                {
                    [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:NO];

                    NSString *localFilePath = [self.request  localFilePath];
                    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:localFilePath]];
                    [self.contentViewerWebView loadRequest:request];
                }
                else if (nil != [complInfo objectForKey:kRequestCompletePercentKey])
                {
                    NSNumber *progress = [complInfo objectForKey:kRequestCompletePercentKey];
                    if (nil != progress) {
                        [self performSelectorOnMainThread:@selector(updateProgress:) withObject:progress waitUntilDone:NO];
                    }
                }
            }
        }
    }];
}

- (void)updateProgress:(NSNumber *) progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progressValue = [progress floatValue];
        self.hudAnimator.progress = progressValue;
    });
}

- (void)showActivity {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hudAnimator = nil;
        self.hudAnimator = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
        self.hudAnimator.mode = MBProgressHUDModeAnnularDeterminate;
        self.hudAnimator.label.text = NSLocalizedString(@"Loading...", @"HUD loading title");
        [self.hudAnimator.button setTitle:NSLocalizedString(@"Cancel", @"HUD cancel button title") forState:UIControlStateNormal];
        [self.hudAnimator.button addTarget:self action:@selector(cancelLoadList:) forControlEvents:UIControlEventTouchUpInside];
    });
}

- (void)hideActivity {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.hudAnimator) {
            [self.hudAnimator hideAnimated:YES];
        }
    });
}

@end