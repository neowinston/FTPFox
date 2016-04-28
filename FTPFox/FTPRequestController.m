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

- (IBAction)listingButton:(id)sender;
- (IBAction)createDirectoryButton:(id)sender;
- (IBAction)deleteDirectoryButton:(id)sender;
- (IBAction)deleteFileButton:(id)sender;
- (IBAction)uploadFileButton:(id)sender;
- (IBAction)downloadFileButton:(id)sender;

- (void)setupRequestManager;

@end

@implementation FTPRequestController

- (IBAction)listingButton:(id)sender {
    [self setupRequestManager];
    [self.requestsManager addRequestForListDirectoryAtPath:@"/"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)createDirectoryButton:(id)sender {
    [self setupRequestManager];
    [self.requestsManager addRequestForCreateDirectoryAtPath:@"dir/"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)deleteDirectoryButton:(id)sender {
    [self setupRequestManager];
    [self.requestsManager addRequestForDeleteDirectoryAtPath:@"dir/"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)deleteFileButton:(id)sender {
    [self setupRequestManager];
    [self.requestsManager addRequestForDeleteFileAtPath:@"dir/file.txt"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)uploadFileButton:(id)sender {
    [self setupRequestManager];
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"TestFile" ofType:@"txt"];
    [self.requestsManager addRequestForUploadFileAtLocalPath:bundlePath toRemotePath:@"dir/file.txt"];
    [self.requestsManager startProcessingRequests];
}

- (IBAction)downloadFileButton:(id)sender {
    [self setupRequestManager];
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *localFilePath = [documentsDirectoryPath stringByAppendingPathComponent:@"DownloadedFile.txt"];

    [self.requestsManager addRequestForDownloadFileAtRemotePath:@"dir/file.txt" toLocalPath:localFilePath];
    [self.requestsManager startProcessingRequests];
}

#pragma mark - Private Methods

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

- (id<GRRequestProtocol>)downloadFileWithInfo:(NSDictionary *) userInfo withCompletionHandler:(completionGetList) callback {
    
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

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
    NSString *filePath = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"nilesh1883.%@", remotePath.pathExtension]];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];

    
    id<GRRequestProtocol> request = [self.requestsManager addRequestForDownloadFileAtRemotePath:remotePath toLocalPath:filePath];
    [self.requestsManager startProcessingRequests];
    
    
    downloadFileCallBack = callback;
    
    return request;
}

- (id<GRRequestProtocol>)uploadFileWithInfo:(NSDictionary *) userInfo withCompletionHandler:(completionUploadFile) callback {
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
    NSString *remotePath = hostName;
    
    if (nil != hostName) {
        hostName = [NSString stringWithFormat:@"ftp://%@/%@", hostName, [localFilePath lastPathComponent]];
    }
    
    id<GRRequestProtocol> request = [self.requestsManager addRequestForUploadFileAtLocalPath:remotePath toRemotePath:localFilePath];
    [self.requestsManager startProcessingRequests];
    
    
    uploadFileCallBack = callback;
    
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
        
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:listing, kFileListArrayKey, nil];
        getListCallBack(dic);
    }
    else
    {
        NSError *error = [NSError errorWithDomain:kNetworkErrorDomain code:FileListingErrorCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Error in file listing", @"message", nil]];
        
        NSDictionary *errorDic = [NSDictionary dictionaryWithObjectsAndKeys:error, kFileListingErrorKey, nil];
        getListCallBack(errorDic);
    }
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailRequest:(id<GRRequestProtocol>)request withError:(NSError *)error {
    NSLog(@"requestsManager:didFailRequest:withError: \n %@", error);
    NSDictionary *errorDic = [NSDictionary dictionaryWithObjectsAndKeys:error, kLoginErrorKey, nil];

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

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteCreateDirectoryRequest:(id<GRRequestProtocol>)request {
    NSLog(@"requestsManager:didCompleteCreateDirectoryRequest:");
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteDeleteRequest:(id<GRRequestProtocol>)request {
    NSLog(@"requestsManager:didCompleteDeleteRequest:");
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompletePercent:(float)percent forRequest:(id<GRRequestProtocol>)request {
    NSLog(@"requestsManager:didCompletePercent:forRequest: %f", percent);
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteUploadRequest:(id<GRDataExchangeRequestProtocol>)request {
    NSLog(@"requestsManager:didCompleteUploadRequest:");
    uploadFileCallBack(nil);
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didCompleteDownloadRequest:(id<GRDataExchangeRequestProtocol>)request {
    NSLog(@"requestsManager:didCompleteDownloadRequest:");
    downloadFileCallBack(nil);
}

- (void)requestsManager:(id<GRRequestsManagerProtocol>)requestsManager didFailWritingFileAtPath:(NSString *)path forRequest:(id<GRDataExchangeRequestProtocol>)request error:(NSError *)error {
    NSLog(@"requestsManager:didFailWritingFileAtPath:forRequest:error: \n %@", error);
    
    NSDictionary *errorDic = [NSDictionary dictionaryWithObjectsAndKeys:error, kLoginErrorKey, nil];
    
    if (nil != uploadFileCallBack) {
        uploadFileCallBack(errorDic);
    }
}

@end
