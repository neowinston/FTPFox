//
//  ServerListViewController.m
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import "ServerListViewController.h"
#import "LoginViewController.h"
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
    NSURLCredential *cred = [Utilities credentialForProtectionSpace:protectionSpace];

    if ([cred hasPassword] && (NO == [[cred password] isEqualToString:@""]))
    {
        [self performSelectorOnMainThread:@selector(showActivity) withObject:nil waitUntilDone:NO];
        self.requestController = [[FTPRequestController alloc] init];
        
        self.request = [self.requestController getFileListWithInfo:nil withCompletionHandler:^(NSDictionary *complInfo) {
            if (nil != complInfo) {
                NSError *error = [complInfo valueForKey:kFileListingErrorKey];
                if (nil == error) {
                    error = [complInfo valueForKey:kLoginErrorKey];
                }
                
                if (nil != error) {
                    [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:NO];
                    NSDictionary *userInfo = [error userInfo];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[userInfo valueForKey:@"message"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        [alert show];
                    });
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
        
        NSURLCredential *cred = [Utilities credentialForProtectionSpace:protectionSpace];

        [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:cred forProtectionSpace:protectionSpace];
        
        [self.serverListArray removeObject:protectionSpace];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        if (self.serverListArray.count) {
            [[NSUserDefaults standardUserDefaults] setObject:[[self.serverListArray objectAtIndex:0] host] forKey:kCurrentHostKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            UITabBarController *tabBarCtlr = (UITabBarController *)self.parentViewController;
            FilesTableViewController *fileVC = (FilesTableViewController *)[[[[tabBarCtlr viewControllers] objectAtIndex:1] viewControllers] objectAtIndex:0];
            [fileVC serverChanged:[[self.serverListArray objectAtIndex:0] host]];
        }
        else
        {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            LoginViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            loginViewController.selectedSpace = nil;
            [self presentViewController:loginViewController animated:YES completion:^{
            }];
        }
    }
}

- (void)switchTab {
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBarController *tabBarCtlr = (UITabBarController *)self.parentViewController;
        [tabBarCtlr setSelectedIndex:1];
    });
}

#pragma mark - Private Methods

- (void)showActivity {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hudAnimator = nil;
        self.hudAnimator = [MBProgressHUD showHUDAddedTo:self.tabBarController.view animated:YES];
        self.hudAnimator.mode = MBProgressHUDModeIndeterminate;
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

- (void)cancelLoadList:(UIButton *) sender {
    [self.request cancelRequest];
    [self performSelectorOnMainThread:@selector(hideActivity) withObject:nil waitUntilDone:NO];
}

- (void)updateProgress:(NSNumber *) progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat progressValue = [progress floatValue];
        self.hudAnimator.progress = progressValue;
    });
}

@end
