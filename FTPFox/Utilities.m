//
//  Utilities.m
//  MyTeam
//
//  Created by Nilesh Jaiswal on 4/8/16.
//  Copyright © 2016 Oracle. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

+ (BOOL)isModal:(UIViewController *) vc {
    
    BOOL retValue = NO;
    
    if([vc presentingViewController])
    {
        retValue =  YES;
    }
    else if([[vc presentingViewController] presentedViewController] == vc)
    {
        retValue =  YES;
    }
    else if([[[vc navigationController] presentingViewController] presentedViewController] == [vc navigationController])
    {
        retValue =  YES;
        
    }
    else if([[[vc tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]])
    {
        retValue =  YES;
    }
    else
    {
        retValue = NO;
    }
    
    return retValue;
}

+ (NSString *)documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    return documentsPath;
}

+ (NSURL *)documentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (NSURLProtectionSpace *)protectionSpaceForHost:(NSString *) string {
    NSURLProtectionSpace *protectionSpace = nil;
    NSURL *url = [NSURL URLWithString:string];
    
    if (nil != url) {
        
        NSString *protocol = [url scheme];
        int port = 80;
        
        if (nil != protocol)
        {
            if([protocol caseInsensitiveCompare:@"sftp"] == NSOrderedSame )
            {
                port = 443;
            }
        }
        else
        {
            protocol = @"ftp";
        }
        
        NSString *host = [url host];
        if (nil == host) {
            host = [url absoluteString];
        }
        
        protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:host port:port protocol:protocol realm:@"Protected Area" authenticationMethod:NSURLAuthenticationMethodHTTPBasic];
    }
    
    return protectionSpace;
}

+ (NSString *)generateFileNameWithExtension:(NSString *)extensionString {
    
    if ([extensionString rangeOfString:@"."].location == NSNotFound) {
        extensionString = [NSString stringWithFormat:@".%@", extensionString];
    }
    
    extensionString = (([extensionString isEqualToString:@""] || (nil == extensionString)) ? @".png" : extensionString);
    NSDate *time = [NSDate date];
    NSDateFormatter* df = [NSDateFormatter new];
    [df setDateFormat:@"dd-MM-yyyy-hh-mm-ss"];
    NSString *timeString = [df stringFromDate:time];
    NSString *fileName = [NSString stringWithFormat:@"newFile-%@%@", timeString, extensionString];
    
    return fileName;
}


@end
