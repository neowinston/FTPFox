//
//  FTPRequestController.h
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GRRequestProtocol.h"


@interface FTPRequestController : NSObject  {
    
}

typedef void(^completionGetList)(NSDictionary *);
typedef void(^completionDownloadFile)(NSDictionary *);
typedef void(^completionUploadFile)(NSDictionary *);


- (id<GRRequestProtocol>)getFileListWithInfo:(NSDictionary *) userInfo withCompletionHandler:(completionGetList) callback;
- (id<GRDataExchangeRequestProtocol>)downloadFileWithInfo:(NSDictionary *) userInfo withCompletionHandler:(completionDownloadFile) callback;
- (id<GRDataExchangeRequestProtocol>)uploadFileWithInfo:(NSDictionary *) userInfo withCompletionHandler:(completionUploadFile) callback;

@end
