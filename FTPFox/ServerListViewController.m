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
#import "GRRequestsManager.h"

@interface ServerListViewController () {
    
}

@property (nonatomic, strong) GRRequestsManager *requestsManager;
@property (nonatomic, strong) NSArray *serverListArray;
@property (weak, nonatomic) IBOutlet UITableView *serverListTableView;

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
    self.serverListArray = [credentialsDict allKeys];
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
    // Dispose of any resources that can be recreated.
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

    if ([cred hasPassword])
    {
        self.requestsManager = [[GRRequestsManager alloc] initWithHostname:[protectionSpace host]
                                                                      user:[cred user]
                                                                  password:[cred password]];
        self.requestsManager.delegate = self;
        [self.requestsManager addRequestForListDirectoryAtPath:@"/"];
        [self.requestsManager startProcessingRequests];
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
