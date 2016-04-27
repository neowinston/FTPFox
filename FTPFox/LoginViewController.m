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

@interface LoginViewController() {
}

@property (nonatomic, strong) GRRequestsManager *requestsManager;

@property (weak, nonatomic) IBOutlet UITextField *serverTextField;
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

- (IBAction)loginButtonClicked:(UIButton *)sender;
- (IBAction)cancelButtonClicked:(UIBarButtonItem *)sender;
- (IBAction)savePwdValueChange:(UISwitch *)sender;

@end

@implementation LoginViewController

- (id)initWithUserCredential:(NSURLProtectionSpace *) protectionSpace {
    if (self = [super init]) {
        self.selectedSpace = protectionSpace;
    }
    return self;
}

- (IBAction)loginButtonClicked:(UIButton *)sender {
    
    self.requestsManager = [[GRRequestsManager alloc] initWithHostname:self.serverTextField.text
                                                                  user:self.userNameTextField.text
                                                              password:self.passwordTextField.text];

    self.requestsManager.delegate = self;
    [self.requestsManager addRequestForListDirectoryAtPath:@"/"];
    [self.requestsManager startProcessingRequests];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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

- (IBAction)cancelButtonClicked:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (IBAction)savePwdValueChange:(UISwitch *)sender {
}

#pragma mark - GRRequestsManagerDelegate

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didScheduleRequest:(id<GRRequestProtocol>)request {
    NSLog(@"requestsManager:didScheduleRequest:");
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteListingRequest:(id<GRRequestProtocol>)request listing:(NSArray *)listing {
    NSLog(@"requestsManager:didCompleteListingRequest:listing: \n%@", listing);
    
    if (nil != listing)
    {
        [(UITabBarController *)self.parentViewController setSelectedIndex:1];

        NSString *hostUrl = [request hostString];
        [[NSUserDefaults standardUserDefaults] setObject:hostUrl forKey:kCurrentHostKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSURLCredential *credential = [NSURLCredential credentialWithUser:self.userNameTextField.text
                                                                 password:self.passwordTextField.text
                                                              persistence:NSURLCredentialPersistencePermanent];
        NSURLProtectionSpace *protectionSpace = [Utilities protectionSpaceForHost:self.serverTextField.text];
        [[NSURLCredentialStorage sharedCredentialStorage] setCredential:credential forProtectionSpace:protectionSpace];
        
        [self.delegate loginCompletedWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:listing, kFileListArrayKey, nil]];
    }
    else
    {
        NSError *error = [NSError errorWithDomain:kNetworkErrorDomain code:FileListingErrorCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error in file listing", @"message", nil]];
        [self.delegate loginCompletedWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, kFileListingErrorKey, nil]];
    }
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailRequest:(id<GRRequestProtocol>)request withError:(NSError *)error {
    NSLog(@"requestsManager:didFailRequest:withError: \n %@", error);
    [self.delegate loginCompletedWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, kLoginErrorKey, nil]];
}

@end
