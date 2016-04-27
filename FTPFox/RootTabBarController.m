//
//  RootTabBarController.m
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import "RootTabBarController.h"
#import "LoginViewController.h"
#import "FilesTableViewController.h"
#import "ServerListViewController.h"

@interface RootTabBarController ()

- (void)tabSelectedAtIndex:(NSUInteger)selectedIndex;

@end

@implementation RootTabBarController

- (id)init {
    if (self = [super init]) {
        self.delegate = self;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setSelectedIndex:0];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    return YES;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [super setSelectedIndex:selectedIndex];
    [self tabSelectedAtIndex:selectedIndex];
}

- (void)tabSelectedAtIndex:(NSUInteger)selectedIndex {
    UINavigationController *navCtlr = [[self viewControllers] objectAtIndex:1];
    FilesTableViewController *fileListVC = [[navCtlr viewControllers] objectAtIndex:0];
    ServerListViewController *serversListVC = [[self viewControllers] objectAtIndex:0];
    serversListVC.delegate = fileListVC;
    
    NSDictionary *allCred = [[NSURLCredentialStorage sharedCredentialStorage] allCredentials];
    if (nil == allCred || allCred.count <= 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        LoginViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        loginViewController.selectedSpace = nil;
        loginViewController.delegate  = fileListVC;
        [self presentViewController:loginViewController animated:YES completion:^{
        }];
    }
    
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    [self tabSelectedAtIndex:tabBarController.selectedIndex];
}


@end
