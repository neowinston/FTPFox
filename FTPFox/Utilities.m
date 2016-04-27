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
        
        protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:[url host] port:port protocol:protocol realm:@"Protected Area" authenticationMethod:NSURLAuthenticationMethodHTTPBasic];
    }
    
    return protectionSpace;
}


@end
