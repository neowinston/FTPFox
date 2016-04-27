//
//  ServerListViewController.h
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRRequestsManager.h"


@protocol ServerListViewControllerDelegate <NSObject>

- (void)loginCompletedWithInfo:(NSDictionary *) userInfo;

@end


@interface ServerListViewController : UIViewController <GRRequestsManagerDelegate>

@property (nonatomic, weak) id<ServerListViewControllerDelegate> delegate;

@end
