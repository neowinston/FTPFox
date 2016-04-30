//
//  Utilities.h
//  MyTeam
//
//  Created by Nilesh Jaiswal on 4/8/16.
//  Copyright © 2016 Oracle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface Utilities : NSObject

+ (BOOL)isModal:(UIViewController *) vc;
+ (NSURL *)documentsDirectory;
+ (NSString *)documentsDirectoryPath;
+ (NSURLProtectionSpace *)protectionSpaceForHost:(NSString *) string;
+ (NSString *)generateFileNameWithExtension:(NSString *)extensionString;

@end
