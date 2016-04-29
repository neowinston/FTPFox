//
//  Constants.h
//  MyTeam
//
//  Created by Nilesh Jaiswal on 4/8/16.
//  Copyright © 2016 Oracle. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FileListingErrorCode                1883001


@interface Constants : NSObject

extern NSString *const  kNetworkErrorDomain;

extern NSString *const  kCurrentHostKey;
extern NSString *const  kCurrentUserKey;
extern NSString *const  kCurrentPasswordKey;

extern NSString *const  kSavePasswordEnabledKey;


extern NSString *const  kFileListArrayKey;
extern NSString *const  kFileListingErrorKey;
extern NSString *const  kLoginErrorKey;
extern NSString *const  kDownloadErrorKey ;
extern NSString *const  kUploadErrorKey;

extern NSString *const  kRequestCompletePercentKey;

extern NSString *const  kRequestCompleteAlertKey;

extern NSString *const  kFilePathKey;

extern NSString *const  kRequestManagerObjKey;


@end
