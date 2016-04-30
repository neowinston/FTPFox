//
//  FTPRequestController.m
//  FTPFox
//
//  Created by Nilesh Jaiswal on 4/27/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import "FTPRequestController.h"
#import "GRRequestsManager.h"
#import "Constants.h"
#import "Utilities.h"

@interface FTPRequestController () <GRRequestsManagerDelegate> {
    
    completionGetList getListCallBack;
    completionDownloadFile downloadFileCallBack;
    completionUploadFile uploadFileCallBack;
}

@property (nonatomic, strong) GRRequestsManager *requestsManager;
@property (nonatomic, strong) NSString *hostname;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, assign) BOOL isSavePasswordEnabled;

- (void)setupRequestManager;

@end

@implementation FTPRequestController

#pragma mark - Private Methods

-(BOOL)array:(NSArray*)array containsString:(NSString*)name {
    for(NSString *str in array)
    {
        if([name isEqualToString:str])
            return YES;
    }
    return NO;
}

- (void)setupRequestManager {
    
    self.requestsManager = nil;
    
    if (nil != self.hostname && nil != self.username && nil != self.password) {
        self.requestsManager = [[GRRequestsManager alloc] initWithHostname:self.hostname
                                                                      user:self.username
                                                                  password:self.password];
        self.requestsManager.delegate = self;
    }
    else
    {
        
    }
}

#pragma mark - Instance Method

- (id<GRRequestProtocol>)getFileListWithInfo:(NSDictionary *) userInfo withCompletionHandler:(completionGetList) callback {
    self.hostname = [userInfo objectForKey:kCurrentHostKey];
    self.username = [userInfo objectForKey:kCurrentUserKey];
    self.password = [userInfo objectForKey:kCurrentPasswordKey];
    
    NSNumber *savePassObj = [userInfo objectForKey:kSavePasswordEnabledKey];
    
    if(savePassObj)
    {
        self.isSavePasswordEnabled = [savePassObj boolValue];
    }
    else
    {
        self.isSavePasswordEnabled = YES;
    }
    
    
    [self setupRequestManager];
    id<GRRequestProtocol> request = [self.requestsManager addRequestForListDirectoryAtPath:@"/"];
    [self.requestsManager startProcessingRequests];

    getListCallBack = callback;
    
    return request;
}

- (id<GRDataExchangeRequestProtocol>)downloadFileWithInfo:(NSDictionary *) userInfo withCompletionHandler:(completionGetList) callback {
    
    NSString *hostName = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentHostKey];
    NSURLProtectionSpace *protectionSpace = [Utilities protectionSpaceForHost:hostName];
    NSDictionary *credDic = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protectionSpace];
    NSArray *userNameArray = [credDic allKeys];
    NSURLCredential *cred = [credDic objectForKey:[userNameArray objectAtIndex:0]];
    
    self.hostname = [protectionSpace host];
    self.username = [cred user];
    self.password = [cred password];
    
    NSNumber *savePassObj = [userInfo objectForKey:kSavePasswordEnabledKey];
    
    if(savePassObj)
    {
        self.isSavePasswordEnabled = [savePassObj boolValue];
    }
    else
    {
        self.isSavePasswordEnabled = YES;
    }
    
    [self setupRequestManager];

    NSString *remotePath = [userInfo valueForKey:kFilePathKey];
    NSString *filePath = [[Utilities documentsDirectoryPath] stringByAppendingPathComponent:[Utilities generateFileNameWithExtension:remotePath.pathExtension]];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];

    id<GRDataExchangeRequestProtocol> request = [self.requestsManager addRequestForDownloadFileAtRemotePath:[remotePath lastPathComponent] toLocalPath:filePath];
    [self.requestsManager startProcessingRequests];

    downloadFileCallBack = callback;

    return request;
}

- (id<GRDataExchangeRequestProtocol>)uploadFileWithInfo:(NSDictionary *) userInfo withCompletionHandler:(completionUploadFile) callback {
    NSString *hostName = [[NSUserDefaults standardUserDefaults] stringForKey:kCurrentHostKey];
    NSURLProtectionSpace *protectionSpace = [Utilities protectionSpaceForHost:hostName];
    NSDictionary *credDic = [[NSURLCredentialStorage sharedCredentialStorage] credentialsForProtectionSpace:protectionSpace];
    NSArray *userNameArray = [credDic allKeys];
    NSURLCredential *cred = [credDic objectForKey:[userNameArray objectAtIndex:0]];
    
    self.hostname = [protectionSpace host];
    self.username = [cred user];
    self.password = [cred password];
    
    NSNumber *savePassObj = [userInfo objectForKey:kSavePasswordEnabledKey];
    
    if(savePassObj)
    {
        self.isSavePasswordEnabled = [savePassObj boolValue];
    }
    else
    {
        self.isSavePasswordEnabled = YES;
    }
    
    [self setupRequestManager];
    
    NSString *localFilePath = [userInfo valueForKey:kFilePathKey];
    NSString *remotePath = [NSString stringWithFormat:@"/%@", [localFilePath lastPathComponent]];
    
    id<GRDataExchangeRequestProtocol> request = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:localFilePath]) {
        request = [self.requestsManager addRequestForUploadFileAtLocalPath:localFilePath toRemotePath:remotePath];
        [self.requestsManager startProcessingRequests];
        uploadFileCallBack = callback;
    }
    
    return request;
}

#pragma mark - GRRequestsManagerDelegate

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didScheduleRequest:(id<GRRequestProtocol>)request {
    NSLog(@"requestsManager:didScheduleRequest:");
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteListingRequest:(id<GRRequestProtocol>)request listing:(NSArray *)listing {
    NSLog(@"requestsManager:didCompleteListingRequest:listing: \n%@", listing);
    
    if (nil != listing)
    {
        NSString *hostUrl = [request hostString];
        [[NSUserDefaults standardUserDefaults] setObject:hostUrl forKey:kCurrentHostKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSURLProtectionSpace *protectionSpace = [Utilities protectionSpaceForHost:self.hostname];

        NSURLCredential *credential = [NSURLCredential credentialWithUser:self.username
                                                                 password:(self.isSavePasswordEnabled ? self.password : @"")
                                                              persistence:NSURLCredentialPersistencePermanent];
        
        [[NSURLCredentialStorage sharedCredentialStorage] removeCredential:credential forProtectionSpace:protectionSpace];
        [[NSURLCredentialStorage sharedCredentialStorage] setCredential:credential forProtectionSpace:protectionSpace];

        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:listing, kFileListArrayKey, @"Listing Completed Successfully", kRequestCompleteAlertKey, nil];
        getListCallBack(dic);
    }
    else
    {
        NSError *error = [NSError errorWithDomain:kNetworkErrorDomain code:FileListingErrorCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error in file listing", @"message", nil]];
        
        NSDictionary *errorDic = [NSDictionary dictionaryWithObjectsAndKeys:error, kFileListingErrorKey, nil];
        getListCallBack(errorDic);
    }
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteCreateDirectoryRequest:(id<GRRequestProtocol>)request {
    NSLog(@"requestsManager:didCompleteCreateDirectoryRequest:");
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteDeleteRequest:(id<GRRequestProtocol>)request {
//    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@"Delete Completed Successfully", kRequestCompleteAlertKey, nil];
    NSLog(@"requestsManager:didCompleteDeleteRequest:");
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteUploadRequest:(id<GRDataExchangeRequestProtocol>)request {
    NSLog(@"requestsManager:didCompleteUploadRequest:");
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@"Upload Completed Successfully", kRequestCompleteAlertKey, self, kRequestManagerObjKey, nil];
    uploadFileCallBack(dic);
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteDownloadRequest:(id<GRDataExchangeRequestProtocol>)request {
    NSLog(@"requestsManager:didCompleteDownloadRequest:");
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:@"Download Completed Successfully", kRequestCompleteAlertKey, nil];
    downloadFileCallBack(dic);
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompletePercent:(float)percent forRequest:(id<GRRequestProtocol>)request {
    NSLog(@"requestsManager:didCompletePercent:forRequest: %f", percent);
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:percent], kRequestCompletePercentKey, self, kRequestManagerObjKey, nil];
    
    if (nil != getListCallBack) {
        getListCallBack(dic);
    }
    
    if (nil != downloadFileCallBack) {
        downloadFileCallBack(dic);
    }
    
    if (nil != uploadFileCallBack) {
        uploadFileCallBack(dic);
    }
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailRequest:(id<GRRequestProtocol>)request withError:(NSError *)error {
    NSLog(@"requestsManager:didFailRequest:withError: \n %@", error);
    NSDictionary *errorDic = [NSDictionary dictionaryWithObjectsAndKeys:error, kLoginErrorKey, self, kRequestManagerObjKey, nil];
    
    if (nil != getListCallBack) {
        getListCallBack(errorDic);
    }
    
    if (nil != downloadFileCallBack) {
        downloadFileCallBack(errorDic);
    }
    
    if (nil != uploadFileCallBack) {
        uploadFileCallBack(errorDic);
    }
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailWritingFileAtPath:(NSString *)path forRequest:(id<GRDataExchangeRequestProtocol>)request error:(NSError *)error {
    NSLog(@"requestsManager:didFailWritingFileAtPath:forRequest:error: \n %@", error);
    
    NSDictionary *errorDic = [NSDictionary dictionaryWithObjectsAndKeys:error, kLoginErrorKey, nil];
    
    if (nil != uploadFileCallBack) {
        uploadFileCallBack(errorDic);
    }
}

@end
