//
//  FilesTableViewController.h
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerListViewController.h"
#import "LoginViewController.h"

@interface FilesTableViewController : UITableViewController <ServerListViewControllerDelegate, LoginViewControllerDelegate>

@end
