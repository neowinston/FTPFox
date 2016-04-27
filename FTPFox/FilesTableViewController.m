//
//  FilesTableViewController.m
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import "FilesTableViewController.h"
#import "Constants.h"

@interface FilesTableViewController ()

@property(nonatomic, strong) NSArray *fileListArray;

@end

@implementation FilesTableViewController
@synthesize fileListArray = _fileListArray;

- (id)init {
    if (self = [super init]) {
        self.fileListArray = [NSArray array];
    }
    return self;
}

- (void)viewDidLoad {
    NSString *hostName = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentHostKey];
    
    if (nil == hostName) {
        hostName = @"Files";
    }
    
    [self.navigationItem setTitle:hostName];
    [super viewDidLoad];
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
    return self.fileListArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *fileNameReuseIdentifier = @"fileNameReuseIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:fileNameReuseIdentifier forIndexPath:indexPath];
    
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:fileNameReuseIdentifier];
    }
    
    cell.textLabel.text = [self.fileListArray objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    
//    NSURLProtectionSpace *protectionSpace = [self.fileListArray objectAtIndex:indexPath.row];
//    
//    NSDictionary *credDic = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protectionSpace];
//    NSArray *userNameArray = [credDic allKeys];
//    NSURLCredential *cred = [credDic objectForKey:[userNameArray objectAtIndex:0]];
//    
//    if ([cred hasPassword])
//    {
//        self.requestsManager = [[GRRequestsManager alloc] initWithHostname:[protectionSpace host]
//                                                                      user:[cred user]
//                                                                  password:[cred password]];
//        self.requestsManager.delegate = self;
//        [self.requestsManager addRequestForListDirectoryAtPath:@"/"];
//        [self.requestsManager startProcessingRequests];
//    }
//    else
//    {
//        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//        LoginViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
//        loginViewController.selectedSpace = protectionSpace;
//        [self presentViewController:loginViewController animated:YES completion:^{
//        }];
//    }
}


- (void)loginCompletedWithInfo:(NSDictionary *) userInfo {
    
    if ((nil != [userInfo objectForKey:kLoginErrorKey]) || (nil != [userInfo objectForKey:kFileListingErrorKey]))
    {
        
    }
    else if (nil != [userInfo objectForKey:kFileListArrayKey])
    {
        self.fileListArray = [userInfo objectForKey:kFileListArrayKey];
        [self.tableView reloadData];
    }
}

@end
