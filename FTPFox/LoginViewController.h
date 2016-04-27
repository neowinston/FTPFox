//
//  LoginViewController.h
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRRequestsManager.h"

@protocol LoginViewControllerDelegate <NSObject>

- (void)loginCompletedWithInfo:(NSDictionary *) userInfo;

@end

@interface LoginViewController : UIViewController <GRRequestsManagerDelegate> {
    
}

@property (nonatomic, weak) id<LoginViewControllerDelegate> delegate;
@property (nonatomic, strong) NSURLProtectionSpace *selectedSpace;

@end
