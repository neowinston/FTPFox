//
//  UploadListViewController.h
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UploadListViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

- (IBAction)uploadFile:(UIBarButtonItem *)sender;

@end
