//
//  FTPFoxTests.m
//  FTPFoxTests
//
//  Created by Nilesh Jaiswal on 08/05/16.
//  Copyright © 2016 Nilesh Jaiswal. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LoginViewController.h"
#import "AppDelegate.h"

@interface LoginViewController(Test) {
    
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButton;
@property (weak, nonatomic) IBOutlet UITextField *serverTextField;
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UISwitch *savePasswordSwitch;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

- (IBAction)loginButtonClicked:(UIButton *)sender;
- (IBAction)cancelButtonClicked:(UIBarButtonItem *)sender;
- (IBAction)savePwdValueChange:(UISwitch *)sender;

@end


@interface FTPFoxTests : XCTestCase {
// add instance variables to the CalcTests class
@private
    LoginViewController     *loginViewController;
}

@end

@implementation FTPFoxTests

- (void)setUp {
    [super setUp];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [loginViewController view];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    loginViewController = nil;
    [super tearDown];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testViewControllerViewExists {
    XCTAssertNotNil([loginViewController view], @"ViewController should contain a view");
}

- (void)testUserNameTextFieldConnection {
    XCTAssertNotNil([loginViewController userNameTextField], @"userNameTextField should be connected");
}

- (void)testPasswordTextFieldConnection {
    XCTAssertNotNil([loginViewController passwordTextField], @"passwordTextField should be connected");
}

- (void)testCancelBarButtonConnection {
    XCTAssertNotNil([loginViewController cancelBarButton], @"cancelBarButton should be connected");
}

- (void)testSavePasswordSwitchConnection {
    XCTAssertNotNil([loginViewController savePasswordSwitch], @"savePasswordSwitch should be connected");
}

- (void)testLoginButtonConnection {
    XCTAssertNotNil([loginViewController loginButton], @"loginButton should be connected");
}

- (void)testLoginButtonCheckIBAction {
    NSArray *actions = [loginViewController.loginButton actionsForTarget:loginViewController forControlEvent:UIControlEventTouchUpInside];
    XCTAssertTrue([actions containsObject:@"loginButtonClicked:"], @"Login action is not connected");
}

- (void)testCancelButtonCheckIBAction {
    SEL action = [loginViewController.cancelBarButton action];
    XCTAssertTrue([NSStringFromSelector(action) isEqualToString:@"cancelButtonClicked:"],
                  @"Cancel action is not connected");
}

- (void)testSaveSwitchCheckIBAction {
    NSArray *actions = [loginViewController.savePasswordSwitch actionsForTarget:loginViewController forControlEvent:UIControlEventValueChanged];
    XCTAssertTrue([actions containsObject:@"savePwdValueChange:"], @"Save password swtch action is not connected");
}

- (void)testLoninClickNoFieldShouldBeEmpty {
    loginViewController.serverTextField.text = @"10";
    loginViewController.userNameTextField.text = @"20";
    loginViewController.passwordTextField.text = @"30";
    
    [loginViewController.loginButton sendActionsForControlEvents: UIControlEventTouchUpInside];
    
    XCTAssertFalse([loginViewController.serverTextField.text isEqualToString:@""], @"Host textfield should not be empty");

    XCTAssertFalse([loginViewController.userNameTextField.text isEqualToString:@""], @"Username textfield should not be empty");

    XCTAssertFalse([loginViewController.passwordTextField.text isEqualToString:@""], @"Password textfield should not be empty");
}

@end
