//
//  FTPRequestController.h
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GRRequestProtocol.h"

typedef void(^completionGetList)(NSDictionary *);
typedef void(^completionDownloadFile)(NSDictionary *);
typedef void(^completionUploadFile)(NSDictionary *);


@interface FTPRequestController : NSObject

- (id<GRRequestProtocol>)getFileListWithInfo:(NSDictionary *) userInfo withCompletionHandler:(completionGetList) callback;
- (id<GRRequestProtocol>)downloadFileWithInfo:(NSDictionary *) userInfo withCompletionHandler:(completionDownloadFile) callback;
- (id<GRRequestProtocol>)uploadFileWithInfo:(NSDictionary *) userInfo withCompletionHandler:(completionUploadFile) callback;

@end
