//
//  LoginViewController.m
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import "LoginViewController.h"
#import "GRRequestProtocol.h"
#import "Constants.h"
#import "Utilities.h"
#import "FTPRequestController.h"
#import "MBProgressHUD.h"
#import "FilesTableViewController.h"

@interface LoginViewController() {
    
}

@property (nonatomic, assign) BOOL isSavePasswordEnabled;
@property (nonatomic, weak) id<GRRequestProtocol> request;
@property (nonatomic, strong) MBProgressHUD *hudAnimator;
@property (nonatomic, strong) FTPRequestController *requestController;

@property (weak, nonatomic) IBOutlet UITextField *serverTextField;
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UISwitch *savePasswordSwitch;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

- (IBAction)loginButtonClicked:(UIButton *)sender;
- (IBAction)cancelButtonClicked:(UIBarButtonItem *)sender;
- (IBAction)savePwdValueChange:(UISwitch *)sender;

- (void)showActivity;
- (void)hideActivity;

@end

@implementation LoginViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.isSavePasswordEnabled = self.savePasswordSwitch.isOn;
    
    if (nil != self.selectedSpace)
    {
        NSURLProtectionSpace *protectionSpace = self.selectedSpace;
        NSDictionary *credDic = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protectionSpace];
        NSArray *userNameArray = [credDic allKeys];
        NSURLCredential *cred = [credDic objectForKey:[userNameArray objectAtIndex:0]];
        
        self.userNameTextField.text = [cred user];
        self.passwordTextField.text = ([cred password] != nil) ? [cred password] : @"";
        self.serverTextField.text = [protectionSpace host];
    }
    else
    {
//        self.userNameTextField.text = @"eauusers";
//        self.passwordTextField.text = @"YTNhOTNmYTAwOTljYmFmMDlhMTJlODVl";
//        self.serverTextField.text = @"ftp://52.26.67.76";
    }
}

- (void)cancelLoadList:(UIButton *) sender {
    [self.request cancelRequest];
    [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:NO];
}

- (IBAction)loginButtonClicked:(UIButton *)sender {
    [self performSelectorOnMainThread:@selector(showActivity) withObject:nil waitUntilDone:NO];

    self.requestController = [[FTPRequestController alloc] init];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.serverTextField.text, kCurrentHostKey,  self.userNameTextField.text, kCurrentUserKey, self.passwordTextField.text, kCurrentPasswordKey, [NSNumber numberWithBool:self.isSavePasswordEnabled], kSavePasswordEnabledKey, nil];
    
    self.request = [self.requestController getFileListWithInfo:userInfo withCompletionHandler:^(NSDictionary *complInfo) {
        [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:NO];
        
        if (nil != complInfo) {
            NSError *error = [complInfo valueForKey:kFileListingErrorKey];
            
            if (nil == error) {
                error = [complInfo valueForKey:kLoginErrorKey];
            }
            
            if (nil != error)
            {
                NSDictionary *userInfo = [error userInfo];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[userInfo valueForKey:@"message"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
            }
            else
            {
                if ([complInfo objectForKey:kRequestCompleteAlertKey])
                {
                    UITabBarController *tabBarCtlr = (UITabBarController *)self.presentingViewController;
                    [self performSelectorOnMainThread:@selector(switchTab) withObject:nil waitUntilDone:NO];
                    UINavigationController *navController = [[tabBarCtlr viewControllers] objectAtIndex:1];
                    FilesTableViewController *filesVC = [[navController viewControllers] objectAtIndex:0];
                    [filesVC loginCompletedWithInfo:complInfo];
                    
                    [self dismissViewControllerAnimated:YES completion:^{
                    }];
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

- (void)switchTab {
    UITabBarController *tabBarCtlr = (UITabBarController *)self.presentingViewController;
    [tabBarCtlr setSelectedIndex:1];
}

- (IBAction)cancelButtonClicked:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (IBAction)savePwdValueChange:(UISwitch *)sender {
    self.isSavePasswordEnabled = self.savePasswordSwitch.isOn;
}

- (void)showActivity {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hudAnimator = nil;
        self.hudAnimator = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hudAnimator.mode = MBProgressHUDModeDeterminate;
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

- (void)updateProgress:(NSNumber *) progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progressValue = [progress floatValue];
        self.hudAnimator.progress = progressValue;
    });
}

#pragma mark - UITextField Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *username = self.userNameTextField.text;
    NSString *password = self.passwordTextField.text;
    NSString *host = self.serverTextField.text;

    if ([textField isEqual:self.userNameTextField]) {
        username = [textField.text stringByReplacingCharactersInRange:range withString:string];
    }
    else if ([textField isEqual:self.serverTextField]) {
        host = [textField.text stringByReplacingCharactersInRange:range withString:string];
    }
    else if ([textField isEqual:self.passwordTextField]) {
        password = [textField.text stringByReplacingCharactersInRange:range withString:string];
    }
    
    if ((NO == [username isEqualToString:@""]) && (NO == [password isEqualToString:@""]) && (NO == [host isEqualToString:@""]))
    {
        self.loginButton.enabled = YES;
    }
    else
    {
        self.loginButton.enabled = NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField  {
    [textField resignFirstResponder];
    return YES;
}

@end
