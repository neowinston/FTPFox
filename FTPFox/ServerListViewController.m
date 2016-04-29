//
//  ServerListViewController.m
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import "ServerListViewController.h"
#import "Constants.h"
#import "GRRequestProtocol.h"
#import "LoginViewController.h"
#import "MBProgressHUD.h"
#import "FTPRequestController.h"
#import "FilesTableViewController.h"

@interface ServerListViewController () {
    
}

@property (nonatomic, strong) NSMutableArray *serverListArray;
@property (weak, nonatomic) IBOutlet UITableView *serverListTableView;
@property (nonatomic, strong) MBProgressHUD *hudAnimator;
@property (nonatomic, weak) id<GRRequestProtocol> request;
@property (nonatomic, strong) FTPRequestController *requestController;


- (void)showActivity;
- (void)hideActivity;
- (void)updateProgress:(NSNumber *) progress;

@end

@implementation ServerListViewController
@synthesize serverListArray = _serverListArray;
@synthesize serverListTableView = _serverListTableView;


- (id)init {
    if (self = [super init]) {
        self.serverListArray = [NSMutableArray array];
        self.serverListTableView = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSDictionary *credentialsDict = [[NSURLCredentialStorage sharedCredentialStorage] allCredentials];
    self.serverListArray = [[credentialsDict allKeys] mutableCopy];
    [self.serverListTableView reloadData];
    
//    if ([credentialsDict count] > 0) {
//        // the credentialsDict has NSURLProtectionSpace objs as keys and dicts of userName => NSURLCredential
//        NSEnumerator *protectionSpaceEnumerator = [credentialsDict keyEnumerator];
//        id urlProtectionSpace;
//        
//        // iterate over all NSURLProtectionSpaces
//        while (urlProtectionSpace = [protectionSpaceEnumerator nextObject]) {
//            NSEnumerator *userNameEnumerator = [[credentialsDict objectForKey:urlProtectionSpace] keyEnumerator];
//            id userName;
//            
//            // iterate over all usernames for this protectionspace, which are the keys for the actual NSURLCredentials
//            while (userName = [userNameEnumerator nextObject]) {
//                NSURLCredential *cred = [[credentialsDict objectForKey:urlProtectionSpace] objectForKey:userName];
//                NSLog(@"cred to be removed: %@", cred);
//                [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:cred forProtectionSpace:urlProtectionSpace];
//            }
//        }
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.serverListArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *fileNameReuseIdentifier = @"fileNameReuseIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:fileNameReuseIdentifier];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:fileNameReuseIdentifier];
    }

    NSString *hostName = [[self.serverListArray objectAtIndex:indexPath.row] host];
    if ([hostName isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:kCurrentHostKey]])
    {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else
    {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    cell.textLabel.text = hostName;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSURLProtectionSpace *protectionSpace = [self.serverListArray objectAtIndex:indexPath.row];

    NSDictionary *credDic = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protectionSpace];
    NSArray *userNameArray = [credDic allKeys];
    NSURLCredential *cred = [credDic objectForKey:[userNameArray objectAtIndex:0]];

    if ([cred hasPassword] && (NO == [[cred password] isEqualToString:@""]))
    {
        [self performSelectorOnMainThread:@selector(showActivity) withObject:nil waitUntilDone:NO];
        
        self.requestController = [[FTPRequestController alloc] init];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[protectionSpace host], kCurrentHostKey,  [cred user], kCurrentUserKey, [cred password], kCurrentPasswordKey, nil];
        
        self.request = [self.requestController getFileListWithInfo:userInfo withCompletionHandler:^(NSDictionary *complInfo) {
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
                else
                {
                    if ([complInfo objectForKey:kRequestCompleteAlertKey])
                    {
                        [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:NO];

                        [self performSelectorOnMainThread:@selector(switchTab) withObject:nil waitUntilDone:NO];
                        UITabBarController *tabBarCtlr = (UITabBarController *)self.parentViewController;
                        UINavigationController *navController = [[tabBarCtlr viewControllers] objectAtIndex:1];
                        FilesTableViewController *filesVC = [[navController viewControllers] objectAtIndex:0];
                        [filesVC loginCompletedWithInfo:complInfo];
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
    else
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LoginViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        loginViewController.selectedSpace = protectionSpace;
        [self presentViewController:loginViewController animated:YES completion:^{
        }];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSString *hostName = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentHostKey];
        NSURLProtectionSpace *protectionSpace = [self.serverListArray objectAtIndex:indexPath.row];

        if ([hostName isEqualToString:[protectionSpace host]]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentHostKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        [self.serverListArray removeObject:protectionSpace];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)switchTab {
    UITabBarController *tabBarCtlr = (UITabBarController *)self.parentViewController;
    [tabBarCtlr setSelectedIndex:1];
}

#pragma mark - Private Methods

- (void)showActivity {
    self.hudAnimator = nil;
    self.hudAnimator = [MBProgressHUD showHUDAddedTo:self.tabBarController.view animated:YES];
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

- (void)updateProgress:(NSNumber *) progress {
    CGFloat progressValue = [progress floatValue];
    self.hudAnimator.progress = progressValue;
}

@end
