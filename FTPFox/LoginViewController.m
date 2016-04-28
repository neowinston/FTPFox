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

@interface LoginViewController() {
    
}

@property (nonatomic, strong) GRRequestsManager *requestsManager;
@property (nonatomic, assign) BOOL isSavePasswordEnabled;
@property (nonatomic, weak) id<GRRequestProtocol> request;
@property (nonatomic, strong) MBProgressHUD *hudAnimator;


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
        self.userNameTextField.text = @"eauusers";
        self.passwordTextField.text = @"YTNhOTNmYTAwOTljYmFmMDlhMTJlODVl";
        self.serverTextField.text = @"ftp://52.26.67.76";
    }
}

- (void)cancelLoadList:(UIButton *) sender {
    [self.request cancelRequest];
    [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:NO];
}

- (IBAction)loginButtonClicked:(UIButton *)sender {
    [self performSelectorOnMainThread:@selector(showActivity) withObject:nil waitUntilDone:NO];

    FTPRequestController *requestController = [[FTPRequestController alloc] init];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self.serverTextField.text, kCurrentHostKey,  self.userNameTextField.text, kCurrentUserKey, self.passwordTextField.text, kCurrentPasswordKey, [NSNumber numberWithBool:self.isSavePasswordEnabled], kSavePasswordEnabledKey, nil];
    
    self.request = [requestController getFileListWithInfo:userInfo withCompletionHandler:^(NSDictionary *complInfo) {
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
        }
    }];
}

- (IBAction)cancelButtonClicked:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (IBAction)savePwdValueChange:(UISwitch *)sender {
    self.isSavePasswordEnabled = self.savePasswordSwitch.isOn;
}

- (void)showActivity {
    self.hudAnimator = nil;
    self.hudAnimator = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
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

@end
