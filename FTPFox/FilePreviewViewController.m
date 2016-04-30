//
//  FilePreviewViewController.m
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

@import ImageIO;

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
- (BOOL)isImageSourec:(NSString *)imagePath;
- (void)addImageViewWithImagePath:(NSString *) imagePath;
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
                    NSString *localFilePath = [self.request localFilePath];
                    
                    if ([[NSFileManager defaultManager] fileExistsAtPath:localFilePath])
                    {
                        [[self.view viewWithTag:1010] removeFromSuperview];

                        if ([self isImageSourec:localFilePath])
                        {
//                            self.contentViewerWebView.hidden = YES;
//                            [self addImageViewWithImagePath:localFilePath];
                            
                            NSURL * file = [NSURL URLWithString:localFilePath relativeToURL:[Utilities documentsDirectory]];
                            NSURL * absoluteFileString = [file absoluteURL];
                            
                            NSString *imageHTML = [[NSString alloc] initWithFormat:@"%@%@%@", @"<!DOCTYPE html>"
                                                   "<html lang=\"ja\">"
                                                   "<head>"
                                                   "<meta charset=\"UTF-8\">"
                                                   "<style type=\"text/css\">"
                                                   "html{margin:0;padding:0;}"
                                                   "body {"
                                                   "margin: 0;"
                                                   "padding: 0;"
                                                   "color: #363636;"
                                                   "font-size: 90%;"
                                                   "line-height: 1.6;"
                                                   "background: black;"
                                                   "}"
                                                   "img{"
                                                   "position: absolute;"
                                                   "top: 0;"
                                                   "bottom: 0;"
                                                   "left: 0;"
                                                   "right: 0;"
                                                   "margin: auto;"
                                                   "max-width: 100%;"
                                                   "max-height: 100%;"
                                                   "}"
                                                   "</style>"
                                                   "</head>"
                                                   "<body id=\"page\">"
                                                   "<img src='",absoluteFileString,@"'/> </body></html>"];
                            
                            [self.contentViewerWebView loadHTMLString:imageHTML baseURL:nil];
                        }
                        else
                        {
                            self.contentViewerWebView.hidden = NO;
                            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:localFilePath]];
                            [self.contentViewerWebView loadRequest:request];
                        }
                    }
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


- (void)addImageViewWithImagePath:(NSString *) imagePath {
    
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.tag = 1010;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    imageView.frame = self.view.bounds;
    [self.view addSubview:imageView];
    
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:imageView
                                                                        attribute:NSLayoutAttributeBottom
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.view
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0
                                                                         constant:0];
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:imageView
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.view
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0];
    NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint constraintWithItem:imageView
                                                                         attribute:NSLayoutAttributeLeading
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeLeading
                                                                        multiplier:1.0
                                                                          constant:0];
    NSLayoutConstraint *traillingConstraint = [NSLayoutConstraint constraintWithItem:imageView
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.view
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:0];
    
    [self.view addConstraints:@[bottomConstraint, topConstraint, leadingConstraint,  traillingConstraint]];
}

- (BOOL)isImageSourec:(NSString *)imagePath{
    
    NSString *ext = [imagePath pathExtension];
    
    return (([ext caseInsensitiveCompare:@"png"] == NSOrderedSame) ||
            ([ext caseInsensitiveCompare:@"jpg"] == NSOrderedSame) ||
            ([ext caseInsensitiveCompare:@"jpeg"] == NSOrderedSame) ||
            ([ext caseInsensitiveCompare:@"tgt"] == NSOrderedSame) ||
            ([ext caseInsensitiveCompare:@"gig"] == NSOrderedSame));
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